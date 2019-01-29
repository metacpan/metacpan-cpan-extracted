package PMLTQ::PML2BASE;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::PML2BASE::VERSION = '3.0.1';
# ABSTRACT: Convert from PML to SQL


use 5.006;
use strict;
use warnings;
$|=1;
use Data::Dumper;

use open qw(:std :utf8);
use Carp;

# $SIG{__WARN__} = sub { Carp::cluck(@_); };

use constant MAX_NAME_LENGTH => 16;

use constant HYBRID=>1;        # create both separate node table and node table with attributes
use constant NO_TREE_TABLE=>2; # don't create one common common node table for all node types
use constant MAX_MIN_ORD=>4;   # node tables have #max_ord and #min_ord columns
use constant TOP_TREE_FLAG=>8; # The <root>__#files table has a 'top' column indicating that
                               # a given root node belongs to the top-level tree list
                               # of a file (i.e. it is not a nested #NODE within
                               # some non-#NODE and non-#TREES data structure)
#
# Generic SQL DB scheme for PML data:
#
# - every structure/container/ has a unique idx (Number) and carries attributes as columns
#
# - container has a '#content' column
#
# - cdata/constant/choice attributes are stored in the respective columns
#
# - structure/container members are in a separate table where they have a unique idx,
#   referred to by the member column
#
# - unordered-list/alt members are stored in a separate table, whose columns
#   are a 1:N idx referred to by the member column, and a LM/AM column
#   containing the value (following the rules described here);
#
# - sequence members are in a separate table whose columns correspond
#   to the elements, each containing an reference to a table
#   representing all occurrences of that element; this table has
#   an 1:N idx, '#pos' containing position of the element in the sequence,
#   '#elem-pos' containing the number of preceding elements of the same name in the sequence+1,
#   and the value, as usual. To retrieve a complete content of a certain sequence as a table,
#   one has to use a UNION on all the element tables, ordering by #pos and possibly outputing
#   a constant '#name' column
#
# - the table names should be derived from PML type names in a canonical way,
#   one per PML schema type decl
#
# Possible modifications:
#
# a) cast all cdata structure members also into separate tables and thus
#    keep varchar data in separate tables
#
# b) cast node attributes to a separate table, separating the tree structure
#    from node data, making the tree-structure table very thin
#    in fact: this is necessary, since nodes can be of different types
#
# c) use cdata format information to determine the table column format
#
#  some hacks:
#
#  - updating refs in strips .rf suffix if the member is a PMLREF but
#    not if it is a list of PMLREFs
#
#  - prefix of PMLREFs is stripped down; should be kept and
#    used to verify the target based on filename on UPDATE
#
#

use Treex::PML::Schema;
use Treex::PML::Instance;
use PMLTQ::Common;
use PMLTQ::Relation;
use List::Util qw(max first);
use Cwd;
use Carp;

PMLTQ::Relation->load();

my ($file_table,$root_name,$schema,$references_table,%schema,%fh,%orig_name,%seen_ref_schema,
    $node_table,$index_id,$last_type_no,$tree_no,$filename,
    $idx,$node_idx, $last_tree_no, %pmlref_target_info, $relations, @dump_fns
   );

our %opts;

sub init {
  $idx = $opts{'init-idx'} || 0;
  $node_idx=($opts{'init-node-idx'}|| $opts{'init-idx'} || 0);
  $last_type_no=0;
  $index_id=0;
  $tree_no=0;
  $filename=undef;
  $relations=[];
  @dump_fns=();

  %pmlref_target_info=();

  $opts{'related-schema'} ||= [];
  $opts{other_schemas}||=[
    map {
      Treex::PML::Schema->new({filename=>$_,use_resources=>1})
    } @{$opts{'related-schema'}}
  ];
  $opts{hybrid}||=1;
  $opts{prefix}||='';
  $opts{'data-dir'}||='';
}

sub destroy {
  undef $file_table;
  undef $root_name;
  undef $schema;
  undef $references_table;
  undef %schema;
  undef %fh;
  undef %orig_name;
  undef %seen_ref_schema;
  undef $node_table;
  undef $index_id;
  undef $last_type_no;
  undef $tree_no;
  undef $filename;
  undef $idx;
  undef $node_idx;
  undef $last_tree_no;
  undef %pmlref_target_info;
  undef %opts;
  undef $relations;
}

sub varchar { ### TODO REMOVE
  my ($l,$non_ascii)=@_;
  return "VARCHAR($l)";
}
sub numeric { ### TODO REMOVE
  my ($l)=@_;
  return "NUMERIC($l)";
}
sub boolean { ### TODO REMOVE
  my ($l)=@_;
  return "BOOLEAN";
}

sub mkdump {
  return join("\t",map {
    if (defined) {
      my $x=$_;
      $x=~s/[\t\n]/ /g;
      $x=~s/(\\|\r)/\\$1/g;
      $x
    } else {
      "\\N"
    }
  } @_)."\n";
}
sub mkload {
  my ($f,$opts)=@_;
  if ($opts && $opts->{quiet}) {
    return qq{  run_sql_commands '$f' 2>/dev/null 1>&2\n};
  } else {
    return qq{  run_sql_commands '$f'\n};
  }
}
sub mkdataload {
  my ($f,$opts)=@_;
  if ($opts && $opts->{quiet}) {
    return qq{  run_loader_commands '$f' 2>/dev/null 1>&2\n};
  } else {
    return qq{  run_loader_commands '$f'\n};
  }
}

sub complete_schema_pmlref_list {
  my ($schema)=@_;
  $schema->for_each_decl(
    sub {
      my ($decl)=@_;
      my $decl_is = $decl->get_decl_type;
      return if ($decl->get_role||'') eq '#CHILDNODES';
      return if $decl_is == PML_TYPE_DECL or $decl_is==PML_ROOT_DECL;
      my $p=$decl->get_parent_decl;
      return if ($p and $p->get_decl_type == PML_MEMBER_DECL and ($p->get_role||'') eq '#CHILDNODES');
      return if $decl->is_atomic;
      my $table = table_name($decl,1);
      my @m;
      if ($decl_is == PML_STRUCTURE_DECL) {
        @m = map [$_->get_name, $_->get_knit_content_decl], $decl->get_members;
      } elsif ($decl_is == PML_CONTAINER_DECL) {
        @m = ['#content', $_->get_content_decl],map [$_->get_name, $_->get_content_decl], $decl->get_attributes;
      } elsif ($decl_is == PML_SEQUENCE_DECL) {
        @m = map [$_->get_name, $_->get_knit_content_decl], $decl->get_elements;
      } elsif ($decl_is == PML_LIST_DECL or $decl_is == PML_ALT_DECL) {
        @m = ['#value', $decl->get_knit_content_decl];
      } else { return }
      foreach my $member (@m) {
        next unless $member->[1] and $member->[1]->get_decl_type == PML_CDATA_DECL and
          $member->[1]->get_format eq 'PMLREF';
        my $p=$member->[1]->get_parent_decl;
        next if ($p and (($p->get_role||'') eq '#KNIT'
                               or ($p->get_decl_type == PML_LIST_DECL or $p->get_decl_type == PML_ALT_DECL)
                                 and ($p->get_role||'') eq '#KNIT'));
        my $path =$member->[0] eq '#value' ? $table : $table.'/'.$member->[0];
        unless (ref($opts{ref}) and exists ($opts{ref}{$path})) {
          $opts{ref}{$path}='-';
        }
      }
    });
  return ($opts{ref}||={});
}

