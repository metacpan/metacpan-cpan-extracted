use strict;
use warnings;
package Project::Euler;
BEGIN {
  $Project::Euler::VERSION = '0.20';
}

use Modern::Perl;
use 5.010;  # So Dist::Zilla picks it up

#ABSTRACT: Solutions for L<< http://projecteuler.net >>





1; # End of Project::Euler

__END__
=pod

=head1 NAME

Project::Euler - Solutions for L<< http://projecteuler.net >>

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    use Project::Euler::Problem::P001;
    my $problem1 = Project::Euler::Problem::P001->new;

    $problem1->solve;
    print $problem1->status;

=head1 DESCRIPTION

This is the base class which will eventually be responsible for displaying the
interface to interact with the solutions implemented so far.

For now, you will have to manually import the problem_solutions and solve them manually.

=head1 LIBRARIES

These libraries are used by the problem solutions:

=over 4

=item 1

L<< Project::Euler::Lib::Utils >>

=item 2

L<< Project::Euler::Lib::Types >>

=back

=head1 PROBLEMS

These problems are fully implemented so far (extending the base class L<< Project::Euler::Problem::Base >>)

=over 4

=item 1

L<< Project::Euler::Problem::P001 >>

=item 2

L<< Project::Euler::Problem::P002 >>

=item 3

L<< Project::Euler::Problem::P003 >>

=item 4

L<< Project::Euler::Problem::P004 >>

=item 5

L<< Project::Euler::Problem::P005 >>

=back

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=for :stopwords CPAN AnnoCPAN RT CPANTS Kwalitee diff

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Project::Euler

=head2 Websites

=over 4

=item *

Search CPAN

L<http://search.cpan.org/dist/Project-Euler>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Project-Euler>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/Project-Euler>

=item *

CPAN Forum

L<http://cpanforum.com/dist/Project-Euler>

=item *

RT: CPAN's Bug Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Project-Euler>

=item *

CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Project-Euler>

=item *

CPAN Testers Results

L<http://cpantesters.org/distro/P/Project-Euler.html>

=item *

CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Project-Euler>

=item *

Source Code Repository

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<git://github.com/lespea/Project-Euler>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-project-euler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-Euler>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

