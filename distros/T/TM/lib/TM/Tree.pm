package TM::Tree;

use TM;

use Class::Trait 'base';

##our @REQUIRES  = qw(last_mod);

use Data::Dumper;

=pod

=head1 NAME

TM::Tree - Topic Maps, trait for induced tree retrieval

=head1 SYNOPSIS

  use TM::Materialized::AsTMa;
  my $tm = new TM::Materialized::AsTMa (file => 'old_testament.atm');
  Class::Trait->apply ( $tm => 'TM::Tree' );
  $tm->sync_in;

  # old-testament pedigree
  print Dumper $tm->tree (lid   => 'adam',
			  type  => 'has-parent',
			  arole => 'parent',
			  brole => 'child' );

  # new-testament inverse pedigree
  print Dumper $tm->tree (lid   => 'gw-bush',
			  type  => 'has-parent',
			  arole => 'child',
			  brole => 'parent' );


=head1 DESCRIPTION

Obviously, topic maps can carry information which is tree structured. A family pedigree is a typical
example of it; associations having a particular type, particular roles and you can derive a tree
structure from that.

This is exactly what this operator does: it takes one topic map basis and primed with a starting
node, an association type and two roles a tree will be returned to the caller.

=head1 INTERFACE

=head2 Methods

=over

=item B<tree>

I<$treeref> = I<$tm>->tree (
                 I<$start_topic>,
                 I<$type_topic>,
                 I<$role_topic>,
                 I<$role_topic>,
                 [ depth => I<$integer> ])

I<$treeref> = I<$tm>->tree_x (
                 I<$start_topic>,
                 I<$type_topic>,
                 I<$role_topic>,
                 I<$role_topic>,
                 [ depth => I<$integer> ])

This function will analyze the topic map and will detect all maplets of the given type (direct and
indirect ones) having the specified roles. Starting from the I<start topic> it will so find other
topics playing the I<brole>. Those will be used as a next starting point, and so forth.

To avoid the tree to become too big, you can impose an optional limit. Loops are detected.

Every output tree node contains following fields:

=over

=item C<lid>: 

the lid of the node

=item C<children>: 

a list reference of child nodes, there is no specific sort order

=item C<children*>: 

B<Note>: This is currently deactivated.

for convenience this list reference contains all children, grand-children, grand-grand
children.... of this node (this list is neither sorted nor unique out of performance
considerations).

=back

The version C<tree_x> does not honor subclassing of roles and type (but C<tree> does). This means
that is can be considerably faster, especially if you use it for taxonomy stuff with C<isa> and
C<is-subclass-of>.


=cut



sub tree {
  my $self  = shift;
  my ($lid, $type, $arole, $brole) = $self->mids (shift, shift, shift, shift);
  my $depth = shift;

  return       _tree ($self,
		      $lid,
		      {},
		      [ $self->match_forall (type => $type) ],  # where are the associations which are relevant? (do not recompute them over and over, again)
		      $arole,
		      $brole,
		      0,                               # current depth
		      $depth);

sub _tree {
    my $self      = shift;
    my $lid       = shift;                                           # the current topic
    my $visited   = shift;                                           # a hash ref where we record what we have seen
    my $aids      = shift;                                           # list references to all maplets of that type
    my ($a, $b)   = (shift, shift);                                  # the roles
    my ($cd, $md) = (shift, shift);                                  # current depth, maxdepth

#warn "aids";#. Dumper $aids;

    return $visited->{$lid} if $visited->{$lid};                     # been there, done that

    my $n = {                                                        # we create a node for that topic
	      lid         => $lid,
	      children    => [],                                     # contains direct children
#	      'children*' => []                                      # contains also indirect one
	     };

    return $n if defined $md && $cd >= $md;

    foreach (grep ($self->is_x_player ($_, $lid, $a), @{$aids})) {  # shortcut OO method resolution
#warn "working on $_";
	foreach ($self->get_x_players ($_, $b)) {
#warn "    $_";
	    my $child = _tree ($self,
			       $_,
			       $visited,
			       $aids,
			       $a,
			       $b,
			       $cd+1,
			       $md);
	    push @{$n->{'children'}},  $child;
#	    push @{$n->{'children*'}}, $child->{lid}, @{$child->{'children*'}};
	}
    }

    $visited->{$n->{lid}} = $n;                                      # global hash which remembers already built subtrees
    return $n;
}

}


