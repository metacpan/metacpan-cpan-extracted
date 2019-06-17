package PMLTQ::BtredEvaluator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::BtredEvaluator::VERSION = '3.0.2';
# ABSTRACT: Pure perl evaluator of PML-TQ queries based on headless implementation of TrEd called Btred

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';
use Carp;
use Scalar::Util qw(weaken);
use Treex::PML ();
use Treex::PML::Schema;
use POSIX qw(ceil floor);
use PMLTQ::Relation;
use UNIVERSAL::DOES;

use PMLTQ::Common qw(:constants first min max uniq ListV AltV SeqV compute_column_data_type compute_expression_data_type compute_expression_data_type_pt);

our $STOP;
our $PROGRESS;
our $DEBUG = $ENV{PMLTQ_DEBUG};
our $DEBUGGER = $ENV{IN_DEBUGGER}; # set when using a debugger, this will save subroutines as files
our $ALL_SUBQUERIES_LAST=0;

PMLTQ::Relation->load();

sub round {
  my ($num, $digits)=@_;
  $digits = int $digits;
  return sprintf("%.${digits}f", $num);
}
sub trunc {
  my ($self, $num, $digits) = @_;
  $digits = int $digits;
  my $decimalscale = 10**abs($digits);
  if ($digits >= 0) {
    return int($num * $decimalscale) / $decimalscale;
  } else {
    return int($num / $decimalscale) * $decimalscale;
  }
}

my %test_relation = (
  'parent' => q($start->parent == $end),
  'child' => q($end->parent == $start),
  'same-tree-as' => q($start->root==$end->root), # not very efficient !!
  'same-document-as' => q(1),   # FIXME: not correct !!
 );

sub _compute_bounds {
  my ($direction, $min, $max) = @_;
  my ($lmin,$lmax,$rmin,$rmax);

  # return no bounds if the bounds are the default bounds:
  # none, {1,}, or {0,} (which also means {1,})
  return if !defined($max) and (!defined($min) or $min==0 or $min==1);

  $min = 1 if !defined($min);
  if ($min<0) {
    $lmin = (defined($max) and ($max<0)) ? $max : -1;
    $lmax = $min;
  }
  if (!defined($max) or $max>0) {
    $rmin = (defined($min) and ($min>0)) ? $min : 1;
    $rmax = $max;
  }
  if ($direction>0) {
    return ($lmin,$lmax,$rmin,$rmax);
  } else {
    # swap left and right and change signs
    return map {
      defined($_) ? -$_ : undef
    } ($rmin,$rmax, $lmin,$lmax);
  }
}

sub test_depth_first_order {
  my ($start,$end,$dir,$lmin,$lmax,$rmin,$rmax)=@_;

  # see DepthFirstRangeIterator for interpretation of bounds

  # we first find a nearest common ancestor and check the
  # nodes belong to the same tree

  # compute roots and level for each node
  my $with_bounds = (defined($rmin) or defined($lmin)) ? 1 : 0;

  my ($sl,$el)=(0,0);
  my ($sr,$er)=($start,$end);
  my $aux;
  while ($aux = $sr->parent) {
    $sr=$aux; $sl++;
  }
  while ($aux = $er->parent) {
    $er=$aux; $el++;
  }
  return 0 if $sr != $er;
  return 0 if $start == $end;

  # make the nodes be on the same level
  ($sr,$er)=($start,$end);
  if ($sl > $el) {
    do { $sr=$sr->parent; } while --$sl > $el;
  } elsif ($el > $sl) {
    do { $er=$er->parent; } while --$el > $sl;
  }

  my $dist = 0;

  # move the nodes up until their parent is their nearest common ancestor
  while ($sr->parent != $er->parent) {
    $sr = $sr->parent;
    $er = $er->parent;
    $dist++;
  }

  # now at least dist levels must be travelled downwards
  # before we reach one of the nodes from the other
  # still, both maximum bounds must be violated
  if ($with_bounds) { # early check
    if ((!defined($rmin) or defined($rmax) and $dist>$rmax)
          and
            (!defined($lmin) or defined($lmax) and $dist>-$lmax)) {
      return 0;
    }
  }

  # check if $start precedes $end as a sibling
  if ($dir>0) {
    while ($sr and $sr!=$er) {
      $sr = $sr->rbrother;
      $dist++;
    }
  } else {
    while ($sr and $sr!=$er) {
      $sr = $sr->lbrother;
      $dist++;
    }
  }

  if (!$with_bounds) { # we are done
    return $sr ? 1 : 0;
  } else {
    # early check
    if ((!defined($rmin) or defined($rmax) and $dist>$rmax)
          and
            (!defined($lmin) or defined($lmax) and $dist>-$lmax)) {
      return 0;
    }
    if (($dir>0) xor !$sr) {
      return 0 unless defined $rmin; # no right range, but $end is right of $start
      $dist = 0;
      $aux = $start;
      while ($aux) {
        $aux= $aux->following;
        $dist++;
        return 0 if defined($rmax) and $dist>$rmax;
        if ($aux == $end) {
          return (($dist>=$rmin) ? 1 : 0);
        }
      }
      warn("test_depth_first_precedes: This should never happen: expected end node on the following axes, but did not reach it!");
    } else {
      return 0 unless defined $lmin; # no left range, but $end is left of $start
      $dist = 0;
      $aux = $start;
      while ($aux) {
        $aux = $aux->previous;
        $dist--;
        return 0 if defined($lmax) and $dist<$lmax;
        if ($aux == $end) {
          return(($dist<=$lmin) ? 1 : 0);
        }
      }
      warn("test_depth_first_precedes: This should never happen: expected end node on the preceding axes, but did not reach it!");
    }
    return 0; # should not happen
  }
}

#
# The order span of a node N is a pair of numbers [ m(N) , M(N) ], where:
#   m(N)=M(N)=N.ord if N has an ordering attribute named 'ord';
#   otherwise
#      m(N)=min{m(C); C is a child of N}
#      M(N)=min{M(C); C is a child of N}
#
# We say that A order-precedes{x,y} B iff x <= m(B)-M(A) <= y
# and A order-precedes B if m(B)>M(A)
#
# Implementation:
# We assume that the tree does not change during the life-time of this
# query evaluator.
#
# We compute the spans as needed and cache them in the hidden
# attribute '.#order_span' of each node as [m(N),M(N),SELF], where
# SELF is a weak reference to the evaluator, indicating whether the
# precomputed span is to be assumed up-to-date. See
# _compute_order_span() for details.


sub get_cached_order_span_min {
  my ($self,$node)=@_;
  my $span = $self->_compute_order_span($node);
  return $span->[0];
}
sub get_cached_order_span_max {
  my ($self,$node)=@_;
  my $span = $self->_compute_order_span($node);
  return $span->[1];
}

# return a cached order_span, if valid for this evaluator
sub _get_order_span {
  my ($self,$node)=@_;
  return unless $node;
  my $span = $node->{'.#order_span'};
  if (defined($span) and defined($span->[2]) and $span->[2]==$self) {
    return $span;
  }
  return;
}


# Usage: $self->_compute_order_span($node)
#
# return the order span of a given node, updating cache where needed
# for unordered nodes, this means traversing at least some part of the subtree
# and computing (and caching) the spans there too
# Worst case of this algorithm is O(n) where n is the number of nodes
# in the subtree of the given node, however when run over all nodes in a tree,
# the running time is O(n) for n=the number of nodes in the tree

sub _compute_order_span {
  my ($self,$node)=@_;
  for ($self->_get_order_span($node)) {
    return($_) if defined;
  }
  my %order_attributes; # used to cache the name of an ordering attribute for a particular type

  # helper closure that computes the ordering attribute of a given
  # node using the cache:
  my $get_order = sub {
    my ($n)=@_;
    my $type = $n->type;
    $type = $type->get_content_decl if $type->get_decl_type == PML_ELEMENT_DECL;
    my $attr = $order_attributes{ $type };
    unless (defined($attr)) {
      my ($attr) = $type->find_members_by_role('#ORDER');
      $order_attributes{ $type } = ( $attr ? $attr->get_name : '' );
    }
    return $attr;
  };

  #
  # The following is a simple DFS with updating parent's span on the way up
  # we do not enter subtrees of ordered nodes, since the spans of
  # those nodes have no effect on the span of any node higher in the
  # tree
  #
  my $top = $node;
  my $span;
  NODE: while ($node) {
    my $attr = $get_order->($node);
    $span = undef;
    if (length($attr)) {
      my $ord = $node->{$attr};
      $span = [$ord,$ord,$self];
      weaken($span->[2]);
      return $span if $node==$top;
    } else {
      $span=$node->{'.#order_span'}=[undef,undef,$self];
      weaken($span->[2]);
      my $son = $node->firstson;
      if ($son) {
        $node=$son;
        next NODE;
      }
    }
    while ($node) {
      return $span if $node==$top;
      my $rb = $node->rbrother;
      if ($rb) {
        $node = $rb;
        next NODE;
      }
      my $p = $node->parent;
      my $p_span = $self->_get_order_span($p);
      if ($p_span and $span and defined($span->[0])) {
          $p_span->[0] = $span->[0] if !defined($p_span->[0]) or $span->[0]<$p_span->[0];
          $p_span->[1] = $span->[1] if !defined($p_span->[1]) or $span->[1]>$p_span->[1];
      }
      $node = $p;
      $span = $p_span;
    }
  }
  warn(__PACKAGE__."_compute_order_span: This should never happen\n");
  return $self->_get_order_span($top);
}

sub stop {
  $STOP=1;
}

