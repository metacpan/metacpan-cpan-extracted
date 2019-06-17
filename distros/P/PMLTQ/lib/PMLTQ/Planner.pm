package PMLTQ::Planner;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Planner::VERSION = '3.0.2';
# ABSTRACT: Optimalizing search trees for BtredEvaluator


use 5.006;
use strict;
use warnings;
use vars qw(%weight %reverse);

use Graph;
use Graph::ChuLiuEdmonds;
use PMLTQ::Relation;

our $ORDER_SIBLINGS=1;

%weight = (
  'user-defined:a/lex.rf' => 1,
  'user-defined:a/aux.rf' => 2,
  'user-defined:coref_text.rf' => 1,
  'user-defined:coref_gram.rf' => 1,
  'user-defined:compl.rf' => 1,
  'user-defined:a/tree.rf' => 1,
  'descendant' => 30,
  'ancestor' => 8,
  'parent' => 0.5,
  'sibling' => 15,
  'child' => 10,
  'order-precedes' => 1000,
  'order-follows' => 1000,
  'depth-first-precedes' => 100,
  'depth-first-follows' => 100,
  'same-tree-as' => 40,
  'same-document-as' => 10000,
 );



sub SeqV { ref($_[0]) ? $_[0]->elements : () }

sub name_all_query_nodes {
  my ($tree)=@_;
  my @nodes = grep { $_->{'#name'} =~ /^(?:node|subquery)$/ } $tree->descendants;
  my $max=0;
  my %name2node = map {
    my $n=$_->{name};
    $max=$1+1 if defined($n) and $n=~/^n([0-9]+)$/ and $1>=$max;
    (defined($n) and length($n)) ? ($n=>$_) : ()
  } @nodes;

  my $name = 'n0';
  for my $node (@nodes) {
    my $n=$node->{name};
    unless (defined($n) and length($n)) {
      $node->{name}= $n ='n'.($max++);
      $name2node{$n}=$node;
    }
  }
  return \%name2node;
}
sub weight {
  my ($schema_name,$node_type,$rel)=@_;
  my $name = $rel->name;
  my $w;
  if ($name eq 'user-defined') {
    $w = PMLTQ::Relation->iterator_weight($schema_name,$node_type,$name) || $weight{'user-defined:'.$name};
  } else {
    $w = $weight{$name};
  }
  return $w if defined $w;
  # warn "do not have weight for edge: '$name'; assuming 5\n";
  return 5;
}
sub reversed_rel {
  my ($schema_name,$start_type,$ref)=@_;
  my ($rel)=SeqV($ref->{relation});
  my $name = $rel->name;
  if ($name eq 'user-defined') {
    $name=$rel->value->{category}.':'.$rel->value->{label};
  }
  my $rname = PMLTQ::Common::reversed_relation($schema_name,$start_type,$name);
  if (defined $rname) {
    my $relv = $rel->value;
    my $revv = Treex::PML::CloneValue($relv);
    if ($rname =~s/^user-defined://) {
      $revv->{label}=$rname;
      $rname = 'user-defined';
    } elsif ($rname =~s/^(.*)://) {
      my $category = $1;
      $revv->{category}=$category;
      $revv->{label}=$rname;
      $rname = 'user-defined';
    }
    if ($name eq $rname) {
      # attempt to reverse the min/max lengths
      ($revv->{min_length},$revv->{max_length}) =
	map { defined($_) ? (0-$_) : undef }
	  ($relv->{max_length},$relv->{min_length});
    }
    return Treex::PML::Seq::Element->new( $rname, $revv );
  } else {
    return;
  }
}

