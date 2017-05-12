#!/usr/bin/perl -w
package Net::BitTorrent::Util;
{
    use strict;
    use warnings;
    use Carp qw[carp];
    use List::Util qw[min max shuffle sum];
    use version qw[qv];
    our $VERSION_BASE = 50; our $UNSTABLE_RELEASE = 0; our $VERSION = sprintf(($UNSTABLE_RELEASE ? q[%.3f_%03d] : q[%.3f]), (version->new(($VERSION_BASE))->numify / 1000), $UNSTABLE_RELEASE);
    use vars qw[@EXPORT_OK %EXPORT_TAGS];
    use Exporter qw[];
    *import = *import = *Exporter::import;
    @EXPORT_OK = qw[bencode bdecode compact uncompact];
    %EXPORT_TAGS = (all     => [@EXPORT_OK],
                    bencode => [qw[bencode bdecode]],
                    compact => [qw[compact uncompact]],
    );

    sub bencode {
        my ($ref) = @_;
        $ref = defined $ref ? $ref : q[];
        if (not ref $ref) {
            return (  (defined $ref and $ref =~ m[^[-+]?\d+$])
                    ? (q[i] . $ref . q[e])
                    : (length($ref) . q[:] . $ref)
            );
        }
        elsif (ref $ref eq q[ARRAY]) {
            return join(q[], q[l], (map { bencode($_) } @{$ref}), q[e]);
        }
        elsif (ref $ref eq q[HASH]) {
            return
                join(q[], q[d],
                     (map { bencode($_) . bencode($ref->{$_}) }
                      sort keys %{$ref}
                     ),
                     q[e]
                );
        }
        return q[];
    }

    sub bdecode {
        my ($string) = @_;
        return if not defined $string;
        my ($return, $leftover);
        if (   $string =~ m[^([1-9]\d*):]s
            or $string =~ m[^(0+):]s)
        {   my $size = $1;
            $return = q[] if $1 =~ m[^0+$];
            $string =~ s|^$size:||s;
            while ($size) {
                my $this_time = min($size, 32766);
                $string =~ s|^(.{$this_time})||s;
                return if not $1;
                $return .= $1;
                $size = max(0, ($size - $this_time));
            }
            return wantarray ? ($return, $string) : $return;    # byte string
        }
        elsif ($string =~ s|^i([-+]?\d+)e||s) {                 # integer
            return wantarray ? (int($1), $string) : int($1);
        }
        elsif ($string =~ s|^l(.*)||s) {                        # list
            $leftover = $1;
            while ($leftover and $leftover !~ s|^e||s) {
                (my ($piece), $leftover) = bdecode($leftover);
                push @$return, $piece;
            }
            return wantarray ? (\@$return, $leftover) : \@$return;
        }
        elsif ($string =~ s|^d(.*)||s) {                        # dictionary
            $leftover = $1;
            while ($leftover and $leftover !~ s|^e||s) {
                my ($key, $value);
                ($key, $leftover) = bdecode($leftover);
                ($value, $leftover) = bdecode($leftover) if $leftover;
                $return->{$key} = $value if defined $key;
            }
            return wantarray ? (\%$return, $leftover) : \%$return;
        }
        return;
    }

    sub compact {
        my (@peers) = @_;
        if (not @peers) {return}
        my $return;
        my %seen;
    PEER: for my $peer (grep(defined && !$seen{$_}++, @peers)) {
            next if not $peer;
            my ($ip, $port) = split(q[:], $peer, 2);
            if ($peer
                !~ m[^(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.]?){4}):\d+$]
                )
            {   carp q[Invalid IP address: ] . $peer;
            }
            elsif ($port > 2**16) {
                carp q[Port number beyond ephemeral range: ] . $peer;
            }
            else {
                $return .= pack q[C4n],
                    ($ip =~ m[^([\d]+)\.([\d]+)\.([\d]+)\.([\d]+)$]),
                    int $port;
            }
        }
        return $return;
    }

    sub uncompact {
        my $string = shift;
        if (not defined $string) { return; }
        my %peers;
        while ($string =~ m|(....)(..)|g) {
            $peers{
                sprintf(q[%d.%d.%d.%d:%d],
                        unpack(q[C4], $1),
                        unpack(q[n],  $2))
                }++;
        }
        return (shuffle(%peers ? keys %peers : ()));
    }
    1;
}

=pod

=head1 NAME

Net::BitTorrent::Util - BitTorrent Related Utility Functions

=head1 Importing From Net::BitTorrent::Util

By default, nothing is exported.

You may import any of the following or use one or more of these tags:

=over 2

=item C<:all>

Everything is imported into your namespace.

=item C<:bencode>

You get the two Bencode-related functions: L<bencode|/"bencode ( ARGS )">
and L<bdecode|/"bdecode ( STRING )">.  For more on Bencoding, see the
BitTorrent Protocol documentation.

=item C<:compact>

Imports the tracker response-related functions
L<compact|/"compact ( LIST )"> and L<uncompact|/"uncompact ( STRING )">.

=back

=head1 Functions

=over 4

=item C<bencode ( ARGS )>

Expects a single value (basic scalar, array reference, or hash
reference) and returns a single string.

Bencoding is the BitTorrent protocol's basic serialization and
data organization format.  The specification supports integers,
lists (arrays), dictionaries (hashes), and byte strings.

=item C<bdecode ( STRING )>

Expects a bencoded string.  The return value depends on the type of
data contained in the string.

=item C<compact ( LIST )>

Compacts a list of IPv4:port strings into a single string.

A compact peer is 6 bytes; the first four bytes are the host (in network
byte order), the last two bytes are the port (again, in network byte
order).

=item C<uncompact ( STRING )>

Inflates a compacted string of peers and returns a list of IPv4:port
strings.

=back

=head1 See Also

=over

=item The BitTorrent Protocol Specification

http://bittorrent.org/beps/bep_0003.html#the-connectivity-is-as-follows

=item BEP 32: Tracker Returns Compact Peer Lists

http://bittorrent.org/beps/bep_0023.html

=item Other Bencode related modules:

=over

=item L<Convert::Bencode|Convert::Bencode>

=item L<Bencode|Bencode>

=item L<Convert::Bencode_XS|Convert::Bencode_XS>

=back

=back

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2009 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.  See the F<LICENSE>
file included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

Neither this module nor the L<Author|/Author> is affiliated with
BitTorrent, Inc.

=for svn $Id: Util.pm 07f0c35 2010-04-02 18:31:29Z sanko@cpan.org $

=cut
