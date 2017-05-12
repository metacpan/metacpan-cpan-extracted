package NIST::NVD;

use warnings;
use strict;
use LWP::UserAgent;

=head1 NAME

NIST::NVD - Fetch and convert NIST's NVD feeds

=head1 VERSION

Version 1.00.00

=cut

our $VERSION = '1.00.00';

=head1 SYNOPSIS

  my $nvd = NIST::NVD->new( store => 'DB_File',
                            db_path => $db_path,
                           );
  $nvd->update();

=head1 SUBROUTINES/METHODS

=head2 new

  my $nvd = NIST::NVD->new( store => 'DB_File',
                            db_path => $db_path,
                           );

=cut

sub new {

    my ( $class, %args ) = @_;

    $class = ref $class || $class;

    bless {}, $class;

}

=head2 update

  my $result = $nvd->update();

  Not yet implemented.  Stubbed out while other features are completed.

=cut

sub update {
    my ( $self, %args ) = @_;

    my $quick_url    = 'http://nvd.nist.gov/download/nvd-rss.xml';
    my $complete_url = 'http://nvd.nist.gov/download/nvd-rss-analyzed.xml';

    return 1;
}

=head1 AUTHOR

C.J. Adams-Collier, C<< <cjac at f5.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nist-nvd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NIST-NVD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc NIST::NVD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=NIST-NVD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/NIST-NVD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/NIST-NVD>

=item * Search CPAN

L<http://search.cpan.org/dist/NIST-NVD/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2012 F5 Networks, Inc.

CVE(r) and CWE(tm) are marks of The MITRE Corporation and used here with
permission.  The information in CVE and CWE are copyright of The MITRE
Corporation and also used here with permission.

Please include links for CVE(r) <http://cve.mitre.org/> and CWE(tm)
<http://cwe.mitre.org/> in all reproductions of these materials.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of NIST::NVD