sub tree_x {
    my $self  = shift;
    my ($lid, $type, $arole, $brole) = (shift, shift, shift, shift);
    my $depth = shift;
    
    my @aids = $self->match_forall (type => $type);
    my $n = {                                                        # we create a node for that topic
	      lid         => $lid,
	      children    => [],                                     # contains direct children
#	      'children*' => []                                      # contains also indirect one
	     };
    return $n unless @aids;

    my $ai; # index for arole
    my $bi; # index for brole
    {                                             # figure out the static indices in one prototype assoc
	my $rs = $aids[0]->[TM->ROLES];           # we know that there must be at least one
	for (my $i = 0; $i < @$rs; $i++) {
	    if ($rs->[$i] eq $arole) {
		$ai = $i;
	    } elsif ($rs->[$i] eq $brole) {
		$bi = $i;
	    }
	}
    }
    my %arcs;
    foreach my $a (@aids) {
	my ($a, $b) = @{ $a->[TM->PLAYERS] }[$ai,$bi];
	push @{ $arcs{$a}}, $b;
    }
#warn Dumper \%arcs;
    return _tree_x (\%arcs, $lid, {}, 0, $depth);

sub _tree_x {
    my $arcs      = shift;
    my $lid       = shift;                                           # the current node
    my $visited   = shift;                                           # a hash ref where we record what we have seen
    my ($cd, $md) = (shift, shift);                                  # current depth, maxdepth
    return $visited->{$lid} if $visited->{$lid};                     # been there, done that
    my $n = {                                                        # we create a node for that topic
	      lid         => $lid,
	      children    => [],                                     # contains direct children
	     };
    return $n if defined $md && $cd >= $md;
    foreach my $ch (@{ $arcs->{$lid} }) {
	push @{$n->{'children'}}, _tree_x ($arcs, $ch, $visited, $cd+1, $md);
    }
    $visited->{$n->{lid}} = $n;                                      # global hash which remembers already built subtrees
}

}

=pod

=item B<taxonomy>

I<$treeref> = I<$tm>->taxonomy ([ I<$start_lid> ])

This function is a specialization of C<tree>, in that it looks at a particular association type
(C<is-subclass-of>) and the appropriate roles (C<superclass>, C<subclass>). Obviously the result is
a tree holding all subtypes.

The only optional parameter is a toplet C<lid>; that becomes the starting point of the tree. If that
parameter is missing, C<thing> is assumed.

=cut

sub taxonomy {
    my $self = shift;
    my $top  = shift || $self->mids ('thing');

    return $self->tree_x ($top, $self->mids ('is-subclass-of', 'superclass', 'subclass'));
}

=pod

=back

=head1 SEE ALSO

L<TM>

=head1 COPYRIGHT AND LICENSE

Copyright 200[3-6] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION  = 0.4;
our $REVISION = '$Id: Tree.pm,v 1.2 2006/12/01 08:01:00 rho Exp $';


1;

__END__

xxx=cut


computes a tree of topics based on a starting topic, an association type
and two roles. Whenever an association of the given type is found and the given topic appears in the
role given in this very association, then all topics appearing in the other given role are regarded to be
children in the result tree. There is also an optional C<depth> parameter. If it is not defined, no limit
applies. Starting from XTM::base version 0.34 loops are detected and are handled gracefully. The returned
tree might contain loops then.

Examples:


  $hierarchy = $tm->induced_assoc_tree (topic      => $start_node,
					assoc_type => 'at-relation',
					a_role     => 'tt-parent',
					b_role     => 'tt-child' );
  $yhcrareih = $tm->induced_assoc_tree (topic      => $start_node,
					assoc_type => 'at-relation',
					b_role     => 'tt-parent',
					a_role     => 'tt-child',
					depth      => 42 );

B<Note>


x=cut


x=pod

