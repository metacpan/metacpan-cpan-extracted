package Net::Geohash;

use strict;
use warnings;

use LWP::UserAgent;

our $VERSION = '1.1';

sub get {
    my ($coords) = shift @_;
    if (! $coords) { warn 'Missing lattitude/longitude param'; return ''; }
    if (@_) { warn 'Extra parameters found.'; return; }
    my $ua = LWP::UserAgent->new();
    $ua->agent('perl-Net-Geohash/' . $VERSION );
    $ua->max_redirect(0);
    my $resp = $ua->get('http://geohash.org/?q=' . $coords);
    if ($resp->code() eq '303') {
        if (my $loc = $resp->header('location')) {
            if ($loc eq 'http://geohash.org/') {
                warn 'geohash.org response indicates that the geocode was invalid.';
                return '';
            }
            return $loc;
        } else {
            return '';
        }
    }
    warn 'geohash.org response was not a redirect, possibly invalid geocoords.';
    return '';
}

=head1 NAME

Net::Geohash - The great new Net::Geohash!

=head1 VERSION

Version 1.1

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Geohash;

    my $ghurl = Net::Geohash::get('37.391012 -122.071873');
    ...

=head1 EXPORT

=head1 FUNCTIONS

=head2 get

The get function accepts a string containing the lat/lon to send to
geohash.org for hashing. It returns the fully qualified geohash.org url
on success. If an error occurs it will give a warning message and return
an empty string.

Location names such as 'Paris, France' can also be given.

=head1 AUTHOR

Nick Gerakines, C<< <nick at gerakines.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-geohash at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Geohash>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Geohash

You can also look for information at:

=over 4

=item * geohash.org

L<http://geohash.org/>

=item * del.icio.us/tag/geohash

L<http://del.icio.us/tag/geohash>

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Geohash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Geohash>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Geohash>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Geohash>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::Geohash

