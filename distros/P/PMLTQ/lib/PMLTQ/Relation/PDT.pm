package PMLTQ::Relation::PDT;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::PDT::VERSION = '3.0.2';
# ABSTRACT: PDT user defined relations

use warnings;
use strict;

require PMLTQ::Relation::PDT::AEChildIterator;
require PMLTQ::Relation::PDT::AEParentIterator;
require PMLTQ::Relation::PDT::ALexOrAuxRFIterator;
require PMLTQ::Relation::PDT::TEChildIterator;
require PMLTQ::Relation::PDT::TEParentIterator;


#
# This file implements the following user-defined relations for PML-TQ
#
# - a/lex.rf|a/aux.rf
# - eparent (both t-layer and a-layer)
# - echild (both t-layer and a-layer)
#
#################################################


######## A Layer


sub ADiveAuxCP ($){
  $_[0]->{afun}=~/^Aux[CP]/ ? 1 : 0;
}#DiveAuxCP


sub A_ExpandCoordGetEParents { # node through
  my ($node,$through)=@_;
  my @toCheck = $node->children;
  my @checked;
  while (@toCheck) {
    @toCheck=map {
      if (&$through($_)) { $_->children() }
      elsif($_->{afun}=~/Coord|Apos/&&$_->{is_member}){ A_ExpandCoordGetEParents($_,$through) }
      elsif($_->{is_member}){ push @checked,$_;() }
      else{()}
    }@toCheck;
  }
  return @checked;
}# A_ExpandCoordGetEParents

sub AGetEParents { # node through
  my ($node,$through)=@_;
  my $init_node = $node; # only used for reporting errors
  return() if !$node or $node->{afun}=~/^(?:Coord|Apos|Aux[SCP])$/;
  if ($node->{is_member}) { # go to coordination head
    while ($node->{afun}!~/Coord|Apos|AuxS/ or $node->{is_member}) {
      $node=$node->parent;
      if (!$node) {
  print STDERR
    "GetEParents: Error - no coordination head $init_node->{AID}: ".ThisAddress($init_node)."\n";
        return();
      } elsif($node->{afun} eq 'AuxS') {
  print STDERR
    "GetEParents: Error - no coordination head $node->{AID}: ".ThisAddress($node)."\n";
        return();
      }
    }
  }
  if (&$through($node->parent)) { # skip 'through' nodes
    while ($node and &$through($node->parent)) {
      $node=$node->parent;
    }
  }
  return unless $node;
  $node=$node->parent;
  return unless $node;
  return $node if $node->{afun}!~/Coord|Apos/;
  A_ExpandCoordGetEParents($node,$through);
} # AGetEParents


sub A_FilterEChildren{ # node dive suff from
  my ($node,$dive,$suff,$from)=@_;
  my @sons;
  $node=$node->firstson;
  while ($node) {
#    return @sons if $suff && @sons; # comment this line to get all members
    unless ($node==$from){ # on the way up do not go back down again
      if (!$suff&&$node->{afun}=~/Coord|Apos/&&!$node->{is_member}
    or$suff&&$node->{afun}=~/Coord|Apos/&&$node->{is_member}) {
  push @sons,A_FilterEChildren($node,$dive,1,0)
      } elsif (&$dive($node) and $node->firstson){
  push @sons,A_FilterEChildren($node,$dive,$suff,0);
      } elsif(($suff&&$node->{is_member})
        ||(!$suff&&!$node->{is_member})){ # this we are looking for
  push @sons,$node;
      }
    } # unless node == from
    $node=$node->rbrother;
  }
  @sons;
} # A_FilterEChildren

sub AGetEChildren{ # node dive
  my ($node,$dive)=@_;
  return() if !$node or $node->{afun}=~/^(?:Coord|Apos|Aux[SCP])$/;
  my @sons;
  my $from;
  $dive = sub { 0 } unless defined($dive);
  push @sons,A_FilterEChildren($node,$dive,0,0);
  if($node->{is_member}){
    my @oldsons=@sons;
    while($node->{afun}!~/Coord|Apos|AuxS/ or $node->{is_member}){
      $from=$node;$node=$node->parent;
      push @sons,A_FilterEChildren($node,$dive,0,$from);
    }
    if ($node->{afun} eq 'AuxS'){
      print STDERR "Error: Missing Coord/Apos: $node->{id} ".ThisAddress($node)."\n";
      @sons=@oldsons;
    }
  }
  return @sons;
} # AGetEChildren




######## T Layer


