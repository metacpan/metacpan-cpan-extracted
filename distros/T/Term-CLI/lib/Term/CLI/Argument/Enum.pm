#=============================================================================
#
#       Module:  Term::CLI::Argument::Enum
#
#  Description:  Class for "enum" arguments in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  22/Jan/2018
#
#   Copyright (c) 2018 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Argument::Enum  0.053006 {

use 5.014;
use strict;
use warnings;

use Term::CLI::L10N;

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
    is => 'ro',
    isa => ArrayRef | CodeRef,
    required => 1,
);

# Helper for fetching the actual list of values since
# "value_list" can be a CODEREF.
sub _fetch_values {
    my ($self) = @_;

    my $l = $self->value_list;
    return reftype($l) eq 'CODE' ? $l->($self) : $l;
}

sub validate {
    my ($self, $value) = @_;

    defined $self->SUPER::validate($value) or return;

    my $value_list = $self->_fetch_values;

    my @found = grep { rindex($_, $value, 0) == 0 } @{$value_list};
    if (@found == 0) {
        return $self->set_error(loc("not a valid value"));
    }

    if (@found == 1) {
        return $found[0];
    }

    my $match = first { $_ eq $value } @found
        or return $self->set_error(
            loc("ambiguous value (matches: [_1])", join(", ", sort @found))
        );
    return $match;
}


sub complete {
    my ($self, $value) = @_;

    my $value_list = $self->_fetch_values;

    return sort @{$value_list} if !length $value;
    return sort grep { substr($_,0,length($value)) eq $value } @{$value_list};
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Enum - class for "enum" string arguments in Term::CLI

=head1 VERSION

version 0.053006

=head1 SYNOPSIS

 use Term::CLI::Argument::Enum;

 # static value list
 my $arg = Term::CLI::Argument::Enum->new(
     name => 'arg1',
     value_list => [qw( foo bar baz )],
 );

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
        name => STRING,
        value_list => ArrayRef | CodeRef
    );

See also L<Term::CLI::Argument>(3p). The B<value_list> argument is
mandatory and can either be a reference to an array, or a code refrerence.

A value list consisting of a code reference can be used to implement dynamic
values. The code reference will be called with a single argument consisting
of the reference to the C<Term::CLI::Argument::Enum> object.

=back

=head1 ACCESSORS

See also L<Term::CLI::Argument>(3p).

=over

=item B<value_list>

A reference to a either a list of valid values for the argument or a
subroutine which returns a reference to such a list.

=back

=head1 METHODS

See also L<Term::CLI::Argument>(3p).

The following methods are added or overloaded:

=over

=item B<validate>

=item B<complete>

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

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
