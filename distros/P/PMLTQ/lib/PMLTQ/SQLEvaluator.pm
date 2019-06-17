package PMLTQ::SQLEvaluator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::SQLEvaluator::VERSION = '3.0.2';
# ABSTRACT: SQL evaluator of PML-TQ queries which can use PostreSQL as a backend

use 5.006;
use strict;
use warnings;
our $SEPARATE_TREES=0;

use Benchmark;
use Carp;

use Treex::PML::Schema;

# flags stored for a PML schema in the #PML table
use constant HYBRID=>1;        # create both separate node table and node table with attributes
use constant NO_TREE_TABLE=>2; # don't create one common common node table for all node types
use constant MAX_MIN_ORD=>4;   # node tables have #max_ord and #min_ord columns
use constant TOP_TREE_FLAG=>8; # The <root>__#files table has a 'top' column indicating that
                               # a given root node belongs to the top-level tree list
                               # of a file (i.e. it is not a nested #NODE within
                               # some non-#NODE and non-#TREES data structure)


use PMLTQ::Common;
BEGIN {
  import PMLTQ::Common qw(:tredmacro :constants);
}

use constant {PREFER_LEFT_JOINS => 1};
use constant USE_PLANNER => 'never'; #'forests'; # 'always', 'never', 'forests'
use PMLTQ::Planner;


our $MIN_CLIENT_VERSION = '0.2';
our $ALLOW_MISPLACED_PG_JOIN = 1;

# BEGIN { import TredMacro qw(first SeqV AltV ListV) }




sub check_client_version {
  my ($self,$version)=@_;
  return (defined($version) && length($version) && Treex::PML::Schema::cmp_revisions($MIN_CLIENT_VERSION,$version)<=0) ? 1 : 0;
}

sub new {
  my ($class,$query_tree,$opts)=@_;
  if ($^O eq 'MSWin32') {
    die "Not supported OS, PMLTQ::SQLEvaluator requires Sys::SigAction\n";
  } else {
    require Sys::SigAction;
  }

  my $self = bless {
    dbi => $opts->{dbi},
    connect => $opts->{connect},
    debug => $opts->{debug},
    results => undef,
    query_nodes=>undef,
    type_decls => {},
    schema_types => {},
    schemas => {},
    returns_nodes => 1,
  }, $class;
  $self->prepare_query($query_tree,$opts) if $query_tree;
  return $self;
}

sub get_results {
  my $self = shift;
  return $self->{results} || [];
}

sub get_query_nodes {
  my $self = shift;
  return $self->{query_nodes};
}

sub get_sql {
  my $self = shift;
  return $self->{sql};
}

sub prepare_sql {
  my ($self,$sql,$opts)=@_;
  $self->{sth} = undef;
  $self->{sql} = $sql;
  my $dbi = $self->{dbi} || $self->connect();
  print STDERR "$sql\n" if $opts->{debug_sql};
  return $self->run_sql_query($sql,{
    use_cursor => $opts->{use_cursor},
    limit => $opts->{limit},
    prepare_only => 1,
    return_sth => 1,
    no_distinct => $opts->{no_distinct},
    RaiseError=>1,
    timeout => $opts->{timeout},
  });
}

sub get_pmlrf_relation_map {
  my ($self)=@_;
  $self->init_relation_maps;
  return $self->{pmlrf_relations_map};
}

sub init_relation_maps {
  my ($self)=@_;
  return if ref $self->{pmlrf_relations_map};
  my @types = @{$self->get_node_types};
  my %pmlrf_relations;
  my @pmlrf_relations;
  my @user_relations;
  {
    my %pmlref_map;
    foreach my $node_type (@types) {
      my $schema_name = $self->get_schema_name_for($node_type);
      if (!exists $pmlref_map{$schema_name}) {
        my $results = $self->run_sql_query(qq(SELECT "ref_type", "target_layer", "target_type" FROM "${schema_name}__#pmlref_map"),{ RaiseError=>1 });
        my $pmlref_map = $pmlref_map{$schema_name} = {};
        for my $r (@$results) {
          # PMLREF based relation
          $pmlref_map->{$r->[0]} = $r;
        }
      }
      my $decl = $self->get_decl_for($node_type);
      my @attributes = $decl->get_attribute_paths({no_nodes=>1,no_childnodes => 1});
      foreach my $p (@attributes) {
        my $attr_decl_path = $decl->find($p)->get_decl_path;
        $attr_decl_path=~s{^!([^/]*?)(?:\.type)?(/|$)}{$1$2};
        my $target = $pmlref_map{$schema_name}{$attr_decl_path};
        if (defined $target) {
#          $p =~ s/#content/content()/g;
          push @pmlrf_relations, $p;
          $pmlrf_relations{$node_type}{$p}=$target;
        }
      }
    }
  }
  {
    my %usr_rel;
    my $usr_rels = $self->run_sql_query(qq(SELECT "relname", "reverse", "node_type", "target_node_type", "tbl" FROM "#PML_USR_REL"),
                                        { RaiseError=>1 });
    for my $r (@$usr_rels) {
      push @user_relations, $r->[0];
      push @user_relations, $r->[1] if $r->[1];
      $usr_rel{ $r->[2] }{ $r->[0] } = [ $r->[4], undef, $r->[3] ] if $r->[0];
      $usr_rel{ $r->[3] }{ $r->[1] } = [ undef, $r->[0], $r->[2] ] if $r->[1];
    }
    $self->{user_defined_relations} = \@user_relations;
    $self->{user_defined_relations_map} = \%usr_rel;
  }
  my @relations = sort(uniq(@user_relations,@pmlrf_relations));
  $self->{specific_relations} = \@relations;
  $self->{pmlrf_relations} = [sort(uniq(@pmlrf_relations))];
  $self->{pmlrf_relations_map} = \%pmlrf_relations;
  return;
}

sub get_pmlrf_relation_map_for_type {
  my ($self,$type)=@_;
  my $map = $self->get_pmlrf_relation_map;

  return $map->{$type} if exists $map->{$type};
  my %rels;
  for my $nt (keys %$map) {
    for my $rel (@{$self->{pmlrf_relations}}) {
      if ($rel and exists($map->{$nt}{$rel}) and (($nt.'/'.$rel) =~ m{^\Q$type\E/(.*)$})) {
        $rels{$1}=$map->{$nt}{$rel};
      }
    }
  }
  return $map->{$type}=\%rels;
}

sub get_user_defined_relations {
  my ($self,$type)=@_;
  if ($type) {
    my $map = $self->get_user_defined_relation_map();
    $map = ref($map) && $map->{$type};
    return $map ? [sort keys %$map] : [];
  } else {
    $self->init_relation_maps;
    return $self->{user_defined_relations};
  }
}

sub get_pmlrf_relations {
  my ($self,$type)=@_;
  if ($type) {
    my $map = $self->get_pmlrf_relation_map();
    return [] unless ref $map;
    my $rels = $map->{$type};

    # the type may be of the form <node-type>/<member-path>
    # in which case we attempt to locate node-type and
    # then select just those relations that start with member-path
    my $path='';
    while (!$rels and $type=~s{/([^/]+)$}{}) {
      $path = $1.'/'.$path;
      $rels = $map->{$type};
    }
    return $rels ? [ map { /^\Q$path\E(.*)/ ? $1 : () } sort keys %$rels ] : [];
  } else {
    $self->init_relation_maps;
    return $self->{pmlrf_relations};
  }
}

sub get_specific_relations {
  my $self = shift;
  return [uniq(
    @{$self->get_pmlrf_relations(@_)},
    @{$self->get_user_defined_relations(@_)},
   )];
}

sub get_user_defined_relation_map {
  my ($self)=@_;
  $self->init_relation_maps;
  return $self->{user_defined_relations_map};
}

sub get_user_defined_relation_map_for_type {
  my ($self,$type)=@_;
  my $map = $self->get_user_defined_relation_map;
  return $map->{$type} if exists $map->{$type};
  return;
}


sub get_relation_target_type {
  my ($self,$node_type,$relation,$full)=@_;
  my $i=0;
  for my $map ({ $node_type => $self->get_pmlrf_relation_map_for_type($node_type) },
               $self->get_user_defined_relation_map) {
    my $target = $map->{$node_type} && $map->{$node_type}{$relation};
    if ($target) {
      return $full ? [$i,$target] : $target->[2];
    }
    $i++;
  }
  return;
}