sub ExpandCoord {
  my ($node,$keep)=@_;
  return unless $node;
  if (IsCoord($node)) {
    return (($keep ? $node : ()),
      map { ExpandCoord($_,$keep) }
      grep { $_->{is_member} } $node->children);
  } else {
    return ($node);
  }
} #ExpandCoord


sub IsCoord {
  my $node=$_[0];# || $this;
  return 0 unless $node;
  return 0 if $node->{nodetype} eq 'root'; # root does not have functor !!!
  return $node->{functor} =~ /ADVS|APPS|CONFR|CONJ|CONTRA|CSQ|DISJ|GRAD|OPER|REAS/;
}


sub TGetEParents {
  my $node = $_[0];# || $this;
  return() if IsCoord($node);
  if ($node and $node->{is_member}) {
    while ($node and (!IsCoord($node) or $node->{is_member})) {
      $node=$node->parent;
    }
  }
  return () unless $node;
  $node=$node->parent;
  return () unless $node;
  return ($node) if !IsCoord($node);
  return (ExpandCoord($node));
} # TGetEParents


sub T_FilterEChildren { # node suff from
  my ($node,$suff,$from)=@_;
  my @sons;
  $node=$node->firstson;
  while ($node) {
#    return @sons if $suff && @sons; #uncomment this line to get only first occurence
    unless ($node==$from){ # on the way up do not go back down again
      if(($suff&&$node->{is_member})
   ||(!$suff&&!$node->{is_member})){ # this we are looking for
  push @sons,$node unless IsCoord($node);
      }
      push @sons,T_FilterEChildren($node,1,0)
  if (!$suff
      &&IsCoord($node)
      &&!$node->{is_member})
    or($suff
       &&IsCoord($node)
       &&$node->{is_member});
    } # unless node == from
    $node=$node->rbrother;
  }
  return @sons;
} # T_FilterEChildren

sub TGetEChildren { # node
  my $node=$_[0]; #||$this;
  return () if IsCoord($node);
  my @sons;
  my $init_node=$node;# for error message
  my $from;
  push @sons,T_FilterEChildren($node,0,0);
  if($node->{is_member}){
    my @oldsons=@sons;
    while($node and $node->{nodetype} ne 'root'
    and ($node->{is_member} || !IsCoord($node))){
      $from=$node;$node=$node->parent;
      push @sons,T_FilterEChildren($node,0,$from) if $node;
    }
    if ($node->{nodetype} eq 'root'){
      stderr("Error: Missing coordination head: $init_node->{id} $node->{id} ",ThisAddressNTRED($node),"\n");
      @sons=@oldsons;
    }
  }
  return @sons;
} # TGetEChildren




sub ThisAddress {
  my ($node) = @_;
  my $type = $node->type;
  my ($id_attr) = $type && $type->find_members_by_role('#ID');

  return  '#' . $node->{ $id_attr->get_name }
}

sub ThisAddressNTRED {
  my ($node) = @_;
  return  '#???'
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::PDT - PDT user defined relations

=head1 VERSION

version 3.0.2

=over 5

=item DiveAuxCP($node)

You can use this function as a C<through> argument to GetEParents and
GetEChildren. It skips all the prepositions and conjunctions when
looking for nodes which is what you usually want.

=item AGetEParents($node,$through)

Return linguistic parent of a given node as appears in an analytic
tree. The argument C<$through> should supply a function accepting one
node as an argument and returning true if the node should be skipped
on the way to parent or 0 otherwise. The most common C<DiveAuxCP> is
provided in this package.

=item AGetEChildren($node,$dive)

Return a list of nodes linguistically dependant on a given
node. C<$dive> is a function which is called to test whether a given
node should be used as a terminal node (in which case it should return
false) or whether it should be skipped and its children processed
instead (in which case it should return true). Most usual treatment is
provided in C<DiveAuxCP>. If C<$dive> is skipped, a function returning 0
for all arguments is used.

=item ExpandCoord($node,$keep?)

If the given node is coordination or aposition (according to its TGTS
functor - attribute C<functor>) expand it to a list of coordinated
nodes. Otherwise return the node itself. If the argument C<keep> is
true, include the coordination/aposition node in the list as well.

=item IsCoord($node?)

Check if the given node is a coordination according to its TGTS
functor (attribute C<functor>)

=item TGetEParents($node)

Return linguistic parents of a given node as appear in a TG tree.

=item GetEChildren($node?)

Return a list of nodes linguistically dependant on a given node.

=back

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
