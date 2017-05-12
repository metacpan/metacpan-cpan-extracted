#!perl -w -I../lib
use strict;
use warnings;
use Data::Dump;
use Net::BitTorrent::Torrent;
my $torrent = Net::BitTorrent::Torrent->new({Path => 'a.legal.torrent'})
    or exit;
$torrent->as_string(1);
dd $torrent->raw_data(1);
print map { qq[\n] . $_->path } @{$torrent->files};

=pod

=head1 NAME

001-torrent-info.pl - Demonstration of using a standalone Net::BitTorrent::Torrent object to gather information

=head1 Description

This is a demonstration of how standalone C<Net::BitTorrent::Torrent>
objects can be created and used to gather information from a .torrent
file.

=head1 Synopsis

 001-torrent-info.pl

=head1 Lowdown

This section only makes sense when you view the source.

=over

=item Line 6

Returns a new C<Net::BitTorrent::Torrent> object.  Created this way,
(without a 'C<Client>' parameter) the new object is not loaded into a
parent C<Net::BitTorrent> client.

You may use any of the arguments listed in
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent/"new ( { [ARGS] } )">'s
constructor.  If there's a problem loading the .torrent, an error will
(probably) be C<Carp>ed by C<Net::BitTorrent::Torrent>.

=item Line 8

Calls the debugging method
L<as_string|Net::BitTorrent::Torrent/"as_string ( [ VERBOSE ] )"> just
to give you a rundown of what can be parsed from the file.

=item Line 9

Prints a dump of the .torrent file's
L<metadata|Net::BitTorrent::Torrent/"raw_data ( [ RAW ] )">.

=item Line 10

Prints a list of the .torrent's
L<files|Net::BitTorrent::Torrent/"files ( )">.  This line also uses the
L<path|Net::BitTorrent::Torrent::File/"path ( )"> method from
L<Net::BitTorrent::Torrent::File|Net::BitTorrent::Torrent::File>.

=back

=head1 See Also

Please see L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent>'s
documentation for a list of methods and accessors.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

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

=for svn $Id: 001-torrent-info.pl d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