# test if a given DECL is a known PMLREF type
# that we can handle
# It can aslo produce a warning when finding an unknown PMLREF

sub get_pmlref_target_info {
  my ($decl,$table,$column,$warn) = @_;
  if (!$warn and exists($pmlref_target_info{$decl})) {
    return @{$pmlref_target_info{$decl}};
  }
  my $ret = ($pmlref_target_info{$decl}||=[]);
  return unless $decl->get_decl_type == PML_CDATA_DECL and $decl->get_format eq 'PMLREF';
  my $p=$decl->get_parent_decl;
  unless ($p and (($p->get_role||'') eq '#KNIT'
                    or ($p->get_decl_type == PML_LIST_DECL or $p->get_decl_type == PML_ALT_DECL)
                      and ($p->get_role||'') eq '#KNIT')) {
    my $o_name = $orig_name{$table} || $table;
    my $path =$column eq '#value' ? $o_name : $o_name.'/'.$column;
    unless (ref($opts{ref}) and exists ($opts{ref}{$path})) {
      warn "UNHANDLED PMLREF: $path\n" if $warn;
      return;
    }
    if ($opts{ref}{$path} ne '-') { # ignore
      @{$ret} = split(/:/,$opts{ref}{$path},2);
      return @$ret;
    }
  }
  return;
}

# column_spec returns one or more values for colspec
sub column_spec {
  my ($table,$column,$decl,$is_required,$role)=@_;
  my $create_index = (!$decl->is_atomic or (($role||'') eq '#ID')) ? 1 : 0;
  confess("cannot determine column type for undefined declaration")
    unless defined $decl;
  my $decl_is = $decl->get_decl_type;
  my $constraint = $is_required ? ' NOT NULL' : '';
  if ($decl_is == PML_CHOICE_DECL || $decl_is == PML_CONSTANT_DECL) {
    my $max = max(map length, $decl->get_values);
    if (first { !/^(?:0|-?[1-9][0-9]*(?:\.[0-9]*[1-9])?)$/ } $decl->get_values) {
      return [$column => varchar($max).$constraint,$create_index];
    } else {
      return [$column => numeric($max).$constraint,$create_index];
    }
  } elsif ($decl_is == PML_CDATA_DECL) {
    my $format = $decl->get_format;
    return [$column => 'INT'.$constraint,$create_index] if $format =~ /(integer$|int$|short$|byte|long)/i;
    return [$column => boolean().$constraint,$create_index] if $format eq 'boolean';
    return [$column => 'FLOAT'.$constraint,$create_index] if $format =~ /(decimal$|float$|double$)/i;
    if ($format eq 'PMLREF') {
      my ($target,$target_type) = get_pmlref_target_info($decl,$table,$column,1);
      if ((!$opts{'no-schema'} || $opts{'incremental'} ) and
          (defined($target) or defined($target_type))) {
        if (!$target_type) {
          $target_type=$target;
          $target=$root_name;
        }
        my $target_id;
        if ($target_type=~s/[@](.*)$//) {
          $target_id=$1;
        }
        my $comment = "Updating PMLREF column: $table/$column refers to nodes in $target of type $target_type";
        my $col = $column;
        $col=~s/\.rf$//;
        # Possible fix for #329 - table name is renamed twice
        #$table = rename_type($table);
        my $tt;
        if ($target eq $root_name) {
          $tt = rename_type($target_type);
        } else {
          $tt = q(' || tab || ');
        }
        my $rename='';
#         if ($opts{syntax}=~/(oracle|postgres)/) {
#           $rename=<<"EOF";
# ALTER TABLE "$table" RENAME COLUMN "#tmp" TO "$col";
# EOF
#         } else {
#           $rename=<<"EOF";
# ALTER TABLE "$table" ADD "$col" INT;
# UPDATE "$table" t SET "$col"="#tmp";
# ALTER TABLE "$table" DROP COLUMN "#tmp";
# EOF
#         }
        unless ($target_id) {
          my $target_decl = eval { PMLTQ::Common::QueryTypeToDecl($target_type,$schema,@{$opts{other_schemas}}) };
          warn $@ if $@;
          if ($target_decl) {
            my $decl_is = $target_decl->get_decl_type;
            if ($decl_is==PML_STRUCTURE_DECL or
                  $decl_is==PML_CONTAINER_DECL) {
              my ($id_m) = $target_decl->find_members_by_role('#ID');
              if ($id_m) {
                $target_id = $id_m->get_name;
              }
            }
          }
          $target_id||='id';
        }
        my $sql = <<"EOF";
UPDATE "$table" t SET "$col"=(SELECT a."#idx" FROM "$tt" a WHERE a."$target_id"=t."$column~" LIMIT 1) WHERE "$col" IS NULL;
EOF
        unless ($opts{incremental}) {
          $sql .= <<"EOF";
ALTER TABLE "$table" DROP COLUMN "$column~";
EOF
        }
#         unless ($opts{'no-schema'}) {
#           $sql .= <<"EOF";
# CREATE INDEX "#i_${root_name}_$index_id" ON "$table" ("$col");
# EOF
#         }
        unless ($target eq $root_name) {
          $sql =~ s/'/''/g;
            my $execute = join("\n",map {qq(EXECUTE (''$_'');)} grep !/^\s*--/, grep /\S/, split /;\s*\n/, $sql);
            $sql = <<"EOF"
CREATE OR REPLACE FUNCTION pml2base__update_pmlref() RETURNS integer AS '
DECLARE
  tab VARCHAR(40);
BEGIN
  SELECT "table" INTO tab FROM "#PMLTABLES" WHERE "type"=''$target_type'';
  IF tab IS NULL THEN tab := ''$target_type'';  END IF;
$execute
  RETURN 1;
END;
' LANGUAGE plpgsql;

SELECT pml2base__update_pmlref();

DROP FUNCTION pml2base__update_pmlref();

EOF
        }
        $fh{'#POST_SQL'}->print($sql);
        $index_id++;
        #my $fk="";
        #$fk=' FOREIGN KEY REFERENCES "$tt" ("#idx")' if $target eq $root_name;
        {
          my $col = $column;
          $col=~s/\.rf$//;
          return ([$column.'~' => 'STRING()'.$constraint,1], [$col => 'INT',1]);
        }
      }
    }
    return [$column => 'STRING()'.$constraint,$create_index];
  } else {
    my $ref = table_name($decl);
    return [$column => qq{INT${constraint} FOREIGN KEY REFERENCES "$ref" ("#idx")}, 1]
      if ($decl_is==PML_CONTAINER_DECL or $decl_is==PML_STRUCTURE_DECL or $decl_is==PML_SEQUENCE_DECL);
    return [$column => 'INT'.$constraint, $create_index];
  }
}