sub new {
  my ($class,$query_tree,$opts)=@_;
  $opts ||= {};
  #######################
  # The following lexical variables may be used directly by the
  # condition subroutines
  my @conditions;
  my @iterators;
  my @aux_iterators;    # iterators used by transitive 'ref' relations
  my @sub_queries;
  my $parent_query=$opts->{parent_query};
  my $matched_nodes = $parent_query ? $parent_query->{matched_nodes} : [];
  my $all_iterators = $parent_query ? $parent_query->{all_iterators} : [];
  my %have;
  my $query_pos;
  #######################


  my @debug;
  my %name2pos;
  my %name2type;
  # maps node position in a (sub)query to a position of the matching node in $matched_nodes
  # we avoid using hashes for efficiency
  my $self = bless {

    query_pos => 0,
    iterators => \@iterators,
    is_overlapping => [],
    aux_iterators => \@aux_iterators,
    filter => undef,
    conditions => \@conditions,
    have => \%have,

    debug => \@debug,

    sub_queries => \@sub_queries,
    parent_query => $parent_query,
    parent_query_pos => $opts->{parent_query_pos},
    parent_query_match_pos => $opts->{parent_query_match_pos},

    matched_nodes => $matched_nodes, # nodes matched so far (incl. nodes in subqueries; used for evaluation of cross-query relations)
    all_iterators => $all_iterators, # nodes matched so far (incl. nodes in subqueries; used for evaluation of cross-query relations)

    type_mapper => $opts->{type_mapper},

    name2pos => \%name2pos,
    name2type => \%name2type,
    parent_pos => undef,
    pos2match_pos => undef,
    name2match_pos => undef,
    # query_nodes => [],
    results => [],
  }, $class;
  unless ($self->{type_mapper}) {
    if ($opts->{fsfile}) {
      $self->{type_mapper}=PMLTQ::TypeMapper->new({fsfile=>$opts->{fsfile}});
    } elsif ($opts->{current_filelist} or $opts->{current_filelist_trees}) {
      $self->{type_mapper}=PMLTQ::TypeMapper->new({filelist=>TredMacro::GetCurrentFileList()});
    } elsif ($opts->{tree} or $opts->{iterator}) {
      croak(__PACKAGE__."->new: missing required option: type_mapper");
    } else {
      $self->{type_mapper}=PMLTQ::TypeMapper->new({fsfile=>TredMacro::CurrentFile()})
    }
  }
  weaken($self->{parent_query}) if $self->{parent_query};
  $query_pos = \$self->{query_pos};

  my $clone_before_plan = 0;
  if (ref($query_tree)) {
    $clone_before_plan = 1;
  } else {
    $query_tree = PMLTQ::Common::parse_query($query_tree,{
      user_defined_relations => $self->{type_mapper}->get_user_defined_relations(),
      pmlrf_relations => $self->{type_mapper}->get_pmlrf_relations(),
    });
    PMLTQ::Common::DetermineNodeType($_) for $query_tree->descendants;
  }

  my $type = $query_tree->type->get_base_type_name;
  unless ($type eq 'q-query.type' or
            $type eq 'q-subquery.type') {
    die "Not a query tree: $type!\n";
  }
  my $roots;
  my @orig_nodes=PMLTQ::Common::FilterQueryNodes($query_tree);
  my @query_nodes;
  my %orig2query;
  if ($opts->{no_plan}) {
    $roots = ($type eq 'q-query.type') ? [ $query_tree->children ] : [$query_tree];
    @query_nodes=@orig_nodes;
    %orig2query = map { $_ => $_ } @orig_nodes;
  } elsif ($self->{parent_query}) {
    %orig2query = map { $_ => $_ } @orig_nodes;
    @query_nodes=PMLTQ::Common::FilterQueryNodes($query_tree); # reordered
    $roots = [$query_tree];
  } else {
    require PMLTQ::Planner;
    if ($clone_before_plan) {
      $query_tree=Treex::PML::FSFormat->clone_subtree($query_tree);
    }
    @query_nodes=PMLTQ::Common::FilterQueryNodes($query_tree); # same order as @orig_nodes
    %orig2query = map { $orig_nodes[$_] => $query_nodes[$_] } 0..$#orig_nodes;
    PMLTQ::Planner::name_all_query_nodes($query_tree); # need for planning
    $roots = PMLTQ::Planner::plan($self->{type_mapper},\@query_nodes,$query_tree);
    for my $subquery (grep { $_->{'#name'} eq 'subtree' } $query_tree->root->descendants) {
      my $subquery_roots = PMLTQ::Planner::plan(
        $self->{type_mapper},
        [PMLTQ::Common::FilterQueryNodes($subquery)],
        $subquery->parent,
        $subquery
       );
      if (@$subquery_roots>1) {
        die "A subquery is not connected: the sub-graph has more than one root node: ".PMLTQ::Commmon::as_text($subquery)."\n";
      }
    }
    @query_nodes=PMLTQ::Common::FilterQueryNodes($query_tree); # reordered
  }
  my $query_node;
  if (@$roots==0) {
    die "No query node!\n";
  } elsif (@$roots>1) {
    die "The query is not connected: the graph has more than one root node (@$roots)!\n";
  } else {
    ($query_node)=@$roots;
  }
  # @{$self->{query_nodes}}=@orig_nodes;
  %name2pos = map {
    my $name = $query_nodes[$_]->{name};
    (defined($name) and length($name)) ? ($name=>$_) : ()
  } 0..$#query_nodes;
  {
    my %node2pos = map { $query_nodes[$_] => $_ } 0..$#query_nodes;
    $self->{query_node2pos} = { map { $_=>$node2pos{$orig2query{$_}} } @orig_nodes };
    $self->{parent_pos} = [ map { $node2pos{ $_->parent  } } @query_nodes ];
  }

  {
    my @all_query_nodes = grep {$_->{'#name'} =~ /^(node|subquery)$/ } ($query_node->root->descendants);
    print STDERR map { "$all_query_nodes[$_]{name} => $_\n" } 0..$#all_query_nodes if $DEBUG > 4;
    {
      my %node2match_pos = map { $all_query_nodes[$_] => $_ } 0..$#all_query_nodes;
      $self->{pos2match_pos} = [
        map { $node2match_pos{ $query_nodes[$_] } } 0..$#query_nodes
       ];
    }
    # we only allow refferrences to nodes in this query or some super-query
    $self->{name2match_pos} = {
      ($self->{parent_query} ? (%{$self->{parent_query}{name2match_pos}}) : ()),
      map { $_ => $self->{pos2match_pos}[$name2pos{$_}] } keys %name2pos
     };

    if ($DEBUG > 3) {
      use Data::Dumper;
      print STDERR Dumper({
        parent_query_map =>
          ($self->{parent_query} ? $self->{parent_query}{name2match_pos} : undef),
        our_map => $self->{name2match_pos},
      });
    }

    my %node_types = map { $_=> 1 } @{$self->{type_mapper}->get_node_types};
    my %schema_names = map { $_=> 1 } @{$self->{type_mapper}->get_schema_names};
    my $default_type = $query_node->root->{'node-type'};
    if ($default_type and !$node_types{$default_type}) {
      die "The query specifies an invalid type '$default_type' as default node type!";
    }
    for my $node (@all_query_nodes) {
      if (PMLTQ::Common::IsMemberNode($node)) {
        if ($node->{'node-type'}) {
          my $type = PMLTQ::Common::GetMemberNodeType($node,$self->{type_mapper});
          if ($self->{type_mapper}->get_decl_for($type)) {
            # ok
            my $name = $node->{name};
            if (defined($name) and length($name)) {
              $name2type{$name} = $type;
            }
          } else {
            die "Invalid member path '$type' for ".PMLTQ::Common::as_text($node)."\n";
          }
        } else {
          die "Member must specify attribute name: ".PMLTQ::Common::as_text($node)."\n";
        }
        next;
      } elsif ($node->{'node-type'} eq '*') {
        if (keys(%schema_names)>1) {
          die "Node-type wildcard '*' cannot be used for data with mutliple layers: ".PMLTQ::Common::as_text($node)."\n".
            "\nHint: try one of ".join(" ",map "$_:*", sort keys(%schema_names))."\n";
        }
      } elsif ($node->{'node-type'} =~ m{^([^/]+):\*$}) {
        my $schema_name = $1;
        if (!$schema_names{$schema_name}) {
          die "The query specifies an invalid schema name '$schema_name' for node: ".PMLTQ::Common::as_text($node)."\n";
        }
      } elsif ($node->{'node-type'}) {
        if (!$node_types{$node->{'node-type'}}) {
          die "The query specifies an invalid type '$node->{'node-type'}' for node: ".PMLTQ::Common::as_text($node)."\n";
        }
      } else {
        my $parent = $node->parent;
        my @types =
          $parent ?
            (PMLTQ::Common::GetRelativeQueryNodeType(
              $parent->{'node-type'},
              $self->{type_mapper},
              PMLTQ::BtredEvaluator::SeqV($node->{relation}))
             ) : @{$self->{type_mapper}->get_node_types};
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
      my $name = $node->{name};
      if (defined($name) and length($name)) {
        $name2type{$name} = $node->{'node-type'}
      }
    }
  }

  # compile condition testing functions and create iterators
  my (@r1,@r2,@r3);
  for my $i (0..$#query_nodes) {
    my $qn = $query_nodes[$i];
    my $sub = $self->serialize_conditions($qn,{
      query_pos => $i,
      recompute_condition => \@r1,  # appended in recursion
      recompute_subquery => \@r2,   # appended in recursion
      reverted_relations => \@r3,   # appended in recursion
    });
    my $conditions = eval $sub; die $@ if $@; # use the above-mentioned lexical context
    push @debug, $sub;
    push @conditions, $conditions;
    my $iterator;
    if (!$self->{parent_query} and $qn==$query_node) {
      # top-level node iterates throguh all nodes
      my $type = $qn->{'node-type'};
      my $schema = $type && $self->{type_mapper}->get_schema_for_type($type);
      my $schema_root_name = $schema && $schema->get_root_name;
      if (ref $opts->{iterator}) {
        $iterator = $opts->{iterator};
        $iterator->set_conditions($conditions);
      } elsif ($opts->{iterator}) {
        $iterator = $opts->{iterator}->new($conditions);
      } elsif ($opts->{tree}) {
        $iterator = PMLTQ::Relation::TreeIterator->new($conditions,$opts->{tree},$opts->{fsfile});
      } elsif ($opts->{fsfile}) {
        $iterator = PMLTQ::Relation::FSFileIterator->new($conditions,$opts->{fsfile});
      } elsif ($opts->{current_filelist}) {
        if ($opts->{particular_trees}) {
          $iterator = PMLTQ::Relation::CurrentFilelistTreesIterator->new($conditions);
    ## TODO: think of better way of recognizing treex documents
  } elsif ($schema_root_name eq 'treex_document') {
    $iterator = PMLTQ::Relation::TreexFilelistIterator->new($conditions,$schema_root_name);
        } else {
          $iterator = PMLTQ::Relation::CurrentFilelistIterator->new($conditions,$schema_root_name);
        }
      } else {
        if ($opts->{particular_trees}) {
          $iterator = PMLTQ::Relation::CurrentTreeIterator->new($conditions);
        }
  elsif ($schema_root_name eq 'treex_document') {
    $iterator = PMLTQ::Relation::TreexFileIterator->new($conditions,$schema_root_name);
        } else {
          $iterator = PMLTQ::Relation::CurrentFileIterator->new($conditions,$schema_root_name);
        }
      }
    } else {
      $iterator = $self->create_iterator($qn,$conditions);
    }
    push @iterators, $iterator;
    push @{$self->{is_overlapping}}, ($qn->{overlapping} ? 1 : undef);
    $all_iterators->[$self->{pos2match_pos}[$i]]=$iterator;
  }
  unless ($self->{parent_query} or ($opts->{no_filters} and !$opts->{count})) {
    my $first = first { $_->{'#name'} eq 'node' and $_->{name} } $query_tree->children;
    my $output_opts = {
      id => $first->{name},
    };
    my ($init_code,$filters) = $self->serialize_filters(
      ($opts->{count}
           ? Treex::PML::Factory
                 ->createList([{'return'
                                => Treex::PML::Factory->createList(['count()']) }],1)
           : $query_tree->{'output-filters'}),
      $output_opts,
     );
    if ($init_code and @$filters) {
      my $first_filter = $filters->[0];
      $self->{filter} = eval $init_code; die $@ if $@;
      $self->{filters} = $filters;
    }
  }
  return $self;
}

sub type_mapper {
  my ($self)=@_;
  return $self->{type_mapper};
}

sub get_type_of_node {
  my ($self,$name)=@_;
  return $self->{name2type}{$name};
}

sub get_type_decl_for_node {
  my ($self,$name)=@_;
  my $node_type = $self->{name2type}{$name};
  return $node_type && $self->{type_mapper}->get_decl_for($node_type);
}

sub get_results {
  my $self = shift;
  return $self->{results}
}
sub get_result_files {
  my $self = shift;
  return $self->{result_files}
}
sub run_filters {
  my $self = shift;
  if ($self->{filter}) {
    $self->{filter}->($self);
    return 1;
  } else {
    return 0;
  }
}
sub flush_filters {
  my $self = shift;
  if (!$STOP and $self->{filters}) {
    return $self->{filters}[0]->{finish}($self->{filters}[0]);
  }
  return;
}
sub set_default_output_filter {
  my ($self,$output) = @_;
  $self->{default_output_filter}=$output;
}
sub get_default_output_filter {
  my ($self) = @_;
  return $self->{default_output_filter} || $self->std_out_filter;
}

sub init_filters {
  my ($self,$output) = @_;
  $STOP = 0;
  if ($self->{filters} and @{$self->{filters}}) {
    $output ||= $self->get_default_output_filter;
    $self->{filters}[-1]->{output}=$output;
    return $self->{filters}[0]->{init}->($self->{filters}[0]);
  }
  return;
}
sub get_filters {
  my ($self) = @_;
  return $self->{filters};
}

sub r {
  my ($self,$name)=@_;
  return unless $self->{results};
  my $pos =  $self->{name2pos}{$name};
  return unless defined $pos;
  return wantarray ? ($self->{results}[$pos],$self->{result_files}[$pos]) : $self->{results}[$pos];
}
*get_result_node = \&r;

#   sub get_query_nodes {
#     my $self = shift;
#     return $self->{query_nodes};
#   }

sub get_first_iterator {
  return $_[0]->{iterators}[0];
}

sub reset {
  my ($self)=@_;
  $self->{query_pos} = 0;
  %{$self->{have}}= (); #$self->{parent_query} ? %{$self->{parent_query}{have}} : ();
  $_->reset for @{$self->{iterators}};
}


sub create_iterator {
  my ($self,$qn,$conditions)=@_;
  # TODO: deal with negative relations, etc.

  my ($rel) = PMLTQ::BtredEvaluator::SeqV($qn->{relation});
  my $relation = $rel && $rel->name;
  $relation||='child';
  my ($start_node,$target,$target_type);
  if ($qn->{'#name'} eq 'ref') {
    $start_node = $qn;
    $target = $qn->{target};
    $target_type = $self->{name2type}{$target};
  } else {
    $target = $qn->{'id'};
    $target_type = $qn->{'node-type'};
    $start_node = $qn->parent;
  }
  $start_node=$start_node->parent while $start_node && $start_node->{'#name'} !~ /^(node|subquery)$/;
  my $iterator;

  # fix foo/content()/bar and foo/[]/bar
  $target_type = join '/',map { ($_ eq '[]' or $_ eq 'content()') ? '#content' : $_ } split /\//, $target_type;

  if ($relation eq 'child') {
    $iterator = PMLTQ::Relation::ChildnodeIterator->new($conditions);
  } elsif ($relation eq 'member') {
    $iterator = PMLTQ::Relation::MemberIterator->new($conditions,$target_type);
  } elsif ($relation eq 'descendant') {
    my ($min,$max)=
      map { (defined($_) and length($_)) ? $_ : undef }
        map { $rel->value->{$_} }
          qw(min_length max_length);
    if (defined($min) or defined($max)) {
      $iterator = PMLTQ::Relation::DescendantIteratorWithBoundedDepth->new($conditions,$min,$max);
    } else {
      $iterator = PMLTQ::Relation::DescendantIterator->new($conditions);
    }
  } elsif ($relation eq 'parent') {
    $iterator = PMLTQ::Relation::ParentIterator->new($conditions);
  } elsif ($relation eq 'same-tree-as') {
    $iterator = PMLTQ::Relation::SameTreeIterator->new($conditions);
  } elsif ($relation eq 'same-document-as') {
    $iterator = PMLTQ::Relation::FSFileIterator->new($conditions);
  } elsif ($relation eq 'order-precedes' or $relation eq 'order-follows') {
    my ($attr1,$attr2) =
      map {
        if (defined) {
          my $decl = $self->{type_mapper}->get_decl_for($_);
          if ($decl->get_decl_type == PML_ELEMENT_DECL) {
            $decl = $decl->get_content_decl;
          }
          my ($m)=$decl->find_members_by_role('#ORDER');
          defined($m) && $m->get_name
        } else {
          undef;
        }
      } ($start_node->{'node-type'},$target_type);
    my ($min,$max)=
      map { (defined($_) and $_) ? $_ : undef }
        map { $rel->value->{$_} }
          qw(min_length max_length);
    weaken( my $weak_self = $self );
    $iterator = PMLTQ::Relation::OrderIterator->new($conditions,$attr1,$attr2,
                                   (($relation eq 'order-follows') ? -1 : 1),
                                   $min,$max,
                                   sub { $weak_self->_compute_order_span($_[0]) }
                                  );
  } elsif ($relation eq 'depth-first-follows') {
    my ($min,$max)=
      map { (defined($_) and $_) ? $_ : undef }
      map { $rel->value->{$_} } qw(min_length max_length);
    my @bounds = _compute_bounds(-1, $min,$max );
    if (@bounds) {
      $iterator = PMLTQ::Relation::DepthFirstRangeIterator->new($conditions,@bounds);
    } else {
      $iterator = PMLTQ::Relation::DepthFirstFollowsIterator->new($conditions);
    }
  } elsif ($relation eq 'depth-first-precedes') {
    my ($min,$max)=
      map { (defined($_) and $_) ? $_ : undef }
      map { $rel->value->{$_} } qw(min_length max_length);
    my @bounds = _compute_bounds(1, $min,$max );
    if (@bounds) {
      $iterator = PMLTQ::Relation::DepthFirstRangeIterator->new($conditions,@bounds);
    } else {
      $iterator = PMLTQ::Relation::DepthFirstPrecedesIterator->new($conditions);
    }
  } elsif ($relation eq 'ancestor') {
    my ($min,$max)=
      map { (defined($_) and $_) ? $_ : undef }
        map { $rel->value->{$_} }
          qw(min_length max_length);
    if (defined($min) or defined($max)) {
      $iterator = PMLTQ::Relation::AncestorIteratorWithBoundedDepth->new($conditions,$min,$max);
    } else {
      $iterator = PMLTQ::Relation::AncestorIterator->new($conditions);
    }
  } elsif ($relation eq 'sibling') {
    my ($min,$max)=
      map { (defined($_) and $_) ? $_ : undef }
        map { $rel->value->{$_} }
          qw(min_length max_length);
    if (defined($min) or defined($max)) {
      $iterator = PMLTQ::Relation::SiblingIteratorWithDistance->new($conditions,$min,$max);
    } else {
      $iterator = PMLTQ::Relation::SiblingIterator->new($conditions);
    }
  } elsif ($relation eq 'user-defined') {
    my $label = $rel->value->{label};
    my ($min,$max)=($rel->value->{min_length},$rel->value->{max_length});
    my $transitive = ((!(defined($min) && length($min))
                         && !(defined($max) && length($max))) || (defined($max) && $max==1)) ? 0 : 1;
    if (defined($min) && defined($max) && ($min>$max)) {
      die "Invalid bounds for transitive relation '$label\{$min,$max}'\n";
    }

    my $schema = $self->{type_mapper}->get_schema_for_type($start_node->{'node-type'});
    $iterator = PMLTQ::Relation->create_iterator($schema->get_root_name, $start_node->{'node-type'}, $label, $conditions);
    unless (defined $iterator) {
      if (first { $_ eq $label }
            @{$self->{type_mapper}->get_pmlrf_relations($start_node)}) {
        $iterator = PMLTQ::Relation::PMLREFIterator->new($conditions,$label);
      } else {
        die "user-defined relation '".$label."' unknown or not implemented in BTrEd Search\n"
      }
    }

    if ($transitive) {
      if ($start_node->{'node-type'} ne $target_type) {
        die "Cannot create transitive closure for relation with different start-node and end-node types: '$start_node->{q(node-type)}' -> '$target_type'\n";
      }
      $iterator = PMLTQ::Relation::TransitiveIterator->new($iterator,$min,$max);
    }
  } else {
    die "relation ".$relation." not valid for this node or not yet implemented \n"
  }
  print STDERR "iterator: ".ref($iterator)."\n" if defined($DEBUG) and $DEBUG > 1;

  if ($qn->{optional}) {
    print STDERR "iterator: [OPTIONAL]\n" if defined($DEBUG) and $DEBUG > 1;
    return PMLTQ::Relation::OptionalIterator->new($iterator);
  } else {
    return $iterator;
  }
}

sub serialize_filters {
  my ($self,$filters,$opts)=@_;
  return unless ref $filters;
  $opts ||= {};
  # first filter is special, it can refer to nodes
  my $prev;
  my @filters;
  for my $f (PMLTQ::Common::merge_filters_2($filters)) {
    $opts->{filter_id} = "filter_".scalar(@filters);
    push @filters, $self->serialize_filter($f,$opts); # can return multiple filters
  }
  for my $filter (@filters) {
    if ($prev) {
      $prev->{output}=$filter;
    }
    $prev = $filter;
  }
  if ($DEBUG > 2) {
    my $j=0;
    for my $f (@filters) {
      my $i = -1;
      print STDERR "##### RESULT FILTER ", $j++,"\n";
      print STDERR sprintf("%3s\t%s",$i++,$_."\n") for split /\n/,$f->{code};
      my $k=0;
      for my $s (@{$f->{local_filters_code}}) {
        print STDERR "\t##### LOCAL GROUPING FILTER ", $k++," OF FILTER $j\n";
        $i = -1;
        print STDERR sprintf("\t%3s\t%s",$i++,$_."\n") for split /\n/,$s;
      }
    }
    {
      my $i = -1;
      print STDERR "\t##### INIT_CODE\n";
      print STDERR sprintf("\t%3s\t%s",$i++,$_."\n") for split /\n/,$opts->{filter_init};
    }
  }
  return ($opts->{filter_init},\@filters);
}

sub std_out_filter {
  my ($self)=@_;
  return {
    init => sub {
      # print("-" x 60, "\n");
    },
    process_row => sub {
      my ($self,$row)=@_;
      print(join("\t",@$row)."\n");
    },
    finish => sub {
      # print("-" x 60, "\n");
    }
   };
}

sub buffer_all_filter {
  my ($self)=@_;
  return {
    init => sub {
      my ($self)=@_;
      $self->{saved_rows}=[];
    },
    process_row => sub {
      my ($self,$row)=@_;
      push @{$self->{saved_rows}}, $row;
    },
    finish => sub {
      my ($self)=@_;
      return $self->{saved_rows};
    }
   };
}

my %aggregation_template = (
  count => q`
            sub {
              my ($self, $i)=@_;
               $self->{aggregated}[$i]++;
            }`,
  _DEFAULT_ => q`
            sub {
              my ($self, $i, $row)=@_;
              #<IF_LEN _FUNC_VARLIST_>
              my (_FUNC_VARLIST_) = @$row[_FUNC_COLNUMS_];
              #</IF_LEN>
              #<IF_LEN _FUNC_DEFINED_>
              if (_FUNC_DEFINED_) {
              #</IF_LEN>
                _FUNC_OP_
              #<IF_LEN _FUNC_DEFINED_>
              }
              #</IF_LEN>
            }`
 );
my %aggregation_init = (
  sum => '0',
  max => 'undef',
  min => 'undef',
  count => '0',
  avg => '[undef,0]',
  concat => '[]',

  row_number => '[]',
  rank => '[]',
  dense_rank => '[]',
 );
my %aggregation_op = (
  sum => q`$self->{aggregated}[$i] += _ARG_;`,
  max => q`my $max = $self->{aggregated}[$i];
                   my $val = _ARG_;
                   $self->{aggregated}[$i] = $val if !defined($max) or $max<$val`,
  min => q`my $min = $self->{aggregated}[$i];
                   my $val = _ARG_;
                   $self->{aggregated}[$i] = $val if !defined($min) or $val<$min`,
  avg => q`my $avg = $self->{aggregated}[$i];
                   $self->{aggregated}[$i][0] += _ARG_;
                   $self->{aggregated}[$i][1] ++;`, # shell we count null values as 0 ?
  concat => q`push @{$self->{aggregated}[$i]}, [_ARG_,_SORT_ARGS_];`,

  row_number => q`push @{$self->{aggregated}[$i]}, [$row,_SORT_ARGS_];`,
  rank => q`push @{$self->{aggregated}[$i]}, [$row,_SORT_ARGS_];`,
  dense_rank => q`push @{$self->{aggregated}[$i]}, [$row,_SORT_ARGS_];`,
 );
my %aggregation_final = (
  avg => q`_RESULT_ = (_RESULT_->[0] / _RESULT_->[1]);`,
  concat => q`_RESULT_ = do{ use locale; join(_ARG1_, map $_->[0], _SORT_CMP_ @{_RESULT_}) };`,

  row_number => q`use locale; my @sorted = _SORT_CMP_ @{_RESULT_}; _RESULT_ = { map { $sorted[$_][0] => $_+1 } 0..$#sorted };`,

  rank => q`use locale;
            my @sorted = _SORT_CMP_ @{_RESULT_};
            my ($rank,$rowno)=(1,1);
            _RESULT_ =
              @sorted ?
                {
                 ((($a=shift(@sorted))->[0] => 1),
                 map {
                   $b=$_;
                   $rank=$rowno if _CMP_;
                   $rowno++;
                   $a = $b;
                   $a->[0] => $rank
                 } @sorted)
                } : {};`,

  dense_rank => q`use locale;
            my @sorted = _SORT_CMP_ @{_RESULT_};
            my $rank=1;
            _RESULT_ =
              @sorted ?
                {
                 ((($a=shift(@sorted))->[0] => 1),
                 map {
                   $b=$_;
                   $rank++ if _CMP_;
                   $a = $b;
                   $a->[0] => $rank;
                 } @sorted)
                } : {};`,
 );

my %code_template = (
  PLAIN => q`
        {
          type => 'PLAIN',
          init => sub {
            my ($self)=@_;
            #<IF_DISTINCT>
            $self->{seen} = {};
            #</IF_DISTINCT>
            my $out = $self->{output};
            $out->{init}->($out);
          },
          process_row => sub {
            my ($self,$row)= @_;
            #<IF_LEN _RET_VARLIST_>
            my (_RET_VARLIST_) = @$row[_RET_COLNUMS_];
            #</IF_LEN>
            my $out = $self->{output};
            my @out_row = (
              _RET_COLS_
            );
            #<IF_DISTINCT>
            my $key = join "\x0",map { defined $_ ? $_ : '' } @out_row;
            unless (exists $self->{seen}{$key}) {
              $self->{seen}{$key}=undef;
              $out->{process_row}->($out,\@out_row)_IF_FILTER_;
            }
            #</IF_DISTINCT>
            #<IF_NOT_DISTINCT>
            $out->{process_row}->($out,\@out_row)_IF_FILTER_;
            #</IF_NOT_DISTINCT>
          },
          finish => sub {
            my ($self)= @_;
            my $out = $self->{output};
            $out->{finish}($out);
          }
        }`,

  # Example: >> $1, $2, 2+sum($2 over $1)*max($1 over $2)
  AGGREGATE => q`
          {
            type => 'AGGREGATE',
            init => sub {
              my ($self)= @_;
              #<IF_NOT_RETURN>
              my $out = $self->{output};
              $out->{init}->($out);
              #</IF_NOT_RETURN>
              _INIT_AGG_
            },
            process_row => sub {
              my ($self,$row)= @_;
              my $agg=0;
              $_->($self,$agg++,$row) for @{$self->{aggregation}};
            },
            aggregation => [
              _AGGREGATIONS_
             ],
            is_windowing => [
              _IS_WINDOWING_
            ],
            finish => sub {
              my ($self)=@_;
              #<IF_LEN _RET_VARLIST_>
              my (_RET_VARLIST_) = @{$self->{group_columns}}[_RET_COLNUMS_];
              #</IF_LEN>
              _AGG_FINALIZE_
              #<IF_RETURN>
              my @out_row = (
                _RET_COLS_
              );
              return($self->{result} = \@out_row) _IF_FILTER_;
              return; # in case a filter is present and fails
              #</IF_RETURN>
              #<IF_NOT_RETURN>
              my $out = $self->{output};
              my @out_row = (
                _RET_COLS_
              );
              $out->{process_row}->($out, \@out_row)_IF_FILTER_;
              $out->{finish}($out);
              #</IF_NOT_RETURN>
             }
           }`,

  GROUP => q`
        {
          type => 'GROUP',
          init => sub {
            my ($self)= @_;
            $self->{group} = {};
          },
          process_row => sub {
            my ($self,$row)= @_;
            #<IF_LEN _GROUP_VARLIST_>
            my (_GROUP_VARLIST_) = @$row[_GROUP_COLNUMS_];
            #</IF_LEN>
            my $g = [
              _GROUP_COLS_
            ];
            my $key = join "\x0",map { defined $_ ? $_ : '' } @$g;
            my $new;
            my $group = $self->{group}{$key} ||= ($new = {
              key => $key,
              group_columns => $g,
              %{$self->{grouping}}
             });
            $group->{init}->($group) if $new;
            $group->{process_row}->($group,$row);
          },
          finish => sub  {
            my ($self)=@_;
            #<IF_NOT_RETURN>
            my $out = $self->{output};
            $out->{init}->($out);
            #</IF_NOT_RETURN>
            #<IF_RETURN>
            my %return;
            #</IF_RETURN>
            for my $group (values %{$self->{group}}) {
              my $r = $group->{finish}->($group);
              #<IF_RETURN>
              my $key = $group->{key};
              $return{$key}=$r;
              #</IF_RETURN>
              %$group=();       # immediatelly cleanup group data
              #<IF_NOT_RETURN>
              $out->{process_row}($out,$r) if defined $r;
              #</IF_NOT_RETURN>
            }
            #<IF_NOT_RETURN>
            $out->{finish}($out);
            #</IF_NOT_RETURN>
            #<IF_RETURN>
            return \%return;
            #</IF_RETURN>
          },
          grouping => _TEMPLATE_AGGREGATE_,
         };
        `,
  # Example: >> $1, $2, 2+sum($2 over $1)*max($1 over $2)
  INNER_AGGREGATE =>  q`
     {
       type => 'INNNER_AGGREGATE',
       init => sub {
         my ($self)= @_;
         $_->{init}->($_) for @{$self->{local_group}};
         $self->{saved_rows} = [];

         #<IF_NOT_RETURN>
         my $out = $self->{output};
         $out->{init}->($out);
         #</IF_NOT_RETURN>
       },
       local_group => \@local_filters,
       process_row => sub {
         my ($self,$row)= @_;
         push @{$self->{saved_rows}}, $row; # note: we could only save the columns we need
         $_->{process_row}->($_, $row) for @{$self->{local_group}};
       },
       finish => sub {
         my ($self)=@_;
         my $saved_rows = $self->{saved_rows};
         my $row;
         my $out = $self->{output};
         my @l = map $_->{finish}->($_), @{$self->{local_group}};
         my @is_windowing = map $_->{grouping}{is_windowing}[0], @{$self->{local_group}};
         #<IF_DISTINCT>
         my %seen;
         #</IF_DISTINCT>
         while ($row = shift @$saved_rows) {
           #<IF_LEN _RET_VARLIST_>
           my (_RET_VARLIST_) = @$row[_RET_COLNUMS_];
           #</IF_LEN>
           my @keys = (_LOCAL_GROUP_KEYS_); # group-expression of n-th filter

           my (_LOCAL_VARLIST_) =
             map {
               my $group_result = $l[$_]{ $keys[$_] }[0];
               $is_windowing[$_] ? $group_result->{ $row } : $group_result
             } 0..$#l;
           my @out_row = (
             _RET_COLS_
           );
           #<IF_DISTINCT>
           my $key = join "\x0",map { defined $_ ? $_ : '' } @out_row;
           next if exists $seen{$key};
           $seen{$key}=undef;
           #</IF_DISTINCT>
           $out->{process_row}->($out, \@out_row)_IF_FILTER_;
         }
         $out->{finish}($out);
       }
     }`,
  SORT =>  q`
     {
       type => 'SORT',
       init => sub {
         my ($self)= @_;
         $self->{saved_rows} = [];
         my $out = $self->{output};
         $out->{init}->($out);
       },
       process_row => sub {
         my ($self,$row)= @_;
         push @{$self->{saved_rows}}, $row;
       },
       finish => sub {
         my ($self)=@_;
         my $saved_rows = $self->{saved_rows};
         use locale;
         @$saved_rows = _SORT_CMP_ @$saved_rows;
         my $row;
         my $out = $self->{output};
         while ($row = shift @$saved_rows) {
           $out->{process_row}->($out, $row);
         }
         $out->{finish}($out);
       }
     }`,
 );

# do several substitutions at once
sub _code_substitute {
  my (undef, $map)=@_;
  my $what = join('|',reverse sort keys %$map);
  $_[0] =~ s{[ \t]*#<IF_LEN ($what)>\s*?\n(.*?)[ \t]*#</IF_LEN>\s*?\n}{
    defined($map->{$1}) and length($map->{$1}) ? $2 : ''
  }seg;
  $_[0] =~ s{($what)}{ $map->{$1} }eg;
}

sub _code_template_substitute {
  my (undef, $map,$id)=@_;
  $_[0] =~ s{\b_TEMPLATE_([A-Z_]+)_\b}{
    _code_from_template($1, $map->{_MAP_},'sub_'.$id)
  }eg;
  if ($map) {
    my $what = join('|',reverse sort keys %$map);
    $_[0] =~ s{[ \t]*#<IF_((NOT_)?($what))>\s*?\n(.*?)[ \t]*#</IF_\1>\s*?\n}{
      (($2 ? !$map->{$3} : $map->{$3}) ? $4 : '')
    }seg;
  }
}

sub _code_from_template {
  my ($name,$map,$id)=@_;
  $map ||= {};
  my $code = $code_template{$name};
  _code_template_substitute($code, $map,$id);
  return "\n#line 1 ${name}_${id}\n".$code;
}

sub serialize_filter {
  my ($self, $filter, $opts)=@_;
  # $filter->{group-by}
  # $filter->{distinct}
  # $filter->{return}
  # $filter->{sort-by}

  my @group_by = @{ $filter->{'group-by'} || [] };
  my @where = @{ $filter->{where} || [] };
  my @return = @{ $filter->{return} || [] };
  my @sort_by = @{ $filter->{'sort-by'} || [] };
  my $having = $filter->{'having'};

  if ($DEBUG > 3) {
    print STDERR "----------------\n";
    print STDERR "Serializing: g: @group_by, r: @return, s: @sort_by\n";
    print STDERR "Column count: $opts->{column_count}\n";
  }

  my $is_first_filter = defined($opts->{column_count}) ? 0 : 1;
  my $distinct = $filter->{distinct} || 0;

  my $Foreach = $opts->{foreach} || [];
  my $foreach_idx = 0;
  my $input_columns = $opts->{input_columns} || [];
  my $return_columns = $opts->{columns_used} || {};

  my %aggregations;
  my %return_aggregations;
  my @return_vars;
  my @return_exp = do {
    my $i = 0;
    map $self->serialize_column($_, {
      %$opts,
      var_prefix => 'v',
      foreach => ($is_first_filter && !@group_by ? $Foreach : undef),
      input_columns => ($is_first_filter && !@group_by ? $input_columns : undef),
      columns_used => $return_columns,
      vars_used => ($return_vars[$i++]={}),
      local_aggregations => \%return_aggregations,
      old_aggregations => $opts->{aggregations},
      old_aggregations_first_column => $opts->{old_aggregations_column},
      aggregations => \%aggregations,
      column_count => scalar(@group_by) || $opts->{column_count},
      is_first_filter => $is_first_filter,
    }), @return
  };

  use Data::Dumper;
  # print STDERR Dumper({having=>$having});

  my $having_exp = ref($having) && $self->serialize_element({
    %$opts,
    name=>'and',
    columns_used => {},
    is_first_filter => 0,
    condition => $having,
    is_positive_conjunct => 1,
    output_filter => 1,
    output_filter_where_clause => 1,
    column_count => scalar(@return),
    var_prefix => 'out_row[',
    var_suffix => ' - 1]',
  });
  #print STDERR Dumper({having_exp=>$having_exp});

  my @compiled_filters;
  my %old_aggregations;

  my $prev_types = @group_by
    ? [map $self->compute_column_data_type($_,$opts), @group_by]
      : $opts->{column_types};

  if (keys(%return_aggregations) and keys(%aggregations)) {
    # here we should split to two filters:
    # filter one is
    #
    # >> [ for <group> ]
    #    [ give ] <cols_used>, <aggregations>

    # for this filter, we
    # use cols_used and also all occurrences of
    # aggregation functions as original parse trees
    # the first parse of local aggregations content_decl
    # is used to collect these, if embedded into local aggregations
    #
    # we run serialize_filter using only group_by
    # and the faked return

    my @aggregations = sort { $a->[0] <=> $b->[0] } values %aggregations;

    if ($DEBUG > 3) {
      print STDERR "========================\n";
      print STDERR "PART ONE:\n";
    }

    my $agg_filter = {
      'group-by' => $filter->{'group-by'},
      'return' => Treex::PML::Factory->createList([
        (map '$'.$_, sort keys(%$return_columns)),
        # these we pass in parsed
        (map [ 'ANALYTIC_FUNC',
               $_->[1],                      # name
               Treex::PML::CloneValue($_->[2]),   # args
               undef,                        # over
               Treex::PML::CloneValue($_->[4]),   # sort by
              ], @aggregations),
       ]),
    };
    push @compiled_filters, $self->serialize_filter($agg_filter,$opts);

    $prev_types = [
      map $self->compute_column_data_type($_,{
        %$opts,
        column_types => $prev_types,
      }), @{$agg_filter->{return}}
     ];


    $is_first_filter=0;

    if ($DEBUG > 3) {
      print STDERR "========================\n",
        "PART TWO:\n";
    }

    # the second filter is obtained as follows:

    # >> [distinct ] <return_cols_remapping_cols_to_cols_used_and_aggregations_to_extra_cols>
    #    [ sort by <sort_cols> ]

    # so, we clear group_by, aggregations, preserve sort_by, and

    $opts->{column_count} = scalar @group_by;
    @group_by = ();
    %old_aggregations = %aggregations;
    %aggregations = ();

    print STDERR Data::Dumper::Dumper( \%old_aggregations ) if $DEBUG > 3;

    # we make sure that
    # _RET_VARLIST_ is serialized as the usual _RET_VARLIST_
    # appended by aggregation variables
    # and _RET_COLNUMS_ is serialized as 0..$#cols_used + @aggregations
  }

  my %group_columns;
  my @group_vars;
  my @group_by_exp = do {
    my $i = 0;
    map { $self->serialize_column($_, {
      %$opts,
      var_prefix => 'g',
      columns_used => \%group_columns,
      foreach => ($is_first_filter ? $Foreach : undef),
      input_columns => ($is_first_filter ? $input_columns : undef),
      vars_used => ($group_vars[$i++]={}),
      local_aggregations => undef, # not applicable
      aggregations => undef,       # not applicable
      column_count => $opts->{column_count},
      is_first_filter => $is_first_filter,
    }) } @group_by
  };

  my @local_filters;
  my @local_group_keys;
  for my $agg (values %return_aggregations) {
    my ($num, $name, $args, $over, $sort_by, $over_exp, $vars_used) = @$agg;
    # below we pass in something
    # that looks like a filter
    # but contains parse-trees instead of strings
    my $column_count = (@group_by || $opts->{column_count});

    if ($DEBUG > 3) {
      print STDERR "SUBFILTER\n";
      use Data::Dumper;
      print STDERR Dumper({
        name => $name,
        args => $args,
        over => $over,
        over_exp => $over_exp,
        vars_used => $vars_used,
        column_count => $column_count,
        input_columns => $input_columns,
      });
    }
    print STDERR Data::Dumper::Dumper( \%old_aggregations ) if $DEBUG > 3;

    my @f =
      $self->serialize_filter(
        {
          'group-by' => Treex::PML::Factory->createList(
            [@$over]
           ),
          'return' => Treex::PML::Factory->createList(
            [[
              'ANALYTIC_FUNC',
              $name,
              $args,
              undef,
              $sort_by,
             ]]
           ),
        },
        {
          column_types => $opts->{column_types},
          filter_id => $opts->{filter_id}.'_local_'.$num,
          is_local_filter => 1,
          is_first_filter => $is_first_filter,
          input_columns => ($is_first_filter ? $input_columns : undef),
          foreach => ($is_first_filter ? $Foreach : undef),
          old_aggregations => \%old_aggregations,
          old_aggregations_first_column => scalar(keys(%$return_columns)),
          column_count => $column_count,
          code_map_flags => {
            RETURN => 1,
          },
        }
       );
    if (@f>1) {
      die "Internal error: serialize_filter on a local filter returned more than one filter:\n @f!";
    }
    $local_filters[$num] = $f[0];
    my $exp = do {
      my $i = 0;
      join(",\n            ",
           map {
             my @vars_used = sort keys %{$vars_used->[$i]};
             if (@vars_used) {
               '(('.join(' && ',map qq{defined($_)}, @vars_used).') ? ('.$_.') : undef)'
             } else {
               $_
             }
           } @$over_exp)
    };
    $local_group_keys[$num] =
      @$over_exp > 1 ? 'join("\x0",'.$exp.')' : $exp;
  }

  my @aggregations_exp;
  my @aggregations_columns;
  my @aggregations_vars;
  my @aggregations = sort { $a->[0] <=> $b->[0] } values %aggregations;
  if (@aggregations) {
    @aggregations_exp = map {
      my $agg_no = $_->[0];     #no
      my $col_no = 0;
      [$_->[1],                 #name
       [                        # columns
         map $self->serialize_column($_, {
           %$opts,
           var_prefix => 'v',
           columns_used => ($aggregations_columns[$agg_no]||={}),
           foreach => ($is_first_filter ? $Foreach : undef),
           input_columns => ($is_first_filter ? $input_columns : undef),
           vars_used => ($aggregations_vars[$agg_no][$col_no++]={}),
           local_aggregations => undef,
           aggregations => $opts->{aggregations}, # not applicable
           column_count => $opts->{column_count},
           is_first_filter => $is_first_filter,
         }), @{$_->[2]}         # args
        ],
       [                        # sort_by columns and types
         map {
           my $type = $self->compute_column_data_type($_->[0],$opts);
           [
             $self->serialize_column($_->[0], {
               %$opts,
               var_prefix => 'v',
               columns_used => ($aggregations_columns[$agg_no]||={}),
               foreach => ($is_first_filter ? $Foreach : undef),
               input_columns => ($is_first_filter ? $input_columns : undef),
               vars_used => ($aggregations_vars[$agg_no][$col_no++]={}),
               local_aggregations => undef,
               aggregations => $opts->{aggregations}, # not applicable
               column_count => $opts->{column_count},
               is_first_filter => $is_first_filter,
             }), # sort_column
             $type, # sort_column_type
             $_->[1] # sort direction (asc,desc)
            ]} @{$_->[4]}       # sort_by
           ],
      ]
    } @aggregations;
  }

  $opts->{column_types} = [
    map $self->compute_column_data_type($_,{
      %$opts,
      column_types => $prev_types,
    }), @return
   ];

  my @sort_by_exp = do {
    my $i = 0;
    map {
      if (/^\$(\d+)(?:\s+(asc|desc))?$/) {
        my ($col,$dir) = ($1,$2);
        my $max_col_no = scalar @return;
        if ($col > $max_col_no) {
          die "Invalid number $col in sort by clause (there are only $max_col_no output columns)!\n";
        }
        [$col,$self->compute_column_data_type('$'.$col,$opts),$dir]
      } elsif (defined and length) {
        die "Invalid sort column: $_\n";
      } else {
        ()
      }
    } @sort_by
  };

  $opts->{column_count} = scalar @return;

  if ($DEBUG > 3) {
    use Data::Dumper;
    print STDERR Dumper({
      foreach => $Foreach,
      aggregations => \@aggregations_exp,
      return_exp => \@return_exp,
      return_agg => \%return_aggregations,
      group_by_exp => \@group_by_exp,
      sort_by_exp => \@sort_by_exp,
      colum_types => $opts->{column_types},
      input_columns => $input_columns,
    });
  }

  my @columns_used = uniq(sort keys(%$return_columns));
  my @g_columns_used = uniq(sort keys(%group_columns));

  # In case we moved aggregations to a separate filter
  # that precedes this one, we want
  # _RET_VARLIST_ to be serialized as the usual _RET_VARLIST
  # but appended by aggregation variables \$a0..\$a$old_aggregation_count
  # and we want _RET_COLNUMS_ to be 0..(@cols_used + $old_aggregation_count - 1)

  my $old_aggregation_count = scalar keys %old_aggregations;

  my $varlist = join(',', (map '$v'.$_, @columns_used),
                     (map '$a'.$_, 0..($old_aggregation_count-1))
                    );
  my $colnums =
    $old_aggregation_count
      ? join(',', 0..($#columns_used+$old_aggregation_count))
        : join(',', map $_-1, @columns_used);

  my $g_varlist = join(',', map '$g'.$_, @g_columns_used);
  my $g_colnums = join(',', map $_-1, @g_columns_used);
  my $agg_varlist = join(',', map '$a'.$_, 0..$#aggregations_exp);
  my $local_varlist = join(',',map '$l'.$_,0..$#local_filters);

  my ($agg_final,$all_agg_code,$init_agg,$is_windowing);
  {
    $init_agg = do {
      my $i = 0;
      join(";         \n",
           map {
             '$self->{aggregated}['.($i++).'] = '.$aggregation_init{ $_->[0] }."; # init $_->[0](...)"
           } @aggregations_exp)
    };

    {
      my (@agg_code, @agg_final,@is_windowing);
      my $i = 0;
      for my $aggr (@aggregations_exp) {
        my $funcname = $aggr->[0];
        my $args = $aggr->[1];
        my $sort_by_columns_and_types = $aggr->[2];
        my $agg_code = $aggregation_template{$funcname} || $aggregation_template{_DEFAULT_} ;
        my @columns_used = uniq(sort keys(%{$aggregations_columns[$i]}));
        my $varlist = join(',', map '$v'.$_, @columns_used);
        my $colnums = join(',', map $_-1, @columns_used);
        my $defined = join(' && ', map 'defined($v'.$_.')', @columns_used);
        my $op = $aggregation_op{$funcname};
        if (defined $op) {
          _code_substitute($op,
                           {
                             _ARG_ => $args->[0],
                             _SORT_ARGS_ => join(',',map $_->[0], @$sort_by_columns_and_types),
                           }
                          )
        }

        # no substitutions on $agg_code past this point:
        _code_substitute($agg_code,
                         {
                           _FUNC_VARLIST_ => $varlist,
                           _FUNC_COLNUMS_ => $colnums,
                           _FUNC_DEFINED_ => $defined,
                           _FUNC_OP_ => $op,
                         });

        push @agg_code, "          # $funcname(...)\n".$agg_code;
        push @is_windowing,($funcname =~ /^(?:rank|dense_rank|row_number)$/ ? 1 : 0);

        push @agg_final, 'my $a'.$i.' = $self->{aggregated}['.$i.'];';
        if (exists $aggregation_final{$funcname}) {
          my $final_code = $aggregation_final{$funcname};
          my $arg1;
          my $sort_cmp;
          if ($funcname =~ /^(concat|rank|dense_rank|row_number)$/) {
            $arg1 = $aggr->[1][1];
            $arg1 = defined($arg1) && length($arg1) ? $arg1 : q('');
            my @op = map { $_->[1]==COL_NUMERIC ? '<=>' : 'cmp' } @$sort_by_columns_and_types;
            my @dir = map { $_->[2] && $_->[2] eq 'desc' ? '-' : '' } @$sort_by_columns_and_types;
            $sort_cmp = join(' or ',
                             map $dir[$_].'( $a->['.($_+1).'] '.$op[$_].' $b->['.($_+1).'])',
                             0..$#$sort_by_columns_and_types
                            );
          }
          _code_substitute($final_code,
                           {
                             _RESULT_ => '$a'.$i,
                             _ARG1_ => $arg1,
                             _CMP_ => ($sort_cmp || '1'),
                             _SORT_CMP_ => ($sort_cmp ? 'sort {'.$sort_cmp.'}' : '')
                            });
          push @agg_final,$final_code;
        }
        $i++;
      }
      $agg_final = join('',map { "\n              ".$_ } @agg_final);
      $all_agg_code = join(',',@agg_code);
      $is_windowing = join(',',@is_windowing);
    }
  }

  my $cols = $self->serialize_col_expressions(\@return_exp, \@return_vars);
  my $group_cols = $self->serialize_col_expressions(\@group_by_exp, \@group_vars);
  my $local_group_keys = join (",\n           ",@local_group_keys);

  my $output_filter;
  # first without any inner aggregations
  my $code;
  my $filter_id = $opts->{filter_id};

  if (@group_by) {
    # use group_by template
    if (!@local_filters) {
      $code = _code_from_template('GROUP', {
        _MAP_ => { RETURN => 1 },
        RETURN => 0,
        DISTINCT => $distinct,
        %{$opts->{code_map_flags}||{}},
      },$opts->{filter_id});
    } else {
      die "TODO";
    }
  } elsif (@aggregations_exp and !keys(%return_aggregations)) {
    # use the direct template
    $code = _code_from_template('AGGREGATE', {
      RETURN => 0,
      DISTINCT => $distinct,
      %{$opts->{code_map_flags}||{}},
    },$opts->{filter_id});
  } elsif (!@aggregations_exp and keys(%return_aggregations)) {
    $code = _code_from_template('INNER_AGGREGATE', {
      RETURN => 0,
      DISTINCT => $distinct,
      %{$opts->{code_map_flags}||{}},
    },$opts->{filter_id});
  } elsif (@aggregations_exp and keys(%return_aggregations)) {
    die "TODO";
  } else {
    # no aggregations at all
    $code = _code_from_template('PLAIN', {
      RETURN => 0,
      DISTINCT => $distinct,
      %{$opts->{code_map_flags}||{}},
    },$opts->{filter_id});
  }

  # below, user-data may be involved, we must do a one step-substitution
  _code_substitute($code,
                   {
                     _IS_WINDOWING_ => $is_windowing,
                     _AGGREGATIONS_ => $all_agg_code,
                     _RET_VARLIST_ => $varlist,
                     _GROUP_VARLIST_ => $g_varlist,
                     _RET_COLNUMS_ => $colnums,
                     _GROUP_COLNUMS_ => $g_colnums,
                     _AGG_FINALIZE_ => $agg_final,
                     _INIT_AGG_ => $init_agg,
                     _GROUP_COLS_ => $group_cols,
                     _RET_COLS_ => $cols,
                     _IF_FILTER_ => (defined($having_exp) && length($having_exp) ? (' if '.$having_exp) : ''),
                     _LOCAL_VARLIST_ => $local_varlist,
                     _LOCAL_GROUP_KEYS_ => $local_group_keys,
                   }
                  );
  $output_filter = eval $code; die $@ if $@;
  $output_filter->{local_filters_code} = [ map $_->{code}, @local_filters ];
  $output_filter->{code}=$code;

  # filter_init:
  if ($is_first_filter and !$opts->{is_local_filter}) {
    my $code = q`
         $first_filter->{process_row}->($first_filter, [
           _RET_COLS_
         ]);
      `;

    # no substitutions past this point!
    _code_substitute($code,
                     {
                       _RET_COLS_ => join (",\n           ",@$input_columns),
                     }
                    );
    # now we simulate a left join
    {
      $code = $self->foreach_wrap($Foreach,$code,
                                  [[0,'sub {'],
                                   [1,'my ($self)=@_;'],
                                   [1,'my $first_filter = $self->{filters}[0];']],
                                  [[0,'}']]);
    }
    $opts->{filter_init} = $code;
  }
  push @compiled_filters, $output_filter;

  if (@sort_by_exp) {
    my $sort_code = _code_from_template('SORT', {
      RETURN => 0,
      DISTINCT => 0,
    },'sort_'.$opts->{filter_id});
    #      my $sort_varlist = join(',', map '$v'.$_, @sort_columns_used);
    #      my $sort_colnums = join(',', map $_-1, @sort_columns_used);
    #      my $sort_cols = $self->serialize_col_expressions(\@sort_by_exp, \@sort_vars);
    my @op = map { $_->[1]==COL_NUMERIC ? '<=>' : 'cmp' } @sort_by_exp;
    my $sort_cmp = join(' or ',
                        map {
                          (($_->[2] and $_->[2] eq 'desc') ? '-' : '')
                            .'( $a->['.($_->[0]-1).'] '
                              .($_->[1]==COL_NUMERIC ? '<=>' : 'cmp')
                                .' $b->['.($_->[0]-1).'])'
                              } @sort_by_exp);
    _code_substitute($sort_code,
                     {
                       _CMP_ => ($sort_cmp || '1'),
                       _SORT_CMP_ => ($sort_cmp ? 'sort {'.$sort_cmp.'}' : '')
                      }
                    );

    $output_filter = eval $sort_code; die $@ if $@;
    $output_filter->{code}=$sort_code;
    push @compiled_filters, $output_filter;
  }
  return  @compiled_filters;
}

sub foreach_wrap {
  my ($self,$Foreach,$code,$init_wrap_l,$init_wrap_r)=@_;
  # now we simulate a left join
  my @wrap_l=$init_wrap_l ? @$init_wrap_l : ();
  my @wrap_r=$init_wrap_r ? @$init_wrap_r : ();

  my $i=0;
  my $indent=1;
  foreach my $f (@$Foreach) {   # he?
    my $prev_var='$var'.($i-1);
    if ($f->[0]==1) {
      push @wrap_l,
        [$indent,
         ($i && !$f->[2] && $f->[1]=~/\Q$prev_var\E/)
           ? qq`my \@var$i = defined(\$var`.($i-1).qq`) ? $f->[1] : ();`
             : ref($f->[2]) && @{$f->[2]}
               ? qq`my \@var$i = `.join(' && ', map qq`defined($_)`,@{$f->[2]}).qq` ? $f->[1] : (); # return_vars\n`
                 : qq`my \@var$i = $f->[1]; # no defined test\n`
                ],
                  [$indent,qq`foreach my \$var$i (\@var$i ? \@var$i : (undef)) {`];
      unshift @wrap_r, [$i,qq`}`];
      $indent++;
    } elsif ($f->[0]==0) {
      push @wrap_l, [$indent,
                     ($i && !$f->[2] && $f->[1]=~/\Q$prev_var\E/)
                       ? qq`my \$var$i = defined(\$var`.($i-1).qq`) ? $f->[1] : undef;`
                         : ref($f->[2]) && @{$f->[2]}
                           ? qq`my \$var$i = `.join(' && ', map qq`defined($_)`,@{$f->[2]}).qq` ? $f->[1] : undef; # return_vars\n`
                             : qq`my \$var$i = $f->[1]; # no defined test`];
    }
    $i ++;
  }
  return join('',
              map { ('  ' x ($_->[0]+10)).$_->[1]."\n" }
                (
                  @wrap_l,
                  [$indent,$code],
                  @wrap_r,
                 )
               );
}


sub serialize_col_expressions {
  my ($self, $expressions, $vars)=@_;
  my $i = 0;
  return
    join (",\n        ",
          map {
            my @vars_used = sort keys %{$vars->[$i++]};
            if (@vars_used and !/^\$[a-z][0-9]+$/) {
              '(('.join(' && ',map qq{defined($_)}, @vars_used).') ? ('.$_.') : undef)'
            } else {
              $_
            }
          } @$expressions);
}

sub serialize_column {
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
  return $self->serialize_expression_pt($pt,{
    %$opts,
    output_filter => 1,
    expression=>$column,
  });
}

sub serialize_conditions {
  my ($self,$qnode,$opts)=@_;
  my $conditions = $self->serialize_element({
    %$opts,
    id => $qnode->{name},
    type => PMLTQ::Common::GetQueryNodeType($qnode,$self->{type_mapper}),
    name => 'and',
    condition => $qnode,
  });

  my $pos = $opts->{query_pos};
  my $match_pos = $self->{pos2match_pos}[$pos];
  my $optional;
  if ($qnode->{optional}) {
    my $parent_pos = $self->{parent_pos}[$pos];
    if (!defined $parent_pos) {
      die "Optional node cannot at the same time be the head of a subquery!";
    }
    $optional = '$matched_nodes->['.$self->{pos2match_pos}[$parent_pos].']';
  }
  if ($conditions and $conditions=~/\S/) {
    if (defined $optional) {
      $conditions='('.$optional.'==$node or '.$conditions.')';
    }
  } else {
    $conditions=undef
  }

  print STDERR "CONDITIONS[$pos/$match_pos]: $conditions\n" if $DEBUG > 1;
  my $check_preceding = '';

  my $recompute_cond = $opts->{recompute_condition}[$match_pos];
  if (defined $recompute_cond) {
    $check_preceding = join('', map {"\n   and ".
                                       '$conditions['.$_.']->($matched_nodes->['.$self->{pos2match_pos}[$_].'],'
                                         .'$iterators['.$_.']->file,'
                                           .'1) '
                                         } sort { $a<=>$b } keys %$recompute_cond);
  }
  if (length $check_preceding) { # will check preceding nodes in chain
    $check_preceding = "\n".
      '  and ($backref or '.
        '($matched_nodes->['.$match_pos.']=$node) # a trick: make it appear as if this node already matched!'."\n".
          $check_preceding.
            ')';
  }
  my $nodetest =
    $qnode->{overlapping} ? '$node' :
    '$node and ($backref or '
    .(defined($optional) ? $optional.'==$node or ' : '')
      .'!exists($have{$node}))';
  my $type_name = (PMLTQ::Common::IsMemberNode($qnode) or $qnode->{'node-type'} eq '*') ? undef : quotemeta($qnode->{'node-type'});
  my $id=$qnode->{'name'} || '';
  my $sub = qq(#line 1 "query-node/${match_pos}/$id"\n)
    . 'sub { my ($node,$fsfile,$backref)=@_; '."\n  "
      #. 'print STDERR "node_ref: ".ref($node)."\n";' . "\n"
      #. 'print STDERR "backref: $backref\n";' . "\n"
      #. 'print STDERR "have: ($have{$node})\n";' . "\n"
      .$nodetest
        .(defined($type_name) && length($type_name) ? "\n and ".
            ($qnode->{'node-type'} =~ m{^(?:([^/]+):)?\*$}
              ? q[$node->type->get_schema->get_root_name eq qq(].quotemeta($1).q[)]
              : q[$node->type->get_decl_path =~ m{^\!].$type_name.q[(?:\.type)?$}]) : ())
          .(defined($conditions) ? "\n  and ".$conditions : '')
            . $check_preceding
              ."\n}";
  print STDERR "SUB: $sub\n" if $DEBUG > 1;
  # save sub to file
  my $path = "query-node/${match_pos}";

  # save subs as files for debugger
  if ($DEBUGGER) {
      use File::Path;
      File::Path::make_path($path);
      open my $SUB, '>', "$path/$id"
          or die "Cannot open debugger output\n";
      print {$SUB} $sub;
      close $SUB or die "Cannot close debugger output\n";
  }
  return $sub;
}

sub serialize_test {
  my ($self, $left, $operator, $right, $left_type, $right_type)=@_;
  my $negate = $operator=~s/^!// ? 1 : 0;
  $left_type ||= 0;
  $right_type ||= 0;

  # fix empty variables
  $left = "($left||0)" if ($left_type == COL_NUMERIC && $left =~ /^\$/);
  $right = "($right||0)" if ($right_type == COL_NUMERIC && $right =~ /^\$/);

  if ($operator eq '=') {
    if ($left_type == COL_NUMERIC && $right_type == COL_NUMERIC) {
      $operator = $negate ? '!=' : '==';
    } else {
      $operator = $negate ? 'ne' : 'eq';
    }
  } elsif ($operator eq '<') {
    $operator = 'lt' unless ($left_type == COL_NUMERIC && $right_type == COL_NUMERIC);
  } elsif ($operator eq '>') {
    $operator = 'gt' unless ($left_type == COL_NUMERIC && $right_type == COL_NUMERIC);
  } elsif ($operator eq '<=') {
    $operator = 'le' unless ($left_type == COL_NUMERIC && $right_type == COL_NUMERIC);
  } elsif ($operator eq '>=') {
    $operator = 'ge' unless ($left_type == COL_NUMERIC && $right_type == COL_NUMERIC);
  } elsif ($operator eq '~') {
    $operator = $negate ? '!~' : '=~';
  }
  my $condition;
  if ($operator eq '~*') {
    $condition='do{ my $regexp='.$right.'; '.$left.($negate ? '!~' : '=~').' /$regexp/i}';
  } elsif ($operator eq 'in') {
    # TODO: 'first' is actually pretty slow, we should use a disjunction
    # but splitting may be somewhat non-trivial in such a case
    # - postponing till we know exactly how a tree-query term may look like
    $condition='do{ my $node='.$left.'; '.($negate ? '!' : '').'grep $_ eq '.$left.', '.$right.'}';
    # #$condition=$left.' =~ m{^(?:'.join('|',eval $right).')$}';
    #   $right=~s/^\s*\(//;
    #   $right=~s/\)\s*$//;
    #   my @right = split /,/,$right;
    #   $condition='do { my $node='.$left.'; ('.join(' or ',map { '$node eq '.$_ } @right).')}';
  } elsif ($operator eq '->') {
    # this is a special faked operator for PMLREF/ID comparison
    $condition='('.$left.' =~ /^(.*#)?\Q'.$right.'\E$/)';
  } elsif ($operator=~/^<(.*),(.*)>$/) {  # special "fake is-between operator"
    my $exp = qq{($left - $right)};
    $condition =
          (length($1) and length($2)) ? qq{($exp>=$1 and $exp<=$2)} :
          length($1) ? qq{$exp >= $1} :
          length($2) ? qq{$exp <= $2} : die "Internal error: cannot serialize operator $operator\n";
  } else {
    $condition='('.$left.' '.$operator.' '.$right.')';
  }
  return $condition;
}

sub serialize_element {
  my ($self,$opts)=@_;

  my ($name,$node)=map {$opts->{$_}} qw(name condition);
  my $pos = $opts->{query_pos} || 0;
  my $match_pos = $self->{pos2match_pos}[$pos]; #WARN Use of uninitialized value $pos in array element (same bug is in original implementation)
  if ($name eq 'test') {
    my %depends_on;
    my $foreach = [];
    my ($left,$right,$left_type,$right_type);
    my $condition;
    if ($opts->{output_filter}) { #  and $opts->{output_filter_where_clause}
      my ($left_pt, $right_pt) = map PMLTQ::Common::parse_column_expression($node->{$_}), qw(a b);
      ($left_type,$right_type)=map $self->compute_expression_data_type_pt($_,$opts), ($left_pt,$right_pt);
      $left = $self->serialize_expression_pt($left_pt,
                                      {%$opts,
                                       foreach => $opts->{foreach} || $foreach,
                                       expression=>$node->{a}
                                      });
      $right = $self->serialize_expression_pt($right_pt,
                                      {%$opts,
                                       foreach => $opts->{foreach} || $foreach,
                                       expression=>$node->{b}
                                      });
    } else {
      my ($left_pt, $right_pt) = map PMLTQ::Common::parse_expression($node->{$_}), qw(a b);
      ($left_type,$right_type)=map $self->compute_expression_data_type_pt($_,$opts), ($left_pt,$right_pt);
      $left = $self->serialize_expression_pt($left_pt,{%$opts,
                                           foreach => $foreach,
                                           depends_on => \%depends_on,
                                           expression=>$node->{a}
                                          });
      $right = $self->serialize_expression_pt($right_pt, {%$opts,
                                            foreach => $foreach,
                                            depends_on => \%depends_on,
                                            expression=>$node->{b}
                                           });
    }
    $condition = $self->serialize_test($left, $node->{operator},$right, $left_type,$right_type);
    my @wrap_l = ([0,q`do {`],[0,q` my $reslt;`]);
    my @wrap_r = ([0,q` $reslt`],[0,q`}`]);
    my $negate = 0;
    unless ($opts->{output_filter} and $opts->{foreach}) {
      for my $i (0..$#$foreach) {
        if ($foreach->[$i][0]==2) {
          $negate=!$negate;
          unshift @wrap_r, [$i,q`$reslt = !$reslt;`];
        } elsif ($foreach->[$i][0]==1) {
          push @wrap_l, [$i,qq`foreach my \$var$i ($foreach->[$i][1]) {`],
            [$i,qq` if (defined \$var$i) {`] # although we might probably assume that list values are defined
              ;
          unshift @wrap_r, [$i,qq`  last if \$reslt;`],
            [$i,qq` }`],
              [$i,qq`}`];
        } else {
        #my $tmp = $foreach->[$i][1];
        #$tmp =~ s/->.*//;

          push @wrap_l, [$i,qq`my \$var$i = $foreach->[$i][1];`],
        #[$i,qq`use Data::Dumper;`],
        #[$i,qq`print STDERR Dumper(\$var$i);`],
            [$i,qq`if (defined \$var$i) {`];
          unshift @wrap_r, [$i,qq`}`];
        }
      }
    }
    $condition = join('',
                      map { ('  ' x ($_->[0]+10)).$_->[1]."\n" }
                        (
                          @wrap_l,
                          [$#$foreach,qq`  \$reslt = ($condition) ? `.($negate ? '0:1;' : '1:0;')],
                          @wrap_r
                         )
                       );

    my $target_match_pos = max($match_pos,keys %depends_on);
    my $target_pos = Treex::PML::Index($self->{pos2match_pos},$target_match_pos);
    if (defined $target_pos) {
      # target node in the same sub-query
      if ($target_pos<=$pos) { #WARN Use of uninitialized value $pos in numeric le (<=)
        return $condition;
      } elsif ($target_pos>$pos) {
        $opts->{recompute_condition}[$target_match_pos]{$pos}=1;
        return ('( $$query_pos < '.$target_pos.' ? '.int(!$opts->{negative}).' : '.$condition.')');
      }
    } else {
      # this node is referred to from some super-query
      if ($target_match_pos > $self->{parent_query_match_pos}) {
        # we need to postpone the evaluation of the whole sub-query up-till $matched_nodes->[$target_match_pos] is known
        $self->{postpone_subquery_till}=$target_match_pos if ($self->{postpone_subquery_till}||0)<$target_match_pos;
      }
      return $condition;
    }
  } elsif ($name =~ /^(?:and|or|not)$/) {
    my $negative = $opts->{negative} ? 1 : 0;
    if ($name eq 'not') {
      $negative=!$negative;
    }
    my %order = (
      test => 1,
      not => 2,
      or => 3,
      ref => 4,
      subquery => 5,
    );
    my @c =grep {defined and length}
      map {
        $self->serialize_element({
          %$opts,
          negative => $negative,
          name => $_->{'#name'},
          # id => $node->{name},
          # type => $node->{'node-type'},
          condition => $_,
        })
      }
      sort { ($order{$a->{'#name'}}||100)<=>($order{$b->{'#name'}}||100) }
      grep { $_->{'#name'} ne 'node' } $node->children;
    return () unless @c;
    if ($name eq 'not') {
      return 'not('.join("\n  and ",@c).')';
    } else {
      return '('.join("\n  $name ",@c).')';
    }
  } elsif ($name eq 'subquery') {
    my $subquery = ref($self)->new($node, {
      type_mapper => $self->{type_mapper},
      parent_query => $self,
      parent_query_pos => $pos,
      parent_query_match_pos => $match_pos,
    });
    push @{$self->{sub_queries}}, $subquery;
    my $sq_pos = $#{$self->{sub_queries}};
    my @occ = map {
      (length($_->{min}) || length($_->{max})) ?
        ((length($_->{min}) ? $_->{min} : undef),
         (length($_->{max}) ? $_->{max}+1 : undef)) : (1,undef)
       } AltV($node->{occurrences});
    my $occ_list =
      max(map {int($_||0)} @occ)
          .','.join(',',(map { defined($_) ? $_ : 'undef' } @occ));
    my $condition = q`(($backref or $matched_nodes->[`.$match_pos.q`]=$node) and `. # trick: the subquery may ask about the current node
      qq/\$sub_queries[$sq_pos]->test_occurrences(\$node,\$fsfile,$occ_list))/;
    my $postpone_subquery_till = $subquery->{postpone_subquery_till};
    if (!defined $postpone_subquery_till or $ALL_SUBQUERIES_LAST) {
      $postpone_subquery_till = $self->{pos2match_pos}[-1];
      print STDERR "ALL_SUBQUERIES_LAST used\n" if $DEBUG > 1;
    }
    if (defined $postpone_subquery_till) {
      print STDERR "postponing subquery till: $postpone_subquery_till\n" if $DEBUG > 1;
      my $target_pos = Treex::PML::Index($self->{pos2match_pos},$postpone_subquery_till);
      if (defined $target_pos) {
        # same subquery, simply postpone, just like when recomputing conditions
        # my $postpone_pos = $postpone_subquery_till;
        $opts->{recompute_condition}[$postpone_subquery_till]{$pos}=1;
        return ('( $$query_pos < '.$target_pos.' ? '.int(!$opts->{negative}).' : '.$condition.')');
      } else {
        print STDERR "other subquery\n" if $DEBUG > 1;
        # otherwise postpone this subquery as well
        $self->{postpone_subquery_till}=$postpone_subquery_till if $postpone_subquery_till>($self->{postpone_subquery_till}||0);
        return $condition;
      }
    } else {
      return $condition;
    }
  } elsif ($name eq 'ref') {
    my ($rel) = PMLTQ::BtredEvaluator::SeqV($node->{relation});
    return unless $rel;
    my $target = $node->{target};
    my $relation = $rel->name;
    my $expression;
    my $label='';
    if ($relation eq 'user-defined') {
      $label = $rel->value->{label};
      my ($min,$max)=($rel->value->{min_length},$rel->value->{max_length});
      my $transitive = (defined($min) && ($min>1) or defined($max) && ($max>1)) ? 1 : 0;
      if (defined($min) && defined($max) && ($min>$max)) {
        die "Invalid bounds for transitive relation '$label\{$min,$max}'\n";
      }
      my $target_type = $self->{name2type}{$target};
      if ($transitive) {
        if ($opts->{'type'} ne $target_type) {
          die "Cannot create transitive closure for relation with different start-node and end-node types: '$opts->{type}' -> '$target_type'\n";
        }
        push @{$self->{aux_iterators}}, $self->create_iterator($node,sub{1});
        $expression =
          q(do{ my $it = $aux_iterators[).$#{$self->{aux_iterators}}.q(];
                  my $aux = $it->start($start,$start_fsfile);
                  $aux = $it->next while ($aux && $aux!=$end);
                  $it->reset;
                  $aux ? 1 : 0 });
      } else {
        my $start_node = $node->parent;
        $start_node = $start_node->parent while $start_node && $start_node->{'#name'} !~ /^(node|subquery)$/;
        if ($start_node) {
          my $schema = $self->{type_mapper}->get_schema_for_type($start_node->{'node-type'});
          $expression = PMLTQ::Relation->test_code($schema->get_root_name,$start_node->{'node-type'},$label);
        }
        if (!defined $expression) {
          if (first { $_ eq $label } @{$self->{type_mapper}->get_pmlrf_relations($node)}) {
            return $self->serialize_element(
              {
                %$opts,
                name => 'test',
                condition => {
                  '#name' => 'test',
                  a => $label,
                  b => 'id($'.$target.')',
                  operator => '->',
                },
              });
          } else {
            die "User-defined relation '$label' not supported as a test on this node!\n";
          }
        }
      }
    } else {
      if ($relation eq 'descendant' or $relation eq 'ancestor') {
        my ($min,$max)=
          map { (defined($_) and length($_)) ? $_ : undef }
            map { $rel->value->{$_} }
              qw(min_length max_length);
        my ($START,$END)=($relation eq 'ancestor') ? ('$start','$end') : ('$end','$start');
        $expression = 'do { my $n='.$START.'; '.
          ((defined($min) or defined($max)) ? 'my $l=0; ' : '').
            'while ($n and $n!='.$END.(defined($max) ? ' and $l<'.$max : ''). ') { $n=$n->parent; '.
              ((defined($min) or defined($max)) ? '$l++;' : '').
                ' }'.
                  ' ($n and $n!='.$START.' and $n=='.$END.(defined($min) ? ' and '.$min.'<=$l' : '').') ? 1 : 0}';
      } elsif ($relation eq 'sibling') {
        my ($min,$max)=
          map { (defined($_) and length($_)) ? $_ : undef }
            map { $rel->value->{$_} }
              qw(min_length max_length);
        $expression = 'do { if ($start->parent == $end->parent) { my ($ret,$n);';
        if (defined($min) or defined($max)) {
          $expression .= 'my $l;';
        }
        my $went_right;
        unless (defined($max) and $max<=0) {
          $went_right = 1;
          if ((defined($min) and $min>=0) or defined($max)) {
            $expression .= ' $l=1; ';
          }
          $expression .= '$n=$start->rbrother; while ($n';
          if (defined($max)) {
            $expression .= ' and $l<='.$max;
          }
          $expression .= ') { if ($n==$end) { ';
          if (defined($min) and $min>1) {
            $expression .= '$ret = ($l>='.$min.' ? 1 : 0);';
          } else {
            $expression .= '$ret = 1;';
          }
          $expression .= ' last; }; $n=$n->rbrother;';
          if ((defined($max) and $max<0) or defined($min)) {
            $expression .= ' $l++';
          }
          $expression .= '}';
        }
        unless (defined($min) and $min>=0) {
          $expression .= ' unless (defined($ret)) { ' if $went_right;

          if ((defined($max) and $max<0) or defined($min)) {
            $expression .= ' $l=-1; ';
          }
          $expression .= '$n=$start->lbrother; while ($n';
          if (defined($min)) {
            $expression .= ' and $l>='.$min;
          }
          $expression .= ') { if ($n==$end) { ';
          if (defined($max) and $max<-1) {
            $expression .= '$ret = ($l<='.$max.' ? 1 : 0);';
          } else {
            $expression .= '$ret = 1;';
          }
          $expression .= ' last; }; $n=$n->lbrother;';
          if ((defined($max) and $max<0) or defined($min)) {
            $expression .= ' $l--';
          }
          $expression .= '}';
          $expression .= ' } ' if $went_right;
        }
        $expression.= ' $ret ? 1 : 0 } else { 0 } }';
      } elsif ($relation =~ '^depth-first-(precedes|follows)') {
        my $dir = $1 eq 'precedes' ? 1 : -1;
        my ($min,$max)=
          map { (defined($_) and length($_)) ? $_ : undef }
            map { $rel->value->{$_} }
              qw(min_length max_length);
        my @bounds = _compute_bounds($dir, $min, $max);
        $expression =
          q{ PMLTQ::BtredEvaluator::test_depth_first_order($start, $end}
          .qq{, $dir}
          .join('',map { defined($_) ? ", $_" : ', undef' } @bounds)
          .q{ ) };
      } elsif ($relation eq 'order-precedes' or
                 $relation eq 'order-follows') {
        my ($min,$max)=
          map { (defined($_) and length($_)) ? $_ : undef }
            map { $rel->value->{$_} }
              qw(min_length max_length);
        my $operator;
        my ($L,$R) = ($relation eq 'order-follows') ?
          ('order_span_max()','order_span_min($'.$target.')')
            :
          ('order_span_max($'.$target.')','order_span_min()');
        if (defined($min) and defined($max)) {
          $operator = qq{<$min,$max>};
        } elsif (defined($min)) {
          $operator = qq{<$min,>};
        } elsif (defined($max)) {
          $operator = qq{<,$max>};
        } else {
          $operator = '<';
        }
        return $self->serialize_element(
          {
            %$opts,
            name => 'test',
            condition => {
              '#name' => 'test',
              a=>$L,
              b=>$R,
              operator => $operator,
            },
          });
      } else {
        $expression = $test_relation{$relation};
      }
      die "Relation '$relation' not supported test!\n" unless defined $expression;
    }
    my $target_pos = $self->{name2pos}{$target};
    my $target_match_pos = $self->{name2match_pos}{$target};
    my $condition = q/ do{
                              my ($start,$end,$start_fsfile)=($node,$matched_nodes->[/.$target_match_pos.q/],$fsfile); # /.
                              qq{$target (p:}. (defined $target_pos ? $target_pos : 'undef') .
                              qq{/m:} . (defined $target_match_pos ? $target_match_pos : 'undef') . qq{)} .q/
                       /.$expression.q/ } /;
    if (defined $target_pos) {
      # target node in the same sub-query
      if ($target_pos<$pos) {
        return $condition;
      } elsif ($target_pos>$pos) {
        $opts->{recompute_condition}[$target_match_pos]{$pos}=1;
        return ('( $$query_pos < '.$target_pos.' ? '.int(!$opts->{negative}).' : '.$condition.')');
      } else {
        # huh, really?
        return q/ do{ my ($start,$end,$start_fsfile)=($node,$node,$fsfile); /.$expression.q/ } /;
      }
    } elsif (defined $target_match_pos) {
      # this node is matched by some super-query
      if ($target_match_pos > $self->{parent_query_match_pos}) {
        # we need to postpone the evaluation of the whole sub-query up-till $matched_nodes->[$target_pos] is known
        $self->{postpone_subquery_till}=$target_match_pos if ($self->{postpone_subquery_till}||0)<$target_match_pos;
      }
      return $condition;
    } else {
      die "Node '$target' does not exist or belongs to a sub-query and cannot be referred from relation $relation $label at node no. $match_pos!\n";
    }
  } else {
    die "Unknown element $name ";
  }
}

sub serialize_target {
  my ($self,$target,$opts)=@_;
  my ($node)=$self->serialize_target2($target,$opts);
  return $node;
}
# returns the target node + file
sub serialize_target2 {
  my ($self,$target,$opts)=@_;
  my $target_match_pos = $self->{name2match_pos}{$target};
  my $this_pos = $opts->{query_pos};
  if (defined $opts->{id} and $target eq $opts->{id} and !$opts->{output_filter}) {
    return ('$node',qq{\$iterators[$this_pos]->file});
  }
  if (defined $target_match_pos) {
    $opts->{depends_on}{$target_match_pos}=1;
    return (
      ($opts->{output_filter} ? '$all_iterators->['.$target_match_pos.']->node' : '$matched_nodes->['.$target_match_pos.']'),
      '$all_iterators->['.$target_match_pos.']->file',
     );
  } else {
    if ($opts->{output_filter}) {
      die "Node '$target' does not exist or belongs to a sub-query and cannot be referred from an output filter!\n";
    } else {
      my $match_pos = $self->{pos2match_pos}[$this_pos];
      die "Node '$target' does not exist or belongs to a sub-query and cannot be referred from expression $opts->{expression} of node no. $match_pos!\n";
    }
  }
}

sub serialize_expression_pt {   # pt stands for parse tree
  my ($self,$pt,$opts)=@_;
  #use Data::Dumper;
  #print STDERR "parse tree: " . Dumper($pt) if $DEBUG > 1;
  my $this_node_id = $opts->{id};
  if (ref($pt)) {
    my $type = shift @$pt;
    if ($type eq 'EVERY') {
      if ($opts->{output_filter}) {
        die "Cannot use quantifier '*' in output filter: '$opts->{expression}'"
      }
      push @{$opts->{foreach}}, [2];
      return $self->serialize_expression_pt($pt->[0],$opts);
    } elsif ($type eq 'ATTR' or $type eq 'REF_ATTR') {
      my ($node,$node_type);
      if ($opts->{output_filter} and defined($opts->{column_count})) {
        die "Attribute reference cannot be used in output filter columns whose input is not the body of the query: '$opts->{expression}'"
      }
      if ($type eq 'REF_ATTR') {
        my $target = $pt->[0];
        $pt=$pt->[1];
        die "Error in attribute reference of node $target in expression $opts->{expression} of node '$this_node_id'"
          unless shift(@$pt) eq 'ATTR'; # not likely
        if ($target eq '$') {
          $node='$node';
          $node_type = $opts->{type};
        } else {
          $node=$self->serialize_target($target,$opts);
          $node_type = $self->{name2type}{$target};
        }
      } else {
        $node='$node';
        $node_type = $opts->{type};
      }
      # Below we resolve the attribute path according to the PML schema
      # we use $opts->{foreach} array to store information
      # about wrapper loops to be generated; elements of the foreach array are of the form:
      # [type, expression]
      # where type==2 and expressoin is undef for the primitive FORALL quantificator '*' (see 'EVERY')
      #       type==1 if expression produces a list (to be wrapped with a foreach + if defined)
      #       type==0 if expression produces at most one value (to be wrapped with an if defined)
      my $cast;
      if($pt->[0] =~ /^(.+)\?$/) {
        $cast = $1; shift @$pt;
      } elsif ($node_type=~m{^(?:([^/]+):)?\*$}) {
        my $node_types = $self->{type_mapper}->get_node_types($1);
        my @possibilities;
        my $path = join '/',map { ($_ eq '[]' or $_ eq 'content()') ? '#content' : $_ } @$pt;
        for my $nt (@$node_types) {
          my $decl = $self->{type_mapper}->get_decl_for($nt);
          my $attr_decl = $decl && $decl->find($path);
          $attr_decl=$attr_decl->get_content_decl
            while ($attr_decl and ($attr_decl->get_decl_type == PML_LIST_DECL or
                                   $attr_decl->get_decl_type == PML_ALT_DECL));
          push @possibilities,$nt if ($attr_decl and $attr_decl->is_atomic);
        }
        if (!@possibilities) {
          die "The attribute path '$path' is not valid for any node type matched by the '$node_type' wildcard: @$node_types\n";
        } else {
          $cast = '(?:'.join('|',@possibilities).')';
        }
      }
      my $attr=join '/',map { ($_ eq '[]' or $_ eq 'content()') ? '#content' : $_ } @$pt; # translate from PML-TQ notation to PML notation
      my $type_decl = $cast ? undef : $self->{type_mapper}->get_decl_for($node_type);
      my $ret;
      if ($cast) {
        # simplified implementation using Treex::PML::Node->all() method
        my $foreach = $opts->{foreach} ||= [];
        push @$foreach,
          [1, qq[(($node->type->get_decl_path =~ m{^\!].$cast.q[(?:\.type)?$}) ? ].
             $node.q[->all(qq(].quotemeta($attr).qq[)) : ())]
          ];
        $ret = '$var'.$#$foreach;
      } elsif (!$type_decl) {
        die "Cannot resolve attribute path $attr on an unknown node type '$node_type'\n";
      } else {
        my $decl = $type_decl;
        my $foreach = $opts->{foreach} ||= [];
        my $pexp=$node;
        my @steps = @$pt;
        my $step;
        my $decl_is = $decl->get_decl_type;
        while ($step = shift @steps) {
          if ($decl_is == PML_CONTAINER_DECL and ($step eq '[]' or $step eq 'content()') )  {
            $decl=$decl->get_content_decl;
            push @$foreach, [0,$pexp.'->{qq(#content)}'];
            $pexp = '$var'.$#$foreach;
          } elsif ($decl_is == PML_STRUCTURE_DECL or $decl_is == PML_CONTAINER_DECL) {
            my $m = $decl->get_member_by_name($step);
            if (defined $m) {
              $decl=$m->get_content_decl;
            } else {
              $m = $decl->get_member_by_name($step.'.rf');
              if ($m and ($m->get_role||'') eq '#KNIT') {
                $decl=$m->get_knit_content_decl;
              } elsif ($m and ($m->get_content_decl->get_role||'') eq '#KNIT') {
                $decl=$m->get_content_decl;
              } else {
                die "Error while compiling attribute path $attr for objects of type '$node_type': didn't find member '$step'\n" unless defined($m);
              }
            }
            #
            # value
            #
            push @$foreach, [0,$pexp.'->{qq('.quotemeta($step).')}'];
            $pexp = '$var'.$#$foreach;
            undef $step;
          } elsif ($decl_is == PML_SEQUENCE_DECL) {
            my $element = $step;
            my $pos;
            my $el_pos;
            if ($element=~s/^\[(\d+)\]//g) {
              $pos = $1 - 1;
            } elsif ($element=~s/\[\s*(\d+)\s*\]$//g) {
              $el_pos = $1 - 1;
            }
            my $e = $decl->get_element_by_name($element) || die "Error while compiling attribute path $attr for objects of type '$node_type': didn't find element '$element'\n";
            $decl = $e->get_content_decl;
            if (defined $pos) {
              push @$foreach, [0,$pexp.'->value_at('.$pos.')'];
            } elsif (defined $el_pos) {
              push @$foreach, [0,$pexp.'->values(qq('.quotemeta($element).'))->value_at('.$el_pos.')'];
            } else {
              push @$foreach, [1,$pexp.'->values(qq('.quotemeta($element).'))'];
            }
            $pexp = '$var'.$#$foreach;
            undef $step;
          } elsif ($decl_is == PML_LIST_DECL) {
            $decl = $decl->get_knit_content_decl;
            if (defined($step) and $step =~ /^\[([0-9]+)\]$/) {
              push @$foreach, [0,$pexp.'->['.($1-1).']'];
              $pexp = '$var'.$#$foreach;
              undef $step;
            } else {
              push @$foreach, [1,'@{'.$pexp.'}'];
              $pexp = '$var'.$#$foreach;
              if (defined($step) and $step eq 'LM') {
                undef $step;
              } else {
                $decl_is = $decl->get_decl_type;
                redo if defined($step);
              }
            }
          } elsif ($decl_is == PML_ALT_DECL) {
            $decl = $decl->get_content_decl;
            push @$foreach, [1,'PMLTQ::BtredEvaluator::AltV('.$pexp.')'];
            $pexp = '$var'.$#$foreach;
            if (defined($step) and $step eq 'AM') {
              undef $step;
            } else {
              $decl_is = $decl->get_decl_type;
              redo if defined($step);
            }
          # } elsif ($decl->is_atomic and $step eq '#content') {
            # $pexp = '$var'.$#$foreach;
          } else {
            die "Error while compiling attribute path $attr for objects of type '$node_type': Cannot apply location step '$step' to an atomic type '".$decl->get_decl_path."' ($decl_is)!\n";
          }
          $decl_is = $decl->get_decl_type;
          redo if (!@steps and (($decl_is == PML_ALT_DECL) or ($decl_is == PML_LIST_DECL)));
        }
        $ret = $pexp;           #'$var'.$#$foreach;
      }
      push @{$opts->{return_vars}||=[]},$ret;
      if ($opts->{output_filter}) {
        $ret =$self->serialize_column_node_ref($ret,$opts);
      }
      return $ret;
    } elsif ($type eq 'IF') {
      if ($opts->{is_first_filter}) {
        my ($condition,$if_true,$if_false) = @$pt;
        my $test = $self->serialize_element({
          %$opts,
          foreach =>undef,
          name=>$condition->{'#name'},
          condition => $condition,
          is_positive_conjunct => 1,
          no_node_ref => 1,
        });
        my $foreach = $opts->{foreach} ||= [];
        my ($vars1,$vars2,$if_true_foreach, $if_false_foreach)=([],[],[],[]);
        my $if_true_exp = $self->serialize_expression_pt($if_true,{%$opts, no_node_ref => 1, foreach=> $if_true_foreach, return_vars => $vars1});
        my $if_false_exp = $self->serialize_expression_pt($if_false,{%$opts, no_node_ref => 1, foreach=> $if_false_foreach, return_vars => $vars2});
        $if_true_exp = $self->foreach_wrap($if_true_foreach,
                                           q{ push @if_ret, }.
                                             (@$vars1 ?
                                                '('.join(' && ',map "defined($_)", @$vars1).') ? ('.$if_true_exp.') : ()'
                                                  : $if_true_exp)
                                            );
        $if_false_exp = $self->foreach_wrap($if_false_foreach,
                                            q{ push @if_ret, }.
                                              (@$vars2 ?
                                                 '('.join(' && ',map "defined($_)", @$vars2).') ? ('.$if_false_exp.') : ()'
                                                   : $if_false_exp)
                                             );
        push @$foreach,
          [1,
           qq[do { # IF
              my \@if_ret;
              if ($test) {
                # IF_TRUE
                $if_true_exp
              } else {
                # IF_FALSE
                $if_false_exp
              }
              \@if_ret
            }],
           [],                  # no defined() test
          ];
        my $ret = '$var'.$#$foreach;
        push @{$opts->{return_vars}||=[]},$ret;
        if ($opts->{output_filter}) {
          $ret =$self->serialize_column_node_ref($ret,$opts);
        }
        return $ret;
      } else {
        my ($condition,$if_true,$if_false) = @$pt;
        my $test = $self->serialize_element({
          %$opts,
          name=>$condition->{'#name'},
          condition => $condition,
          is_positive_conjunct => 1,
        });
        my $if_true_exp = $self->serialize_expression_pt($if_true,$opts);
        my $if_false_exp = $self->serialize_expression_pt($if_false,$opts);
        return qq{($test ? $if_true_exp : $if_false_exp)};
      }
    } elsif ($type eq 'ANALYTIC_FUNC') {
      my $name = shift @$pt;
      die "The analytic function ${name}() can only be used in an output filter expression!\n"
        unless $opts->{'output_filter'};
      die "The analytic function ${name}() cannot be used in the 'filter' clause!\n"
        if $opts->{'output_filter_where_clause'};
      my ($args,$over,$sort) = @$pt;
      $args||=[];
      if (($over and @$over==1 and $over->[0] eq 'ALL') or
          (!$opts->{is_local_filter} # to avoid infinitely deep recursion
             and !($over and @$over) and ($name =~ /^(rank|dense_rank|row_number)/))) {
        $over = ['0']; # the key can be arbitrary constant scalar
      }

      my $key = $name.'('.Data::Dumper->new([$args,$over,$sort],[qw(args over sort)])->Indent(0)->Dump.')';
      if ($name eq 'concat') {
        die "The analytic function $name takes one or two arguments concat(STR, SEPARATOR?) in the output filter expression $opts->{expression}; got @$args!\n" if @$args==0 or @$args>2;
        if (@$args==2) {
          unless (defined($args->[1]) and !ref($args->[1]) and $args->[1]!~/^\$/) {
            die "The second argument to concat(STR, SEPARATOR?) must be a literal string or number in $opts->{expression}!\n";
          }
        }
      } elsif (@$args>1) {
        die "The analytic function $name takes at most one argument in the output filter expression $opts->{expression}\n";
      } elsif ($name =~ /^(rank|dense_rank|row_number)/) {
        if (@$args>0) {
          die "The analytic function $name takes no arguments in the output filter expression $opts->{expression}; got @$args!\n";
        }
      } elsif (@$args==0) {
        if ($opts->{column_count} and !$opts->{is_first_filter}) {
          $args=['$1'];
        } else {
          $args=['0'];
        }
      }
      if ($name eq 'ratio') {
        return $self->serialize_expression_pt([
          'EXP', Treex::PML::CloneValue($args->[0]), 'div', [ 'ANALYTIC_FUNC', 'sum', $args, $over ] # ratio($1 over $2) translates to $1/sum($1 over $2)
         ] ,$opts);
      }
      if ($sort and @$sort and $name !~ /^(concat|rank|dense_rank|row_number)$/) {
        warn "The 'sort by' clause has no effect in analytic function ${name}() in expression $opts->{expression}!\n";
      }
      if ($over and @$over) {
        if ($opts->{local_aggregations}) {
          #
          # we now compile the columns just to
          # determine a key
          # so that we can merge two aggregations into one
          # and to obtain variables used in individual clauses
          #
          if (@$args==0 and ($name !~ /^(rank|dense_rank|row_number)/)) {
            if ($opts->{column_count} and !$opts->{is_first_filter}) {
              $args=['$1'];
            } else {
              $args=['0'];
            }
          }
          my @vars;
          my $i = -1;

          my @cols = map {
            $i++;
            my $j = 0;
            [map {
              my $ppt = Treex::PML::CloneValue($_);
              $self->serialize_expression_pt($ppt,{
                output_filter => 1,
                var_prefix => 'v',
                expression => $opts->{expression},
                column_count => $opts->{column_count},
                columns_used => $opts->{columns_used},
                aggregations => $opts->{aggregations},
                is_first_filter => $opts->{is_first_filter},
                foreach => $opts->{foreach},
                input_columns => $opts->{input_columns},
                vars_used => ($vars[$i][$j++]={}),
                local_aggregations => undef,
              })} @{$_||[]}
             ],
           } ($args,$over,($sort ? [map $_->[0], @$sort] : []));
          my $key = $name.':'.join(';',map join(',',@$_), @cols);
          my $num;
          if (exists $opts->{local_aggregations}{ $key }) {
            $num = $opts->{local_aggregations}{ $key }[0];
          } else {
            $num = scalar keys %{$opts->{local_aggregations}};
            $opts->{local_aggregations}{ $key } = [
              $num,
              $name,
              $args,
              $over,
              $sort,
              $cols[1],         # over (local group cols)
              $vars[1],         # variables used in over
             ];
          }
          my $var = '$l'.$num;
          $opts->{vars_used}{$var}=1;
          return $var;
        } else {
          die "Cannot use analytic function $name with an 'over' clause in this context in the output filter expression $opts->{expression}!\n";
        }
      } else {
        my ($var, $num);
        if ($opts->{old_aggregations} and exists $opts->{old_aggregations}{ $key }) {
          $num = $opts->{old_aggregations_first_column} +
            $opts->{old_aggregations}{ $key }[0] + 1;
          $var = '$v'.$num;
          $opts->{columns_used}{$num}=1;
          $opts->{vars_used}{$var}=1;
        } elsif ($opts->{aggregations} and exists $opts->{aggregations}{ $key }) {
          $num = $opts->{aggregations}{ $key }[0];
        } else {
          if (!defined $opts->{aggregations}) {
            die "Cannot use analytic function $name without an 'over' clause in this context in the output filter expression $opts->{expression} (@{[ %$opts ]})!\n";
          }
          $num =
            keys(%{$opts->{old_aggregations} || {}}) +
              keys(%{$opts->{aggregations}});
          $opts->{aggregations}{ $key } = [ $num, $name, Treex::PML::CloneValue($args), undef, Treex::PML::CloneValue($sort) ];
        }
        $var ||= '$a'.$num;
        $opts->{vars_used}{$var}=1;
        return $var;
      }
    } elsif ($type eq 'FUNC') {
      my $name = $pt->[0];
      my $args = $pt->[1];
      my $id;
      if ($name=~/^(?:descendants|lbrothers|rbrothers|sons|depth|depth_first_order|name|type_of)$/) {
        my $node;
        if ($args and @$args==1 and !ref($args->[0]) and $args->[0]=~s/^\$//) {
          $node=$self->serialize_target($args->[0],$opts);
        } elsif ($args and @$args) {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(\$node?)\n";
        } else {
          $node=$self->serialize_target($this_node_id,$opts);
        }
        my $ret = ($name eq 'descendants') ? qq{ scalar(${node}->descendants) }
          : ($name eq 'lbrothers')   ? q[ do { my $n = ].$node.q[; my $i=0; $i++ while ($n=$n->lbrother); $i } ]
            : ($name eq 'rbrothers')   ? q[ do { my $n = ].$node.q[; my $i=0; $i++ while ($n=$n->rbrother); $i } ]
              : ($name eq 'depth_first_order') ? q[ do { my $n = ].$node.q[; my $r=$n->root; my $i=0; $i++ while ($n!=$r and $r=$r->following); $i } ]
                : ($name eq 'sons')        ? qq{ scalar(${node}->children) }
                  : ($name eq 'depth')       ? qq{ ${node}->level }
                    : ($name eq 'name')       ? qq{ ${node}->{'#name'} }
                      : ($name eq 'type_of')       ? q[ do { my $t=].$node.q[->type->get_decl_path; $t=~s/^\!|\.type$//g; $t } ]
                        # FIXME: need to pass fsfile as well
                        : die "PMLTQ internal error while compiling expression: should never get here!";
        if ($opts->{output_filter}) {
          die "Cannot use function '$name' at this point of an output filter: '$opts->{expression}'\n"
            if defined($opts->{column_count});
          return $self->serialize_column_node_ref($ret,$opts);
        } else {
          return $ret;
        }
      } elsif ($name =~ /^order_span_(?:min|max)$/) {
        my $node;
        my $node_type;
        if ($args and @$args==1 and !ref($args->[0]) and $args->[0]=~s/^\$//) {
          $node_type = $self->{name2type}{$args->[0]};
          $node=$self->serialize_target($args->[0],$opts);
        } elsif ($args and @$args) {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(\$node?)\n";
        } else {
          $node_type = $opts->{type};
          $node=$self->serialize_target($this_node_id,$opts);
        }
        my $attr;
        if (defined ($node_type)) {
          my $decl = $self->{type_mapper}->get_decl_for($node_type);
          if ($decl->get_decl_type == PML_ELEMENT_DECL) {
            $decl = $decl->get_content_decl;
          }
          my ($m)=$decl->find_members_by_role('#ORDER');
          $attr = defined($m) && $m->get_name
        }
        if ($attr) {
          $attr=quotemeta($attr);
          return qq{ ${node}->{qq($attr)} }
        } else {
          return qq{ \$self->get_cached_$name(${node}) };
        }
      } elsif ($name =~ /^(file|tree_no|address|id)$/) {
        my $ref;
        if ($args and @$args) {
          $ref = $args->[0];
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(\$node?)\n"
            if (@$args>1 or not $ref=~s/^\$(?![0-9])//);
        } else {
          $ref = $this_node_id;
        }
        my ($target,$file) = $self->serialize_target2($ref,$opts);
        my $ret;
        if ($name eq 'file') {
          $ret = qq{$file->filename};
        } else {
          if ($name eq 'id') {
            my $decl = $self->{type_mapper}->get_decl_for( $self->{name2type}{$ref} );
            if ($decl->get_decl_type == PML_ELEMENT_DECL) {
              $decl = $decl->get_content_decl;
            }
            my ($m)=$decl->find_members_by_role('#ID');
            my $id_attr = defined($m) && $m->get_name;
            $ret= defined $id_attr ? $target.qq{->{q($id_attr)}} : 'undef';
          } elsif ($name eq 'tree_no') {
            # FIXME: die if this function is root on a member node
            $ret= qq{1+Treex::PML::Index($file->treeList,$target->root)};
          } elsif ($name eq 'address') {
            # FIXME: die if this function is root on a member node
            $ret= qq{TredMacro::ThisAddress($target,$file)};
          } else {
            die "Function ${name}() not yet implemented!\n";
          }
        }
        if ($opts->{output_filter}) {
          die "Cannot use function '$name' at this point of an output filter: '$opts->{expression}'\n"
            if defined($opts->{column_count});
          return $self->serialize_column_node_ref($ret,$opts);
        } else {
          return $ret;
        }
      } elsif ($name=~/^(?:lower|upper|length)$/) {
        if ($args and @$args==1) {
          my $func = $name eq 'lower' ? 'lc'
            : $name eq 'upper' ? 'uc'
              : $name;
          return $func.'('
            .  $self->serialize_expression_pt($args->[0],$opts)
              . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(string)\n";
        }
      } elsif ($name=~/^(?:abs|floor|ceil|exp|sqrt|ln)$/) {
        if ($args and @$args==1) {
          my $func = $name eq 'ln' ? 'log' : $name;
          return $func.'('
            .  $self->serialize_expression_pt($args->[0],$opts)
              . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(number)\n";
        }
      } elsif ($name =~ /^(?:log|power)$/) {
        my $func = $name eq 'log' ? 'log(%2$s)/log(%1$s)' : '(%s ** %s)';
        if ($args and @$args==1 or @$args==2) {
          my @args = map $self->serialize_expression_pt($_,$opts), @$args;
          @args = (10,@args) if @args==1;
          return sprintf($func, @args);
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(base,number) or ${name}(number)\n";
        }
      } elsif ($name=~/^(?:round|trunc)$/) {
        if ($args and @$args and @$args<3) {
          return $name.'('
            .  join(',',map { $self->serialize_expression_pt($_,$opts) } @$args)
              . ')';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: ${name}(string)\n";
        }
      } elsif ($name eq 'percnt') {
        if ($args and @$args>0 and @$args<3) {
          my @args = map { $self->serialize_expression_pt($_,$opts) } @$args;
          return 'round(100*('.$args[0].')'
            . (@args>1 ? ','.$args[1] : '').q[)];
        } else {
          die "Wrong arguments for function percnt() in expression $opts->{expression} of node '$this_node_id'!\nUsage: percnt(number,precision?)\n";
        }
      } elsif ($name eq 'substr') {
        if ($args and @$args>1 and @$args<4) {
          return 'substr('
            .  join(',', map { $self->serialize_expression_pt($_,$opts) } @$args)
              . ')';
        } else {
          die "Wrong arguments for function substr() in expression $opts->{expression} of node '$this_node_id'!\nUsage: substr(string,from,length?)\n";
        }

      } elsif ($name eq 'replace') {
        if ($args and @$args==3) {
          my @args = map { $self->serialize_expression_pt($_,$opts) } @$args;
          return 'do{ my ($str,$from,$to) = (' .join(',', @args).'); $str=~s/\Q$from/$to/g; $str }';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,target,replacement)\n"
        }
      } elsif ($name eq 'tr') {
        if ($args and @$args==3) {
          my @args = map { $self->serialize_expression_pt($_,$opts) } @$args;
          return 'do{ my ($str,$from,$to) = (' .join(',', @args).'); $from=~s{/}{\\/}g; $to=~s{/}{\\/}g; eval qq{$str=~tr/$from/$to/, 1} or die $@; $str; }';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,from_chars,to_chars)\n"
        }
      } elsif ($name eq 'match') {
        if ($args and @$args>=2 and @$args<=3) {
          my @args = map { $self->serialize_expression_pt($_,$opts) } @$args[0,1];
          my $match_opts = $args->[2];
          if (defined($match_opts) and (ref($match_opts) or $match_opts!~/^\s*'[icnm]*'\s*$/)) {
            die "Wrong match options [$match_opts] for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,pattern,options?), where options is a literal string consisting only of characters from the set [icnm]\n";
          }
          $match_opts=~s/^\s*'([icnm]*)'\s*$/$1/;
          return 'do{ my ($str,$regexp) = (' .join(',', @args).'); $str=~/($regexp)/'.$match_opts.'  ? $1 : undef }';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,from_chars,to_chars)\n"
        }
      } elsif ($name eq 'substitute') {
        if ($args and @$args>=3 and @$args<=4) {
          my @args = map { $self->serialize_expression_pt($_,$opts) } @$args[0..2];
          my $match_opts = $args->[3];
          if (defined($match_opts) and (ref($match_opts) or $match_opts!~/^\s*'[icnmg]*'\s*$/)) {
            die "Wrong match options [$match_opts] for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,pattern,options?), where options is a literal string consisting only of characters from the set [icnmg]\n";
          }
          $match_opts=~s/^\s*'([icnmg]*)'\s*$/$1/;
          return 'do{ my ($str,$regexp,$replacement) = (' .join(',', @args).'); $regexp=~s{/}{\\\\/}g; $replacement=~s{/}{\\\\/}g; $replacement=~s{(\\\\([0-9])|\\\\[^0-9])}{defined $2 ? q($).$2 : $1}ge; eval qq{\$str=~s/$regexp/$replacement/'.$match_opts.'}; $str }';
        } else {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(string,from_chars,to_chars)\n"
        }
      } elsif ($name eq 'first_defined') {
        if (!$args or @$args<2) {
          die "Wrong arguments for function ${name}() in expression $opts->{expression} of node '$this_node_id'!\nUsage: $name(value1,value2,...)\n";
        }
        my $foreach = $opts->{foreach} ||= [];
        my @vars;
        for my $arg (@$args) {
          my $vars=[];
          push @$foreach, [0, $self->serialize_expression_pt($arg,{%$opts,no_node_ref=>1,return_vars=>$vars}),$vars];
          push @vars,'$var'.$#$foreach;
        }
        push @$foreach,
          [0,
           '('.join(' ',map qq[defined($_) ? $_ :],@vars).' undef)',
           [] # no defined() test on variables
          ];
        my $ret = '$var'.$#$foreach;
        push @{$opts->{return_vars}||=[]},$ret;
        if ($opts->{output_filter}) {
          $ret =$self->serialize_column_node_ref($ret,$opts);
        }
        return $ret;
      } else {
        die "$name() NOT YET IMPLEMENTED!\n";
      }
    } elsif ($type eq 'EXP') {
      my $out.='(';
      while (@$pt) {
        $out.=$self->serialize_expression_pt(shift @$pt,$opts);
        if (@$pt) {             # op
          my $op = shift @$pt;
          if ($op eq 'div') {
            $op='/'
          } elsif ($op eq 'mod') {
            $op='%'
          } elsif ($op eq '&') {
            $op=' . '
          } elsif ($op !~ /[-+*]/) {
            die "Urecognized operator '$op' in expression $opts->{expression} of node '$this_node_id'\n";
          }
          $out.=$op;
        }
      }
      $out.=')';
      return $out;
    } elsif ($type eq 'SET') {
      return '('
        .  join(',', map { $self->serialize_expression_pt($_,$opts) } @$pt)
          . ')';
    }
  } else {
    if ($pt=~/^[-0-9']/) {      # literal
      return qq( $pt );
    } elsif ($pt=~s/^(['"])(.*)\1$/$2/s) { # literal string
      $pt=~s/\\([^\\])/$1/sg;
      $pt=~s/'/\\'/sg;
      $pt=q{'}.$pt.q{'};
    } elsif ($pt=~s/^\$//) {    # a plain variable
      if ($pt eq '$') {
        if ($opts->{output_filter}) {
          die "Cannot use node reference '$$' in output filters: '$opts->{expression}'\n";
        } else {
          return '$node';
        }
      } elsif ($pt =~ /^[1-9][0-9]*$/) { #column reference
        die "Column reference \$$pt can only be used in an output filter; error in expression '$opts->{expression}' of node '$this_node_id'\n"
          unless $opts->{'output_filter'};
        die "Column reference \$$pt used at position where there is yet no column to refer to\n"
          unless defined $opts->{'column_count'};
        die "Column reference \$$pt used at position where there are only $opts->{'column_count'} columns\n"
          if $pt > $opts->{'column_count'};
        my $var = '$'.$opts->{var_prefix}.$pt.($opts->{var_suffix}||'');
        $opts->{columns_used}{$pt}=1;
        $opts->{vars_used}{$var}=1;
        return $var;
      } else {
        my ($ret_node,$ret_file) = $self->serialize_target2($pt,$opts);
        if ($opts->{output_filter}) {
          die "Cannot use node reference '$pt' at this point of an output filter: '$opts->{expression}'\n"
            if defined($opts->{column_count});
          my $ret = qq{TredMacro::ThisAddress($ret_node,$ret_file)};
          return $self->serialize_column_node_ref($ret,$opts);
        } else {
          return $ret_node;
        }
      }
    } else {                    # unrecognized token
      die "Token '$pt' not recognized in expression $opts->{expression} of node '$this_node_id'\n";
    }
  }
}

sub serialize_column_node_ref {
  my ($self, $ret, $opts)=@_;
  return $ret if $opts->{no_node_ref};
  push @{$opts->{input_columns}},$ret;
  my $i = scalar @{$opts->{input_columns}};
  my $var = '$'.$opts->{var_prefix}.$i.($opts->{var_suffix}||'');
  $opts->{columns_used}{ $i }=1;
  $opts->{vars_used}{$var}=1;
  return $var;
}

sub serialize_expression {
  my ($self,$opts)=@_;
  my $pt = PMLTQ::Common::parse_expression($opts->{expression}); # $pt stands for parse tree
  die "Invalid expression '$opts->{expression}' on node '$opts->{id}'" unless defined $pt;
  return $self->serialize_expression_pt($pt,$opts);
}

sub test_occurrences {
  my ($self,$seed,$fsfile,$test_max) = (shift,shift,shift,shift);
  $self->reset();
  my $count=0;
  print STDERR "<subquery> $seed->{id},$test_max.\n" if $DEBUG > 4;
  while ($self->find_next_match({boolean => 1, subquery => 1, seed=>$seed, fsfile=>$fsfile})) {
    $count++;
    last unless $count<=$test_max;
    $self->backtrack(0);        # this is here to count on DISTINCT
    # roots of the subquery (i.e. the node with occurrences specified).
  }
  my ($min,$max_plus1)=@_;
  my $ret=0;
  while (@_) {
    ($min,$max_plus1)=(shift,shift);
    if ((!defined($min) || $count>=$min) and
          (!defined($max_plus1) || $count<$max_plus1)) {
      $ret=1;
      last;
    }
  }
  print STDERR "occurrences: >=$count ($ret)\n" if $DEBUG > 4;
  print STDERR "</subquery>\n" if $DEBUG > 4;
  $self->reset() if $count;
  return $ret;
}

sub backtrack {
  my ($self,$pos)=@_;
  my $query_pos = \$self->{query_pos}; # a scalar reference
  return unless $$query_pos >= $pos;

  my $iterators = $self->{iterators};
  my $matched_nodes = $self->{matched_nodes};
  my $pos2match_pos = $self->{pos2match_pos};
  my $have = $self->{have};
  my $iterator;
  my $node;
  while ($pos<$$query_pos) {
    $node = delete $matched_nodes->[$pos2match_pos->[$$query_pos]];
    delete $have->{$node} if $node;
    $$query_pos--;
  }
  return 1;
}
sub find_next_match {
  my ($self,$opts)=@_;
  $opts||={};
  $STOP = 0 unless $opts->{subquery};
  my $iterators = $self->{iterators};
  my $parent_pos = $self->{parent_pos};
  my $query_pos = \$self->{query_pos}; # a scalar reference
  my $matched_nodes = $self->{matched_nodes};
  my $pos2match_pos = $self->{pos2match_pos};
  my $is_overlapping = $self->{is_overlapping};
  my $have = $self->{have};

  my $iterator = $iterators->[$$query_pos];
  my $node = $iterator->node;
  if ($node) {
    delete $have->{$node};
     print STDERR ("iterate $$query_pos $iterator: $self->{debug}[$$query_pos]\n") if $DEBUG;
    $node
      = $matched_nodes->[$pos2match_pos->[$$query_pos]]
      = $iterator->next;
    $have->{$node}=1 if ($node and !$is_overlapping->[$$query_pos]);
  } elsif ($$query_pos==0) {
    # first
    print STDERR "Starting subquery on $opts->{seed}->{id} $opts->{seed}->{t_lemma}.$opts->{seed}->{functor}\n" if $opts->{seed} and $DEBUG;
    $node
      = $matched_nodes->[$pos2match_pos->[$$query_pos]]
      = $iterator->start( $opts->{seed}, $opts->{fsfile} );
    $have->{$node}=1 if $node and !$is_overlapping->[$$query_pos];
  }
  while (1) {
    return if ($STOP);
    if (!$node) {
      if ($$query_pos) {
        # backtrack
        $matched_nodes->[$pos2match_pos->[$$query_pos]]=undef;
        $$query_pos--;          # backtrack
        print STDERR ("backtrack to $$query_pos\n") if $DEBUG > 4;
        $iterator=$iterators->[$$query_pos];

        $node = $iterator->node;
        delete $have->{$node} if $node and !$is_overlapping->[$$query_pos];

        print STDERR ("iterate $$query_pos $iterator: $self->{debug}[$$query_pos]\n") if $DEBUG;
        $node
          = $matched_nodes->[$pos2match_pos->[$$query_pos]]
            = $iterator->next;
        $have->{$node}=1 if $node and !$is_overlapping->[$$query_pos];
        next;
      } else {
        print STDERR "no match\n" if $DEBUG > 4;
        return;                 # NO RESULT
      }
    } else {
      print STDERR ("match $node->{id} [$$query_pos,$pos2match_pos->[$$query_pos]]: $node->{mwes}.$node->{t_lemma}.$node->{functor}\n")
        if ref($node) and  $DEBUG > 4;

      if ($$query_pos<$#$iterators) {
        $$query_pos++;
        $iterator = $iterators->[ $parent_pos->[$$query_pos] ];
        my ($seed,$fsfile) = ($iterator->node, $iterator->file);
        print STDERR 'SEED ',$seed->{id},".\n" if $DEBUG > 4;
        $iterator = $iterators->[$$query_pos];
        $node
          = $matched_nodes->[$pos2match_pos->[$$query_pos]]
            = $iterator->start($seed,$fsfile);
        print STDERR ("restart $$query_pos $iterator from $seed->{id},$seed->{t_lemma}.$seed->{functor} $self->{debug}[$$query_pos]\n") if $DEBUG;
        print STDERR "res_ref: " .(ref($node)) ."\n" if $DEBUG;
        #print STDERR Dumper($node);
        $have->{$node}=1 if $node and !$is_overlapping->[$$query_pos];
        next;

      } else {
        print STDERR ("complete match [bool: $opts->{boolean}]\n") if $DEBUG > 4;
        # complete match:
        if ($opts->{boolean}) {
          return 1;
        } else {
          $self->{result_files}=[map { $_->file } @$iterators];
          return $self->{results}=[map { $_->node } @$iterators];
        }
      }
    }
  }
  return;
}

sub plan_query {
  my ($type_mapper,$query_tree)=@_;
  require PMLTQ::Planner;
  $query_tree||=$TredMacro::root;
  PMLTQ::Planner::name_all_query_nodes($query_tree);
  my @query_nodes=PMLTQ::Common::FilterQueryNodes($query_tree);
  PMLTQ::Planner::plan($type_mapper,\@query_nodes,$query_tree);
}

1; # End of PMLTQ::BtredEvaluator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::BtredEvaluator - Pure perl evaluator of PML-TQ queries based on headless implementation of TrEd called Btred

=head1 VERSION

version 3.0.2

=head1 IMPLEMENTATION

1. find in the query graph an oriented sceleton tree, possibly using
Kruskal and some weighting rules favoring easy to follow types of
edges (relations) with minimum number of potential target nodes
(e.g. parent, ancestor a/lex.rf are better than child, descendant or
a/aux.rf, and far better then their negated counterparts).

2. Order sibling nodes of this tree by similar algorithm so that all
relations between these nodes go from right bottom to left top (using
reversing where possible) and the result is near optimal using similar
weighting as above. This may be done only for relations not occuring
in condition formulas.

3. For each relation between nodes that occurs in a condition formula,
assume that the relation is or is not satisfied so that the truth
value of the condition is not decreased (whether to take the formula
negatively or positively is probably easy to compute since we may
eliminate all negations of non-atomic subformulas and then aim for
TRUE value of the respective literal; that is, we only count the
number of negations on the path from the root of the expression to the
predicate representing the relational constraint and assume TRUE for
even numbers and FALSE for odd numbers).

The actual truth values of these relations will be verified only after
all query nodes have been matched (or maybe for each node as soon as
all nodes it refers to have been matched).

4. The query context consists of:

- the node in the query-tree being matched (current query node)

- association of the previously matched query nodes with result node iterators

- information about unresolved relational constraints on already
  matched nodes

5. the search starts by creating an initial query context and a simple
iterator for the root query node matches

6. in each step one of the following cases occurs:

- the iterator for the current query node is empty
  -> backtrack: return to the state of the context of the previous query node
     and iterate the associated iterator
  -> fail if there is no previous query node

- the iterator returns a node:

  - check relational constraints depending on this node.
    If any of them invalidates the condition on an already matched node,
    itereate and repeat 6

  - if there is a following query node, make it the current query node
    and repeat 6

  - otherwise: we have a complete match. Return the match, back-track
    the context to the root-node and iterate the root-node iterator.
    Then repeat 6.

Note: #occurrences are to be implemented as sub-queries that are
processed along with other conditions within the simple iterators.
The relation predicates from these sub-queries to the out-side trees
are treated as predicate relations in complex relations and are only
resolved as soon as all required query nodes are matched.

=head1 TODO

the code generated from the if() function should read instead (for
both node constraint and filter code)

if (
  do {
    # compute condition (using several nested foreach loops if needed)
    $reslt
  }) {
  # condition where if() is replaced by IF_TRUE
} else {
  # condition where if() is replaced by IF_FALSE
}

# or:

do {
  my @varX =
  do {
    # compute condition (using several nested foreach loops if needed)
    $reslt
  }) ? do {
    # all IF_TRUE values
  } : do {
    # all IF_FALSE values
  };
  foreach $varX (@varX) {
    # ...
  }
}

if ($clone_before_plan) {
  use Data::Dumper;$Data::Dumper::Deparse = 1;$Data::Dumper::Maxdepth = 3;print Dumper $query_tree;
  #$query_tree=Treex::PML::Factory->createFSFormat()->clone_subtree($query_tree); ???????
  $query_tree=Treex::PML::FSFormat->clone_subtree($query_tree);
}

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