sub prepare_query {
  my ($self,$query_tree,$opts)=@_;
  $opts||={};
  unless (ref($query_tree)) {
    $query_tree = PMLTQ::Common::parse_query($query_tree,{
      pmlrf_relations => $self->get_pmlrf_relations,
      user_defined_relations => $self->get_user_defined_relations,
     });
  }

  my $use_planner =
      USE_PLANNER eq 'always' ? 1
    : USE_PLANNER eq 'forests' ? ( ($query_tree->children > 0) ? 1 : 0 )
    : 0;

  $self->{id} = $query_tree->{id} || 'no_ID';
  $self->{query_nodes} = [PMLTQ::Common::FilterQueryNodes($query_tree)];
  {
    my %id;
    my %name2node_hash;
    my @nodes = grep { $_->{'#name'} =~ /^(?:node|subquery)$/ } $query_tree->descendants;
    # try to complete missing node-types
    my %node_types = map { $_=> 1 } @{$self->get_node_types};
    my %schema_names = map { $_=> 1 } @{$self->get_schema_names};
    my $default_type = $query_tree->{'node-type'};
    if ($default_type and !$node_types{$default_type}) {
      die "The query specifies an invalid type '$default_type' as default node type!";
    }
    for my $node (@nodes) {
      {
        my $n=$node->{name};
        if (defined($n) and length($n)) {
          if (exists $name2node_hash{$n}) {
            die "Name \$$n used for more than one selector!\n";
          }
          $name2node_hash{$n}=$node;
        }
      }
      if (PMLTQ::Common::IsMemberNode($node)) {
        if ($node->{'node-type'}) {
          # FIXME: we should check that the member is a valid member for
          # its parent (member or node) node-type
          my $type = PMLTQ::Common::GetMemberNodeType($node,$self);
          unless ($self->get_decl_for($type)) {
            die "Invalid type attribute path '$type' for member ".PMLTQ::Common::as_text($node)."\n";
          }
        } else {
          die "Member must specify attribute name: ".PMLTQ::Common::as_text($node)."\n";
        }
        next;
      } elsif ($node->{'node-type'} eq '*') {
        if (keys(%schema_names)>1) {
          my ($rel) = SeqV($node->{relation});
          $rel = $rel ? $rel->name : '';
          die "Node-type wildcard '*' cannot be used for data with multiple layers: ".PMLTQ::Common::as_text($node)." in relation $rel\n".
            "\nHint: try one of ".join(" ",map "$_:*", sort keys(%schema_names))."\n";
        }
      } elsif ($node->{'node-type'} =~ m{^([^/]+):\*$}) {
        my $schema_name = $1;
        if (!$schema_names{$schema_name}) {
          my ($rel) = SeqV($node->{relation});
          $rel = $rel ? $rel->name : '';
          die "The query specifies an invalid schema name '$schema_name' for node: ".PMLTQ::Common::as_text($node)." in relation $rel\n";
        }
      } elsif ($node->{'node-type'}) {
        if (!$node_types{$node->{'node-type'}}) {
          my ($rel) = SeqV($node->{relation});
          $rel = $rel ? $rel->name : '';
          die "The query specifies an invalid type '$node->{'node-type'}' for node: ".PMLTQ::Common::as_text($node)." in relation $rel\n";
        }
      } else {
        my $parent = $node->parent;
        while ($parent and ($parent->{'#name'}||'') !~/^(?:node|subquery)$/) {
          $parent=$parent->parent;
        }
        my ($rel) = SeqV($node->{relation});
        my @types =
          ($parent && $rel) ?
            (PMLTQ::Common::GetRelativeQueryNodeType(
              $parent->{'node-type'},
              $self,
              $rel)
             ) : @{$self->get_node_types};
        if (@types == 1) {
          $node->{'node-type'} = $types[0];
        } elsif ($default_type) {
          $node->{'node-type'} = $default_type;
        } else {
          die "Could not determine node type of node in ".($rel ?
                                                                 'the '.($rel->name eq 'user-defined' ?
                                                                   $rel->value->{label} :
                                                                   $rel->name)
                                                                 : 'an unknown')." relation "
                                                                   .($parent ? "to $parent->{'#name'} $parent->{'node-type'}:" : ':')
            .PMLTQ::Common::as_text($node)."\n"
            ."Possible types are: ".join(',',@types)." !\n";
        }
      }
    }
    # hash IDs
    %id = map {
      my $n=$_->{name};
      (defined($n) and length($n)) ? ($_=>$n) : ()
    } @nodes;
    my $id = 'n0';
    my %occup; @occup{values %id}=();
    for my $n (@nodes) {
      unless (defined $id{$n} and length $id{$n}) {
        $id++ while exists $occup{$id}; # just for sure
        $id{$n}=$id;                    # generate id;
        if ($use_planner) {
          $n->{name}=$id; # need for planning
        }
        $occup{$id}=1;
        $name2node_hash{$id}=$n;
      }
    }
    $self->{id_map}=\%id;
    $self->{name2node}=\%name2node_hash;


  }

  $self->{query_node_order}=undef;
  if ($use_planner) {
    Treex::PML::Document->determine_node_type($_) for ($query_tree, $query_tree->descendants);
    my $query_nodes=$self->{query_nodes};
    $self->{query_node_order} = { map { $query_nodes->[$_] => $_ } 0..$#$query_nodes };
    my $roots = PMLTQ::Planner::plan($query_nodes,$query_tree);
    for my $root (@$roots) {
      for my $subquery (grep { $_->{'#name'} eq 'subtree' } $root->descendants) {
        my $subquery_roots = PMLTQ::Planner::plan(
          [PMLTQ::Common::FilterQueryNodes($subquery)],
          $subquery->parent,
          $subquery
         );
      }
    }
    $self->{query_nodes} = [PMLTQ::Common::FilterQueryNodes($query_tree)]; # reordered
  }

  $self->{sql}=undef;
  $self->{join_id}=0;
  my $sql = $self->serialize_conditions($query_tree,
                                                     { %$opts,
                                                       #no_filters => $opts->{no_filters},
                                                       #node_limit=>$opts->{node_limit},
                                                       #row_limit=>$opts->{row_limit},
                                                       #select_first=>$opts->{select_first},
                                                       returns_nodes=>\$self->{returns_nodes},
                                                      });
  $self->prepare_sql($sql,
                     {
                       use_cursor => $opts->{use_cursor},
                       limit => ($self->{returns_nodes} ? abs($opts->{node_limit}||0)||undef : abs($opts->{row_limit}||0)||undef),
                       timeout => $opts->{timeout},
                       no_distinct => $opts->{no_distinct},
                     },
                    );
  return $query_tree;
}

sub type_mapper {
  my ($self)=@_;
  return $self;
}

sub get_type_of_node {
  my ($self,$name)=@_;
  my $n = $self->{name2node}{$name};
  return $n && ( PMLTQ::Common::GetQueryNodeType($n,$self) );
}

sub get_type_decl_for_node {
  my ($self,$name)=@_;
  my $n = $self->{name2node}{$name};
  my $node_type = $n && ( PMLTQ::Common::GetQueryNodeType($n,$self) );
  return $node_type && $self->get_decl_for($node_type);
}

sub connect {
  my ($self)=@_;
  return $self->{dbi} if $self->{dbi};
  my $cfg = $self->{connect};
  require DBI;
  # this is taken from http://search.cpan.org/~lbaxter/Sys-SigAction/dbd-oracle-timeout.POD
  eval {
    #note that if you ask for safe, it will not work...
    my $h = Sys::SigAction::set_sig_handler( 'ALRM',
                                             sub {
                                               die "timed out connecting to database on $cfg->{host}\n";
                                             },
                                             { flags=>0 ,safe=>0 } );
    alarm(20);
    $self->{layout_version} = $cfg->{layout_version}||0;

    require DBD::Pg;
    import DBD::Pg qw(:async);

    my $string = 'dbi:Pg:'
                         .($cfg->{host} ? 'host='.$cfg->{host}.';' : '' )
                         .($cfg->{database} ? "database=".$cfg->{database}.';' : '')
                         .($cfg->{port} ? "port=".$cfg->{port} : '');
    $self->{dbi} = DBI->connect($string,
                        $cfg->{username},
                        $cfg->{password},
                        { RaiseError => 1,
                          AutoCommit=>0, 
                          ReadOnly => 1
                        }
                       );
    alarm(0);
    die "Connection failed" if not $self->{dbi};
  };
  alarm(0);
  if ($@) {
    print STDERR "$@";
    undef $self->{dbi};
    die "Unable to connect to the database.";
  }
  return $self->{dbi};
}

sub run {
  my ($self,$opts)=@_;
  delete $self->{results};
  $opts||={};
  my $dbi  = $self->{dbi} ||
    $self->connect ||
    die("Not connected to DBI!\n");
  my $timeout = $opts->{timeout};
  my $t0 = new Benchmark;
  # my $limit = abs(int( $self->{returns_nodes} ? $opts->{node_limit} : $opts->{row_limit} ));
  my $results = eval {
    if ($opts->{use_cursor}) {
      my $buffer = $self->cursor_next(1); # just pre-fill the buffer
      $opts->{return_sth} ? $self->{sth} : $buffer;
    } else {
      $self->run_sql_query($self->{sth},{
        #    ($limit ? (limit=> $limit) : ()),
        timeout => $timeout,
        timeout_callback => $opts->{timeout_callback},
        RaiseError => 1,
        return_sth => $opts->{return_sth},
        use_cursor => $opts->{use_cursor},
      })
    }
  };
  if ($@) {
    my $err = $@;
    $err=~s/\n/ /g;
    if ($err =~ /^TIMEOUT /) {
      die "$self->{id}\tTIMEOUT\t".($timeout)."s\n";
    } else {
      die "$self->{id}\tFAIL\t$err\n";
    }
    return;
  }
  my $t1 = new Benchmark;
  my $time = timestr(timediff($t1,$t0));
  unless ($opts->{quiet}) {
    my $no_results =
    $opts->{return_sth} ? '?'
      : $opts->{count} ? $results->[0][0]
      : scalar(@$results);
    print STDERR "$self->{id}\tOK\tPg\t$no_results\t$time\n" if $self->{debug};
  }
  if ($opts->{return_sth}) {
    return $results;
  } else {
    return $self->{results}=$results;
  }
}

sub find_special_attribute {
  my ($self,$decl,$role)=@_;
  if ($decl->get_decl_type == PML_ELEMENT_DECL) {
    $decl = $decl->get_content_decl;
  }
  my ($m)=$decl->can('find_members_by_role') && $decl->find_members_by_role($role);
  return $m && $m->get_name;
}

sub idx_to_pos {
  my ($self,$idx_list,$force_id)=@_;
  my @res;
  my %id_attr;
  my $layout = $self->{layout_version};
  for my $ident (@$idx_list) {
    my ($idx,$type)=split '/',$ident,2;
    $idx=int($idx);
    my $node_id;
    if ($type=~s{[+@](.*)$}{}) {
      $node_id = $1;
    }
    my $basename = $self->get_schema_name_for($type);
    my $node_tab = $self->get_node_table_for($type);
    my $id_attrs='';
    if ($layout>1) {
      unless (exists($id_attr{$type})) {
        my $decl = $self->get_decl_for($type);
        $id_attr{$type} = $self->find_special_attribute($decl,'#ID');
      }
      $id_attrs=$id_attr{$type} ? qq{, "n"."$id_attr{$type}", "f"."top"} : q{, null, "f"."top"};
    }
    my $sql=<<"EOF". "LIMIT 1;";
SELECT "f"."file", "f"."tree_no", "n"."#idx"-"n"."#root_idx" $id_attrs
FROM "${node_tab}" "n" JOIN "${basename}__#files" "f" ON "n"."#root_idx"="f"."#idx"
WHERE "n"."#idx" = ${idx}
EOF
    # print STDERR "$sql\n";
    my $result = $self->run_sql_query($sql,{ MaxRows=>1, RaiseError=>1 });
    $result = $result->[0];
    my ($fn,$tn,$nn,$id,$is_top) = @$result;
    if (defined($id) and (!$is_top || $force_id)) {
      push @res, $fn.'#'.$id;
    } else {
      push @res, $fn.'##'.($tn+1).'.'.$nn;
    }
  }
  return @res;
}

sub ids_to_pos {
  my ($self, $ids,$id_suffix)=@_;
  my $resolved = 0;
  my @sql;
  my $top_col;
  if ($self->{layout_version}>1) {
    $top_col = q{, "f"."top"};
  } else {
    $top_col = q{, 1};
  }
  foreach my $node_type (@{$self->get_node_types}) {
    my $decl = $self->get_decl_for($node_type);
    my $id_attr = $self->find_special_attribute($decl,'#ID');
    next unless $id_attr;
    my $node_tab = $self->get_node_table_for($node_type);
    my $basename = $self->get_schema_name_for($node_type);
    my $id_tests = join(' OR ',map {
      my $id = $_;
      $id=~s{'}{}g; $id=~s{\\}{}g; # these characters are NOT allowed
      qq{"n"."$id_attr" = '$id'}
    } @$ids);
    my $sql;
    $sql=<<"EOF";
SELECT "f"."file", "f"."tree_no", "n"."#idx"-"n"."#root_idx", "n"."$id_attr"$top_col
FROM "${node_tab}" "n" JOIN "${basename}__#files" "f" ON "n"."#root_idx"="f"."#idx"
WHERE $id_tests
EOF
    push @sql,$sql;
  }
  my $sql = join("  UNION\n",@sql);
  # print STDERR "$sql\n";
  my $rows = $self->run_sql_query($sql,{ MaxRows=>scalar(@$ids), RaiseError=>1 });
  my %result = map {
    $_->[3] => $_,
  } @$rows;
  my @res;
  for my $id (@$ids) {
    my $row = $result{$id};
    if ($row) {
      my ($fn,$tn,$nn,undef,$is_top) = @$row;
      if ($id_suffix or !(lc($is_top) eq 'true' or $is_top==1)) {
        push @res, $fn.'#'.$id;
      } else {
        push @res, $fn.'##'.($tn+1).'.'.$nn;
      }
    } else {
      push @res, undef;
    }
  }
  return @res;
}

# sub first_x_distinct_postgres {
#   $dbi->do("DECLARE csr CURSOR FOR SELECT $select");
#   my $total=0;
#   my $count=0;
#   my %seen;
#   CUR: while (1) {
#     my $sth = $dbi->prepare("FETCH $limit FROM CSR");
#     $sth->execute;
#     last if 0 == $sth->rows;
#     while (my $row = $sth->fetchrow_arrayref) {
#       $total++;
#       my $key = join("\t",@$row);
#       next if exists $seen{$key};
#       $seen{$key}=undef;
#       $count++;
# #      print "$key\n";
#       last CUR if $count>=$limit;
#     }
#   }
#   $dbi->do("CLOSE csr");
#   print "counted ",$count," distinct rows, fetched $total\n";
# }

sub close_cursor {
  my ($self)=@_;
  my $dbi = $self->{dbi} || die "Not connected to DBI!\n";
  my $cursor = delete $self->{cursor};
  return unless $cursor;
  my $close = delete $cursor->{close};
  $close->($self) if $close;
  delete $cursor->{distinct};
  return $cursor;
}
sub cursor_sth {
  my ($self)=@_;
  return $self->{cursor} ? $self->{cursor}{sth} : undef;
}
sub cursor_next {
  my ($self,$keep)=@_;

#  print STDERR "cursor_next\n";
  my $cursor = $self->{cursor};
  my $csr = $cursor->{name};
  my $buffer = $cursor->{buffer}||=[];
  my $sth = $cursor->{sth};
  my $distinct = $cursor->{distinct};
  if (!@$buffer and (!defined($cursor->{limit}) or $cursor->{limit}>0)) {
    $cursor->{buffer}=[];
    my $size = $cursor->{buffer_size};
#    print STDERR "refilling buffer: $size\n";
    while (1) {
      if ($csr) {
        if (defined($cursor->{limit}) and $cursor->{limit}<$size) {
          $size = $cursor->{buffer_size} = $cursor->{limit};
          if ($distinct) {
            my $ratio = $cursor->{ratio} ? ($cursor->{ratio}[0]/$cursor->{ratio}[1]) : undef;
            $size=$ratio ? int($size/$ratio)+1 : $size;
          }
          $sth = $cursor->{sth} = $self->{dbi}->prepare(qq{FETCH $size FROM "$csr"},{ pg_async => 1 });
#         print STDERR "New sth for $size: $sth\n";
        }
        my $opts = { timeout => $cursor->{timeout}, update_timeout=>1 };
        $buffer = $self->run_sql_query($sth,$opts);
        $cursor->{timeout} = $opts->{timeout};
      } else {
        if (defined($cursor->{limit}) and $cursor->{limit}<$size) {
          $size = $cursor->{buffer_size} = $cursor->{limit};
        }
        $buffer = $sth->fetchall_arrayref(undef,$size);
      }
      if ($buffer and @$buffer and $distinct) {
        no warnings;
        foreach my $row (@$buffer) {
          my $key = join("\x0",@$row);
          unless (exists $distinct->{$key}) {
            push @{$cursor->{buffer}},$row;
            $distinct->{$key}=undef;
          }
        }
        $buffer = $cursor->{buffer};
        $cursor->{ratio}||=[0,0];
        $cursor->{ratio}[0]+=scalar(@$buffer);
        $cursor->{ratio}[1]+=$size;
        next if !@$buffer;
      } elsif ($distinct) {
        $cursor->{buffer} = $buffer;
      } else {
#       print STDERR "got ".scalar(@$buffer)." rows\n";
        $cursor->{buffer} = $buffer;
      }
      last;
    }
    if (defined($cursor->{limit}) and $buffer) {
      splice(@$buffer,$cursor->{limit}) if (@$buffer>$cursor->{limit});
      $cursor->{limit} -= scalar(@$buffer);
    }
  }
  if ($buffer and @$buffer) {
    return $keep ? $buffer : shift(@$buffer);
  } else {
    return;
  }
}

sub run_sql_query {
  my ($self, $sql_or_sth, $opts)=@_;
  # print STDERR "run_sql_query: $sql_or_sth\n" if ($self->{debug} and !ref($sql_or_sth));

  my $dbi = $self->{dbi} || die "Not connected to DBI!\n";
  local $dbi->{RaiseError} = $opts->{RaiseError};
  local $dbi->{LongReadLen} = $opts->{LongReadLen} if exists($opts->{LongReadLen});
  require Time::HiRes;
  my $canceled = 0;
  if ($opts->{use_cursor}) {
#    print STDERR "Use cursor\n";
    $self->close_cursor if $self->{cursor};
    my $cursor = $self->{cursor} = {};
    my $size = $opts->{cursor_buffer_size} || 10_000;
    $cursor->{limit} = $opts->{limit} || $size;
    $size = $cursor->{limit} if $cursor->{limit} < $size;
    $cursor->{buffer_size} = $size;
    $cursor->{distinct}={} if ($opts->{no_distinct} and $self->{returns_nodes});
    $cursor->{timeout} = $opts->{timeout};
    my $csr = "pmltq_".$$;
    $cursor->{name}=$csr;
    eval {
      $dbi->do(qq{DECLARE "$csr" CURSOR FOR }.$sql_or_sth);
    };
    my $err = $@;
    if ($err) {
      $dbi->rollback();
      die $err;
    }

    $cursor->{close} = sub {
      eval { $dbi->do(qq{CLOSE "$csr"}) };
      $dbi->rollback() if $@;
    };
    if ($opts->{return_sth}) {
      $cursor->{sth} = $dbi->prepare(qq{FETCH $size FROM "$csr"},{ pg_async => 1 });
      if ($opts->{prepare_only}) {
        $self->{sth} = $cursor->{sth};
      }
#     print STDERR "Created sth for $size: $cursor->{sth}\n";
      return $cursor->{sth};
    } else {
      return;
    }
  }
  my $sth = ref($sql_or_sth) ? $sql_or_sth : $dbi->prepare( $sql_or_sth,{ pg_async => 1 } );
  if ($opts->{use_cursor}) {
    $self->{cursor}{sth}=$sth;
  }
  if ($opts->{prepare_only}) {
    if ( $opts->{return_sth} ) {
      return $self->{sth} = $sth;
    } else {
      return;
    }
  }

  my $step=0.05;
  my $time=$opts->{timeout};
  eval {
    $sth->execute(ref($opts->{Bind}) ? @{$opts->{Bind}} : ());
    if (defined $time) {
      while (!$sth->pg_ready) {
        $time-=$step;
        Time::HiRes::sleep($step);
        if ($time<=0) {
          if ($opts->{'timeout_callback'} and $opts->{'timeout_callback'}->($self)) {
            $time=$opts->{timeout};
          } else {
            $sth->pg_cancel();
            $opts->{timeout} = 0 if $opts->{update_timeout};
            die "TIMEOUT\n"
          }
        }
      }
    }
    $sth->pg_result;
  };
  my $err = $@;
  if ($err) {
    $dbi->rollback();
    die $err;
  #} else {
    #$dbi->commit();
  }
  $opts->{timeout} = $time if $opts->{update_timeout};

  if ($opts->{return_sth}) {
    return $sth;
  } elsif ($opts->{use_cursor}) {
    return;
  } else {
    return $sth->fetchall_arrayref(undef,$opts->{limit});
  }
}

# serialize to SQL (or SQL fragment)
sub serialize_conditions {
  my ($self,$node,$opts)=@_;
  $opts||={};
  if ($node->parent or $opts->{output_filter}) {
    return [$self->serialize_element({
      %$opts,
      name => 'and',
      condition => $node,
      is_positive_conjunct => 1,
    })];
  } else {
    return $self->build_sql($node,{
      node_IDs=>$opts->{node_IDs},
      returns_nodes=>$opts->{returns_nodes},
      no_filters => $opts->{no_filters},
      count=>$opts->{count},
      node_limit => $opts->{node_limit},
      row_limit => $opts->{row_limit},
      select_first => $opts->{select_first},
      no_distinct => $opts->{no_distinct},
    });
  }
}

sub relation {
  my ($self,$id,$rel,$target,$opts)=@_;
  my $relation = $rel->name;
  my $params = $rel->value;
  if ($relation eq 'ancestor') {
    $relation = 'descendant';
    ($id,$target)=($target,$id);
  } elsif ($relation eq 'parent') {
    $relation = 'child';
    ($id,$target)=($target,$id);
  } elsif ($relation eq 'order-follows') {
    $relation = 'order-precedes';
    ($id,$target)=($target,$id);
  } elsif ($relation eq 'depth-first-follows') {
    $relation = 'depth-first-precedes';
    ($id,$target)=($target,$id);
  }
  my $cond;
  if ($relation eq 'user-defined') {
    return $self->user_defined_relation($id,$params,$target,$opts);
  } elsif ($relation eq 'descendant') {
    $cond = qq{"$id"."#root_idx"="$target"."#root_idx" AND "$id"."#idx"!="$target"."#idx" AND }.
      qq{"$target"."#idx" BETWEEN "$id"."#idx" AND "$id"."#r"};
    my $min = $params->{min_length}||0;
    my $max = $params->{max_length}||0;
    if ($min>0 and $max>0) {
      $cond.=qq{ AND "$target"."#lvl"-"$id"."#lvl" BETWEEN $min AND $max};
    } elsif ($min>0) {
      $cond.=qq{ AND "$target"."#lvl"-"$id"."#lvl">=$min}
    } elsif ($max>0) {
      $cond.=qq{ AND "$target"."#lvl"-"$id"."#lvl"<=$max}
    }
  } elsif ($relation eq 'sibling') {
    $cond = qq{"$id"."#parent_idx"="$target"."#parent_idx" AND "$id"."#idx"!="$target"."#idx"};
    my $min = $params->{min_length};
    my $max = $params->{max_length};
    if ($min and $max) {
      $cond.=qq{ AND "$target"."#chord"-"$id"."#chord" BETWEEN $min AND $max};
    } elsif ($min) {
      $cond.=qq{ AND "$target"."#chord"-"$id"."#chord">=$min}
    } elsif ($max) {
      $cond.=qq{ AND "$target"."#chord"-"$id"."#chord"<=$max}
    }
  } elsif ($relation eq 'child') {
    $cond = qq{"$id"."#idx"="$target"."#parent_idx"};
  } elsif ($relation eq 'depth-first-precedes') {
    $cond = qq{"$id"."#root_idx"="$target"."#root_idx"};
    my $min = $params->{min_length}||0;
    my $max = $params->{max_length}||0;
    if ($min!=0 and $max!=0) {
      $cond.=qq{ AND "$target"."#idx"-"$id"."#idx" BETWEEN $min AND $max}.
        (($min>0 or $max<0) ? q{} : qq{ AND "$target"."#idx"!="$id"."#idx"})
    } elsif ($min!=0) {
      $cond.=qq{ AND "$target"."#idx"-"$id"."#idx">=$min}.($min>0 ? q{} : qq{ AND "$target"."#idx"!="$id"."#idx"});
    } elsif ($max!=0) {
      $cond.=qq{ AND "$target"."#idx"-"$id"."#idx"<=$max}.($max<0 ? q{} : qq{ AND "$target"."#idx"!="$id"."#idx"});
    } else {
      $cond.=qq{ AND "$target"."#idx">"$id"."#idx"}
    }
  } elsif ($relation eq 'same-tree-as') {
    $cond = qq{"$id"."#root_idx"="$target"."#root_idx"};
  } elsif ($relation eq 'same-document-as') {
    $cond = $self->serialize_predicate(
        {
          id=>$opts->{id},
          type=>$opts->{type},
          join=>$opts->{join},
          is_positive_conjunct=>$opts->{is_positive_conjunct},
          expression => qq{file(\$$target)},
        },
        {
          id=>$opts->{id},
          type=>$opts->{type},
          join=>$opts->{join},
          is_positive_conjunct=>$opts->{is_positive_conjunct},
          expression => qq{file(\$$id)},
        },
        '=',$opts # there should be no ambiguity here, treat expressoins as positive
       );
  } elsif ($relation eq 'order-precedes') {
    my $flags = $self->get_schema_flags($self->get_schema_name_for($opts->{type}));
    my ($S,$T);
    if (defined($flags) and ($flags & MAX_MIN_ORD)>0) {
      $S = {
        sql => qq{"$id"."#max_ord"},
        col_type => COL_NUMERIC,
       };
      $T = {
        sql => qq{"$target"."#min_ord"},
        col_type => COL_NUMERIC,
      };
    } else {
      my $decl = $self->get_decl_for($opts->{type});
      my $order = $self->find_special_attribute($decl,'#ORDER');
      if ($order) {
        $T = {
          id=>$opts->{id},
          type=>$opts->{type},
          join=>$opts->{join},
          is_positive_conjunct=>$opts->{is_positive_conjunct},
          expression => qq{\$$target.$order},
        };
        $S = {
          id=>$opts->{id},
          type=>$opts->{type},
          join=>$opts->{join},
          is_positive_conjunct=>$opts->{is_positive_conjunct},
          expression => qq{\$$id.$order},
        };
      }
    }
    if (not defined($S)) {
      die "No ordering is defined on nodes of type '$opts->{type}'!\n";
    }
    my ($min,$max)=
      map { (defined($_) and length($_)) ? $_ : undef }
        map { $params->{$_} }
          qw(min_length max_length);
    $cond =qq{"$id"."#root_idx"="$target"."#root_idx" AND };
    if (defined($min) and defined($max)) {
      $cond.=$self->serialize_predicate( $T,$S, qq{<$min,$max>},$opts)
        .(($min>0 or $max<0) ? q{} : qq{ AND "$target"."#idx"!="$id"."#idx"});
    } elsif (defined($min)) {
      $cond.=$self->serialize_predicate( $T,$S, qq{<$min,>},$opts)
        .($min>0 ? q{} : qq{ AND "$target"."#idx"!="$id"."#idx"});
    } elsif (defined($max)) {
      $cond.=$self->serialize_predicate( $T,$S, qq{<,$max>},$opts)
        .($max<0 ? q{} : qq{ AND "$target"."#idx"!="$id"."#idx"});
    } else {
      $cond.=$self->serialize_predicate( $T,$S, '>',$opts); # there should be no ambiguity here, treat expressions as positive
    }
    # print STDERR $cond,"\n";
  } elsif ($relation eq 'member') {
    # take parent's type,
    # use this type as a
    # use \$$target.#idx as b
    my $path = $self->{name2node}{$target}{'node-type'};
    $cond =
      $self->serialize_predicate(
        {
          id=>$opts->{id},
          type=>$opts->{type},
          join=>$opts->{join},
          is_positive_conjunct=>$opts->{is_positive_conjunct},
          expression => qq{\$$id.$path},
          allow_non_atomic => 1,
        },
        qq{"$target"."#idx"},
        q(=),$opts,
       );
  } else {
    die "Unsupported relation: $relation between nodes $id and $target\n";
  }
  return $cond;
}

# Given min_length and max_length of a relation, determine
# whether to treat the relation as transitive or not (faster).
# If neither min or max is defined or if max==1, we treat the relation as non-transitive.
sub _is_transitive {
  my ($min,$max)=@_;
  return ((!(defined($min) && length($min))
        && !(defined($max) && length($max))) || (defined($max) && $max==1)) ? 0 : 1;

}

sub user_defined_relation {
  my ($self,$id,$params,$target,$opts)=@_;
  my $relation=$params->{label};
  my $type = $opts->{type};
  my $cond;
  my $from_id = $opts->{id}; # view point

  my $target_spec = $self->get_relation_target_type($type,$relation,1);
  if ($target_spec
      and $target_spec->[0] == 1 # user defined
      and !$target_spec->[1][0]) { # revered
    ($id,$target)=($target,$id);
    $target_spec = $self->get_relation_target_type($type,$target_spec->[1][1],1);
    $relation = $target_spec->[1][1] if $target_spec;
  }
  unless ($target_spec) {
    die "Relation '$relation' not defined for nodes of type '$type'. ".
      "\nPossible PMLREF relations: ".
      join(', ',@{$self->get_pmlrf_relations($type)}).
      "\nPossible user-defined relations: ".
      join(', ',@{$self->get_user_defined_relations($type)});
  }

  my $min = $params->{min_length};
  my $max = $params->{max_length};
  if (defined($min) && length($min) && defined($max) && length($min) && ($min>$max)) {
    die "Invalid bounds for transitive relation '$relation\{$min,$max}'\n";
  }
  if ((defined($min) && length($min) || defined($max) && length($min)) and $type ne $target_spec->[1][2]) {
    die "Cannot create transitive closure for relation with different start-node and end-node types: '$type' -> '$target_spec->[1][2]'\n";
  }
  my $transitive = _is_transitive($min,$max);

  if ($target_spec->[0]==0) {
    # specfic (i.e. PMLREF -based) relation
    my $path = $relation;
    #     # fixup:
    #     if ($relation =~ /^(coref_text|coref_gram|compl)$/) {
    #       $relation .= '.rf';
    #     }
    if ($path=~/\.rf$/) {
      my $decl = $self->get_decl_for($type);
      $decl = $decl && $decl->find($relation);
      if ($decl) {
        if ($decl->get_decl_type == PML_CDATA_DECL and $decl->get_format eq 'PMLREF') {
          $path=~s/\.rf$//;
        }
      }
    }
    # print STDERR qq{RELATION: \$$id.$path = "$target"."#idx" ($opts->{is_positive_conjunct})\n};

    if ($transitive) {
      my $rec_table = $self->precompute_table({type=>$type,path=>$path,recursive=>1,max=>$max});
      $cond = $self->tabular_relation($opts,"#rec_".$rec_table->{name},$id,$target,$min,$max);
    } else {
      $cond =
        $self->serialize_predicate(
          {
            id=>$from_id,
            type=>$type,
            join=>$opts->{join},
            expression => qq{\$$id.$path},
            is_positive_conjunct=>$opts->{is_positive_conjunct},
          },
          qq{"$target"."#idx"},
          q(=),$opts,
         );
    }
  } else {
    # user-defined relation
    my $table = $target_spec->[1][0];
    if ($transitive) {
      my $rec_table = $self->precompute_table({type=>$type,table=>$table,recursive=>1,max=>$max});
      $table = "#rec_".$rec_table->{name};
      $cond = $self->tabular_relation($opts,$table,$id,$target,$min,$max);
    } else {
      $cond = $self->tabular_relation($opts,$table,$id,$target,undef,undef);
    }
  }
  return $cond;
}

sub precompute_table {
  my ($self,$spec)=@_;
  my $precomputed = $self->{precompute_recursive_relation}||={};
  my $rec_table;
  my $table;
  if ($spec->{table}) {
    $table = $spec->{table}
  } else {
    $table = $spec->{type}.'/'.$spec->{path};
  }
  if (exists($precomputed->{$table})) {
    $rec_table = $precomputed->{$table};
     # in future we may want to try precomputing non-recursive relations as well
    if ($spec->{recursive} and !$rec_table->{recursive}) {
      $rec_table->{recursive}=1;
      $rec_table->{max}=$spec->{max}
    } elsif ($spec->{recursive}) {
      if (defined($spec->{max})) {
        $rec_table->{max} = $spec->{max} if defined($rec_table->{max}) and $spec->{max}>$rec_table->{max};
      } else {
        $rec_table->{max}=undef; # unbounded
      }
    }
  } else {
    $rec_table = $spec;
    $rec_table->{name}=scalar(keys(%$precomputed));
    $precomputed->{$table} = $rec_table;
  }
  return $rec_table;
}

sub tabular_relation {
  my ($self,$opts,$table,$id,$target,$min,$max)=@_;
  my $join=$opts->{join};
  my $depth='';
  if (defined($min) and defined($max)) {
    $depth = " AND %s.depth BETWEEN $min AND $max"
  } elsif (defined($min)) {
    $depth = " AND %s.depth >= $min"
  } elsif (defined($max)) {
    $depth = " AND %s.depth <= $max"
  }
  if ($opts->{is_positive_conjunct}) {
    my $join_to;
    if ($opts->{subquery}) {
      $join_to = $opts->{id} eq $id ? $id : $target;
    } else {
      $join_to = $opts->{id} eq $id ? $target : $id;
    }
    my $J = ($join->{$join_to}||=[]);
    my $i = @$J;
    my $eid=$join_to."/U-$i";
    $depth=sprintf($depth,qq{"$eid"});
    if ($join_to eq $target) {
      push @$J,[$eid,$table, qq{"$eid"."#value"="$target"."#idx"}.$depth];
      return qq("$eid"."#idx" = "$id"."#idx");
    } else {
      push @$J,[$eid,$table, qq("$eid"."#idx" = "$id"."#idx").$depth];
      return qq{"$eid"."#value"="$target"."#idx"};
    }
  } else {
    $depth=sprintf($depth,'x');
    return qq{ EXISTS (SELECT 1 FROM "$table" x WHERE x."#idx" = "$id"."#idx" AND x."#value"="$target"."#idx"${depth}) };
  }
}

sub get_tabspec {
  my ($self, $id, $node_type, $n)=@_;
  my $tabspec;
  if (PMLTQ::Common::IsMemberNode($n,$self)) {
    my $query_type = PMLTQ::Common::DeclPathToQueryType($self->get_decl_for($node_type)->get_decl_path);
    $tabspec = [
      $self->get_real_table_name( $query_type ),
      $id,
      $n
     ];
  } else {
    $tabspec = [$self->get_node_table_for($node_type),$id,$n];
  }
  return $tabspec;
}

sub build_sql {
  my ($self,$tree,$opts)=@_;
  $opts||={};
  my ($format,$count,$tree_parent_id) = map {$opts->{$_}} qw(format count parent_id);
  $count||=0;
  # we rely on depth first order!
  my @nodes = PMLTQ::Common::FilterQueryNodes($tree);
  my @select;
  my @table;
  my @where;
  my %conditions;
  my $extra_joins = $opts->{join} || {};
  local $self->{precompute_recursive_relation} unless $tree->parent;
  #  my $default_type = $opts->{type}||$tree->root->{'node-type'}||'UNKNOWN';
  for (my $i=0; $i<@nodes; $i++) {
    my $n = $nodes[$i];
    my $node_type = PMLTQ::Common::GetQueryNodeType($n,$self);
    my $id = $self->{id_map}{$n};

    push @select, $id;
    my $parent = $n->parent;
    while ($parent and ($parent->{'#name'}||'') !~/^(?:node|subquery)$/) {
      $parent=$parent->parent;
    }
    my $parent_id = defined($parent) && $self->{id_map}{$parent};
    $conditions{$id} = PMLTQ::Common::as_text($n);
    my @conditions;
    {
      my $tabspec = $self->get_tabspec($id,$node_type,$n);
      if ($parent && $parent->parent) {
        # print STDERR "EXTRA JOINS: $extra_joins\n";
        my $parent_type = PMLTQ::Common::GetQueryNodeType($parent,$self);
        my ($rel) = SeqV($n->{relation});
        $rel ||= PMLTQ::Common::SetRelation($n,'child');

        my $relation = $self->relation($parent_id,$rel,$id, {
          %$opts,
          id=>$id,
          join => $extra_joins,
          subquery => ($n->{'#name'} eq 'subquery' ? 1 : 0),
          type=>PMLTQ::Common::GetQueryNodeType($parent,$self), # ($parent->{'node-type'}||$default_type),
          is_positive_conjunct=>1, #($n->{'#name'} eq 'subquery' ? 0 : 1),
        });

        if (($n->{optional} && $parent_type eq $node_type) or $n->{'#name'} eq 'subquery' or $rel->name eq 'same-document-as') {
          push @table,$tabspec;
          push @conditions, [$relation, $n];
        } else {
          push @{$extra_joins->{ $parent_id }}, [ $tabspec->[1], $tabspec->[0], $relation, $n->{optional} ? 'LEFT' : '' ];
        }
      } else {
        push @table,$tabspec;
      }
    }

    unless ($n->{overlapping}) {
      # overlapping nodes, denoted as ' +relation type [ ... ] ' do not
      # have to be disjoint from other nodes matched by the query
      push @conditions,
        (map {
          [qq{"$self->{id_map}{$_}"."#idx"}.
           (
            (($_->parent == $n->parent) &&
             $conditions{$id} eq $conditions{$self->{id_map}{$_}}) ? '<' : '!=' ).
           qq{"${id}"."#idx"},$n] }
         grep {                 #$_->parent == $n->parent
           #  or
           my $type=PMLTQ::Common::GetQueryNodeType($_,$self); #  $_->{'node-type'}||$default_type;
           !$_->{overlapping} and ($type eq $node_type)
         }
         map { $nodes[$_] } 0..($i-1));
    }
    {
      my $conditions = $self->serialize_conditions($n,{
        type=>$node_type,
        id=>$id,
        parent_id=>$parent_id,
        join => $extra_joins,
      });
      push @conditions, [$conditions,$n] if @$conditions;
    }
    # where could also be obtained by replacing ___SELF___ with $id
    if ($n->{optional}) {
      # identify with parent
      if (@conditions) {
        @conditions = ( [ [['(('], @{PMLTQ::Common::_group(\@conditions,["\n    AND "])}, [qq{) OR "$id"."#idx"="$parent_id"."#idx")}]], $n] );
      }
    }
    push @where, @conditions;
  }

  my @sql = (['SELECT ']);
  my @outputs = ($opts->{no_filters} || $tree->parent) ? () : PMLTQ::Common::merge_filters($tree->{'output-filters'});
  my $returns_nodes = $opts->{returns_nodes} || \ my $dummy;
  if ($count == 2) {
    $$returns_nodes=0;
    push @sql,['count(DISTINCT "'.$self->{id_map}{$tree}.'"."#idx")','space'];
  } elsif ($count == 3) { # exists
    $$returns_nodes=0;
    push @sql,['1','space'];
  } elsif ($count) {
    $$returns_nodes=0;
    push @sql,['count(1)','space'];
  } elsif (@outputs) {
    $$returns_nodes=0;
    push @sql, (
      ($opts->{select_first} ? () : (["DISTINCT\n  "])),
      map {
      my $n = $nodes[$_];
      (($_==0 ? () : [",\n  ",'space']),
       [qq{"$select[$_]"."#idx"},$n],
       [' AS "'.$select[$_].'.#idx"',$n],
      )
    } 0..$#nodes);
  } else {
    $$returns_nodes=1;
    my @order = $self->{query_node_order} ? @{$self->{query_node_order}}{@nodes} : (0..$#nodes);
    die "Internal error: cannot recover query_node_order" if @order!=@nodes;
    my $i=0;
    push @sql, (
      (($opts->{select_first} || $opts->{no_distinct}) ? () : (["DISTINCT\n  "])),
      map {
        my $o = $_;
      my $n = $nodes[$o];
      my $sep = PMLTQ::Common::IsMemberNode($n) ? '//' : '/';
      my $node_type = PMLTQ::Common::GetQueryNodeType($n,$self);
      (($i++==0 ? () : [",\n  ",'space']),
       [qq{"$select[$o]"."#idx" || '$sep$node_type' }
        .(
          $opts->{node_IDs} ?
            do {
              my @types;
              if ($node_type=~m{^(?:([^/]+):)?\*$}) {
                @types=@{$self->get_node_types($1)};
              } else {
                @types=($node_type);
              }
              my @col;
              if ($SEPARATE_TREES==1 or @types>1 or (@types and $types[0] ne $node_type)) {
                my $name = $self->{id_map}{$n};
                @col = map [ $_, $self->join_table_for_type_cast({
                  id=>$name,
                  cast=> $_,
                  join => $extra_joins,
                  left=>(@types>1 ? 1 : 0),
                }) ], @types;
              } else {
                @col=([$node_type,$select[$o]]);
              }
              for my $col (@col) {
                my $decl = $self->get_decl_for($col->[0]);
                $col->[2] = $self->find_special_attribute($decl,'#ID');
              }
              @col = grep $_->[2], @col;
              if (@col==1) {
                qq{ || '\@' || "$col[0]->[1]"."$col[0]->[2]" }
              } elsif (@col>1) {
                qq{ || '\@' || COALESCE(}.join(',',map qq{"$_->[1]"."$_->[2]"}, @col).qq{)}
              } else {
                q{}
              }
            }
            : ''
         ),$n],
       [' AS "'.$select[$_].'.#addr"',$n],
      )
    } @order
   );
  }

  # joins
  #  print STDERR Data::Dumper::Dumper($extra_joins);
  {
    my $i=0;
    my %seen;
    for my $t (@table) {
      my ($tab, $name, $node)=@$t;
      push @sql, ($i++)==0 ? ["\nFROM\n  ",'space'] : [",\n  ",'space'];
      push @sql, [qq{"$tab" "$name"},$node];
      $self->serialize_joins(\@sql, $extra_joins, $name, $node, \%seen);
    }
    # serialize joins for which we have no table here
    for my $name (grep { $_ ne '..' } keys %$extra_joins) {
      $self->serialize_joins(\@sql,$extra_joins,$name, undef, \%seen);
    }
  }
  my $have_where=0;
  {
    my @w=@{PMLTQ::Common::_group(\@where,["\n  AND "])};
    push @sql, [ "\nWHERE\n     ",'space'],@w if @w;
    $have_where = 1 if @w;
  }
  if (defined $opts->{select_first}) {
    my $limit = 'LIMIT 1';
    push @sql, ["\n".$limit,'space'];
  }
  if (@outputs) {
    my $output_opts;
    $$returns_nodes=0;
    my $first = first { $_->{'#name'} eq 'node' } $tree->children;
    $output_opts = {
      id     => $self->{id_map}{$first},
      join   => {},
      referred_nodes => {},
    };
    my (@f_sql,@f_where);
    push @f_sql, ['SELECT '];
    push @f_sql, ['DISTINCT '] if $outputs[0]->{distinct};
    $output_opts->{group_by} = $self->serialize_columns($outputs[0]->{'group-by'},0,$output_opts,'group_by');
    push @f_where, @{$self->serialize_conditions($outputs[0]->{'where'},
                   {%$output_opts, output_filter=>1, output_filter_where_clause=>1})}
      if ref $outputs[0]->{'where'};
    push @f_sql,[$self->serialize_columns($outputs[0]->{return},0,$output_opts,'select'),'space'];
    $output_opts->{prev_columns}=$outputs[0]->{return};
    $output_opts->{column_types} = [
      map $self->compute_data_type($_,{%$output_opts, output_filter=>1}), @{$output_opts->{prev_columns}}
    ];
    push @f_sql, [" FROM (\n"];
    unshift @sql, @f_sql;
    push @sql, [ qq{\n) "#qnodes"\n} ];

    {
      my %seen;
      my @f_table =
        map {
          my $n = $self->{name2node}{$_};
          $self->get_tabspec($_,PMLTQ::Common::GetQueryNodeType($n,$self),$n)
        } sort keys %{$output_opts->{referred_nodes}};
      for my $t (@f_table) {
        my ($tab, $name, $node)=@$t;
        my $left = $node->{optional} && $node->parent
          && PMLTQ::Common::GetQueryNodeType($node, $self) ne PMLTQ::Common::GetQueryNodeType($node->parent, $self);
        push @sql, [($left ? '  LEFT ' : '  ').qq{JOIN "$tab" "$name" ON "$name"."#idx"="#qnodes"."$name.#idx"\n},$node];
        $self->serialize_joins(\@sql, $output_opts->{join}, $name, $node, \%seen);
      }
      for my $name (grep { $_ ne '..' } keys %{$output_opts->{join}}) {
        $self->serialize_joins(\@sql,$output_opts->{join},$name, undef, \%seen);
      }
    }

    my @f_w=@{PMLTQ::Common::_group(\@f_where,["\n  AND "])};
    push @sql, [ "\nWHERE\n     ",'space'],@f_w if @f_w;
    my $group_by = delete $output_opts->{group_by};
    push @sql,
      (@$group_by ?
         ["\n GROUP BY ".join(', ',@$group_by)."\n",$tree] : ()),
      ($outputs[0]->{'sort-by'} ?
         ["\n ORDER BY ".$self->serialize_columns($outputs[0]->{'sort-by'},1,$output_opts,'order_by'),$tree] : ());
    shift @outputs;
    my $i=1;
    for my $out (@outputs) {
      #print "===============\n";
      #print STDERR "for:\n";
      $output_opts->{group_by} = $self->serialize_columns($out->{'group-by'},$i,$output_opts,'group_by');
      # $output_opts->{prev_columns}=$out->{'group-by'};
      #print STDERR "give:\n";
      unshift @sql, ['SELECT '
                    .($out->{distinct} ? 'DISTINCT ' : '')
                      .$self->serialize_columns($out->{'return'},$i,$output_opts,'select')." FROM (\n",$tree];
      push @sql,
        [qq{) "#filter_$i" \n},$tree];
      if ($out->{where}) {
        push @sql, ["\nWHERE\n",'space'],
          @{ $self->serialize_conditions($out->{'where'},{%$output_opts, output_filter=>$i+1, output_filter_where_clause=>1}) };
      }
      $output_opts->{prev_columns}=$out->{'return'};
      $output_opts->{column_types} = [
        map $self->compute_data_type($_,{%$output_opts, output_filter=>$i+1}), @{$output_opts->{prev_columns}}
       ];
      #print STDERR "sort:\n";
      my $group_by = delete $output_opts->{group_by};
      push @sql,
        (@$group_by ?
           ["\n GROUP BY ".join(', ',@$group_by)."\n",$tree] : ()),
        ($out->{'sort-by'} ?
           ["\n ORDER BY ".$self->serialize_columns($out->{'sort-by'},$i+1,$output_opts,'order_by')."\n",$tree] : ());
      $i++;
    }
  }
  unless (defined($tree_parent_id) and defined($self->{id_map}{$tree})) {
    if ($$returns_nodes) {
#      push @sql, ["\n".$self->serialize_limit($opts->{node_limit},$have_where ? 0 : 1)."\n",'space'] if defined $opts->{node_limit};

#      if ($opts->{syntax} eq 'oracle') {
      unless ($opts->{no_distinct}) {
        if ($opts->{node_limit}) {
          if ($opts->{node_limit}<0 or $opts->{node_limit}==1) {
            push @sql, [' '.'LIMIT '.abs($opts->{node_limit}).';'];
          } else {
            unshift @sql, ['SELECT * FROM ('];
            push @sql, [qq{\n) "results" }.'LIMIT '.$opts->{node_limit}.';'];
          }
        }
      }
#      } else {
#       push @sql, [' '.$self->serialize_limit($opts->{node_limit},1)];
#      }

    } elsif ($opts->{row_limit}) {
#      if ($opts->{syntax} eq 'oracle') {
        unshift @sql, ['SELECT * FROM ('];
        push @sql, [qq{) "#count" }.'LIMIT '.$opts->{row_limit}.';'];
#      } else {
#       push @sql, [' '.$self->serialize_limit($opts->{row_limit},1)];
#      }
    }
    if ($self->{precompute_recursive_relation}) {
      my @with;
      my $tables = delete $self->{precompute_recursive_relation};
      my $next_with_clause =
        (grep ({ !$_->{recursive} } values(%$tables)))
          ? qq{WITH\n} : qq{WITH RECURSIVE\n};
      for my $key (reverse sort keys %$tables) {
        my $spec = $tables->{$key};
        my $out;
        my %joins;
        my $rel_table;

        if ($spec->{table}) {
#         my $id = '#n';
#         my $J = $joins{$id}=[ ['u',$spec->{table}, qq(u."#idx" = "$id"."#idx")] ];
#         $out = q{u."#value"};
          $rel_table = $spec->{table};
        } else {
          my $pt = PMLTQ::Common::parse_expression($spec->{path});
          my $out = $self->serialize_expression_pt($pt,{
            id => '#n', # just a fake node ID
            join => \%joins,
            type=>$spec->{type},
            expression=>$spec->{path},
            is_positive_conjunct=>1
           },\%joins); # do not copy $opts here!
          $rel_table = "#rel_".$spec->{name};
          push @with, [$next_with_clause.
                         qq{  "$rel_table" AS (\n}.
                         qq{  SELECT "#n"."#idx" "#idx", $out "#value" FROM "$spec->{type}" "#n" }];

          $next_with_clause = qq{),\n};
        }
        for my $name (grep { $_ ne '..' } keys %joins) {
          for my $join_spec (@{$joins{$name}}) {
            my ($join_as,$join_tab,$join_on,$join_type)=@{$join_spec};
            $join_tab = $self->get_real_table_name($join_tab);
            $join_type||='';
            push @with, ["\n  ",'space'], [qq($join_type JOIN "$join_tab" "$join_as" ON $join_on)]
          }
        }
        if ($spec->{recursive}) {
          # recursive version of $rel_table
          my $select;
          my $max_depth='';
          $select =
            qq{    SELECT "#idx" "#idx", "#value" "#value", 1 depth, '['||"#idx"||']' path FROM "$rel_table"\n}.
            qq{  UNION\n}.
            qq{    SELECT r."#idx", c."#value", r.depth+1, r.path || '[' || c."#idx"||']'\n}.
            qq{      FROM "#rec_$spec->{name}" r\n}.
            qq{      JOIN "$rel_table" c ON r."#value" = c."#idx"\n}.
            qq{    WHERE r."#idx" != c."#value" and strpos(path,'[' || c."#idx" || ']')=0\n}.
            (defined($spec->{max}) ? qq{          AND r.depth <= $spec->{max}\n} : q{});
          push @with, [ qq{$next_with_clause "#rec_$spec->{name}" AS (\n}.$select ];
        }
        push @with, [qq{)\n}];
        $next_with_clause = qq{,\n};
      }
      unshift @sql, @with;
    }
  }

  if ($format) {
    return PMLTQ::Common::make_string_with_tags(\@sql,[$tree]);
  } else {
    return PMLTQ::Common::make_string(\@sql);
  }
}

