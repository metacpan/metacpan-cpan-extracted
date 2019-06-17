package PMLTQ::Common;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Common::VERSION = '3.0.2';
# ABSTRACT: Helper functions mainly for PML manipulations

use 5.006;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Treex::PML::Schema;
use UNIVERSAL::DOES;
use List::Util qw(first min max);
use version;

#BEGIN {
#  import TredMacro qw(uniq SeqV AltV ListV)
#}

BEGIN {
  use constant do {
    %PMLTQ::Common::constants = (
      COL_UNKNOWN => 0,
      COL_STRING  => 1,
      COL_NUMERIC => 2,
     );
    \%PMLTQ::Common::constants
  };

  require Exporter;
  our @ISA = qw(Exporter);

  # Items to export into callers namespace by default. Note: do not export
  # names by default without a very good reason. Use EXPORT_OK instead.
  # Do not simply export all your public functions/methods/constants.

  # This allows declaration	use PMLTQ::Common ':all';
  # If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
  # will save memory.

  $PMLTQ::pmlrf_relations = '';
  $PMLTQ::user_defined = '';

  our %operator_precedence = (
    div => 2,
    mod => 2,
    '*' => 2,
    '+' => 1,
    '-' => 1,
    '&' => 1,
   );

  our %EXPORT_TAGS = ( 'all' => [ qw(
				      tq_serialize
				      as_text
				      occ_as_text
				      rel_as_text
				      _group
				      make_string
				      make_string_with_tags
				      query_parser
				      parse_query
				      parse_node
				      parse_conditions
				      parse_expression
				      parse_column_expression
				      cmp_subquery_scope
				      sort_children_by_node_type

				      SetRelation
				      GetRelationTypes
				      GetRelativeQueryNodeType
				      CreateRelation
				      FilterQueryNodes
				      Schema
				      CompleteMissingNodeTypes
				      compute_column_data_type
				      compute_expression_data_type
				      compute_expression_data_type_pt
				   ),
				  keys(%PMLTQ::Common::constants)
				 ],
		       'tredmacro' => [ qw(
					    first min max uniq ListV AltV SeqV
					 )],
		       'constants' => [
			 keys %PMLTQ::Common::constants,
			],
		      );

  our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} },  @{ $EXPORT_TAGS{'tredmacro'} } );
  our @EXPORT = qw(  );
}				# BEGIN



sub uniq  { my %a; grep { !($a{$_}++) } @_ }
sub AltV  { UNIVERSAL::DOES::does($_[0], 'Treex::PML::Alt') ? @{$_[0]} : $_[0] }
sub ListV { UNIVERSAL::DOES::does($_[0], 'Treex::PML::List') ? @{$_[0]} : () }
sub SeqV  { UNIVERSAL::DOES::does($_[0], 'Treex::PML::Seq') ? $_[0]->elements : () }



sub user_defined_relations_re {
  my ($type_mapper) = @_;
  my $relations = $PMLTQ::user_defined;
  if ($type_mapper) {
    $relations = _user_defined_relations_regexp($type_mapper->get_user_defined_relations());
  }
  return $relations;
}

sub pmlrf_relations_re {
  my ($type_mapper) = @_;
  my $relations = $PMLTQ::pmlrf_relations;
  if ($type_mapper) {
    $relations = _pmlrf_relations_regexp($type_mapper->get_pmlrf_relations());
  }
  return $relations;
}

my %reversed_relations = (
  'descendant' => 'ancestor',
  'ancestor' => 'descendant',
  'parent' => 'child',
  'sibling' => 'sibling',
  'child' => 'parent',
  'same-tree-as' => 'same-tree-as',
  'same-document-as' => 'same-document-as',
  'order-precedes' => 'order-follows',
  'order-follows' => 'order-precedes',
  'depth-first-precedes' => 'depth-first-follows',
  'depth-first-follows' => 'depth-first-precedes',
 );
my %type = (
  ':descendant' => '#descendant',
  ':ancestor' => '#ancestor',
  ':child' => '#child',
  ':parent' => '#parent',
  ':sibling' => '#sibling',
  ':depth-first-precedes' => '#same_doc',
  ':depth-first-follows' => '#same_doc',
  ':order-precedes' => '#same_doc',
  ':order-follows' => '#same_doc',
  ':same-tree-as' => '#same_doc',
  ':same-document-as' => '#same_doc',
  ':member' => '#member',
);

sub reversed_relation {
  my ($schema_name,$node_type,$name)=@_;
  if ($name=~s{^implementation:}{}) {
    return PMLTQ::Relation->reversed_relation($schema_name,$node_type,$name);
  }
  return $reversed_relations{$name};
}

sub standard_relations {
  return ['descendant' , 'ancestor' , 'child' , 'sibling', 'parent' ,
	  'depth-first-precedes' , 'depth-first-follows' ,
	  'order-precedes' , 'order-follows' , 'same-tree-as' ,
	  'same-document-as' , 'member'];
}

# Preloaded methods go here.

my $query_schema;
sub Schema {
  return ($query_schema ||= Treex::PML::Schema->new({filename => 'tree_query_schema.xml',use_resources=>1}));
}

