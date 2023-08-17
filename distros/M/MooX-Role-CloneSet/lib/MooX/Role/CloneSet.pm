package MooX::Role::CloneSet;

use 5.012;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Moo::Role;
use namespace::clean;

sub cset($ %)
{
	my ($self, %new) = @_;

	# Hmm, so Moo doesn't have metaclasses, right?
	return $self->new(%{$self}, %new);
}

1;
__END__

=encoding utf-8

=head1 NAME

MooX::Role::CloneSet - create updated copies of immutable objects

=head1 SYNOPSIS

    package Someone;

    use Moo;
    with 'MooX::Role::CloneSet';

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

C<MooX::Role::CloneSet> is a role for immutable objects, providing an easy
way to create a new object with some modified properties.  It provides
the C<cset()> method that creates a new object with the specified changes,
shallowly copying all the rest of the original object's properties.

=head1 METHODS

=over 4

=item * cset(field => value, ...)

Shallowly clone the object, making the specified changes to its attributes.

Note that this method obtains the names and values of the current attributes
by dereferencing the object as a hash reference; since Moo does not provide
metaclasses by default, it cannot really get to them in any other way.
This will not work for parameters that declare an C<init_arg>; see
C<MooX::Role::CloneSet::BuildArgs> for an alternative if using truly
immutable objects.

=back

=head1 LICENSE

Copyright (C) 2016  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

