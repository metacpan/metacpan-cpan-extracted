package Net::BitTorrent::Protocol::BEP07;
use strict;
use warnings;
use Carp qw[carp];
our $VERSION = "1.5.3";
use vars qw[@EXPORT_OK %EXPORT_TAGS];
use Exporter qw[];
*import = *import = *Exporter::import;
@EXPORT_OK = qw[compact_ipv6 uncompact_ipv6];
%EXPORT_TAGS = (all => [@EXPORT_OK], bencode => [@EXPORT_OK]);

sub uncompact_ipv6 {
    return $_[0] ?
        map {
        my (@h) = unpack 'n*', $_;
        [sprintf('%X:%X:%X:%X:%X:%X:%X:%X', @h), $h[-1]]
        } $_[0] =~ m[(.{20})]g
        : ();
}

sub compact_ipv6 {
    my $return;
    my %seen;
PEER: for my $peer (grep(defined && !$seen{$_}++, @_)) {
        my ($ip, $port) = @$peer;
        $ip // next;
        if ($port > 2**16) {
            carp 'Port number beyond ephemeral range: ' . $peer;
        }
        else {
            next PEER unless $ip;
            if ($ip =~ /^(.+):(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
            {    # mixed hex, dot-quad
                next PEER if $2 > 255 || $3 > 255 || $4 > 255 || $5 > 255;
                $ip = sprintf("%s:%X%02X:%X%02X", $1, $2, $3, $4, $5)
                    ;    # convert to pure hex
            }
            my $c;
            next PEER
                if $ip =~ /[^:0-9a-fA-F]/ ||    # non-hex character
                    #(($c = $ip) =~ s/::/x/ && $c =~ /(?:x|:):/)
                    #||                          # double :: ::?
                    $ip =~ /[0-9a-fA-F]{5,}/;   # more than 4 digits
            $c = $ip =~ tr/:/:/;                # count the colons
            next PEER if $c < 7 && $ip !~ /::/;
            if ($c > 7) {                       # strip leading or trailing ::
                next PEER unless $ip =~ s/^::/:/ || $ip =~ s/::$/:/;
                next PEER if --$c > 7;
            }
            $ip =~ s/::/:::/ while $c++ < 7;    # expand compressed fields
            $ip .= 0 if $ip =~ /:$/;
            next if $seen{$ip . '|'. $port}++;
            $return .= pack('H36', join '', split /:/, $ip) . pack 'n', $port;
        }
    }
    return $return;
}
1;

=pod

=head1 NAME

Net::BitTorrent::Protocol::BEP07 - Utility functions for BEP07: IPv6 Tracker Extension

=head1 Importing From Net::BitTorrent::Protocol::BEP07

By default, nothing is exported.

You may import any of the following or use one or more of these tag:

=over

=item C<:all>

Imports the tracker response-related functions
L<compact|/"compact_ipv6 ( LIST )"> and
L<uncompact|/"uncompact_ipv6 ( STRING )">.

=back

=head1 Functions

=over

=item C<compact_ipv6 ( @list )>

Compacts a list of [IPv6, port] values into a single string.

A compact peer is 18 bytes; the first 16 bytes are the host and the last two
bytes are the port.

=item C<uncompact_ipv6 ( $string )>

Inflates a compacted string of peers and returns a list of [IPv6, port]
values.

=back

=head1 See Also

=over

=item BEP 07: IPv6 Tracker Extension - http://bittorrent.org/beps/bep_0007.html

=back

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2010-2012 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=cut
