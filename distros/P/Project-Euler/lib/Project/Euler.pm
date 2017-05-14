package Project::Euler;

use Modern::Perl;

=head1 NAME

Project::Euler - Solutions for L<< http://projecteuler.net >>

=head1 VERSION

Version v0.1.5

=cut

use version 0.77; our $VERSION = qv("v0.1.5");


=head1 SYNOPSIS

    use Project::Euler;

=head1 DESCRIPTION

This is the base class which will eventually be responsible for displaying the
interface to interact with the solutions implemented so far.

For now, you will have to manually import the problem_solutions and solve them manually.

    use Project::Euler::Problem::P001;
    my $problem1 = Project::Euler::Problem::P001->new;

    $problem1->solve;
    print $problem1->status;

While not the most elegant solution, it will have to do for now.

=head1 PROBLEMS

These problems are fully implemented so far:

=over 4

=item * L<< Project::Euler::Problem::P001 >>

=item * L<< Project::Euler::Problem::P002 >>

=back

using the base class:  L<< Project::Euler::Problem::Base >>


=head1 LIBRARIES

These libraries are used by the problem_solutions:

=over 4

=item * L<< Project::Euler::Lib::MultipleCheck >>

=item * L<< Project::Euler::Lib::Types >>

=back

=head1 EXPORT

#  Todo:  implement interface functions

=head1 FUNCTIONS

#  Todo:  implement interface functions



=head1 AUTHOR

Adam Lesperance, C<< <lespea at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-project-euler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-Euler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Project::Euler

Also, you can follow the development of this module on L<< http://www.github.com >>

=over 4

=item * L<< http://www.github.com/lespea/Project--Euler/ >>

=back

You can look for further information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Project-Euler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Project-Euler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Project-Euler>

=item * Search CPAN

L<http://search.cpan.org/dist/Project-Euler/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Adam Lesperance.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Project::Euler
