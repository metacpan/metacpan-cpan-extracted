#===============================================================================
#
#       Module:  Term::CLI::Argument::String
#
#  Description:  Class for arbitrary string arguments in Term::CLI
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
#===============================================================================

use 5.014_001;

package Term::CLI::Argument::String  0.03002 {

use Modern::Perl;
use Moo;
use namespace::clean;

extends 'Term::CLI::Argument';

sub validate {
    my ($self, $value) = @_;

    $self->set_error('');
    if (!defined $value) {
        return $self->set_error("value must be defined");
    }
    return $value;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::String - class for basic string arguments in Term::CLI

=head1 VERSION

version 0.03002

=head1 SYNOPSIS

 use Term::CLI::Argument::String;

 my $arg = Term::CLI::Argument::String->new(name => 'arg1');

=head1 DESCRIPTION

Simple class for string arguments in L<Term::CLI>(3p). This is basically
the L<Term::CLI::Argument>(3p) class, but also allowing empty strings.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Argument>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

See L<Term::CLI::Argument>(3p).

=head1 ACCESSORS

See L<Term::CLI::Argument>(3p).

=head1 METHODS

See L<Term::CLI::Argument>(3p).

=over

=item B<validate> ( I<Str> )

Overloaded from L<Term::CLI::Argument> to also allow empty strings.

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
