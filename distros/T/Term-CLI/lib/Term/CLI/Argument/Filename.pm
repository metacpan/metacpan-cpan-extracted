#=============================================================================
#
#       Module:  Term::CLI::Argument::Filename
#
#  Description:  Class for file name arguments in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  23/01/18
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

package Term::CLI::Argument::Filename  0.051007 {

use Modern::Perl 1.20140107;
use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Argument';

sub complete {
    my $self = shift;
    my $partial = shift;

    my $func_ref = $self->term->Attribs->{filename_completion_function}
        or return;

    my $state = 0;
    my @list;
    while (my $f = $func_ref->($partial, $state)) {
        push @list, $f;
        $state = 1;
    }
    return @list;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Filename - class for file name arguments in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::Argument::Filename;

 my $arg = Term::CLI::Argument::Filename->new(name => 'arg1');

=head1 DESCRIPTION

Class for file name arguments in L<Term::CLI>(3p). Inherits from
the L<Term::CLI::Argument>(3p) class.

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

See L<Term::CLI::Argument>(3p). Additionally:

=over

=item B<complete> ( I<PARTIAL> )

Use L<Term::ReadLine::Gnu>'s file name completion function.

=back

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
L<Term::ReadLine::Gnu>(3p),
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