sub DetermineNodeType {
  my ($ref)=@_;
  if (exists &Treex::PML::Document::determine_node_type) {
    return Treex::PML::Document->determine_node_type($ref);
  } elsif (exists &TredMacro::DetermineNodeType) {
    return TredMacro::DetermineNodeType($ref);
  }
  return;
}


sub GetQueryNodeType {
  my ($node,$type_mapper)=@_;
  my $p;
  return unless $node;
  $node=$p while (($p=$node->parent) && $node->{'#name'} !~ /^(?:node|subquery)$/);
  if (IsMemberNode($node)) {
    return GetMemberNodeType($node,$type_mapper);
  }
  if ($type_mapper) {
    return $node->{'node-type'} || ($p && $p->parent
       ? ( wantarray
	     ? uniq map GetRelativeQueryNodeType($_,$type_mapper,SeqV($node->{relation})), GetQueryNodeType($p,$type_mapper)
	     : GetRelativeQueryNodeType(scalar(GetQueryNodeType($p,$type_mapper)),$type_mapper,SeqV($node->{relation})))
       : (wantarray
	    ? @{$type_mapper->get_node_types||[]}
	    : do {
	      my $t = $type_mapper->get_node_types;
	      @$t==1 ? $t->[0] : ()
	    })
      );
  } else {
    return $node->{'node-type'} || $node->root->{'node-type'};
  }
}


sub DeclToQueryType {
  my ($decl)=@_;
  $decl = $decl->get_content_decl if $decl->get_decl_type == PML_ELEMENT_DECL;
  return DeclPathToQueryType( $decl->get_decl_path );
}
sub DeclPathToQueryType {
  my ($path) = @_;
  return unless defined $path;
  $path =~ s/\[LIST\]/LM/;
  $path =~ s/\[ALT\]/AM/;
  $path =~ s/^!// unless $path =~ s{^!([^/]+)\.type\b}{$1};
  return $path;
}
sub QueryTypeToDecl {
  my ($type,@schemas)=@_;
  my $path = '!'.$type;
  $path =~ s/content\(\)|\[\]/#content/g;
  my $decl;
  for my $schema (@schemas) {
    $decl = $schema->find_type_by_path($path);
    last if $decl;
  }
  if (!$decl and $path=~s{(/|$)}{.type$1}) {
    for my $schema (@schemas) {
      $decl = $schema->find_type_by_path($path);
      last if $decl;
    }
  }
  if ($decl) {
    unless($type=~m{/\.$}) { # trailing /. means do not expand trailing Alts and Lists
      my $decl_is = $decl->get_decl_type;
      while ($decl_is == PML_LIST_DECL or $decl_is == PML_ALT_DECL) {
	$decl = $decl->get_knit_content_decl;
	$decl_is = $decl->get_decl_type;
      }
    }
    return $decl;
  }
  confess( "Did not find type '!$type'" );
}