sub plan {
  my ($type_mapper,$query_nodes,$query_tree,$query_root)=@_;
  die 'usage: plan($type_mapper,\@nodes,$query_tree,$query_node?)' unless
    $type_mapper and ref($query_nodes) eq 'ARRAY' and $query_tree;
  my %node2pos = map { $query_nodes->[$_] => $_ } 0..$#$query_nodes;
  my %name2pos = map {
    my $name = $query_nodes->[$_]->{name};
    (defined($name) and length($name)) ? ($name=>$_) : ()
  } 0..$#$query_nodes;
  my $root_pos = defined($query_root) ? $node2pos{$query_root} : undef;

  my @edges;
  my @parent;
  my @parent_edge;
  my @is_member_node;
  for my $i (0..$#$query_nodes) {
    my $n = $query_nodes->[$i];
    my $parent = $n->parent;
    my $p = $node2pos{$parent};
    if (PMLTQ::Common::IsMemberNode($n)) {
      while (defined($p) and PMLTQ::Common::IsMemberNode($parent)) {
	$parent = $parent->parent;
	$p = $node2pos{$parent};
      }
      $parent[$i]=$p; # this is the node to which we will collapse the member node
      $is_member_node[$i] = 1;
      next;
    } else {
      $parent[$i]=$p;
    }

    # turn node's relation into parent's extra-relation
    if (defined $p) {
      my ($rel) = SeqV($n->{relation});
      $rel||=Treex::PML::Seq::Element->new('child', Treex::PML::Factory->createContainer());
      $parent_edge[$i]=$rel;
      delete $n->{relation};
      my $ref = Treex::PML::Factory->createNode();
      $ref->paste_on($parent);
      $ref->{'#name'} = 'ref';
      PMLTQ::Common::DetermineNodeType($ref);
      $ref->{relation}=Treex::PML::Factory->createSeq([$rel]);
      $ref->{target} = $n->{name};
    }
  }

  for my $i (0..$#$query_nodes) {
    my $n = $query_nodes->[$i];
    for my $ref (grep { $_->{'#name'} eq 'ref' } $n->children) {
      my $target = $ref->{target};
      my ($rel)=SeqV($ref->{relation});
      next unless $rel;
      my $t = $name2pos{$target};
      my $no_reverse;
      my $no_direct;
      my $tn = $query_nodes->[$t];
      my $sn = $n;
      my $s = $i;
      my $edge_data=[$i,$t];
      if ($is_member_node[$i]) {
	$s = $parent[$i];
	$sn = $query_nodes->[$s];
	$no_reverse=1;
      }
      if ($is_member_node[$t]) {
	$t = $parent[$t];
	$tn = $query_nodes->[$t];
	$no_direct=1;
      }
      my $tnp=$tn->parent;
      next unless defined $t and defined $s and $t!=$s;

      if ($n->{optional} or $tn->{optional} or ($tnp and $tnp->{optional})) {
	# only direct edges can go in and out of an optional node
	# and only direct edge can go to a child of an optional node
	next unless $rel==$parent_edge[$t];
	$no_reverse=1;
      }

      # similarly for member nodes:
      # only one edge can come to a member node and it must be the member edge itself
      unless ($no_direct) {
	push @edges,{
	  from => $s,
	  to => $t,
	  ref=>$ref,
	  real_start=>$edge_data->[0],
	  real_end=>$edge_data->[1],
	  weight=>weight($type_mapper->get_schema_name_for($sn->{'node-type'}),$sn->{'node-type'},$rel),
	} unless defined($root_pos) and $t==$root_pos;
      }
      unless ($no_reverse or (defined($root_pos) and $s==$root_pos)) {
	my $reversed = reversed_rel($type_mapper->get_schema_name_for($tn->{'node-type'}),$tn->{'node-type'},$ref);
	if (defined $reversed) {
	  push @edges,{
	  from => $t,
	  to => $s,
	  ref=>$reversed,
	  reverse_of_ref => $ref,
	  real_start=>$edge_data->[1],
	  real_end=>$edge_data->[0],
	  weight => weight($type_mapper->get_schema_name_for($tn->{'node-type'}),$tn->{'node-type'},$reversed),
	};
	}
      }
    }
  }
  undef @parent_edge; # not needed anymore
  my $g=Graph->new(directed=>1);
  for my $i (0..$#$query_nodes) {
    $g->add_vertex($i) unless $is_member_node[$i];
  }
  my %edges;
  for my $e (@edges) {
    my $has = $g->has_edge($e->{from},$e->{to});
    my $w = $e->{weight}||100000;
    if (!$has or $g->get_edge_weight($e->{from},$e->{to})>$w) {
      $edges{$e->{from}}{$e->{to}}=$e;
      $g->delete_edge($e->{from},$e->{to}) if $has;
      $g->add_weighted_edge($e->{from},$e->{to}, $w);
    }
  }
  my $mst=$g->MST_ChuLiuEdmonds();
#ifdef TRED
#    TredMacro::ChangingFile(1);
#endif
#    return;

  for my $i (0..$#$query_nodes) {
    next if $is_member_node[$i];
    $query_nodes->[$i]->cut();
  }
  my $last_ref=0;
  my @roots;
  my %w;
  for my $i (0..$#$query_nodes) {
    next if $is_member_node[$i];
    my $qn = $query_nodes->[$i];
    my $e;
    if ($mst->in_degree($i)==0) {
      $qn->paste_on($query_tree);
      push @roots,$qn;
    } else {
      my ($edge) = $mst->edges_to($i);
      $e = $edges{$edge->[0]}{$i};
      if ($ORDER_SIBLINGS) {
	$qn->{'.edge_weight'}=
	  $mst->get_edge_weight($edge->[0],$edge->[1]) / $mst->in_degree($i);
	$qn->paste_on($query_nodes->[$e->{real_start}],'.edge_weight');
      } else {
	$qn->paste_on($query_nodes->[$e->{real_start}]);
      }
    }

    # now turn the selected extra-relation into relation
    # of $qn
    if (defined $e) {
      my $ref = $e->{ref};
      my $rel;
      if ($e->{reverse_of_ref}) {
	$rel = $ref; # $ref is a 'Treex::PML::Seq::Element'
	$ref = $e->{reverse_of_ref};
      } else {
	($rel) = SeqV($ref->{relation});
      }
      $ref->cut()->destroy();
      $qn->{relation} = Treex::PML::Factory->createSeq([$rel]);
    }
  }
  return \@roots;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Planner - Optimalizing search trees for BtredEvaluator

=head1 VERSION

version 3.0.2

=head1 DESCRIPTION

This module provides a simple query planning for BtredEvaluator and
can also be used to transform a query-forest to a query-tree (if
possible). We use directed MST to find a spanning tree.

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
