#=============================================================================
#
#       Module:  Term::CLI::Argument::Tree
#
#  Description:  Class for nested arguments in Term::CLI
#
#       Author:  Diab Jerius (DJERIUS), <djerius@cpan.org>
#      Created:  19/April/2022
#
#   Copyright (c) 2022 Diab Jerius, Smithsonian Astrophysical Observatory
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Argument::Tree 0.060000;

use warnings;

use Scalar::Util qw( refaddr );
use Term::CLI::Util qw( find_text_matches );
use Types::Standard qw( CodeRef HashRef InstanceOf );

use Moo;

extends 'Term::CLI::Argument';

has +max_occur => (
    is       => 'ro',
    default  => 0,
    init_arg => undef,
);

has _values => (
    is       => 'ro',
    required => 1,
    init_arg => 'values',
    isa      => CodeRef | HashRef
);

has cache_values => (
    is      => 'rw',
    default => 0,
    trigger => sub {
        my ( $self, $value ) = @_;
        $self->_clear_value_cache if !$value;
    },
);

has _value_cache => (
    is        => 'rw',
    isa       => HashRef,
    predicate => 1,
    clearer   => 1,
);

sub values {
    my ($self) = shift;
    my $values = $self->_values;
    return $values             if 'HASH' eq ref($values);
    return $self->_value_cache if $self->_has_value_cache;

    $values = $self->$values;
    $self->_value_cache($values) if $self->cache_values;
    return $values;
}

=begin internals

=sub _find_parent

  $parent = $self->find_parent( $parent, $processed );

traverse the argument list, identifying arguments associated with this
tree, and use them to descend the tree.

Returns one of the following:

=over

=item *

a non-empty hashref, which is a node

=item *

* an empty hashref or I<undef> in which case we've moved off of the
tree

=item *

anything else is a leaf, hopefully it's a string, but that's up to the caller
to have correctly populated the values structure

=back

=end internals

=cut

sub _descend_tree {
    my ( $self, $processed ) = @_;

    my $next = $self->values;

    # find first processed argument corresponding to $self
    my $addr = refaddr($self);
    my @path;
    for my $arg ( grep { refaddr( $_->{element} ) == $addr } @{$processed} ) {
        my $value = $arg->{value};

        # this protects against treating $parent as a node when it's actually
        # a leaf. this happens if the user is passing too many arguments
        # for the depth of this path through the tree.
        return ( undef, \@path )
            unless 'HASH' eq ref $next && exists $next->{$value};
        push @path, $value;
        $next = $next->{$value};
    }

    return $next, \@path;
}

sub validate {
    my ( $self, $value, $state ) = @_;

    my ( $next, $path ) = $self->_descend_tree( $state->{processed} );

  # normally this should not happen, as previous calls to validate on early
  # elements will hae signalled an error, but just in case the calling program
  # is ignoring errors...
    return $self->set_error(
        qq/hierarchy validates up to ${ \join( '.', @$path) } /)
        if !defined $next;

    return ( ( 'HASH' eq ref $next && exists $next->{$value} )
            || $next eq $value )
        ? $value
        : $self->set_error(
        qq/$value is not in hierarchy: ${ \join( '.', @$path) }/);
}

sub complete {
    my ( $self, $value, $state ) = @_;

    my ( $next, $path ) = $self->_descend_tree( $state->{processed} );
    return if !defined $next;

    my @values = ( 'HASH' eq ref $next ? sort( keys %$next ) : $next );
    return         if !@values;
    return @values if !length $value;
    return find_text_matches( $value, \@values );
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Tree - class for tree arguments in Term::CLI

=head1 VERSION

version 0.060000

=head1 SYNOPSIS

 use Term::CLI::Argument::Tree;

 # static values
 my $arg = Term::CLI::Argument::Tree->new(
     name => 'arg1',
     values => { l1 => { l2 => 't1', l3 => undef } }
 );

 my $values = $arg->values; # returns { l1 => { l2 => 't1', l3 => undef } }

 # dynamic values
 my $arg = Term::CLI::Argument::Tree->new(
     name => 'arg1',
     values => sub {  my %values = (...); \%values },
 );

=head1 DESCRIPTION

This class provides a multi-valued argument representing levels in a
hierarchical data structure.  For example, with the structure
presented in the L</Synopsis>, the following sequences of command line
argument values are accepted:

  l1
  l1 l2
  l1 l2 t1
  l1 l3

The object provides completion at each level.

Because this argument hoovers up an indeterminate number of input tokens
it should be the last argument object specified.

This class inherits from the L<Term::CLI::Argument>(3p) class.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Argument>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

=over

=item B<new>

    OBJ = Term::CLI::Argument::Tree(
        name         => STRING,
        values       => HashRef | CodeRef,
        cache_values => BOOL,
    );

See also L<Term::CLI::Argument>(3p). The B<values> argument is
mandatory and can either be a reference to a hash, or a code
refrerence. The latter can be used to implement dynamic values or
delayed expansion (where the values have to be fetched from a database
or remote system). The code reference will be called with a single
argument consisting of the reference to the
L</Term::CLI::Argument::Tree> object.

The C<cache_values> attribute can be set to a true value to prevent
repeated calls to the C<value> code reference. For dynamic values this
is not desired, but for values that are generated through expensive
queries, this can be useful. The default is 0 (false).

=back

=head1 ACCESSORS

See also L<Term::CLI::Argument>(3p).

=over

=item B<values>
X<values>

A reference to a either a hash of valid values for the argument or a
subroutine which returns a reference to such a hash.

Note that once set, changing the hash pointed to by the reference
will result in undefined behaviour.

=item B<cache_values>
X<cache_values>

=item B<cache_values> ( [ I<BOOL> ] )

Returns or sets whether the values hash should be cached in case
C<values> is a code reference.

For dynamic hashes this should be false, but for hashes that are
generated through expensive queries, it can be useful to set this to
true.

If the value is changed from true to false, the cache is
immediately cleared.

=back

=head1 METHODS

See also L<Term::CLI::Argument>(3p).

The following methods are added or overloaded:

=over

=item B<validate>

=item B<complete>

Overloaded from L<Term::CLI::Argument>(3p).

=item B<values>

Returns an Hashref containing the valid values for this
argument object.

In case L</values> is a CodeRef, it will call the
code to expand the list, sort it, and return the result.

=back

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
L<Term::CLI>(3p).

=head1 AUTHOR

Diab Jerius E<lt>djeriusr@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Diab Jerius, Smithsonian Astrophysical Observatory

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