sub CompleteMissingNodeTypes {
  my ($type_mapper,$subtree)=@_;
  my @nodes = grep { ($_->{'#name'}||'') =~ /^(?:node|subquery)$/ } $subtree,$subtree->descendants;
  # try to complete missing node-types
  my $node_types = $type_mapper->get_node_types;
  my %node_types = map { $_=> 1 } @$node_types;
  my $query_tree = $subtree->root;
  undef $query_tree if $query_tree->{'#name'};
  my $default_type = $query_tree && $query_tree->{'node-type'};
  if ($default_type and !$node_types{$default_type}) {
    die "The query specifies an invalid type '$default_type' as default node type!";
  }
  for my $node (@nodes) {
    if ($node->{'node-type'}) {
      if ( !$node_types{$node->{'node-type'}} and !IsMemberNode($node)) {
	my ($rel) = SeqV($node->{relation});
	$rel = $rel ? $rel->name : '';
	die "The query specifies an invalid type '$node->{'node-type'}' for node: ".PMLTQ::Common::as_text($node)." in relation $rel\n";
      }
    } else {
      my $parent = $node->parent;
      my @types =
	$parent ?
	  (GetRelativeQueryNodeType(
	    $parent->{'node-type'},
	    $type_mapper,
	    SeqV($node->{relation}))
	   ) : @$node_types;
      if (@types == 1) {
	$node->{'node-type'} = $types[0];
      } elsif ($default_type) {
	$node->{'node-type'} = $default_type;
      } else {
	die "Could not determine node type of node "
	  .PMLTQ::Common::as_text($node)."\n"
	    ."Possible types are: ".join(',',@types)." !\n";
      }
    }
  }
}
sub GetRelativeQueryNodeType {
  my ($type,$type_mapper,$rel)=@_;
  $type ||= '';
  # TODO: if $type is void, we could check if there is just one node-type in the schema and return it if so
  my $name = $rel ? $rel->name : 'child';
  #  $name .= ':'.$rel->value->{label} if $name eq 'user-defined';
  my $reltype = ($name eq 'user-defined' ?
		 $type_mapper->get_relation_target_type($type,$rel->value->{label},$rel->value->{category})
		 : ($type{$type.':'.$name} || $type{':'.$name})) || return;
  my @decls;
  my ($schema,$schema_name);
  my @t;

  if ($type=~m{^([^/]+):\*$}) {
    $schema_name=$1;
    $schema = $type_mapper->get_schema($schema_name);
    @decls = $schema->node_types()
  } else {
    $schema = $type_mapper->get_schema_for_type($type);
    $schema_name = $schema->get_root_name;
    @decls = ($type_mapper->get_decl_for($type));
  }
  unless (@decls) {
    die "Cannot translate type $type to a schema type declaration (for schema $schema_name)!\n";
  }
  unless (first { $_->get_role eq '#NODE' } @decls) {
    return unless $reltype eq '#member' or $name eq 'user-defined';
  }
  if ($reltype eq '#same') {
    @t=@decls;
  } elsif ($reltype eq '#member') {
    @t=map { GetMemberPaths($_,$type_mapper) } @decls;
  } elsif ($reltype =~ /^(#ancestor|#same_doc)/) {
    return unless $schema;
    @t = @{$type_mapper->get_node_types($schema_name)};
  } elsif ($reltype eq '#any') {
    @t = @{$type_mapper->get_node_types};
  } elsif ($reltype eq '#descendant') {
    return unless $schema;
    @t = uniq map $_->get_childnodes_decls, @decls;
    my %seen; @seen{@t}=();
    my $i=0;
    while ($i<@t) {
      for my $t ($t[$i]->get_childnodes_decls) {
	if (!exists($seen{$t})) {
	  push @t, $t;
	  $seen{$t}=undef;
	}
      }
      $i++;
    }
  } elsif ($reltype eq '#child') {
    return unless $schema;
    @t = map $_->get_childnodes_decls, @decls;
  } elsif ($reltype eq '#parent') {
    return unless $schema;
    my %decls; @decls{@decls}=();
    @t = grep {
      first {
	exists($decls{$_})
      }
      map {
	($_->get_decl_type == PML_ELEMENT_DECL) ? ($_,$_->get_content_decl) : $_
      } $_->get_childnodes_decls
    } $schema->node_types;
  } elsif ($reltype eq '#sibling') {
    return unless $schema;
    my %decls; @decls{@decls}=();
    @t = map {
      my @c = map { ($_->get_decl_type == PML_ELEMENT_DECL) ? $_->get_content_decl : $_ }
	$_->get_childnodes_decls;
      (first { exists($decls{$_}) } @c) ? @c : ()
    } $schema->node_types;
  } else {
    return $reltype;
  }
  @t = uniq map {ref($_) ? DeclToQueryType( $_ ) : $_} @t;
  return if !wantarray and @t!=1;
  return wantarray ? @t : $t[0];
}

sub CreateRelation {
  my ($type,$opts)=@_;
  if ($type=~s/ \((user-defined|implementation|pmlrf)\)$// and !($opts and $opts->{label})) {
    $opts||={};
    $opts->{label}=$type;
    $type = 'user-defined';
    $opts->{category}=$1 unless $1 eq 'user-defined';
  }
  return Treex::PML::Seq::Element->new(
    $type => Treex::PML::Factory->createContainer(undef,$opts)
  );
}

sub SetRelation {
  my ($node,$type,$opts)=@_;
  my $rel = CreateRelation( $type, $opts );
  $node->{relation}||=Treex::PML::Factory->createSeq();
  @{$node->{relation}->elements_list}=( $rel );
  return $rel;
}

sub GetRelationTypes {
  my ($node,$type_mapper,$direct)=@_;
  my $node_type = GetQueryNodeType($node,$type_mapper);
  return [
    map {
      my $name = $_->get_name;
      if ($name eq 'user-defined') {
	($type_mapper
	   ? (
	     (map { qq{$_ (implementation)} } @{$type_mapper->get_user_defined_relations($node_type)}),
	     (map { qq{$_ (pmlrf)} } @{$type_mapper->get_pmlrf_relations($node_type)}),
	    ) : ())
      } else {
	$name;
      }
    } $node->type->schema->get_type_by_name(
      $direct ? 'q-relation.type' : 'q-ref-relation.type'
     )->get_content_decl->get_elements(),
  ];
}

# select only those paths that make sense
# to be used on a member edge
sub _map_path_to_ambiguous_subpaths {
  my ($path)=@_;
  my @steps = split '/',$path;
  my $base='';
  my $base_trail='';
  my @paths;
  while (@steps) {
    my $step = shift @steps;
    if ($step =~/^[LA]M$/) {
      my $base_with_trail = join('/',grep length, ($base, $base_trail));
      if (@paths) {
	push @paths, $base_with_trail.'/.';
      } elsif (@steps) {
	push @paths, $base unless $base_trail;
      }
      $base_trail=$base_trail ? $base_trail.'/'.$step : $step;
    } elsif ($step=~s/\[\d+\]//) {
      $base_trail='';
      $base=$base ? $base.'/'.$step : $step;
      push @paths, $base if @steps;
    } else {
      $base_trail='';
      $base=$base ? $base.'/'.$step : $step;
    }
  }
  return @paths;
}

sub GetMemberPaths {
  my ($ptype,$type_mapper)=@_;
  return unless $type_mapper;
  my $decl;
  if (ref($ptype)) {
    $decl = $ptype;
  } elsif ($ptype=~m{^(?:([^/]+):)?\*$}) {
    return uniq map GetMemberPaths($_,$type_mapper), @{$type_mapper->get_node_types($1)};
  } else {
    $decl = $type_mapper->get_decl_for($ptype);
  }
  warn "Didn't find type $ptype" unless $decl;
  my @node_members =
    grep { defined && length }
      $decl->get_schema->find_decl(sub { $_[0]->get_role eq '#NODE' },$decl,{
	no_childnodes => 1,
	with_Seq_brackets => 1,
      });
  my $node_member_re = _list_to_regexp(\@node_members);

  return unless $decl;
  return
    uniq
      map { my $t = $_; $t=~s{#content}{[]}g; $t }
	(@node_members,
	map _map_path_to_ambiguous_subpaths($_),
	grep { $node_member_re ? !m{^$node_member_re(?:\[|/|$)} : 1 }
	$decl->get_paths_to_atoms({
	  no_childnodes => 1,
	  with_LM=>1,
	  with_AM=>1,
	  with_Seq_brackets => 1,
	}));
}

sub FilterQueryNodes {
  my ($tree)=@_;
  my @nodes;
  my $n = $tree;
  while ($n) {
    my $name = $n->{'#name'}||'';
    if ($name eq 'node' or
	  ($n==$tree and $name eq 'subquery')) {
      push @nodes, $n;
    } elsif ($n->parent) {
      $n = $n->following_right_or_up($tree);
      next;
    }
    $n = $n->following($tree);
  }
  return @nodes;
}

sub IsMemberNode {
  my ($node)=@_;
  return unless ref $node;
  my ($rel) = SeqV($node->{relation});
  return $rel && $rel->name eq 'member';
}

sub GetMemberNodeType {
  my ($node,$type_mapper)=@_;
  my $type = $node->{'node-type'};
  my $p = $node->parent;
  my $mtype;
  while ($p) {
    if ($p->{'#name'} =~ /^(node|subquery)$/) {
      $mtype = GetQueryNodeType($p,$type_mapper).'/'.$type;
      last;
    }
    $p = $p->parent;
  }
  if (!defined $mtype) {
    $mtype = '/'.$type;
  }
  ### THIS BREAKS get_scheama_for($type) on SQL search
  ### which requires the type name to start with
  ### a node path:
  #
  # Need to reengeneer type mapping!
  #
  # if ($type_mapper) {
  #   my $decl = $type_mapper->get_decl_for($mtype);
  #   $mtype = DeclToQueryType($decl) if $decl;
  # }
  return $mtype;
}

sub GetElementNamesForDecl {
  my ($decl)=@_;
  my %names;
  $decl->get_schema->for_each_decl(
    sub {
      my ($d)=@_;
      if ($d->get_decl_type == PML_ELEMENT_DECL
	    and $d->get_content_decl == $decl) {
	$names{ $d->get_name } = 1;
      }
    }
   );
  return [sort keys %names];
}

### Query serialization

sub cmp_subquery_scope {
  my ($node,$ref_node) = @_;
  return 0 if $node==$ref_node;
  while ($node->parent and $node->{'#name'} ne 'subquery') {
    $node=$node->parent;
  }
  while ($ref_node->parent and $ref_node->{'#name'} ne 'subquery') {
    $ref_node=$ref_node->parent;
  }
  #return 0 if $node==$ref_node;
  my $subquery_level = 0;
  for ($node, $node->ancestors) {
    return $subquery_level if ($_==$ref_node);
    $subquery_level++ if $_->{'#name'} eq 'subquery';
  }
  # return 1 if first { $_==$ref_node } $node->ancestors;
  return -1;
}

sub occ_as_text {
  my ($node)=@_;
  return '' unless ($node->{'#name'}||'') eq 'subquery';
  return join('|', grep { /\d/ } map {
    my ($min,$max)=($_->{min},$_->{max});
    $min='' if !defined $min;
    $max='' if !defined $max;
    if (length($min) and length($max)) {
      if (int($min)==int($max)) {
	int($min)
      } else {
	int($min).'..'.int($max)
      }
    } elsif (length($min)) {
      int($min).'+'
    } elsif (length($max)) {
      if (int($max)==0) {
	'0'
      } else {
	int($max).'-'
      }
    } else {
      '1+'
    }
  } AltV($node->{occurrences}));
}


my %child_order = (
  test=>1,
  not=>2,
  or=>3,
  and=>4,
  ref=>5,
  subquery=>6,
  node=>7,
);

sub sort_children_by_node_type {
  my ($node)=@_;
  return map { $_->[0] }
         sort { $a->[1]<=>$b->[1] }
         map { [$_,int($child_order{$_->{'#name'}})] } $node->children;
}

sub rel_length_as_text {
  my ($rv)=@_;
  if ( (defined($rv->{min_length}) && length($rv->{min_length}))||
       (defined($rv->{max_length}) && length($rv->{max_length}))) {
    return '{'.($rv->{min_length}||'').','.($rv->{max_length}||'').'}'
  }
  return '';
}

sub rel_as_text {
  my ($node)=@_;
  my ($rel) = SeqV($node->{relation});
  if ($rel) {
    my ($rn,$rv)=($rel->name,$rel->value);
    if ($rn eq 'user-defined') {
      my $label = $rv->{label}.rel_length_as_text($rv);
      if ($rv->{label} =~ /^(?:member|ancestor|descendant|sibling|child|parent|same-tree-as|same-document-as|depth-first-precedes|depth-first-follows|order-precedes|order-follows)$/) {
	$label.='->';
      }
      # FIXME: if a PMLRF relation collides with a user-defined relation
      # append -> as well; this requires a type_mapper!
      return $label;
    } elsif ($rn =~ /^(?:ancestor|descendant|sibling|order-precedes|order-follows|depth-first-precedes|depth-first-follows)/) {
      return $rn.rel_length_as_text($rv);
    } elsif ($rn eq 'child') {
      return ''; # child
    } else {
      return $rn;
    }
  } else {
    return ''; # child
  }
}

sub tq_serialize {
  my ($node,$opts)=@_;
  my $indent = $opts->{indent};
  my $do_wrap = $opts->{wrap};
  my $query_node = $opts->{query_node};
  my $name = $node->{'#name'};
  $indent||='';
  my @ret;
  my $wrap=($do_wrap||0) ? "\n$indent" : " ";
  $name = '' if !defined $name;
  if (!(length $name) and !$node->parent) {
    my $desc = (!$opts->{no_description} && $node->{description})||'';
    $desc=~s{\n}{\n# }g;
    my $fwrap = $do_wrap ? "\n     "  :  " ";
    return [
      [(length($desc) ? '# '.$desc."\n" : ''),$node,-foreground=>'brown'],
      ($opts->{no_childnodes} ? () : (map { (@{tq_serialize($_,$opts)},($opts->{where} ? [" "] : [";\n"])) } $node->children)),
      map {
	[join('',
	      '  >>',
	      (ref($_->{where}) ?
		 (' filter '.make_string(tq_serialize($_->{where},{%$opts,where=>1,no_childnodes=>0})))
		 : (
		   (ListV($_->{'group-by'}) ? (' for ',join(',',ListV($_->{'group-by'})),
					       "${fwrap}give ")  : (' give ')),
		   ($_->{distinct} ? ('distinct ')  : ()),
		   join(',',ListV($_->{return})),
		   (ListV($_->{'sort-by'}) ? ("${fwrap}sort by ",join(',',ListV($_->{'sort-by'})))  : ())
		  )),
	      "\n"
	     ), $node, -foreground=>'brown' ]
      } $opts->{no_filters} ? () : ListV($node->{'output-filters'})
     ]
  } else {
    my $copts = {%$opts,no_childnodes=>0,no_refs=>0,indent=>$indent."     "};
    my @children = $opts->{no_childnodes} ? (grep { $_->{'#name'} ne 'node' } $node->children) : $node->children;
    if ($name eq 'subquery' or $name eq 'node') {
      my %order = (
	test => 1,
	not => 2,
	or => 3,
	ref => 4,
	subquery => 5,
       );
      $copts->{query_node}=$node;
      @children = sort { ($order{$a->{'#name'}}||100)<=>($order{$b->{'#name'}}||100) } @children;
    }

    my @r = map [tq_serialize($_,$copts)], @children;
    if ($name eq 'test') {
      my $op = $node->{operator};
      # if ($node->parent and ($node->parent->{'#name'}||'') eq 'not' and !$node->rbrother and !$node->lbrother and $op =~ /^[~=]/) {
      # 	$op='!'.$op;
      # }
      my $test=  $node->{a}.' '.$op.' '.$node->{b};
      @ret = ( [$test,$node,$query_node] );
    } elsif ($name=~/^(?:not|or|and)$/) {
      if ($name eq 'not') {
      	#my $f = $node->firstson;
      	#unless ($f and ($f->{'#name'}||'') eq 'test' and !$f->rbrother and $f->{operator} =~ /^[~=]/) {
	push @ret,['!',$node,$query_node,'-foreground=>darkcyan'];
      	#}
      	$name='and';
      }
      if (@r) {
	push @ret,( @r==1 ? $r[0] : (['(',$node,$query_node,'-foreground=>darkcyan'],
				     @{_group(\@r,["${wrap}$name ",$node,$query_node,'-foreground=>darkcyan'])},
				     [')',$node,$query_node,'-foreground=>darkcyan']) );
      }
    } elsif ($name eq 'ref') {
      my $rel=rel_as_text($node) || 'child';
      my $arrow = $rel;
      $arrow=~s/{.*//;
      my $color=ref($opts->{arrow_colors}) ? $opts->{arrow_colors}{$arrow} : ();
      push @ret,
	[$rel.' ',$node,$query_node,($color ? ('-foreground=>'.$color) : ())];
      my $ref = $node->{target} || '???';
      push @ret,["\$$ref",$node,$query_node,'-foreground=>darkblue'];
    } elsif ($name eq 'subquery' or $name eq 'node') {
      if ($name eq 'subquery') {
	push @ret, [occ_as_text($node).'x ',$node,'-foreground=>darkgreen'];
      } else {
	if ($node->{optional}) {
	  push @ret, ['?',$node,'-foreground=>darkgreen'];
	}
	if ($node->{overlapping}) {
	  push @ret, ['+',$node,'-foreground=>darkgreen'];
	}
      }

      my $rel='';
      if ($node->parent and $node->parent->parent) {
	$rel=rel_as_text($node);
	my $arrow = $rel;
	$arrow=~s/{.*//;
	my $color=ref($opts->{arrow_colors}) ? $opts->{arrow_colors}{$arrow} : ();
	push @ret,[$rel.' ',$node,($color ? ('-foreground=>'.$color) : ())];
      }
      my $type=$node->{'node-type'}; #
      $type = GetQueryNodeType($node) if !$type and $opts->{resolve_types};

      push @ret,[$type.' ',$node] if $type; #FIXME:
      if ($node->{name}) {
	push @ret,['$'.$node->{name},$node,'-foreground=>darkblue'],[' := ',$node];
      }
      if ($do_wrap) {
	if (@r) {
	  push @ret, (["[ ",$node],["${wrap}  "],
		      @{_group(\@r,[",${wrap}  "])},
		      ["${wrap}"],[" ]",$node]);
	} else {
	  push @ret, (["[  ]",$node]);
	}
      } else {
	unshift @ret,["\n${indent}"] if $node->lbrother;
	if (@r) {
	  push @ret,["\n${indent}"],["[ ",$node],
	    @{_group(\@r,[", ",$node])},
	      [" ]",$node];
	} else {
	  push @ret, (["[  ]",$node]);
	}
      }
    } else {
      @ret = (['## unknown: '.$name."\n",$node]);
    }
  }
  return \@ret;
}

sub as_text {
  my ($node,$opts)=@_;
  make_string(tq_serialize($node,$opts));
}

sub _group {
  my ($array,$and_or) = @_;
  return [ map {
    ($_==0) ? ($array->[$_]) : ($and_or,$array->[$_])
  } 0..$#$array ];
}

sub make_string {
  my ($array) = @_;
  Carp::cluck "not an array" unless ref($array) eq 'ARRAY';
  return join '', map {
    ref($_->[0]) ? make_string($_->[0]) : $_->[0]
  } @$array;
}

sub make_string_with_tags {
  my ($array,$tags) = @_;
  return [map {
    ref($_->[0]) ? @{make_string_with_tags($_->[0],[uniq(@$tags,@{$_}[1..$#$_])])} : [$_->[0], uniq(@$tags,@{$_}[1..$#$_])]
  } @$array];
}

sub _list_to_regexp {
  my ($values)=@_;
  return unless defined($values) and @$values;
  return '\b(?:'.join('|',map quotemeta, sort { $b cmp $a } @$values).')\b';
}
sub _pmlrf_relations_regexp {
  my ($names)=@_;
  return _list_to_regexp($names) || $PMLTQ::pmlrf_relations;
}
sub _user_defined_relations_regexp {
  my ($names)=@_;
  return _list_to_regexp($names) || $PMLTQ::user_defined;
}

### Query parsing

sub merge_and_nodes {
  my ($n1,$n2)=@_;
  if ($n1->{'#name'} eq 'and') {
    for my $c ( ($n2->{'#name'} eq 'and') ? $n2->children : $n2) {
      $c->cut()->paste_on($n1);
    }
    return $n1;
  } elsif ($n2->{'#name'} eq 'and') {
    return merge_and_nodes($n2,$n1);
  } else {
    return _new_node({'#name'=>'and'},[$n1,$n2]);
  }
}

#
# merge_filters translates 'filter' output filters
# to a where clause of the following filter
#
sub merge_filters {
  my ($filters)=@_;
  my @out;
  my $last_where;
  return unless $filters;
  while (@$filters) {
    my $f = shift @$filters;
    if ($f->{'return'}) {
      push @out, $f;
      $f->{where} = $last_where;
      $last_where=undef;
    } elsif ($f->{'where'}) {
      if ($last_where) {
	$last_where = merge_and_nodes($last_where,$f->{where});
      } else {
	$last_where = $f->{where};
      }
    } else {
      die "unexpected filter type: @$f\n";
    }
  }
  if ($last_where) {
    # copy columns from the last filter
    push @out, Treex::PML::Factory->createStructure({
      'return' => Treex::PML::Factory->createList([map { '$'.$_ } 1..@{$out[-1]{return}}],1),
      'where' => $last_where,
     });
  }
  return @out;
}

#
# merge_filters translates 'filter' output filters
# to a having clause of the preceding filter
#
sub merge_filters_2 {
  my ($filters)=@_;
  my @out;
  my $last_filter;
  return unless $filters;
  while (@$filters) {
    my $f = shift @$filters;
    if ($f->{'return'}) {
      push @out, $f;
      $last_filter = $f;
    } elsif ($f->{'where'}) {
      if ($last_filter) {
	if ($last_filter->{having}) {
	  merge_and_nodes($last_filter->{having},$f->{where});
	} else {
	  $last_filter->{having} = $f->{where};
	}
      } else {
	die "Output-filter 'filter' must be preceded by at least one filter with a 'give' clause\n";
      }
    } else {
      die "unexpected filter type: @$f\n";
    }
  }
  return @out;
}


sub _new_node {
  my ($hash,$children)=@_;
  my $new = Treex::PML::Factory->createNode($hash,1);
  if ($children) {
    if (ref($children) eq 'ARRAY') {
      for (reverse @$children) {
	if (UNIVERSAL::DOES::does($_, 'Treex::PML::Node')) {
	  $_->paste_on($new)
	} else {
	  warn "new_node: child of $hash->{'#name'} is not a node:\n".
	    Data::Dumper::Dumper([$_]);
	}
      }
    } else {
      warn "new_node: 2nd argument of constructor to $hash->{'#name'} is not an ARRAYref:\n".
	Data::Dumper::Dumper([$children]);
    }
  }
  return $new;
}

my $parser;
sub query_parser {
    return $parser if defined $parser;
    eval {
        require PMLTQ::_Parser;
        $parser = PMLTQ::_Parser->new();
        1;
    } and return $parser;

    die "Cannot create query parser";
}

sub parse_query {
  my ($query,$opts)=@_;
# $query =~ s{\Q[]\E(?=/)|(?<=/)\Q[]\E}{content()}g;
  local $PMLTQ::pmlrf_relations = _pmlrf_relations_regexp($opts->{pmlrf_relations});
  local $PMLTQ::user_defined = _user_defined_relations_regexp($opts->{user_defined_relations});
  my $ret = eval {query_parser()->parse_query($query)};
  confess($@) if $@;
  $ret->set_type(Schema()->find_type_by_path('!q-query.type'));
  return $ret;
}
sub parse_filters {
  my ($filters,$opts)=@_;
  my $ret = eval {query_parser()->parse_filters($filters)};
  confess($@) if $@;
  return $ret;
}
sub parse_expression {
  my ($query,$opts)=@_;
  my $ret = eval { query_parser()->parse_expression($query) };
  confess($@) if $@;
  return $ret;
}
sub parse_flat_expression {
  my ($query,$opts)=@_;
  my $ret = eval { query_parser()->parse_flat_expression($query) };
  confess($@) if $@;
  return $ret;
}
sub parse_column_expression {
  my ($query,$opts)=@_;
  my $ret = eval { query_parser()->parse_column_expression($query) };
  confess($@) if $@;
  return $ret;
}

sub parse_node {
  my ($query,$opts)=@_;
  local $PMLTQ::pmlrf_relations = _pmlrf_relations_regexp($opts->{pmlrf_relations});
  local $PMLTQ::user_defined = _user_defined_relations_regexp($opts->{user_defined_relations});
  my $ret = eval { query_parser()->parse_node($query) };
  confess($@) if $@;
  return $ret;
}

sub parse_conditions {
  my ($query,$opts)=@_;
  local $PMLTQ::pmlrf_relations = _pmlrf_relations_regexp($opts->{pmlrf_relations});
  local $PMLTQ::user_defined = _user_defined_relations_regexp($opts->{user_defined_relations});
  my $ret = eval { query_parser()->parse_conditions($query) };
  confess($@) if $@;
  return $ret;
}

# returns:
#  COL_NUMERIC for numeric type
#  COL_STRING for string type
#  COL_UNKNOWN for any other type

# $self must support the following methods:
#
#  $type_mapper_object = $self->type_mapper()
#  $type_name = $self->get_type_of_node($name)
#

sub compute_column_data_type {
  my ($self,$column,$opts)=@_;
  $opts||={};
  my $pt;
  if (ref($column)) {
    $pt = $column;
  } else {
    # column is a PT:
    $pt = PMLTQ::Common::parse_column_expression($column); # $pt stands for parse tree
    die "Invalid column expression '$column'" unless defined $pt;
  }
  compute_expression_data_type_pt($self,$pt,$opts);
}

sub compute_expression_data_type {
  my ($self,$exp,$opts)=@_;
  $opts||={};
  my $pt;
  if (ref($exp)) {
    $pt = $exp;
  } else {
    # column is a PT:
    $pt = PMLTQ::Common::parse_expression($exp); # $pt stands for parse tree
    die "Invalid expression '$exp'" unless defined $pt;
  }
  compute_expression_data_type_pt($self,$pt,$opts);
}

sub compute_expression_data_type_pt {
	## BUG in numeric comparison (it create expression with string equation when reference like $[0-9]+ is used)
  my ($self,$pt,$opts)=@_;
  if (ref $pt) {
    my ($type) = @$pt;
    if (!defined $type) {
      Carp::cluck("Computing type of an undefined kind: ".join(",",@$pt)."\n");
    } elsif ($type eq 'EVERY') {
      return compute_expression_data_type_pt($self,$pt->[1],$opts);
    } elsif ($type eq 'ATTR' or $type eq 'REF_ATTR') {
      my $node_type_decl;
      my $target;
      if ($type eq 'REF_ATTR') {
	$target = $pt->[1];
	$pt=$pt->[2];
      } else {
	$target=$opts->{id};
      }
      my $cast;
      my $node_type = $self->get_type_of_node($target);
      if($pt->[1] =~ /^(.+)\?$/) {
	$cast = $1; # shift @$pt;
      } elsif ($node_type=~m{^(?:([^/]+):)?\*$}) {
	my $node_types = $self->type_mapper->get_node_types($1);
	my @possibilities;
	my $path = join '/',map { $_ eq '[]' ? '#content' : $_ } @$pt[1..$#$pt];
	for my $nt (@$node_types) {
	  my $decl = $self->type_mapper->get_decl_for($nt);
	  my $attr_decl = $decl && $decl->find($path);
	  $attr_decl=$attr_decl->get_content_decl
	    while ($attr_decl and ($attr_decl->get_decl_type == PML_LIST_DECL or
				   $attr_decl->get_decl_type == PML_ALT_DECL));
	  push @possibilities,
	    $type eq 'REF_ATTR' ? ['REF_ATTR',$target,['ATTR',$nt.'?',@$pt[1..$#$pt]]] : ['ATTR',$nt.'?',@$pt[1..$#$pt]]
	      if ($attr_decl and $attr_decl->is_atomic);
	}
	if (!@possibilities) {
	  die "The attribute path '$path' is not valid for any node type matched by the '$node_type' wildcard: @$node_types\n";
	} elsif (@possibilities == 1) {
	  return compute_expression_data_type_pt($self,$possibilities[0],$opts);
	} else {
	  return compute_expression_data_type_pt($self,['FUNC','first_defined',\@possibilities],$opts);
	}
      }
      $node_type_decl = $self->type_mapper->get_decl_for($cast || $node_type);
      my $attr=join('/',@{$pt}[($cast ? 2 : 1)..$#$pt]);
      $attr=~s{\[\]}{#content}g;
      $attr=~s{/\[[^\]]*\]}{}g;
      my $decl = $node_type_decl->find($attr);
      my $decl_is = $decl && $decl->get_decl_type;
      while ($decl and
	       ($decl_is == PML_LIST_DECL or
		  $decl_is == PML_ALT_DECL or
		    $decl_is == PML_MEMBER_DECL or
		      $decl_is == PML_ELEMENT_DECL)) {
	$decl  = $decl->get_content_decl;
	$decl_is = $decl->get_decl_type;
      }
      if ($decl and $decl->is_atomic) {
	if ($decl_is == PML_CHOICE_DECL or
	      $decl_is == PML_CONSTANT_DECL) {
	  my @values = $decl->get_values;
	  if (@values and !grep { !/^(?:0|-?[1-9][0-9]*(?:\.[0-9]*[1-9])?)$/ } @values) {
	    return COL_NUMERIC;
	  } else {
	    return COL_STRING;
	  }
	} else {
	  my $format = $decl->get_format;
	  if ($format =~ /(integer$|int$|short$|byte|long|decimal$|float$|double$)/i) {
	    return COL_NUMERIC;
	  } else {
	    return COL_STRING;
	  }
	}
      } else {
	return COL_UNKNOWN;
      }
    } elsif ($type eq 'ANALYTIC_FUNC') {
      if ($pt->[1] eq 'concat') {
	return COL_STRING;
      } else {
	return COL_NUMERIC;
      }
    } elsif ($type eq 'FUNC') {
      my $name = $pt->[1];
      if ($name=~/^(?:descendants|lbrothers|rbrothers|sons|depth_first_order|order_span_min|order_span_max|depth|length|abs|floor|ceil|round|trunc|tree_no)$/) {
	return COL_NUMERIC;
      } elsif ($name eq 'first_defined') {
	return min(map compute_expression_data_type_pt($self,$_,$opts), @{$pt->[2]});
      } else {
	return COL_STRING;
      }
    } elsif ($type eq 'IF') {
      return min(map compute_expression_data_type_pt($self,$_,$opts), ($pt->[2],$pt->[3]));
    } elsif ($type eq 'EXP') {
      my @exp = @$pt;
      shift @exp;		# shift EXP
      return compute_expression_data_type_pt($self,$exp[0],$opts) if @exp==1;
      my $lowest_precedence;
      my $last_lowest_precedence_op;
      while (@exp) {
	shift @exp;		# shift an operand
	if (@exp) {
	  my $op = shift @exp;
	  my $precedence =$PMLTQ::Common::operator_precedence{$op};
	  if (!defined($lowest_precedence) or $precedence<=$lowest_precedence) {
	    $last_lowest_precedence_op = $op;
	    $lowest_precedence = $precedence;
	  }
	}
      }
      if ($last_lowest_precedence_op eq '&') {
	return COL_STRING;
      } else {
	return COL_NUMERIC;
      }
    }
  } else {
    if ($pt=~/^[-0-9]/) {	# literal number
      return COL_NUMERIC;
    } elsif ($pt=~/^['"]/) {	# literal string
      return COL_STRING;
    } elsif ($pt=~/^\$/) {
      my $var = $pt; $var=~s/^\$//;
      if ($var =~ /^[1-9][0-9]*$/) {
	return $opts->{column_types}[$var - 1];
      } elsif ($var eq '$') { # this cause BUGGY behaviour
	return UNIVERSAL::DOES::does($self,'PMLTQ::SQLEvaluator') ? COL_NUMERIC :  COL_UNKNOWN;
      } else {
	return UNIVERSAL::DOES::does($self,'PMLTQ::SQLEvaluator') ? COL_NUMERIC :  COL_UNKNOWN;
      }
    } else {
      confess( "Unrecognized sub-expression: $pt\n" );
    }
  }
}

sub NewQueryFileInstance {
  my ($filename)=@_;
  return Treex::PML::Instance->load({
    filename => $filename,
    config   => $Treex::PML::Backend::PML::config,
    string   => <<"END" });
<?xml version="1.0" encoding="utf-8"?>
<tree_query xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
 <head>
  <schema href="tree_query_schema.xml" />
 </head>
 <q-trees>
 </q-trees>
</tree_query>
END
}

sub NewQueryDocument {
  return NewQueryFileInstance(@_)->convert_to_fsfile();
}

1; # End of PMLTQ::Common

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Common - Helper functions mainly for PML manipulations

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