sub serialize_joins {
  my ($self, $sql, $extra_joins, $name, $node, $seen)=@_;
  return if $seen->{$name} or $name eq '..';
  $seen->{$name}=1;
  for my $join_spec (@{$extra_joins->{$name}}) {
    my ($join_as,$join_tab,$join_on,$join_type)=@{$join_spec};
    $join_tab = $self->get_real_table_name($join_tab);
    $join_type||='';
    push @$sql, ["\n  ",'space'], [qq($join_type JOIN "$join_tab" "$join_as" ON $join_on),($node ? $node : ())];
    unless ($node) {
      print STDERR qq{MISPLACED_JOIN: $join_type JOIN "$join_tab" "$join_as" ON $join_on\n};
    }
  }
  for my $join_spec (@{$extra_joins->{$name}}) {
    $self->serialize_joins($sql, $extra_joins, $join_spec->[0], $node, $seen);
  }
}

sub serialize_columns {
  my ($self,$col_list,$j,$opts,$type,$prev_columns)=@_;
  my @cols;
  my $i=1;
  for my $col (ListV($col_list)) {
    my $dir;
    if ($type eq 'order_by') {
      if ($col=~s{\s+(asc|desc)}{}) {
        $dir = uc($1);
      }
    }
    my ($str,$wrap,$cal_be_null)=$self->serialize_expression({%$opts,expression=>$col,output_filter=>$j+1,is_positive_conjunct=>1});
    push @cols, $str.($type eq 'select' ? ' AS c'.($j+1).'_'.($i++) : '').
      ($dir ? ' '.$dir : '')
  }
  return $type eq 'group_by' ? \@cols : join(',  ', @cols);
}

