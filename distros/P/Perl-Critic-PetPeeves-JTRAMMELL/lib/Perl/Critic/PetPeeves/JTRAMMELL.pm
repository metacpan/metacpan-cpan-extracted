package Perl::Critic::PetPeeves::JTRAMMELL;

use strict;
use warnings;
our $VERSION = '0.04';

=head1 NAME

Perl::Critic::PetPeeves::JTRAMMELL - policies to prohibit/require my pet peeves

=head1 DESCRIPTION

Module C<Perl::Critic::PetPeeves::JTRAMMELL> provides policies that I want that
haven't already been implemented elsewhere.  So far this is:

=over 4

=item Perl::Critic::Policy::Variables::ProhibitUselessInitialization

Considers unnecessary initialization a style violation, I<e.g.>:

    my $foo = undef;     # assignment not needed
    my @bar = ();        # ditto

=back

=head1 AUTHOR

John Trammell C<< <johntrammell =at= gmail !dot! com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-perl-critic-petpeeves-jtrammell at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Critic-PetPeeves-JTRAMMELL>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl::Critic::PetPeeves::JTRAMMELL

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl-Critic-PetPeeves-JTRAMMELL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl-Critic-PetPeeves-JTRAMMELL>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic-PetPeeves-JTRAMMELL>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl-Critic-PetPeeves-JTRAMMELL>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2011 John Trammell, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