sub to_filename {
  my ($tab,$ext)=@_;
  $ext ||= 'dump';
  $tab=~s{/}{_0}g;
  if ($tab=~s/__#/__1/s) {
    return $tab.'.'.$ext;
  } else {
    return $root_name.'__'.$tab.'.'.$ext;
  }
}
sub table2filename {
  my ($tab,$ext)=@_;
  $tab=~s{/#content((?:/|$))}{/7content$1}g;
  if ($tab=~/#/) {
    return to_filename($tab,$ext);
  } else {
    $ext ||= 'dump';
    $tab=~s{/}{_0}g;
    return $root_name.'__type_'.$tab.'.'.$ext;
  }
}

sub _abs2rel {
  my ($file)=@_;
  my $base=$opts{'data-dir'}; # we assume base has already been abs-path'ed
  return $file unless defined($base) and length($base);
  if (UNIVERSAL::isa($file,'URI')) {
    if ($file->scheme eq 'file') {
      $file=$file->file;
    } elsif (!$file->scheme) {
      $file->scheme('file');
      $file=$file->file;
    } else {
      return $file;
    }
  }
  # This shouldn't be needed anymore
  #$file = Cwd::abs_path($file);
  return File::Spec->abs2rel($file,$base);
}

sub abs2rel {
  my ($file)=@_;
  my $ret = _abs2rel($file);
  croak "Incorrect --data_dir value '$opts{'data-dir'}' (resolved to '$ret') or invalid filename '$file'\n"
    ."Explanation: Paths stored in the database should not start with ../ since this breaks URLs"
      if $ret=~m{^\.\.};
  return $ret;
}

our %node_schema = (
  colspec => [
    ["#idx", 'INT NOT NULL PRIMARY KEY',0],
    ["#r", 'INT NOT NULL', 1],
    ["#lvl", 'INT NOT NULL',0],
    ["#chld", 'INT NOT NULL',0],
    ["#chord", 'INT NOT NULL',0],
    ["#parent_idx", 'INT', 1],
    ["#root_idx", 'INT NOT NULL', 1],
    ["#name", 'STRING()',0],
    ["#type", 'STRING()',0],
    ["#min_ord", 'INT',0],
    ["#max_ord", 'INT',0],
    # ["#ID", 'STRING()',0]
   ],
);

sub convert_schema {
  $schema = shift;
  my ($opts)=@_;
  if ($opts{'load-rename-map'}) {
    open my $fh, '<:utf8', $opts{'load-rename-map'} or die "Cannot load rename map: $!\n";
    while (<$fh>) {
      chomp;
      my ($k,$v)=split /\t/,$_;
      $opts{'rename-type'}{$k}=$v;
    }
    close $fh;
  }
  if ($opts{'rename-type'}) {
    %orig_name=(reverse %{$opts{'rename-type'}});
  } else {
    %orig_name=();
  }

  # in theory, we can now check whether we need #min_ord and #max_ord at all
  # and drop them if not

  $root_name= $opts{prefix}.$schema->get_root_name;
  $node_table = $root_name."__#trees";
  $file_table = $root_name."__#files";
  $references_table = $root_name."__#references";
  my $pmlref_table = $root_name."__#pmlref_map";
  open $fh{'#INIT_LIST'},'>',get_full_path(to_filename("init",'list')) || die "$!";
  unless ($opts{'no-schema'}) {
    open $fh{'#INIT_SQL'},'>',get_full_path(to_filename("init",'sql'))  || die "$!";
    open $fh{'#DELETE_SQL'},'>',get_full_path(to_filename("delete",'sql'))  || die "$!";
  }
  unless ($opts{'no-schema'} and !$opts{'incremental'}) {
    open $fh{'#POST_SQL'},'>',get_full_path(to_filename("postprocess",'sql'))  || die "$!";
  }
  open $fh{'#FILE_TABLE'},'>',get_full_path(to_filename($file_table))  || die "$!";
  open $fh{'#REFFILE_TABLE'},'>',get_full_path(to_filename($references_table))  || die "$!";
  open $fh{$node_table},'>',get_full_path(to_filename($node_table))  || die "$!";

  my ($db_cmd,$ldr_cmd,$extra_flags);
  $extra_flags='';
  $db_cmd = 'psql';
  $ldr_cmd = 'psql';
  if ($opts{'schema'} and !$opts{'incremental'}) {
    $extra_flags.=' --init|--finish'
  }

  $schema{$node_table} = {
    table => $node_table,
    %node_schema,
  };
  $schema{$file_table} = {
    '#decl_order' => 0,
    table => $file_table,
    colspec => [
      ["#idx", 'INT NOT NULL PRIMARY KEY',0],
      ["file", 'STRING()',0],
      ["tree_no", 'INT',0],
      ["top", boolean(),0],
     ],
    col => { file=>0 },
  };
  $schema{$references_table} = {
    '#decl_order' => 0,
    table => $references_table,
    colspec => [
      ["source", 'STRING()',0],
      ["name", 'STRING()',0],
      ["id", 'STRING()',1],
      ["file", 'STRING()',0],
     ],
    col => { file=>0, name=>0, id=>0, source=>0 },
  };


  unless ($opts{'no-schema'}) {
    $fh{'#INIT_LIST'}->print(to_filename("delete",'sql')."\n");
    $fh{'#INIT_LIST'}->print(to_filename("init",'sql')."\n");
    dump_schema($schema);
    for my $decl ($schema->node_types) {
      my $tab = table_name($decl,1);
      $fh{'#INIT_SQL'}->print(qq{INSERT INTO "#PMLTYPES" VALUES('$tab','$root_name');\n\n});
    }
    $fh{'#DELETE_SQL'}->print(qq{DELETE FROM "#PML" WHERE "root"='$root_name';\n\n});
    $fh{'#DELETE_SQL'}->print(qq{DELETE FROM "#PMLTYPES" WHERE "root"='$root_name';\n\n});

    #   $fh{'#INIT_SQL'}->print(qq{CREATE TABLE "" (}.
    #                             qq{ "ref_type" }.varchar(128).
    #                             qq{, "ref_table" }.varchar(MAX_NAME_LENGTH).
    #                             qq{, "target_layer" }.varchar(128).
    #                             qq{, "target_table" }.varchar(MAX_NAME_LENGTH).
    #                             qq{, "target_type" }.varchar(128).
    #                             qq{, "pmref" }.boolean().qq{);\n});
    $fh{'#INIT_SQL'}->print(qq{CREATE TABLE "$pmlref_table" (}.
                               qq{ "ref_type" }.varchar(128).
                            qq{, "ref_table" }.varchar(MAX_NAME_LENGTH).
                            qq{, "target_layer" }.varchar(128).
                            qq{, "target_table" }.varchar(MAX_NAME_LENGTH).
                            qq{, "target_type" }.varchar(128).qq{);\n\n});
    $fh{'#DELETE_SQL'}->print(qq{DROP TABLE IF EXISTS "$pmlref_table";\n\n});
    for my $k (sort keys %{$opts{ref}}) {
      my ($t1,$t2) = split /:/,$opts{ref}{$k};
      unless ($t2) {
        $t2=$t1;
        $t1=$root_name;
      }
      my $tab = rename_type($k);
      if ($t1 eq $root_name) {
        my $tab = rename_type($t2);
        $fh{'#INIT_SQL'}->print(qq{INSERT INTO "$pmlref_table" VALUES('$k','$tab','$t1','$tab','$t2');\n\n});
      } else {
        $fh{'#INIT_SQL'}->print(qq{INSERT INTO "$pmlref_table" VALUES('$k','$tab','$t1',}.
                                  qq{(SELECT "table" FROM "#PMLTABLES" WHERE "type"='$t2'),'$t2');\n\n});
        $fh{'#INIT_SQL'}->print(qq{UPDATE "$pmlref_table" SET ("target_table")=('$t2') }.
                                  qq{WHERE "ref_type"='$k' AND "target_table" IS NULL;\n\n});
      }
    }
  }

  my $decl_order=10;
  $schema->for_each_decl(
    sub {
      my ($decl)=@_;
      my $decl_is = $decl->get_decl_type;
      return if ($decl->get_role||'') eq '#CHILDNODES';
      return if $decl_is == PML_TYPE_DECL or $decl_is==PML_ROOT_DECL;
      my $p=$decl->get_parent_decl;
      if ($p and $p->get_decl_type == PML_MEMBER_DECL
            and ($p->get_role||'') eq '#CHILDNODES') {
        return;
      }
      my $table = table_name($decl);
      my $desc;
      my $is_node = (($opts{no_tree_table}||$opts{hybrid}) && (($decl->get_role||'') eq '#NODE')) ? 1  : 0;
      if ($decl_is == PML_STRUCTURE_DECL) {
        my @m = grep {
          (!defined($_->get_role) or ($_->get_role ne '#CHILDNODES' and $_->get_role ne '#TREES'))
            and (($_->get_content_decl && $_->get_content_decl->get_role ||'') ne '#TREES')
          } $decl->get_members;
        $desc = {
          table=> $table,
          colspec => [
            ($is_node ? @{$node_schema{colspec}} : ['#idx', 'INT NOT NULL PRIMARY KEY', 0]),
            map column_spec($table,$_->get_knit_name,$_->get_knit_content_decl,$_->is_required,$_->get_role),
            @m
           ],
         };
      } elsif ($decl_is == PML_CONTAINER_DECL) {
        my ($content_decl) = grep {
          (!defined($_->get_role) or ($_->get_role ne '#CHILDNODES' and $_->get_role ne '#TREES'))
            and ((($_->get_content_decl && $_->get_content_decl->get_role) ||'') ne '#TREES')
              } grep defined, $decl->get_knit_content_decl;
        $desc = {
          table=> $table,
          colspec => [
            ($is_node ? @{$node_schema{colspec}} : ['#idx', 'INT NOT NULL PRIMARY KEY']),
            ($content_decl ? column_spec($table,"#content",$content_decl,$content_decl->get_role) : ()),
            map column_spec($table,$_->get_name,$_->get_content_decl,$_->is_required,$_->get_role), $decl->get_attributes
           ],
        };
      } elsif ($decl_is == PML_SEQUENCE_DECL) {
        $desc = {
          table=> $table,
          colspec => [
            ["#idx", 'INT NOT NULL PRIMARY KEY',0],
            map [$_->get_name,'INT',1], $decl->get_elements
           ],
         };
      } elsif ($decl_is == PML_ELEMENT_DECL) {
        my $content_decl = $decl->get_knit_content_decl;
        $table = '#e_'.table_name($content_decl);
        $desc = {
          table=> $table,
          colspec => [
            ["#idx",'INT'],
            ["#pos",'INT'],
            ["#elpos",'INT'],
            column_spec($table,'#value',$content_decl,$content_decl->get_role)
           ]
         };
      } elsif ($decl_is == PML_LIST_DECL) {
        my $content_decl = $decl->get_knit_content_decl;
        $desc = {
          table=> $table,
          colspec => [
            ["#idx",'INT',1],
            ($decl->is_ordered ? ["#pos",'INT'] : ()),
            column_spec($table,'#value',$content_decl,$content_decl->get_role),
           ]
         };
      } elsif ($decl_is == PML_ALT_DECL) {
        my $content_decl = $decl->get_knit_content_decl;
        $desc = {
          table=> $table,
          colspec => [
            ["#idx",'INT',1],
            column_spec($table,'#value',$content_decl,$content_decl->get_role),
           ]
         };
      } elsif ($decl_is == PML_CHOICE_DECL) {
      } elsif ($decl_is == PML_CONSTANT_DECL) {
      } elsif ($decl_is == PML_CDATA_DECL) {
      } elsif ($decl_is == PML_ATTRIBUTE_DECL
               || $decl_is == PML_MEMBER_DECL
               || $decl_is == PML_ELEMENT_DECL) {
        #    print $decl->get_parent_decl->get_decl_path,"/[".$decl->get_name,"]\n";
      } else {
        print STDERR "Unexpected decl: ",$decl->get_decl_type_str,"\n";
      }
      if ($desc) {
        warn "couldn't determine table name for decl $decl\n" if !defined $table;
        $desc->{'#decl_order'}=$decl_order++;
        $schema{$desc->{table}}=$desc;
        unless ($opts{schema}) {
          my $fn = table2filename($desc->{table});
          open $fh{$desc->{table}},'>',get_full_path($fn) or  die "Cannot open '$fn' for writing: $!";
        }
      }
    });
  if ($opts and ref $opts->{for_schema}) {
    $opts->{for_schema}->($schema,\%schema,\%fh);
  }

  if ($opts{'load-idx'}) {
    if (open my $fh, '<:', $opts{'load-idx'}) {
      $_ = <$fh>;
      chomp;
      ($idx, $node_idx) = split /\t/,$_,2;
      close $fh;
    } else {
      warn "Cannot load idx info: $!\n";
    }
  }
  if ($opts{'load-col-info'}) {
    open my $fh, '<:utf8', $opts{'load-col-info'} or die "Cannot load rename map: $!\n";
    while (<$fh>) {
      chomp;
      my ($table,$column,$length,$non_ascii)=split /\t/,$_;
      my $l = $schema{$table}{col}{$column}||0;
      $schema{$table}{col}{$column} = $length if $length>$l;
      $schema{$table}{non_ascii}{$column} ||= $non_ascii;
    }
    close $fh;
  }
}


# this function creates a loader that loads a PML schema into the database
# and stores information about the schema in the #PML table
sub dump_schema {
  my ($schema,$append)=@_;
  return if $opts{'no-schema'};
  my $root_name = $schema->get_root_name;
  return if ($seen_ref_schema{$root_name});
  $seen_ref_schema{$root_name}=1;
  $root_name = $opts{prefix}.$root_name;

  my $data_dir = $opts{'data-dir'};
  my $filename= _abs2rel($schema->get_url);
  if ($filename=~/\.\./) {
    $filename = "".$schema->get_url; # using absolute URL
  }

  my $flags = MAX_MIN_ORD | TOP_TREE_FLAG;
  $flags |= HYBRID if $opts{hybrid};
  $flags |= NO_TREE_TABLE if $opts{no_tree_table};

  my $schema_dump = "${root_name}__schema.dump";
  my $blob;
  $schema->write({string=>\$blob});
  open(my $fh, '>', get_full_path($schema_dump));
  my $r=$root_name;

  s{(\\|\n|\r|\^)}{\\$1}g for $r,$filename,$data_dir,$blob;
  print $fh ($r.'^',
             $filename.'^',
             $data_dir.'^',
             $flags.'^',
             $blob
            );
  close $fh;
  my $ctl = "${root_name}__pml_init.ctl";
  open $fh, ($append ? '>>' : '>'), get_full_path($ctl);

  print $fh <<"EOF";
COPY "#PML" ("root", "schema_file", "data_dir", "flags", "schema") FROM '$schema_dump' DELIMITER '^'
EOF
  close $fh;
  $fh{'#INIT_LIST'}->print("$ctl\n");
}

sub analyze_string {
  my ($table,$column,$string)=@_;
  return unless defined $string;
  my $l = length($string) || 0;
  if ($opts{'enforce-col-info'}) {
    for ($schema{$table}{col}{$column}||0) {
      if ($l > $_) {
        warn "Truncating value in table $table, column $column from $l to $_ chars\n";
        $_[2] = substr($string,0,$_);
      }
    }
    warn "NON-ASCII value in table $table, column $column\n"  if !$schema{$table}{non_ascii}{$column} and $string=~/[^[:ascii:]]/;
  } else {
    for ($schema{$table}{col}{$column}) {
      $l+=10 if $opts{incremental};
      $_=$l if $l > ($_||0)
    }
    $schema{$table}{non_ascii}{$column}=1 if $string=~/[^[:ascii:]]/;
  }
}

sub dump_typemap {
  my $typemap = $opts{'rename-type'};
  return unless ref $typemap;
  my ($type_name, $table_name);
  while (($type_name,$table_name)=each %$typemap) {
    if (exists $schema{$table_name}) {
      # qq{DELETE FROM "#PMLTABLES" WHERE "type"='$type_name';\n}.
      $fh{'#INIT_SQL'}->print(qq{INSERT INTO "#PMLTABLES" VALUES('$type_name','$table_name');\n\n});
      $fh{'#DELETE_SQL'}->print(qq{DELETE FROM "#PMLTABLES" WHERE "type"='$type_name';\n\n});
    }
  }
}

sub convert_references {
  my ($source,$schema,$references,$refnames,$refdata,$opts)=@_;
  return unless keys %$references;
  $source = abs2rel($source);
  analyze_string($references_table,source =>$source);
  my %name = map {
    my $name = $_;
    my $ids = $refnames->{$name};
    ref($ids) ? (map { $_ => $name } @$ids) : ( $ids => $name )
  } keys %$refnames;
  my ($id,$reffile,$name);
  while (($id,$reffile)=each %$references) {
    $name = $name{$id};
    my $r = $schema->get_named_reference_info($name);
    next unless $r and $r->{readas}; # skip references that are not requried
    my $file = abs2rel($reffile);
    analyze_string($references_table,name =>$name);
    analyze_string($references_table,id =>$id);
    analyze_string($references_table,file =>$file);
    $fh{'#REFFILE_TABLE'}->print(mkdump($source,$name,$id,$file));
    if ($r->{readas} eq 'pml' and ref($refdata)) {
      # we need to extract the schema
      my $refpml = $refdata->{$id};
      if (UNIVERSAL::DOES::does($refpml,'Treex::PML::Instance')) {
        my $ref_schema = $refpml->get_schema;
        # dump_schema($ref_schema);
        convert_references($reffile,
                     $ref_schema,
                     $refpml->get_references_hash,
                     $refpml->get_refname_hash,
                     $refpml->get_ref($id),
                     $opts);
      }
    }
  }
}

sub col_val {
  my ($decl,$table,$col,$str)=@_;
  if (get_pmlref_target_info($decl,$table,$col)) {
    # the column named "$col" will contain #idx pointers
    # the culumn "$col~" will contain the original PMLREF
    $col.='~';
  }
  return $col => val($decl,$table,$col,$str);
}

sub val {
  my ($decl,$table,$col,$str)=@_;
  if (ref($str)) {
    Carp::confess("Attempt to store a reference $str as vchar in table $table, column $col");
  }
  analyze_string($table,$col => $str);
  if (defined($str) and $decl and $decl->get_decl_type == PML_CDATA_DECL and $decl->get_format eq 'PMLREF') {
    $str=~s/^.+?#// if defined $str;
  }
  if ($decl and !(defined $str and length $str)) {
    my $def = $opts{defaults}{ table_name($decl) };
    $str=$def if defined $def;
  }
  return $str;
}

sub table_name {
  my ($decl,$no_rename) = @_;
  confess("missing decl") unless $decl;
  my $path = $decl->get_decl_path;
  if (!$path) {
    my $parent_is = $decl->get_parent_decl->get_decl_type;
#    warn("Couldn't determine table name for $decl with parent ".$decl->get_parent_decl."\n");
    return rename_type('/'.$decl->get_parent_decl->get_name,$no_rename) if $parent_is==PML_ROOT_DECL;
    if ($parent_is==PML_STRUCTURE_DECL or
        $parent_is==PML_SEQUENCE_DECL or
        $parent_is==PML_CONTAINER_DECL) {
      my $name = $decl->get_name;
      $path = table_name($decl->get_parent_decl,1);
#      print "result: $path/$name\n";
      return rename_type($path.'/'.$name,$no_rename) if $path;
    }
    $decl->write({fh=>\*STDERR});
    confess("Couldn't determine table name for $decl with parent ".$decl->get_parent_decl."\n");
  }
  $path=~s{^/}{ '/'.$decl->get_schema->get_root_name.'/' }e;
  $path = PMLTQ::Common::DeclPathToQueryType($path);
  return rename_type($path,$no_rename);
}


sub rename_type {
  my ($table_name,$no_rename)=@_;
  return $table_name if $no_rename;
  $table_name=$opts{prefix}.$table_name;
  if ($opts{'rename-type'} and
        $opts{'rename-type'}{$table_name}) {
    $table_name=$opts{'rename-type'}{$table_name};
  } elsif (length($table_name)>MAX_NAME_LENGTH) {
    my $new_name = $opts{'rename-type'}{$table_name} = $root_name.'##'.($last_type_no++);
    $orig_name{$new_name}=$table_name;
    warn "renaming table for type '$table_name' to '$new_name'\n" if $opts{debug};
    $table_name = $new_name;
  }
  return $table_name;
}


sub traverse_data {
  my ($decl,$value,$index,$opts)=@_;
  $opts||={};
  my $table = delete($opts->{'#table'}) || table_name($decl);
  my $decl_is = $decl->get_decl_type;
  $index=$idx++ unless defined $index;
  my $is_tree = UNIVERSAL::DOES::does($value,'Treex::PML::Node') && !$value->parent? 1 : 0;
  my $desc;
  if ($decl_is == PML_STRUCTURE_DECL) {
      $is_tree = 1 if ($opts{is_treex} and ($decl->get_structure_name || '') =~ /[atn]-root/);
    my %midx;
    my @members = grep {
      (!defined($_->get_role) or ($_->get_role ne '#CHILDNODES' and $_->get_role ne '#TREES'))
        and (($_->get_content_decl && $_->get_content_decl->get_role ||'') ne '#TREES')
        } $decl->get_members;
    $desc = {
      '#table' => $table,
      '#idx' => ($is_tree ? new_tree($value,$desc) : $index),
    };
    for (@members) {
      my $n = $_->get_knit_name;
      my $v = $value->{$n};
      my $d = $_->get_knit_content_decl;
      if (defined($v) and !$d->is_atomic) {
        my $mdump = traverse_data($d,$v);
        $desc->{$n} = data_index($mdump);
      } else {
        # HACK for Interset structure
        if (ref $v && UNIVERSAL::DOES::does($value, 'Lingua::Interset::FeatureStructure')) {
          $v = [ map { $_ . '=' . $v->{$_} } keys %$v ] if ref $v eq 'HASH';
          $v = join ('|', @$v) if ref $v eq 'ARRAY';
        }
        my ($key,$value) = col_val($d,$table,$n,$v);
        $desc->{$key} = $value;
      }
    }
    $desc=traverse_subtree($value,$desc,$opts) if $is_tree;
  } elsif ($decl_is == PML_CONTAINER_DECL) {
    my $midx;
    my @attrs = $decl->get_attributes;
    $desc = {
      '#table' => $table,
      '#idx' => ($is_tree ? new_tree($value,$desc) : $index),
      map {
        my $n = $_->get_name;
        my $v = $value->{$n};
        col_val($_->get_content_decl,$table,$n,$v)
      } @attrs
    };
    my $knit_content_decl = $decl->get_knit_content_decl;
    my $content_decl = $decl->get_content_decl;
    my $role = ($content_decl && $content_decl->get_role)||'';
    if (defined($content_decl) and $role ne '#CHILDNODES' and $role ne '#TREES') {
      if ($knit_content_decl and defined($value->{'#content'})) {
        if ($knit_content_decl->is_atomic) {
          my ($key,$value) = col_val($knit_content_decl,$table,'#content',$value->{'#content'});
          $desc->{$key} = $value;
        } else {
          $desc->{'#content'} = data_index(traverse_data($knit_content_decl,$value->{'#content'}));
        }
      } else {
        $desc->{'#content'} = undef;
      }
    }
    $desc=traverse_subtree($value,$desc,$opts) if $is_tree;
  } elsif ($decl_is == PML_SEQUENCE_DECL) {
    my %midx;
    my @elems = $decl->get_elements;
    $desc = {
      '#table' => $table,
      '#idx'   => $index,
      map {
        my $n = $_->get_name;
        $n => ($midx{$n}=$idx++)
      } @elems
    };
    my %epos;
    my $i=0;
    for (@{$value->elements_list}) {
      my $n = $_->name;
      my $v = $_->value;
      my $e = $decl->get_element_by_name($n);
      traverse_data($e,$v,$midx{$n},{
        '#table'=>'#e_'.table_name($e->get_knit_content_decl),
        '#pos'=>$i++,
        '#elpos' => ($epos{$n}++||0),
      });
    }
  } elsif ($decl_is == PML_ELEMENT_DECL) {
    my $content_decl=$decl->get_knit_content_decl;
    my $compact = !defined($value) || $content_decl->is_atomic;
    $desc = {
      '#table'=> $table,
      '#idx', => $index,
      %$opts,
     };
    if ($compact) {
      my ($key,$value) = col_val($content_decl,$table,'#value',$value);
      $desc->{$key} = $value;
    } else {
      $desc->{'#value'} = data_index(traverse_data($content_decl,$value));
    }
  } elsif ($decl_is == PML_LIST_DECL || $decl_is == PML_ALT_DECL) {
    if ($decl_is == PML_ALT_DECL and !UNIVERSAL::DOES::does($value,'Treex::PML::Alt')) {
      $value=Treex::PML::Alt->new($value);
    }
    my $content_decl=$decl->get_knit_content_decl;
    my $atomic = $content_decl->is_atomic;
    my $ordered = ($decl_is == PML_LIST_DECL and $decl->is_ordered);
    my $i=0;
    $desc = [];
    if ($atomic) {
      for my $v ($value->values) {
        push @$desc, {
          '#table'=>$table,
          '#idx'=>$index,
           col_val($content_decl,$table,'#value',$v),
          ($ordered ? ('#pos'=>$i++) : ()),
        };
      }
    } else {
      for my $v ($value->values) {
        push @$desc, {
          '#table'=>$table,
          '#idx'=>$index,
          '#value'=> defined($v) && data_index(traverse_data($content_decl,$v)),
          ($ordered ? ('#pos'=>$i++) : ()),
        };
      }
    }
  } elsif ($decl_is == PML_CHOICE_DECL || $decl_is == PML_CONSTANT_DECL || $decl_is == PML_CDATA_DECL) {
    confess("traversing atomic type\n");
  } else {
    die "unhandled data type: $decl\n";
  }
#  print "$decl\n" unless defined $desc;
#  print Dumper($desc) if $desc;
  dump_data_desc($desc) unless $opts->{no_dump};
  return $desc;
}

sub data_index {
  my ($desc)=@_;
  $desc = $desc->[0] if ref($desc) eq 'ARRAY';
  return defined($desc) ? $desc->{'#idx'} : undef;
}

sub dump_data_desc {
  my ($desc)=@_;
  for my $desc_item (ref($desc) eq 'ARRAY' ? @$desc : $desc) {
    my %d = (%$desc_item);
    my $table = delete $d{'#table'};
    confess( "no #table:".Dumper(\%d) ) unless defined $table;
    my @columns = map $_->[0],@{$schema{$table}{colspec}};
    if (defined $fh{$table}) {
      $fh{$table}->print(mkdump(delete @d{@columns}));
      die "The following columns were left in a row for table $table: "
        .join(',',keys %d)."\n"
          ."expected: ".join(',',@columns)."\n"
            if keys %d;
    } else {
      print join(" ",keys %fh),"\n";
      die "Error: didn't find any filehandle for table $table\n";
    }
  }
}

sub new_tree {
  my ($node,$desc,$opts)=@_;
  my $idx = ++$node_idx;
  $node_idx=$idx + $node->descendants; # reserve a span in the node indexing sequence for this tree
  my $primary = (!defined($last_tree_no) || ($last_tree_no != $tree_no)) ? 1 : 0;
  $fh{'#FILE_TABLE'}->print(mkdump($idx,$filename,$tree_no,$primary)); # FIXME: wont work for bundles
  $last_tree_no = $tree_no;
  return $idx;
}

sub traverse_subtree {
  my ($node,$desc,$opts)=@_;
  my $idx=$desc->{'#idx'};
  my $root_idx = $idx;
  my $lvl=0;
  my %hash;
  my $tree=$node;
    while ($node) {
    my $parent = $node->parent;
    unless (defined $hash{$node}) {
      $hash{$node} = {};
      $hash{$node}{'#table'} = $node_table;
      $hash{$node}{'#data'} = $parent ?
        traverse_data($node->type,
                      $node,
                      ++$idx,
                      {%$opts,
                       no_dump => 1,
                       root_idx=>$root_idx})
          : $desc;
      #$hash{$node}{'#ID'}=$node->get_id;
      $hash{$node}{'#idx'}=$hash{$node}{'#data'}{'#idx'};
      $hash{$node}{'#chld'}  = 0;
      my $name = $node->{'#name'};
      my $type = $hash{$node}{'#data'}{'#table'};
      if (defined($name) and length($name)) {
        val(undef,$node_table,'#name',$name);
        $hash{$node}{'#name'}  = val(undef,$type,'#name',$name);
      }
      val(undef,$node_table,'#type',table_name($node->type,1));
      $hash{$node}{'#type'}  = val(undef,$type,'#type',table_name($node->type,1));
      $hash{$node}{'#chord'} = $parent ? $hash{$parent}{'#chld'}++ : 0;
      $hash{$node}{'#lvl'}   = $parent ? $hash{$parent}{'#lvl'}+1 : 0;
      $hash{$node}{'#parent_idx'} = $parent ? $hash{$parent}{'#idx'} : undef ;
      $hash{$node}{'#root_idx'}  = $root_idx;
      $hash{$node}{'#min_ord'} = $hash{$node}{'#max_ord'} = $node->get_order;
      if ($node->firstson) {
        $node = $node->firstson;
        next;
      }
    }
    $hash{$node}{'#r'} = $idx;
    my ($min_ord,$max_ord)=@{$hash{$node}}{'#min_ord', '#max_ord'};
    if ($parent and defined($min_ord) and !defined($parent->get_order)) {
      my $hp=$hash{$parent};
      $hp->{'#min_ord'} = $min_ord
        if (!defined($hp->{'#min_ord'}) or $hp->{'#min_ord'} > $min_ord);
      $hp->{'#max_ord'} = $max_ord
        if (!defined($hp->{'#max_ord'}) or $hp->{'#max_ord'} < $max_ord);
    }
    if (ref $opts{for_each_node}) {
      $opts{for_each_node}->($node,\%hash,\%fh);
    }
    $node = $node->rbrother || $parent;
  }
  if (ref $opts{for_each_tree}) {
    $opts{for_each_tree}->($tree,\%hash,\%fh);
  }
  if (@dump_fns) {
    $_->($tree,\%hash) for @dump_fns;
  }
  return [ map {
    my $h = $_->[1];
    my $data = delete $h->{'#data'};
    $opts{no_tree_table} ? { %$h, %$data } :
    $opts{hybrid}        ? ({ %$h, %$data }, $h)
                         : ($data, $h)
  } sort { $a->[0]<=>$b->[0] }
    map  { [$_->{'#idx'},$_] } values %hash
  ];
}

sub is_treex_document {
    my $fs = shift;
    return ($fs->metaData('schema') && $fs->metaData('schema')->get_root_name eq 'treex_document') ? 1:0;
}

sub fs2base {
  my ($fs,$opts)=@_;
  $opts||={};

  # prepare global option
  $opts{'data-dir'}=Cwd::abs_path($opts{'data-dir'}) if $opts{'data-dir'};
  $opts{for_each_tree} = $opts->{for_each_tree};
  $opts{for_each_node} = $opts->{for_each_node};

  ## little hack for treex files
  if (is_treex_document($fs)) {
      require Treex::Core::Document;
      Treex::Core::Document->new({pmldoc => $fs}); ## rebless all nodes
      $opts{is_treex}=1;
      print "Converting to Treex document\n";
  }

  if (!$schema) {
    convert_schema($fs->metaData('schema'),$opts);
    $relations = PMLTQ::Relation->relations_for_schema($schema->get_root_name);

    for my $rel (@$relations) {
      next unless $rel->{table_name}; # if it doesn't have table we ignore it
      my $reversed_relation = $rel->{reversed_relation};
      $reversed_relation =~ s/^implementation:// if $reversed_relation;
      my $spec = make_user_rel_table($rel->{table_name}, $rel->{name}, $reversed_relation, $rel->{start_node_type}, $rel->{target_node_type});

      my $init_sql = $rel->{iterator_class}->can('init_sql');
      $init_sql->($spec->{table}, $schema, $spec, \%fh) if $init_sql;

      my $dump_fn = $rel->{iterator_class}->can('dump_relation');
      push @dump_fns, sub {
        my ($tree, $hash) = @_;
        return unless $tree->type->get_structure_name||'' eq $rel->{tree_root};
        $dump_fn->(@_, $fh{$spec->{table}})
      } if $dump_fn;
    }

    dump_typemap() unless $opts{'no-schema'};
  }
  my $f = $filename = $fs->filename;
  $filename = abs2rel($filename);

  convert_references($f,
                     $schema,
                     $fs->metaData('references'),
                     $fs->metaData('refnames'),
                     $fs->appData('ref'),
                     $opts);
  analyze_string($file_table,file => $f);
  my $trees_type =$fs->metaData('pml_trees_type');
  if ($trees_type->get_decl_type == PML_MEMBER_DECL) {
    $trees_type = $trees_type->get_content_decl;
  }
  traverse_data(
    $trees_type,
    $fs->metaData('pml_prolog'),
   ) if $fs->metaData('pml_prolog');
  traverse_data(
    $fs->metaData('schema')->get_root_type,
    $fs->metaData('pml_root'),
   ) if $fs->metaData('pml_root');

  $tree_no=0;
  for my $tree ($fs->trees) {
    traverse_data($tree->type, $tree,undef,$opts);
    $tree_no++;
  }
  traverse_data(
    $trees_type,
    $fs->metaData('pml_epilog'),
   ) if $fs->metaData('pml_epilog');
}

sub finish {
  if (defined $opts{'max-node-idx'} and $node_idx>$opts{'max-node-idx'}) {
    warn("NODE_IDX EXCEEDED LIMIT: next $node_idx, limit $opts{'max-node-idx'}");
  }
  if (defined $opts{'max-idx'} and $idx>$opts{'max-idx'}) {
    warn("DATA_IDX EXCEEDED LIMIT: next $idx, limit $opts{'max-idx'}");
  }
  if ($opts{incremental}) {
    $fh{'#POST_SQL'}->print(qq{UPDATE "#PML" SET ("last_idx","last_node_idx")=($idx,$node_idx)}.
                            qq{ WHERE "root"='$root_name';\n\n});
  }
  if ($opts{'dump-rename-map'}) {
    open my $fh, '>:utf8', $opts{'dump-rename-map'};
    my ($k,$v);
    while (($k,$v)=each %{$opts{'rename-type'}}) {
      print $fh "$k\t$v\n";
    }
    close $fh;
  }

  my @tables = sort {($a->{'#decl_order'}||0)<=>($b->{'#decl_order'}||0)} values %schema;
  unless ($opts{'no-schema'}) {
    for my $desc (reverse @tables) {
      $fh{'#INIT_SQL'}->print(qq{CREATE TABLE "$desc->{table}" (\n    },
                              join(",\n    ",
                                   map {
                                     my ($c,$t)=@$_;
                                     if ($t=~/STRING\(\)/i) {
                                       my $l = $desc->{col}{$c}||=0;
                                       my $non_ascii = $desc->{non_ascii}{$c}||=0;
                                       warn ("length for $c in $desc->{table} is 0; changing to 1\n") if !$l;
                                       $l||=1;
                                       $t=~s/STRING\(\)/varchar($l,$non_ascii)/ieg;
                                     }
                                     $t=~s/ FOREIGN KEY.*$//;
                                     qq{"$c" $t}
                                   } @{$desc->{colspec}}
                                  ), "\n);\n\n");
      for (@{$desc->{colspec}}) {
        if ($_->[2]) {
          $fh{'#INIT_SQL'}->print(qq{CREATE INDEX "#i_${root_name}_$index_id" ON "$desc->{table}" ("$_->[0]");\n\n});
          $index_id++;
        }
      }
    }
    for my $desc (@tables) {
      $fh{'#DELETE_SQL'}->print(qq{DROP TABLE IF EXISTS "$desc->{table}" CASCADE;\n\n});
    }
  }
  unless ($opts{'schema'}) {
    for my $desc (reverse @tables) {
      my $t = $desc->{table};
      my $dump = table2filename($t);
      my $ctl=table2filename($t,'ctl');
      open LOAD_SQL,'>',get_full_path($ctl);
      my $replace = $opts{'no-schema'} ? "APPEND" : "REPLACE";
      my $cols = join ',', map { qq{"$_->[0]"} } @{$desc->{colspec}};
      print LOAD_SQL qq{COPY "$t" ($cols) FROM '$dump'\n};
      close LOAD_SQL;
      $fh{'#INIT_LIST'}->print("$ctl\n");
    }
  }
  if ($opts{'no-schema'}) {
    if ($opts{incremental}) {
      $fh{'#INIT_LIST'}->print(to_filename("postprocess",'sql')."\n");
    }
  } else {
    $fh{'#INIT_LIST'}->print(to_filename("postprocess",'sql')."\n");
    unless ($opts{incremental}) {
      for my $desc (values %schema) {
        for my $col (@{$desc->{colspec}}) {
          my ($c,$t)=@$col;
          if ($t =~ m/ (FOREIGN KEY) (.*)$/) {
            $fh{'#POST_SQL'}->print(qq{ALTER TABLE "$desc->{table}" ADD $1("$c") $2;\n\n});
          }
        }
      }
    }
    for my $desc (values %schema) {
      $fh{'#POST_SQL'}->print(qq{VACUUM FULL ANALYZE "$desc->{table}";\n\n});
    }
  }

  if ($opts{'dump-idx'}) {
    open my $fh, '>', get_full_path($opts{'dump-idx'});
      print $fh "$idx\t$node_idx\n";
    close $fh;
  }
  if ($opts{'dump-col-info'}) {
    open my $fh, '>:utf8', get_full_path($opts{'dump-col-info'});
    foreach my $table (keys %schema) {
      if ($schema{$table}{col}) {
        foreach my $column (keys %{$schema{$table}{col}}) {
          my $length=$schema{$table}{col}{$column}||0;
          my $non_ascii=$schema{$table}{non_ascii}{$column}||0;
          print $fh "$table\t$column\t$length\t$non_ascii\n";
        }
      }
    }
  }

  close $_ for values %fh;

}


sub get_full_path {
  my $file = shift;
  return exists $opts{'output-dir'} ? File::Spec->catfile($opts{'output-dir'},$file) : $file;
}

sub make_user_rel_table {
  my ($table_name, $name, $reverse_name, $node_type, $target_node_type) = @_;

  $target_node_type = $node_type unless defined $target_node_type; # default target node to start node

  my $table = rename_type($table_name);
  my $values = join(',', map { defined $_ ? "'$_'" : 'NULL' } ($name, $reverse_name, $node_type, $target_node_type, $table));

  unless ($opts{'no-schema'}) {
    $fh{'#INIT_SQL'}->print(<<"SQL");
INSERT INTO "#PML_USR_REL" VALUES(${values});

SQL
    $fh{'#DELETE_SQL'}->print(<<"SQL");
    DELETE FROM "#PML_USR_REL" WHERE "tbl"='${table}';

SQL
  }

  my $spec = $schema{$table} = {
    table => $table,
    colspec => [
      ['#idx','INT'],
      ['#value','INT'],
    ],
    index => ['#idx','#value']
  };

  open $fh{$table}, '>', get_full_path(to_filename($table));

  return $spec;
}

1; # End of PMLTQ::PML2BASE

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::PML2BASE - Convert from PML to SQL

=head1 VERSION

version 3.0.1

=head1 DESCRIPTION

This module contans functions that generate SQL schema and data
loaders for a given set of PML documents that adher to
a common PML schema.

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