sub get_real_table_name {
  my ($self,$path)=@_;
  croak("No table!") unless defined $path;
  if (exists $self->{pml_tables}{$path}) {
    return $self->{pml_tables}{$path};
  }
  # HACK(pajas): element tables are named in PML2BASE by '#e_'.table_name($decl),
  # therefore we need to strip #e_, resolve and prepend.
  my $p = $path;
  my $prefix = ($p=~s/^(#e_)//) ? $1 : '';
  my $results = $self->run_sql_query(qq(SELECT "table" FROM "#PMLTABLES" WHERE "type" = ? ),{ MaxRows=>1, RaiseError=>1, Bind=>[$p] });
  my $table = $results->[0][0];
  return $self->{pml_tables}{$path} = $table ? $prefix.$table : $path;
}

sub get_node_table_for {
  my ($self,$type)=@_;
  my $table;
  if ($type eq '*') {
    $table = $self->get_schema_names->[0].'__#trees';
  } elsif ($type=~m{^([^/]+):\*$}) {
    $table = $1.'__#trees';
  } else {
    $table = $SEPARATE_TREES==1 ?
      $self->get_schema_name_for($type).'__#trees' : $type;
  }
  return $self->get_real_table_name($table);
}
sub get_schema_name_for {
  my ($self,$type)=@_;
  if ($type eq '*') {
    return $self->get_schema_names->[0];
  } elsif ($type=~m{^([^/]+):\*$}) {
    return $1;
  }

  if (exists $self->{schema_types}{$type}) {
    if (defined $self->{schema_types}{$type} ) {
      return $self->{schema_types}{$type};
    } else {
      confess("Did not find schema name for type $type (0)\n");
    }
  }
  croak("No type!") unless defined $type;
  my $results = $self->run_sql_query(qq(SELECT "root" FROM "#PMLTYPES" WHERE "type" = ? OR ? LIKE ("type" || '/%')),{ MaxRows=>1, RaiseError=>1, Bind=>[$type,$type] });
  my $schema_name = $results->[0][0];

  if ($schema_name) {
    return $self->{schema_types}{$type} = $schema_name
  } else {
    # fallback: try all schemas:
    $results = $self->run_sql_query(qq(SELECT DISTINCT "root" FROM "#PMLTYPES"),{RaiseError=>1});
    for $schema_name (map $_->[0], @$results) {
      my $schema = $self->get_schema($schema_name);
      if (PMLTQ::Common::QueryTypeToDecl($type,$schema)) {
        return $self->{schema_types}{$type} = $schema_name
      }
    }
    $self->{schema_types}{$type} = undef;
    confess("Did not find schema name for type $type\n");
  }
}
sub get_schema {
  my ($self,$name)=@_;
  return unless $name;
  if ($self->{schemas}{$name}) {
    return $self->{schemas}{$name};
  }
  my $results = $self->run_sql_query(qq(SELECT "schema" FROM "#PML" WHERE "root" = ? ),
                                     { MaxRows=>1, RaiseError=>1, LongReadLen=> 512*1024, Bind=>[$name] });
  unless (ref($results) and ref($results->[0]) and $results->[0][0]) {
    die "Failed to obtain PML schema $name\n";
  }
  return $self->{schemas}{$name} = Treex::PML::Schema->new({string => $results->[0][0]});
}
sub get_node_types {
  my ($self,$schema_name)=@_;
  if ($schema_name) {
    return $self->{schema_node_types}{$schema_name} if defined $self->{schema_node_types};
    my $results = $self->run_sql_query(qq(SELECT "type","root" FROM "#PMLTYPES" ORDER BY "type"),{ MaxRows=>1, RaiseError=>1 });
    my $cached = $self->{schema_node_types} = {};
    for my $row (@$results) {
      push @{$cached->{$row->[1]}},$row->[0];
    }
    return $self->{schema_node_types}{$schema_name};
  } else {
    return $self->{node_types} if defined $self->{node_types};
    my $results = $self->run_sql_query(qq(SELECT "type" FROM "#PMLTYPES" ORDER BY "type"),{ MaxRows=>1, RaiseError=>1 });
    return $self->{node_types} = [ map $_->[0], @$results ];
  }
}
sub get_schema_names {
  my ($self)=@_;
  return $self->{schema_names} if defined $self->{schema_names};
  my $results = $self->run_sql_query(qq(SELECT "root" FROM "#PML" ORDER BY "root"),{ MaxRows=>1, RaiseError=>1 });
  return $self->{schema_names} = [ map $_->[0], @$results ];
}

sub get_decl_for {
  my ($self,$type)=@_;
  return unless $type;
  return $self->{type_decls}{$type} ||= PMLTQ::Common::QueryTypeToDecl($type,$self->get_schema_for_type($type));
}

sub get_schema_for_type {
  my ($self,$type)=@_;
  return $self->get_schema($self->get_schema_name_for($type));
}

sub get_schema_flags {
  my ($self,$schema_name)=@_;
  return $self->{schema_flags}{$schema_name} if exists($self->{schema_flags});
  my $rows = eval {
    $self->run_sql_query(qq(SELECT "root","flags" FROM "#PML"),{ RaiseError=>1 });
  };
  $self->{schema_flags} = {
    map { $_->[0] => $_->[1] } @{$rows || []}
  };
  return $self->{schema_flags}{$schema_name};
}

sub join_table_for_type_cast {
  my ($self, $opts)=@_;
  my ($node_id,$cast,$ref_join,$check_joins, $left) = @$opts{qw(id cast join check_joins left)};
  my $id=$node_id."/#n_".$cast;
  unless (first {$_->[0] eq $id} (@{$ref_join->{$node_id}}, map { @{$_->{$node_id}} } @{$check_joins||[]})) {
    push @{$ref_join->{$node_id}},
      [$id,$cast, qq("$node_id"."#type"='$cast' AND "$id"."#idx" = "$node_id"."#idx"), $left ? 'LEFT' : () ];
  }
  return $id;
}
my %asoc_precedence = (
  div => 1,
  mod => 1,
  '*' => 1,
  '&' => 0, #concat
  '-' => 0,
  '+' => 0,
);
sub serialize_expression_pt {# pt stands for parse tree
  my ($self,$pt,$opts,$extra_joins)=@_;
  my $this_node_id = $opts->{id};

  if (ref($pt)) {
    my $type = shift @$pt;
    if ($type eq 'ATTR' or $type eq 'REF_ATTR') {
      if (defined($opts->{output_filter}) and $opts->{output_filter}>1) {
        die "Attribute reference cannot be used in output filter columns whose input is not the body of the query: '$opts->{expression}'"
      }
      my ($id,$attr,$cmp,$node_type,$cast,$decl);
      if ($type eq 'REF_ATTR') {
        $id = $pt->[0];
        $pt=$pt->[1];
        die "Error in attribute reference of node $id in expression $opts->{expression} of node '$this_node_id'"
          unless shift(@$pt) eq 'ATTR'; # not likely
        if ($id eq '$') {
          $cmp=0;
          $id=$this_node_id;
          $node_type = $opts->{type};
        } else {
          $cmp = $self->cmp_subquery_scope($this_node_id,$id);
          #     print "Comparing $this_node_id and $id scope: $cmp\n";
          if ($cmp<0) {
            die "Node '$id' belongs to a sub-query and cannot be referred from the scope of node '$this_node_id' ($opts->{expression})\n";
          }
          $node_type = $self->get_type_of_node($id);
        }
      } else {
        $cmp=0;
        $id=$this_node_id;
        $node_type = $opts->{type};
      }
      if($pt->[0] =~ /^(.+)\?$/) {
        $cast = $1; shift @$pt;
      } elsif ($node_type=~m{^(?:([^/]+):)?\*$}) {
        my $node_types = $self->get_node_types($1);
        my @possibilities;
        my $path = join '/',map { ($_ eq '[]' or $_ eq 'content()') ? '#content' : $_ } @$pt;
        for my $nt (@$node_types) {
          my $decl = $self->get_decl_for($nt);
          my $attr_decl = $decl && $decl->find($path);
          $attr_decl=$attr_decl->get_content_decl
            while ($attr_decl and ($attr_decl->get_decl_type == PML_LIST_DECL or
                                   $attr_decl->get_decl_type == PML_ALT_DECL));

          push @possibilities,
            $type eq 'REF_ATTR' ? ['REF_ATTR',$id,['ATTR',$nt.'?',@$pt]] : ['ATTR',$nt.'?',@$pt]
              if ($attr_decl and $attr_decl->is_atomic);
        }
        if (!@possibilities) {
          die "The attribute path '$path' is not valid for any node type matched by the '$node_type' wildcard: @$node_types\n";
        } elsif (@possibilities == 1) {
          return $self->serialize_expression_pt($possibilities[0],$opts,$extra_joins);
        } else {
          return $self->serialize_expression_pt(['FUNC','first_defined',\@possibilities],$opts,$extra_joins);
        }
      }
      $decl = $self->get_decl_for($cast || $node_type);
      if (!$decl) {
        die "Couldn't determine node type of node '$id' to evaluate $opts->{expression}\n";
      }
      # ??? why not just $table = ($cast || $node_type) ?? members?
      my $table=PMLTQ::Common::DeclPathToQueryType($decl->get_decl_path);
      $opts->{referred_nodes}{$id}=1 if ref($opts->{referred_nodes});

      my $node_id = $id;
      my $j;
#       if (!$opts->{is_positive_conjunct} or $cmp) {
#         print "extra joins\n";
#         $opts->{use_exists}=1;
#         $j=$extra_joins;
#       } else {
#         print "normal joins\n";
          $j=$opts->{join};
#       }
      $extra_joins->{$node_id}||=[];

      my $ref_join = $opts->{join};
      $ref_join = $ref_join->{'..'} for 1..$cmp;
      $ref_join->{$node_id}||=[];
      if ($SEPARATE_TREES==1 or ($cast and $cast ne $node_type)) {
        $id = $self->join_table_for_type_cast({
          # table=>$table,
          id=>$node_id,
          left=>($cast?1:0),
          cast=> $table, # ($cast||$node_type),
          join => $ref_join,
          check_joins => [$extra_joins]
         });
      } else {
        $id=$node_id;
      }

        my @t = @$pt;
        my $column;
        my $iter=0;
        while ($iter++ < 100) {
          my ($mdecl,$mtable);
          my $can_be_null = ($cast and $iter == 1) ? 1 : 0;
          my $decl_is = $decl->get_decl_type;
          my $extra_condition;
          my $pos_condition;
          my $prev = $id;
          if ($decl_is == PML_STRUCTURE_DECL or
              $decl_is == PML_CONTAINER_DECL) {
            last unless @t;
            $column= shift @t;
            if ($column eq '[]' or $column eq 'content()') {
              $column = '#content';
            }
            $mdecl = $decl->get_member_by_name($column);
            if (!$mdecl and $decl_is == PML_STRUCTURE_DECL) {
              $mdecl=$decl->get_member_by_name($column.'.rf');
              $mdecl=undef unless $mdecl; # and $mdecl->get_knit_name eq $column;
            }
            if ($column eq '#content') {
              # TODO(pajas): Figure out if there are cases when #content
              # cannot be NULL.
              $can_be_null=1;
            } elsif ($mdecl) {
              unless ($mdecl->is_required) {
                $can_be_null=1;
              }
              $mdecl = $mdecl->get_knit_content_decl;
            }
          } elsif ($decl_is == PML_LIST_DECL) {
            shift @t if @t and $t[0] eq 'LM';
#           if ($decl->is_ordered and @t and $t[0]=~m{^\[\s*(\d+)\s*\]$}) {
#             $mdecl = $decl;
#           } else {
              $mdecl=$decl->get_knit_content_decl;
#           }
            $column='#value';
            $can_be_null=1;
          } elsif ($decl_is == PML_ALT_DECL) {
            shift @t if @t and $t[0] eq 'AM';
            $mdecl=$decl->get_knit_content_decl;
            $column='#value';
            $can_be_null=1;
          } elsif ($decl_is == PML_SEQUENCE_DECL) {
            last unless @t;
            $column= shift @t;
            #print STDERR "prev: $prev id: $id\n";
            if ($column=~s/^\[(\d+)\]//g) {
              $pos_condition = qq{"#pos" = $1-1 };
            } elsif ($column=~s/\[\s*(\d+)\s*\]$//g) {
              $pos_condition = qq{"#elpos" = $1-1 };
            }
            $mdecl = $decl->get_element_by_name($column);
            if ($mdecl) {
              $mtable='#e_'.PMLTQ::Common::DeclPathToQueryType($mdecl->get_knit_content_decl->get_decl_path);
            } else {
              die "Sequence does not allow element '$column' in expression $opts->{expression} at node "
                .($cast||$node_type)
                ." \$$this_node_id: ".join('/',@t);
            }
            $can_be_null=1;
          } elsif ($decl_is == PML_ELEMENT_DECL) {
            $mdecl=$decl->get_knit_content_decl;
            $column='#value';
          } elsif ($decl->is_atomic) {
#           if (@t==1 and $t[0] eq '.') {
#             $mdecl = $decl;
#             $column='#value';
#             shift @t;
#           } else {
              die "Cannot apply attribute path to an atomic type in expression $opts->{expression} at node "
                .($cast||$node_type)
                ." \$$this_node_id: ".join('/',@t);
#           }
          } else {
            die ref($self)." internal error: Didn't expect type $decl_is\n";
          }
          die "Didn't find member '$column' on '$table' while compiling expression $opts->{expression} of node '$this_node_id'" unless $mdecl;

          my $mdecl_is = $mdecl->get_decl_type;
          $opts->{can_be_null}=1 if $can_be_null;

          my $is_ambiguous = ($mdecl_is == PML_LIST_DECL or $mdecl_is == PML_ALT_DECL or $mdecl_is == PML_SEQUENCE_DECL) ? 1 : 0;

          #print STDERR "prev: $prev, column: $column, decl: $decl, mdecl: $mdecl, can_be_null: $can_be_null\n";
          #print STDERR "mdecl is ",$mdecl->get_decl_type,"; is atomic: ",$mdecl->is_atomic," \n";

          if ($mdecl->is_atomic) {
            if (@t) {
              die "Cannot follow attribute path past atomic type while compiling expression $opts->{expression} of node "
                .($cast||$node_type)." \$$this_node_id: ".join('/',@t);
            }
            return qq( "$prev"."$column" );
          } elsif ($opts->{allow_non_atomic} and $mdecl->get_decl_type != PML_ELEMENT_DECL and
                     ((!@t and $mdecl->get_decl_type != PML_LIST_DECL and $mdecl->get_decl_type != PML_ALT_DECL)
                     or( @t==1 and $t[0] eq '.'))) {
            return qq( "$id"."$column" );
          } else {

            #
            # We now decide our strategy: either we use JOIN in the apropriate SELECT,
            # or use a subquery with EXISTS
            # or, in PostgreSQL, we may even try JOIN on the current SELECT
            #

            my $j = $ref_join; # default is join to the current or outer SELECT
            my $left=''; # use LEFT join
            if ($opts->{use_exists}==2) {
              # forced use of EXISTS
              $j=$extra_joins;
            } elsif ($opts->{allow_non_atomic}) {
              #       # special case: we want to join members
            } elsif ($opts->{can_be_null} or ($is_ambiguous and $cmp)) {
              # either a nullable column or an ambiguous column from some outer SELECT
              if (!$opts->{is_positive_conjunct}) {
                # non-positive conjunct: we must use EXIST
                $opts->{use_exists}||=1;
                $j=$extra_joins;
              } elsif ($cmp) {
                # outer SELECT, we can't join there if nullable
                if ($ALLOW_MISPLACED_PG_JOIN) {
                  # but in postgres, we may in fact JOIN to the current SELECT
                  # (and we do because EXISTS is very slow there,
                  # try e.g. the query: t-node [ 0x a/aux.rf a-node [] ]
                  # with forced EXSITS
                  $j = $opts->{join};
                } else {
                  # elsewhere we use EXISTS
                  $opts->{use_exists}||=1;
                  $j=$extra_joins;
                }
              } else {
                $opts->{use_exists}||=1 unless (PREFER_LEFT_JOINS);
                #$j=$extra_joins;
                if ($opts->{use_exists}) {
                  $j=$extra_joins;
                } else {

                  # we are in a positive conjunct, so the value must be there and non-null, right?

                   $left='LEFT';
                }
              }
            }
            my $i=$self->{join_id}++;
            $id=$node_id."/$i";
            my $condition = qq("$id"."#idx" = "$prev"."$column");

            if ($pos_condition) {
        $condition= qq{($condition AND "$id".$pos_condition)};
      }

            if ($extra_condition) {
              $condition= qq{($condition AND "$id".$extra_condition)};
            }
            my $mdecl_is = $mdecl->get_decl_type;

            if (($mdecl_is == PML_LIST_DECL) and @t and $t[0]=~m{^\[\s*(\d+)\s*\]$}) {
              if ($mdecl->is_ordered) {
                $condition= qq{($condition AND "$id"."#pos" = $1-1)};
                shift @t;
              } else {
                my $p = $mdecl->get_decl_path;
                $p=~s/^!//;
                die "Cannot use index '$t[0]' in expression '$opts->{expression}' of node '$this_node_id' on value of type '$p' that is declared in the PML schema as an *unordered* list";
              }
            }
            $table = $mtable||PMLTQ::Common::DeclPathToQueryType($mdecl->get_decl_path);
            push @{$j->{$node_id}},[$id,$table, $condition, $opts->{output_filter} ? 'LEFT' : $left  ];
            #print STDERR "$node_id => JOIN $table as $id ON $condition\n";
          }
          $decl=$mdecl;
        }
        if ($iter>=100) {
          die "Deep recursion while compiling '$opts->{expression}' of node '$this_node_id'";
        }
        die "Expression '$opts->{expression}' of node '$this_node_id' does not lead to an attomic value";
    } elsif ($type eq 'FUNC') {
      my $name = $pt->[0];
      my $args = $pt->[1];
      $opts->{can_be_null}=1;
      my $id;
      if ($name=~/^(?:descendants|lbrothers|sons|depth|depth_first_order|order_span_min|order_span_max|name|type_of)$/) {
        if ($args and @$args==1 and !ref($args->[0]) and $args->[0]=~s/^\$//) {
          $id = $args->[0];
          if ($self->cmp_subquery_scope($this_node_id,$id)<0) {
            die "Node '$id' belongs to a sub-query and cannot be referred from the scope of node '$this_node_id' ($opts->{expression})\n";
          }
        } elsif ($args and @$args) {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(\$node?)\n";
        } else {
          $id=$this_node_id;
        }
        $opts->{referred_nodes}{$id}=1 if ref($opts->{referred_nodes});

        if ($name =~ /^order_span/) {
          my $span = $1;
          my $flags = $self->get_schema_flags($self->get_schema_name_for($opts->{type}));
          if (!defined($flags) or !($flags & MAX_MIN_ORD)) {
            my $n = $self->{name2node}{$id};
            $n or die "Cannot refer to node '$id' from $name() in expression $opts->{expression} of node '$this_node_id'!\n";
            my $type = PMLTQ::Common::GetQueryNodeType($n,$self);
            my $decl = $self->get_decl_for($type);
            if ($decl->get_decl_type == PML_ELEMENT_DECL) {
              $decl = $decl->get_content_decl;
            }
            my ($order) = map { $_->get_name } $decl->find_members_by_role('#ORDER');
            if (defined $order) {
              return qq{"$id"."$order"}
            } else {
              die "No ordering is defined on nodes of type '$type'!\n";
            }
          }
        }
        return ($name eq 'descendants') ? qq{("$id"."#r"-"$id"."#idx")}
             : ($name eq 'lbrothers')   ? qq{"$id"."#chord"}
             : ($name eq 'sons')        ? qq{"$id"."#chld"}
             : ($name eq 'depth')       ? qq{"$id"."#lvl"}
             : ($name eq 'depth_first_order') ? qq{("$id"."#idx"-"$id"."#root_idx")}
             : ($name =~ 'order_span_min') ? qq{"$id"."#min_ord"}
             : ($name eq 'order_span_max') ? qq{"$id"."#max_ord"}
             : ($name eq 'name')        ? qq{"$id"."#name"}
             : ($name eq 'type_of')     ? qq{"$id"."#type"}
             : die "PMLTQ internal error while compiling expression: should never get here!";
      } elsif ($name eq 'length') {
        if ($args and @$args==1) {
          my $ret = 'LENGTH('
              .  $self->serialize_expression_pt($args->[0],$opts,$extra_joins)
                . ')';
          return $ret;
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(string)\n";
        }
      } elsif ($name=~/^(?:lower|upper)$/) {
        if ($args and @$args==1) {
          return uc($name).'('
            .  $self->serialize_expression_pt($args->[0],$opts,$extra_joins)
            . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(string)\n";
        }
      } elsif ($name=~/^(?:abs|floor|ceil|exp|sqrt|ln)$/) {
        if ($args and @$args==1) {
          return uc($name).'('
            .  $self->serialize_expression_pt($args->[0],$opts,$extra_joins)
            . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(number)\n";
        }
      } elsif ($name =~ /^(?:log|power)$/) {
        my $func = uc($name);
        if ($args and @$args==1) {
          return $func.'(10,CAST('
            .  $self->serialize_expression_pt($args->[0],$opts,$extra_joins)
            . ' AS FLOAT))';
        } elsif ($args and @$args==2) {
          return $func.'('
            .  $self->serialize_expression_pt($args->[0],$opts,$extra_joins).','
            .  'CAST('.$self->serialize_expression_pt($args->[1],$opts,$extra_joins).' AS FLOAT)'
            . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(base,number) or ${name}(number)\n";
        }
      } elsif ($name eq 'address') {
        my @arg;
        if ($args and @$args) {
          my $ref = $args->[0];
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(\$node?)\n"
            if (@$args>1 or $ref!~/^\$(?!\d)/);
          @arg = ($ref);
        }
        return $self->serialize_expression_pt(
          ['EXP' =>
             [FUNC => 'file', [@arg]],
             '&', "'##'", '&',
             [FUNC => 'tree_no', [@arg]],
             '&', "'.'", '&',
            [FUNC => 'depth_first_order', [@arg]],
          ],$opts,$extra_joins);
      } elsif ($name =~ /^(file|tree_no)$/) {
        my $id;
        if ($args and @$args) {
          my $ref = $args->[0];
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(\$node?)\n"
            if (@$args>1 or not $ref=~s/^\$(?!\d)//);
          $id= $ref eq '$' ? $this_node_id : $ref;
        } else {
          $id = $this_node_id;
        }
        my $n = $self->{name2node}{$id};
        my $cmp = $self->cmp_subquery_scope($this_node_id,$id);
        if (!$n or $cmp<0) {
          die "Node '$id' belongs to a sub-query and cannot be referred from the scope of node '$this_node_id' ($opts->{expression})\n";
        }
        $opts->{referred_nodes}{$id}=1 if ref($opts->{referred_nodes});
        my $j = $opts->{join};
        $j = $j->{'..'} for 1..$cmp;
        my $J = ($j->{$id}||=[]); #($extra_joins->{$id}||=[]);
        my $table = $self->get_schema_name_for(PMLTQ::Common::GetQueryNodeType($n,$self)).'__#files';
        my $fid = $id."/#file";
        push @$J,[$fid,$table, qq("$fid"."#idx" = "$id"."#root_idx")] unless first { $_->[0] eq $fid } @$J;
        return $name eq 'tree_no' ? qq{("$fid"."$name"+1)} : qq{"$fid"."$name"};
      } elsif ($name eq 'rbrothers') {
        my $id;
        if ($args and @$args) {
          my $ref = $args->[0];
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(\$node?)\n"
            if (@$args>1 or not $ref=~s/^\$(?!\d)//);
          $id= $ref eq '$' ? $this_node_id : $ref;
        } else {
          $id = $this_node_id;
        }
        my $n = $self->{name2node}{$id};
        my $cmp = $self->cmp_subquery_scope($this_node_id,$id);
        if (!$n or $cmp<0) {
          die "Node '$id' belongs to a sub-query and cannot be referred from the scope of node '$this_node_id' ($opts->{expression})\n";
        }
        $opts->{referred_nodes}{$id}=1 if ref($opts->{referred_nodes});
        my $j = $opts->{join};
        $j = $j->{'..'} for 1..$cmp;
        my $J = ($j->{$id}||=[]); #($extra_joins->{$id}||=[]);
        my $table = $self->get_schema_name_for(PMLTQ::Common::GetQueryNodeType($n,$self)).'__#trees';
        my $p_id = $id."/#parent";
        push @$J,[$p_id,$table, qq("$p_id"."#idx" = "$id"."#parent_idx")] unless first { $_->[0] eq $p_id } @$J;
        return qq{("$p_id"."#chld"-"$id"."#chord"-1)};
      } elsif ($name eq 'id') {
        my $id;
        if ($args and @$args) {
          my $ref = $args->[0];
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(\$node?)\n"
            if (@$args>1 or not $ref=~s/^\$(?!\d)//);
          $id= $ref eq '$' ? $this_node_id : $ref;
        } else {
          $id = $this_node_id;
        }
        my $n = $self->{name2node}{$id};
        $n or die "Cannot refer to node '$id' from $name() in expression $opts->{expression} of node '$this_node_id'!\n";
        $opts->{referred_nodes}{$id}=1 if ref($opts->{referred_nodes});
        my $decl = $self->get_decl_for(PMLTQ::Common::GetQueryNodeType($n,$self));
        if ($decl->get_decl_type == PML_ELEMENT_DECL) {
          $decl = $decl->get_content_decl;
        }
        my ($m)=$decl->find_members_by_role('#ID');
        my $id_attr = defined($m) && $m->get_name;
        if (defined $id_attr) {
          return $self->serialize_expression_pt(['REF_ATTR',$id,[$id_attr]],$opts,$extra_joins);
        } else {
          return 'NULL';
        }
      } elsif ($name=~/^(?:round|trunc)$/) {
        if ($args and @$args and @$args<3) {
          return uc($name).'('
                 .  join(',',map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$args)
                 . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(string)\n";
        }
      } elsif ($name eq 'percnt') {
        if ($args and @$args>0 and @$args<3) {
          my @args = map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$args;
          my $ret = 'round(100*('.$args[0].')'
            . (@args>1 ? ','.$args[1] : '').q[)];
          return $ret;
        } else {
          die "Wrong arguments for function percnt() in expression $opts->{expression} of node '$this_node_id'!\nUsage: percnt(number,precision?)\n";
        }
      } elsif ($name eq 'substr') {
        if ($args and @$args>1 and @$args<4) {
          my $cast_to_string;
          if ($self->compute_data_type($args->[0],$opts)!=COL_STRING) {
            $cast_to_string=1;
          }
          my @args = map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$args;
          $args[1].='+1';
          $args[0]='cast('.$args[0].' as varchar)' if $cast_to_string;
          return 'SUBSTR('.  join(',', @args) . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: substr(string,from,length?)\n";
        }
      } elsif ($name=~/(?:replace|tr)$/) {
        if ($args and @$args==3) {
          my $cast_to_string;
          if ($self->compute_data_type($args->[0],$opts)!=COL_STRING) {
            $cast_to_string=1;
          }
          my @args = map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$args;
          $args[0]='cast('.$args[0].' as varchar)' if $cast_to_string;
          return ($name eq 'tr' ? 'TRANSLATE' : uc($name) ).'('
            .  join(',', @args)
              . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name".
            ($name eq 'replace' ? "(string,target,replacement)\n"
                                : "(string,from_chars,to_chars)\n");
        }
      } elsif ($name eq 'substitute') {
        if ($args and @$args>=3 and @$args<=4) {
          my @cast_to_string;
          for (0..2) {
            $cast_to_string[$_]= ($self->compute_data_type($args->[$_],$opts)!=COL_STRING) ? 1 : 0 if $_<@$args;
          }
          my @args = map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$args;
          for (0..2) {
            $args[$_]='cast('.$args[$_].' as varchar)' if ($_<@$args and $cast_to_string[$_]);
          }
          my $match_opts = $args[3];
          if (defined($match_opts) and (ref($match_opts) or $match_opts!~/^\s*'[icnmg]*'\s*$/)) {
            die "Wrong match options $match_opts for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,pattern,replacement,options), where options is a literal string consisting only of characters from the set [icnmg]\n";
          }
          return 'REGEXP_REPLACE('.join(',', @args[0..2],$match_opts ? $match_opts : ()).')'
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,pattern,replacement,options)\n";
        }
      } elsif ($name eq 'match') {
        if ($args and @$args>=2 and @$args<=3) {
          my @cast_to_string;
          for (0..1) {
            $cast_to_string[$_]= ($self->compute_data_type($args->[$_],$opts)!=COL_STRING) ? 1 : 0 if $_<@$args;
          }
          my @args = map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$args;
          for (0..1) {
            $args[$_]='cast('.$args[$_].' as varchar)' if ($_<@$args and $cast_to_string[$_]);
          }
          my $match_opts = $args[2];
          if (defined($match_opts) and (ref($match_opts) or $match_opts!~/^\s*'[icnm]*'\s*$/)) {
            die "Wrong match options [$match_opts] for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,pattern,options?), where options is a literal string consisting only of characters from the set [icnm]\n";
          }
          return '(REGEXP_MATCHES('.qq{$args[0],'(' || $args[1] || ')',}
                                   .($match_opts || q(''))
                                   .'))[1]'

        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,pattern,options?)\n";
        }
      } elsif ($name eq 'first_defined') {
        if (!$args or @$args<2) {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(value1,value2,...)\n";
        }
        my @types = map { $self->compute_data_type($_,$opts) } @$args;
        my @args = map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$args;
        if (first { $_ !=COL_NUMERIC } @types) {
          for (@args) {
            if ( shift(@types)!=COL_STRING ) {
              $_=qq{cast($_ as varchar)} ;
            }
          }
        }
        return 'COALESCE('.join(',', @args).')'
      } else {
        die "Function ${name}() unknown or not yet implemented!\n";
      }
    } elsif ($type eq 'EVERY') {
      $opts->{use_exists}=2;
      $opts->{is_positive_conjunct}=0;
      if ($opts->{output_filter}) {
        die "Cannot use quantifier '*' in output filter: '$opts->{expression}'"
      }
      return $self->serialize_expression_pt($pt->[0],$opts,$extra_joins);
    } elsif ($type eq 'IF') {
      my ($condition,$if_true,$if_false) = @$pt;
      my $test = PMLTQ::Common::make_string([$self->serialize_element({
        name => $condition->{'#name'},
        condition => $condition,
        is_positive_conjunct => 1,
        %$opts,
      })]);
      my ($true_type,$false_type) = map $self->compute_data_type($_,$opts), ($if_true, $if_false);
      my ($if_true_sql,$if_false_sql) = map { $self->serialize_expression_pt($_,$opts,$extra_joins) }
        ($if_true,$if_false);
      if ($true_type != $false_type or $true_type == COL_UNKNOWN) {
        $_=qq{cast($_ as varchar)} for ($if_true_sql, $if_false_sql);
      }
      return qq{(CASE WHEN $test THEN $if_true_sql ELSE $if_false_sql END)};
    } elsif ($type eq 'ANALYTIC_FUNC') {
      my $name = shift @$pt;
      die "The analytic function ${name}() can only be used in an output filter expression!\n"
        unless $opts->{'output_filter'};
      die "The analytic function ${name}() cannot be used in the 'filter' clause!\n"
        if $opts->{'output_filter_where_clause'};
      my $args = shift @$pt;
      die "The analytic function $name without an 'over' clause cannot be used to compute an argument to another analytic function without an 'over' clause $opts->{aggregated} in the output filter expression $opts->{expression}!\n"
        if defined($opts->{'aggregated'})
          and !@$pt #over
          and !($opts->{group_by} and @{$opts->{group_by}});
      $name = 'ratio_to_report' if $name eq 'ratio';
      my @args;
      if ($args) {
        if ($name eq 'concat') {
          die "The analytic function $name takes one or two arguments concat(STR, SEPARATOR?) in the output filter expression $opts->{expression}; got @$args!\n" if @$args==0 or @$args>2;
          if (@$args==2) {
            unless (defined($args->[1]) and !ref($args->[1]) and $args->[1]!~/^\$/) {
              die "The second argument to concat(STR, SEPARATOR?) must be a literal string or number in $opts->{expression}!\n";
            }
          }
        } elsif ($name =~ /^(rank|dense_rank|row_number)/ and @$args>0) {
          die "The analytic function $name takes no arguments in the output filter expression $opts->{expression}!\n";
        } elsif (@$args>1) {
          die "The analytic function $name takes at most one arguments in the output filter expression $opts->{expression}!\n";
        }
        for my $arg (@$args) {
          push @args, $self->serialize_expression_pt($arg,{%$opts,
                                                           (@$pt ? () : (aggregated=>$name, group_by=>undef))
                                                          },$extra_joins)
        }
      }
      my $out='';
      if ($name eq 'concat') {
        $out=q{concat_agg(};
        if (@args==1) {
          $out.=$args[0];
        } elsif (@args==2) {
          my $sep = $args[1];
          $out=q{regexp_replace(}.$out.$args[0].' || '.$sep;
        }
      } elsif ($name eq 'ratio_to_report') {
        my $arg = @args ? $args[0] : 'count(*)';
        $out='(('.$arg.') / sum('.$arg;
      } else {
        $out=uc($name).'('.(@args ? $args[0] : '');
      }
      unless (@args) {
        if ($name eq 'count') {
          $out.='*'
        } elsif ($name eq 'ratio_to_report') {
          $out.='count(*)'
        } elsif ($name !~ /^(rank|dense_rank|row_number)/) {
          if ($opts->{group_by} and @{$opts->{group_by}}) {
            $out .= $opts->{group_by}[0];
          } elsif ($opts->{'output_filter'}<2) {
            die "Cannot use analytic function ${name}() with implicit argument (\$1) in the first filter!\n";
          } else {
            $out .= 'c'.($opts->{'output_filter'}-1).'_1';
          }
        }
      }
      $out.=')';
      my ($over,$sort)=@$pt;
      if (($over and @$over) or ($sort and @$sort) or $name =~ /^(rank|dense_rank|row_number)/) {
        $out.= ' OVER (';
        if ($over and @$over and !(@$over==1 and $over->[0] eq 'ALL')) {
          $out.= 'PARTITION BY '.join(',',map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$over)
        }
        if ($sort and @$sort) {
          $out.=' ORDER BY '.join(',',map { $self->serialize_expression_pt($_->[0],$opts,$extra_joins).
                                              ($_->[1] ? ' '.uc($_->[1]) : '')
                                            } @$sort);
          if ($name !~ /^(rank|dense_rank|row_number)/) {
            $out.=' RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING'
          }
        }
        $out.=')';
      }
      if ($name eq 'concat') {
        if (@args==2) {
          #
          # we now quote 2nd argument so that we can use it as a regexp
          # that matches the trailing separator
          # e.g. SQL ''' | ''' (that is q{' | '}) becomes '\'' \| \''$'
          #                                       (that is q{\' \| \'$})
          #
          my $trim_separator = $args[1];
          if ($trim_separator =~ /^(\s*E?)(['])(.*?)([']\s*)$/) {
            my ($lead,$lead2,$body,$trail)=($1,$2,$3,$4);
            $body=~s/\\(.)/$1/g; # unquote '
            $body=quotemeta($body); # quote meta characters
            $body=~s/\\/\\\\/g; # quote \\ and '
            $body=~s/'/\\'/g; # quote '
            $lead =~s/$/E/ if $lead!~/E/;
            $trim_separator = $lead.$lead2.$body.'$'.$trail;
          } elsif ($trim_separator =~ /^(\s*[NU]?['])(.*?)([']\s*)$/) {
            my ($lead,$body,$trail)=($1,$2,$3);
            $body=~s/''/'/g; # unquote '
            $body=quotemeta($body); # quote meta characters
            $body=~s/'/''/g; # quote '
            $trim_separator = $lead.$body.'$'.$trail;
          }
          $out.=qq{,$trim_separator,'')};
        }
      }
      return $out;
    } elsif ($type eq 'EXP') {
      my $out='';
      my $mult='';
      $mult = $self->serialize_expression_pt(shift @$pt,$opts,$extra_joins) if @$pt;
      while (@$pt) {
        my $op = shift @$pt;
        die "Missing left expression for operator '$op' in expression $opts->{expression} of node '$this_node_id'\n"
          unless @$pt;
        my $exp = $self->serialize_expression_pt(shift @$pt,$opts,$extra_joins);
        # a+b*c%2+d/2*2+f
        # a+ => a+(b) => a+(b*c) => a+mod(b*c,2) => a+mod(b*c,2)+
        if ($op eq 'div') {
          $mult=qq{($mult / $exp)};
        } elsif ($op eq 'mod') {
          $mult=qq{MOD($mult,$exp)};
        } elsif ($op eq '*') {
          $mult=qq{($mult * $exp)};
        } elsif ($op eq '&') {
          $out.=qq{$mult || };
          $mult = $exp;
        } elsif ($op =~ /^[-+]$/) {
          $out.=qq{$mult $op };
          $mult = $exp;
        } else {
          die "Urecognized operator '$op' in expression $opts->{expression} of node '$this_node_id'\n";
        }
      }
      return qq{($out$mult)}
    } elsif ($type eq 'SET') {
      my $res= '('
        .  join(',', map { $self->serialize_expression_pt($_,$opts,$extra_joins) } @$pt)
        . ')';
      $opts->{can_be_null}=0;
      return $res;
    } else {
      die "Internal error: unrecognized parse tree item $type\n";
    }
  } else {
    if ($pt=~/^[-0-9]/) { # literal number
      return qq( $pt );
    } elsif ($pt=~s/^(['"])(.*)\1$/$2/s) { # literal string
      $pt=~s/\\(.)/$1/sg;
      $opts->{can_be_null}=1 if !length $pt;
      if ($pt=~m/\\/) {
        $pt=~s/'/\\'/sg;
        $pt=~s{\\}{\\\\}g;
        qq( E'$pt' );
      } else {
        $pt=~s/'/''/sg;
        qq( '$pt' );
      }
    } elsif ($pt=~s/^\$//) { # a plain variable
      if ($pt =~ /^\d+$/) { #column reference

        die "Column reference \$$pt can only be used in an output filter; error in expression '$opts->{expression}' of node '$this_node_id'\n"
          unless $opts->{'output_filter'};
        my $col;
#       print STDERR "$opts->{'output_filter'}: \$$pt, aggregated=$opts->{aggregated}, group by (@{$opts->{group_by}||[]}), prev_columns: (@{$opts->{prev_columns}||[]})\n";
        if (!$opts->{output_filter_where_clause} and $opts->{group_by} and @{$opts->{group_by}}) {
          $col =  $opts->{group_by}[$pt-1];
          if (!defined $col) {
            die "Cannot refer to column number $pt from the expression $opts->{expression} following a 'for' with ".
              scalar(@{$opts->{group_by}})." column(s): (".join(', ',ListV($opts->{group_by})).")!\n";
          }
        } else {
          if ($opts->{'output_filter'}<2) {
            die "Cannot refer to a numbered column \$$pt from the first filter!\n";
          } elsif ($pt-1 < ListV($opts->{prev_columns})) {
            $col = 'c'.($opts->{'output_filter'}-1).'_'.$pt;
          } else {
            die "Cannot refer to column number $pt from the expression '$opts->{expression}' following a filter with ".
              scalar(@{$opts->{prev_columns}})." column(s): (".join(', ',ListV($opts->{prev_columns})).")!\n";
          }
        }
        return ' '.$col.' ';
      }
      if (defined($opts->{'output_filter'}) and $opts->{'output_filter'}==1) {
        if ($pt eq '$') {
          die "The variable '\$\$' cannot be used in an output filter!\n";
        } elsif ($self->cmp_subquery_scope($this_node_id,$pt)<0) {
          die "Node '$pt' belongs to a sub-query and cannot be referred from the scope of node '$this_node_id' ($opts->{expression})\n";
        }
        return qq{ "#qnodes"."$pt.#idx" }; # not "$pt"."#idx" !!
      } elsif ($opts->{'output_filter'}) {
        die("Cannot refer to a named node '$pt' from an output filters except for the first filter! ($opts->{expression})\n");
      } else {
        return qq{ "$this_node_id"."#idx" } if $pt eq '$';
        if ($self->cmp_subquery_scope($this_node_id,$pt)<0) {
          die "Node '$pt' belongs to a sub-query and cannot be referred from the scope of node '$this_node_id' ($opts->{expression})\n";
        }
        return qq( "$pt"."#idx" );
      }
    } else { # unrecognized token
      die "Token '$pt' not recognized in expression $opts->{expression} of node '$this_node_id'\n";
    }
  }
}

sub serialize_expression {
  my ($self,$opts)=@_;
  my $pt =
    $opts->{'output_filter'}
      ? PMLTQ::Common::parse_column_expression($opts->{expression})
      : PMLTQ::Common::parse_expression($opts->{expression}); # $pt stands for parse tree
  die "Invalid expression '$opts->{expression}' on node '$opts->{id}'" unless defined $pt;

  my $extra_joins=$opts->{'output_filter'} ? $opts->{join} : {};
  $opts->{use_exists}=0;
  $opts->{can_be_null}=0;
  my $out = $self->serialize_expression_pt($pt,$opts,$extra_joins); # do not copy $opts here!
  my $wrap;
  if (!$opts->{'output_filter'} and $opts->{use_exists}) {
    my @from;
    my @where;
    for my $name (grep { $_ ne '..' } keys (%$extra_joins)) {
      if ($extra_joins->{$name}) {
        my $table;
        for my $join_spec (@{$extra_joins->{$name}}) {
          my ($join_as,$join_tab,$join_on,$join_type)=@{$join_spec};
          $join_type||='';
          $join_tab = $self->get_real_table_name($join_tab);
          if (defined $table) {
            $table.=qq(\n  $join_type JOIN "$join_tab" "$join_as" ON $join_on);
          } else {
            $table=qq("$join_tab" "$join_as");
            push @where, $join_on;
          }
        }
        push @from,$table;
      }
    }
    if (@from) {
      $wrap=($opts->{use_exists}==2 ? 'NOT EXISTS' : 'EXISTS').' (SELECT *'
        .' FROM '.join(', ',@from)
        .' WHERE '.join("\n   AND ",@where);
      $wrap=~s/%/%%/g;
      $wrap.="\n  AND " if @where;
      if ($opts->{use_exists}==2) {
        $wrap.='NOT(%s) )';
      } else {
        $wrap.='%s )';
      }
    }
  }
  #  $out = '' if $opts->{use_exists}==2;
  return ($out,$wrap,$opts->{can_be_null});
}

sub compute_data_type {
  my ($self, $exp, $opts)=@_;
  if ($opts->{output_filter}) {
    return PMLTQ::Common::compute_column_data_type($self,$exp,$opts);
  } else {
    return PMLTQ::Common::compute_expression_data_type($self,$exp,$opts);
  }
}

sub serialize_predicate {
  my ($self,$L,$R,$operator,$opts)=@_;
  $opts->{join}||={};

  my ($left,$wrap_left,$left_can_be_null) = ref($L) ?
    (defined($L->{sql}) ? ($L->{sql}) : $self->serialize_expression($L)) : ($L);
  if (ref($L) and defined($L->{use_exists}) and $L->{use_exists}==2) {
    $R->{is_positive_conjunct}=0;
    $R->{can_be_null}=1;
  }
  my $right_every;
  my ($right,$wrap_right,$right_can_be_null) = ref($R) ?
    (defined($R->{sql}) ? ($R->{sql}) : $self->serialize_expression($R)) : ($R);
  my $is_positive_conjunct = $opts->{is_positive_conjunct};
  my $negate = $operator=~ s/^!// ? 1 : 0;
  $is_positive_conjunct=0 if $is_positive_conjunct && $negate;

  my $res;
  my ($R_type, $L_type) = (COL_UNKNOWN, COL_UNKNOWN);
  $R_type = ref($R) ?
    (defined($R->{col_type}) ? $R->{col_type} : $self->compute_data_type($R->{expression},$opts))
      : defined($opts->{R_type}) ? $opts->{R_type} : COL_UNKNOWN;
  $L_type = ref($L) ?
    (defined($L->{col_type}) ? $L->{col_type} : $self->compute_data_type($L->{expression},$opts))
      : defined($opts->{L_type}) ? $opts->{L_type} : COL_UNKNOWN;

  if ($right =~ qr{^\s*[NE]?''\s*$} and $left =~ qr{^\s*[NE]?''\s*$}) {
    $res = qq{0=0}
  } elsif ($right =~ qr{^\s*[NE]?''\s*$}) {
    if ($L_type == COL_STRING) {
      $res = qq{($left }.uc($operator).qq{ $right OR $left IS NULL)}
    } else {
      $res = qq{$left IS NULL}
    }
  } elsif ($left =~ qr{^\s*[NE]?''\s*$}) {
    if ($R_type == COL_STRING) {
      $res = qq{($right }.uc($operator).qq{ $left OR $right IS NULL)}
    } else {
      $res = qq{$right IS NULL}
    }
  }
  if (!defined $res) {
    if ($operator =~/[<>=]/) { # includes "fake is-between operator" <N,M>
      if ($L_type == COL_NUMERIC and
            $R_type != COL_NUMERIC) {
        $left=qq{cast($left as varchar)};
      } elsif ($R_type == COL_NUMERIC and
                 $L_type != COL_NUMERIC) {
        $right=qq{cast($right as varchar)};
      }
    }
    my $cmp =
      $operator=~/^<(.*),(.*)>$/ ?  # special "fake is-between operator"
        qq{($left - $right)}.
        (
          (length($1) and length($2)) ? qq{BETWEEN $1 AND $2} :
          length($1) ? qq{>=$1} :
            length($2) ? qq{<=$2} : die("Internal error: cannot serialize operator $operator\n")
        )
      : qq{$left }.uc($operator).qq{ $right};
    $res = '('.$cmp
      .($left_can_be_null && !$is_positive_conjunct ? qq{ AND $left IS NOT NULL} : '')
      .($right_can_be_null && !$is_positive_conjunct ? qq{ AND $right IS NOT NULL} : '')
      .')';
  }
  $res = qq{NOT($res)} if $negate;
  if (defined $wrap_right) {
    $res=sprintf($wrap_right,$res);
  }
  if (defined $wrap_left) {
    $res=sprintf($wrap_left,$res);
  }
  return $res;
}

sub serialize_element {
  my ($self,$opts)=@_;
  my ($name,$node,$as_id,$parent_as_id)=map {$opts->{$_}} qw(name condition id parent_id);
  my $is_positive_conjunct = $opts->{is_positive_conjunct};
  if ($name eq 'test') {
    return
      [$self->serialize_predicate({%$opts,
                                   expression=>$node->{a},
                                   is_positive_conjunct=>$is_positive_conjunct},
                                  {%$opts,
                                   expression=>$node->{b},
                                   is_positive_conjunct=>$is_positive_conjunct},
                                  $node->{operator},
                                  $opts),$node];
  } elsif ($name =~ /^(?:and|or|not)$/) {
    my @c = $node->children;
    if (defined($is_positive_conjunct)) {
      if ($name eq 'not') {
        $is_positive_conjunct=!$is_positive_conjunct;
        $is_positive_conjunct=undef if @c>1 and !$is_positive_conjunct;
      } elsif ($name eq 'and') {
        $is_positive_conjunct=undef if @c>1 and !$is_positive_conjunct;
      } elsif ($name eq 'or') {
        $is_positive_conjunct=undef if @c>1 and $is_positive_conjunct;
      }
    }
    @c =
      grep { @$_ }
      map {
        my $n = $_->{'#name'};
        $self->serialize_element({
          %$opts,
          name => $n,
          condition => $_,
          id => $as_id,
          parent_id => $parent_as_id,
          is_positive_conjunct=>$is_positive_conjunct
         })
      } grep { $_->{'#name'} ne 'node' } @c;
   return unless @c;
   return
     $name eq 'not' ? [[['NOT('],@{PMLTQ::Common::_group(\@c,["\n      AND "])},[')']],$node] :
     $name eq 'and' ? [[['('],@{PMLTQ::Common::_group(\@c,["\n    AND "])},[')']],$node] :
     $name eq 'or' ? [[['('],@{PMLTQ::Common::_group(\@c,["\n    OR "])},[')']],$node] : ();
  } elsif ($name eq 'subquery') {
    my @sql;
    my @occ;
    my @vals = grep ref, AltV($node->{occurrences});
    @vals=(Treex::PML::Factory->createStructure({min=>1})) unless @vals;
    # we treat 0x and 1+x especially
    # using exists and not exists
    my ($exists, $not_exists);
    $exists = (@vals==1 and $vals[0]{min}==1 and
                   (!defined($vals[0]{max}) or !length($vals[0]{max})));
    $not_exists = ( ! $exists
                    and @vals == 1
                    and defined $vals[0]{max} and length $vals[0]{max} and $vals[0]{max} == 0
                    and ($vals[0]{min}||0) == 0);
    my $subquery = $self->build_sql($node,{
      format => 1,
      count=> ($exists || $not_exists ) ? 3 : 2,
      parent_id=>$opts->{id},
      join => {
        '..' => $opts->{join}, # where joins for nodes in the outer scope should go
      }, # $opts->{join}, # let subqueries use their own join
    });

    if ($exists) {
      return [[['EXISTS ('],@$subquery,[qq')']],$node];
    } elsif ($not_exists) {
      return [[['NOT EXISTS ('],@$subquery,[qq')']],$node];
    } else {
      for my $occ (@vals) {     # this is not optimal for @occ>1
        my ($min,$max)=($occ->{min},$occ->{max});
        $min='' unless defined $min;
        $max='' unless defined $max;
        if (length($min) and length($max)) {
          if ($min==$max) {
            push @occ,[[['('],@$subquery,[qq')=$min']],$node];
          } else {
            push @occ,[[['('],@$subquery,[qq') BETWEEN $min AND $max']],$node];
          }
        } elsif (length($min)) {
          push @occ,[[['('],@$subquery,[qq')>=$min']],$node];
        } elsif (length($max)) {
          push @occ,[[['('],@$subquery,[qq')<=$max']],$node];
        }
      }
      return (@occ ? [[ ['('],@{PMLTQ::Common::_group(\@occ,[' OR '])},[')'] ],$node] : ());
    }
  } elsif ($name eq 'ref') {
    my $target = $node->{target};
    my $cmp = $self->cmp_subquery_scope($node,$target);
    if ($cmp<0) {
      die "Node '$as_id' belongs to a sub-query and cannot be referred from the scope of node '$target'\n";
    }
    # case $cmp>0 implies we use negative approach on Oracle by forcing using EXISTS (on Postgress this drops performance drammatically)
    # FIXME: why exactly do we do it on Oracle?
    my ($rel) = SeqV($node->{relation});
    if ($target and $rel) {
      return ['('.$self->relation($as_id,$rel,$target,
                                  {%$opts,is_positive_conjunct=>(($opts->{is_positive_conjunct} || !$cmp) 
                                                                 ? 1 : undef)},
                                  $opts
                                 ).')',$node];
    } else {
      return;
    }
  } else {
    Carp::cluck("Unknown element $name ");
    return;
  }
}

sub cmp_subquery_scope {
  my ($self,$src,$target)=@_;
  $_ = ref($_) ? $_ : $self->{name2node}{$_} || croak("Didn't find node '\$$_'")
    for $src,$target;
  return PMLTQ::Common::cmp_subquery_scope($src,$target);
}

sub DESTROY {
  my $self = shift;

  # Make sure we disconnect from database when destroyed
  $self->{dbi}->disconnect() if $self->{dbi};
}

1; # End of PMLTQ::SQLEvaluator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::SQLEvaluator - SQL evaluator of PML-TQ queries which can use PostreSQL as a backend

=head1 VERSION

version 3.0.2

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
