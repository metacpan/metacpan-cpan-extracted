package Test::Chimps::ReportCollection;

use warnings;
use strict;

=head1 NAME

Test::Chimps::ReportCollection - Encapsulate a collection of smoke test reports

=head1 SYNOPSIS

See L<Jifty::DBI::Collection>.

=cut
  
use base qw/Jifty::DBI::Collection/;

=head1 METHODS

=head2 record_class

Overridden method.  Always returns 'Test::Chimps::Report'.

=cut

sub record_class {
  return 'Test::Chimps::Report';
}

=head2 table

Overridden method.  Always returns 'reports'.

=cut

# we don't need this for SVN Jifty::DBI, but those changes haven't
# been pushed to CPAN yet
sub table {
  return 'reports';
}

=head1 AUTHOR

Zev Benjamin, C<< <zev at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-chimps at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Chimps>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Chimps

You can also look for information at:

=over 4

=item * Mailing list

Chimps has a mailman mailing list at
L<chimps@bestpractical.com>.  You can subscribe via the web
interface at
L<http://lists.bestpractical.com/cgi-bin/mailman/listinfo/chimps>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Chimps>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Chimps>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Chimps>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Chimps>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
