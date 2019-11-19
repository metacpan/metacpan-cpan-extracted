#=============================================================================
#
#       Module:  Term::CLI::Argument::Enum
#
#  Description:  Class for "enum" arguments in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  22/01/18
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

use 5.014_001;

package Term::CLI::Argument::Enum  0.051007 {

use Modern::Perl 1.20140107;
use Term::CLI::L10N;

use Types::Standard 1.000005 qw(
    ArrayRef
);

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Argument';

has value_list => (
    is => 'ro',
    isa => ArrayRef,
    required => 1,
);


sub validate {
    my ($self, $value) = @_;

    defined $self->SUPER::validate($value) or return;

    my @found = grep { rindex($_, $value, 0) == 0 } @{$self->value_list};
    if (@found == 0) {
        return $self->set_error(loc("not a valid value"));
    }
    elsif (@found == 1) {
        return $found[0];
    }
    else {
        @found = sort @found;
        return $self->set_error(
            loc("ambiguous value (matches: [_1])", join(", ", @found))
        );
    }
}


sub complete {
    my ($self, $value) = @_;

    if (!length $value) {
        return sort @{$self->value_list};
    }
    else {
        return sort grep
                { substr($_, 0, length($value)) eq $value }
                @{$self->value_list};
    }
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Enum - class for "enum" string arguments in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::Argument::Enum;

 my $arg = Term::CLI::Argument::Enum->new(
     name => 'arg1',
     value_list => [qw( foo bar baz )],
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

=item B<new> ( B<name> =E<gt> I<STRING>, B<value_list> =E<gt> I<ARRAYREF> )

See also L<Term::CLI::Argument>(3p). The B<value_list> argument is
mandatory.

=back

=head1 ACCESSORS

See also L<Term::CLI::Argument>(3p).

=over

=item B<value_list>

A reference to a list of valid values for the argument.

=back

=head1 METHODS

See also L<Term::CLI::Argument>(3p).

The following methods are added or overloaded:

=over

=item B<validate>

=item B<complete>

=back

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
