#=============================================================================
#
#       Module:  Term::CLI::Argument::Enum
#
#  Description:  Class for "enum" arguments in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  22/Jan/2018
#
#   Copyright (c) 2018-2022 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Argument::Enum 0.061000;

use 5.014;
use warnings;

use Term::CLI::L10N qw( loc );
use Term::CLI::Util qw( is_prefix_str find_text_matches );

use Types::Standard 1.000005 qw(
    ArrayRef
    CodeRef
);

use Moo 1.000001;
use List::Util 1.23 qw( first );
use Scalar::Util 1.23 qw( reftype );

use namespace::clean 0.25;

extends 'Term::CLI::Argument';

has value_list => (
    is       => 'ro',
    isa      => ArrayRef | CodeRef,
    required => 1,
    coerce   => sub {
        my ($arg) = @_;
        return $arg if ref $arg && reftype $arg ne 'ARRAY';
        return [ sort @$arg ];
    }
);

has cache_values => (
    is       => 'rw',
    default  =>  0,
# Trigger for when caching gets disabled to immediately clear the
# cache. This allows for quicker cleanup of objects, file handles, etc.
    trigger => sub {
        my ($self, $new) = @_;
        $self->_clear_value_cache if ! $new;
    }
);

has _value_cache => (
    is        => 'rw',
    isa       => ArrayRef,
    predicate => 1,
    clearer   => 1,
);

sub values {
    my ($self) = @_;

    my $value_list = $self->value_list;
    return $value_list if reftype $value_list eq 'ARRAY';

    # Dynamic values...

    # Return cache if possible.
    if ( $self->_has_value_cache ) {
        return $self->_value_cache;
    }

    my $list_ref = [ sort @{ $value_list->($self) } ];

    if ( $self->cache_values ) {
        $self->_value_cache( $list_ref );
    }

    return $list_ref;
}


sub validate {
    my ( $self, $value ) = @_;

    defined $self->SUPER::validate($value) or return;

    my $values_r = $self->values;

    my @found = find_text_matches( $value, $values_r, exact => 1 );

    if ( @found == 0 ) {
        return $self->set_error( loc("not a valid value") );
    }

    return $found[0] if @found == 1;

    return $self->set_error(
        loc( "ambiguous value (matches: [_1])", join( ", ", @found ) ) );
}

sub complete {
    my ( $self, $text ) = @_;

    my $values_r = $self->values;

    return @{$values_r} if !length $text;
    return find_text_matches( $text, $values_r );
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Enum - class for "enum" string arguments in Term::CLI

=head1 VERSION

version 0.061000

=head1 SYNOPSIS

 use Term::CLI::Argument::Enum;

 # static value list
 my $arg = Term::CLI::Argument::Enum->new(
     name => 'arg1',
     value_list => [qw( foo bar baz )],
 );

 my $val_list = $arg->values; # returns ['bar', 'baz', 'foo']

 # dynamic value list
 my $arg = Term::CLI::Argument::Enum->new(
     name => 'arg1',
     value_list => sub {  my @values = (...); \@values },
 );

=head1 DESCRIPTION

Class for "enum" string arguments in L<Term::CLI>(3p).

This class inherits from
the L<Term::CLI::Argument>(3p) class.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Argument>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

=over

=item B<new>

    OBJ = Term::CLI::Argument::Enum(
        name         => STRING,
        value_list   => ArrayRef | CodeRef,
        cache_values => BOOL,
    );

See also L<Term::CLI::Argument>(3p). The B<value_list> argument is
mandatory and can either be a reference to an array, or a code refrerence.

A value list consisting of a code reference can be used to implement
dynamic values or delayed expansion (where the values have to be
fetched from a database or remote system). The code reference will
be called with a single argument consisting of the reference to the
C<Term::CLI::Argument::Enum|Term::CLI::Argument::Enum>
object.

The C<cache_values> attribute can be set to a true value to prevent
repeated calls to the C<value_list> code reference. For dynamic value
lists this is not desired, but for lists that are generated through
expensive queries, this can be useful. The default is 0 (false).

=back

=head1 ACCESSORS

See also L<Term::CLI::Argument>(3p).

=over

=item B<value_list>
X<value_list>

A reference to a either a list of valid values for the argument or a
subroutine which returns a reference to such a list.

Note that once set, changing the list pointed to by an I<ArrayRef>
will result in undefined behaviour.

=item B<cache_values>
X<cache_values>

=item B<cache_values> ( [ I<BOOL> ] )

Returns or sets whether the value list should be cached in case
C<value_list> is a code reference.

For dynamic value lists this should be false, but for lists that are
generated through expensive queries, it can be useful to set this to
true.

If the value is changed from true to false, any cached list is
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

Returns an ArrayRef containing a sorted list of valid values for this
argument object.

In case L<value_list|/value_list> is a CodeRef, it will call the
code to expand the list, sort it, and return the result.

=back

=head1 EXAMPLES

Return values depending on the time of day:

    # Valid values for 'at' depend on the current time of day.
    # Before 1pm, 'today' is possible, otherwise only 'tomorrow'.
    my $arg = Term::CLI::Argument::Enum(
        name => 'at',
        value_list => sub {
            my ($self) = @_;
            my $hr = (localtime)[2];
            return ($hr < 13) ? ['today', 'tomorrow'] : ['tomorrow'];
        }
    );

Return values based on a predefined list of values that can be
(temporarily) overridden with C<local()>:

    my @LIST = qw( one two three );

    my $arg = Term::CLI::Argument::Enum(
        name => 'arg',
        value_list => sub { return \@LIST }
    );

    ...

    # Will allow 'one', 'two', 'three' for 'arg'.
    $cli->execute($cli->readline);

    {
        local(@LIST) = qw( four five six );
        # Now allow 'four', 'five', 'six' for 'arg'.
        $cli->execute($cli->readline);
    }

    # Allow 'one', 'two', 'three' for 'arg' again.
    $cli->execute($cli->readline);

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
L<Term::CLI>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
