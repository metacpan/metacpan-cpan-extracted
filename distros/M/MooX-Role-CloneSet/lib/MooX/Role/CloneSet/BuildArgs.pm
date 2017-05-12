package MooX::Role::CloneSet::BuildArgs;

use 5.012;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.0");

use Moo::Role;
use namespace::clean;

with 'MooX::BuildArgs';

sub cset($ %)
{
	my ($self, %new) = @_;

	# Hmm, so Moo doesn't have metaclasses, right?
	return $self->new(%{$self->build_args}, %new);
}

1;
__END__

=encoding utf-8

=head1 NAME

MooX::Role::CloneSet::BuildArgs - create updated copies of truly immutable objects

=head1 SYNOPSIS

    package Someone;

    use Moo;
    with 'MooX::Role::CloneSet::BuildArgs';

    has name => (
        is => 'ro',
    );

    has race => (
        is => 'ro',
    );

    package main;

    my $first = Someone->new(name => 'Drizzt', race => 'drow');

    my $hybrid = $first->cset(race => 'dwarf');

    my $final = $weird->cset(name => 'Catti-brie', race => 'human');

=head1 DESCRIPTION

C<MooX::Role::CloneSet::BuildArgs> is a role very similar to
C<MooX::Role::CloneSet>; the only difference is that its C<cset()> method
does not try to obtain the current values of the object's attributes, but
uses the ones the object was constructed with (using C<MooX::BuildArgs>).

=head1 METHODS

=over 4

=item * cset(field => value, ...)

Shallowly clone the object, making the specified changes to its attributes.

Note that this method obtains the names and values of the object's
attributes by using the C<build_args()> method from C<MooX::BuildArgs>;
thus, it really depends on the fact that none of the attributes has had its
value changed since the object was constructed.

=back

=head1 LICENSE

Copyright (C) 2016  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

