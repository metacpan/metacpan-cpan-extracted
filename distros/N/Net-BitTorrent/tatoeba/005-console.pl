#!perl -w -I../lib
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Carp qw[croak carp];
use Time::HiRes qw[sleep];
use Math::BigInt 0.78 try => q[Pari,GMP,FastCalc,Calc];
use Net::BitTorrent::Protocol qw[:types];
use Net::BitTorrent::Util qw[:bencode];
use Net::BitTorrent::Torrent qw[:status];
use Net::BitTorrent;
$|++;
my ($dir, $chk, $int, $VERSION, $port, $ver, @tor, %opts)
    = (q[./], 1, 1, 0.050);
GetOptions(
    q[check!]      => \$chk,
    q[directory:s] => \$dir,
    q[help|?]      => sub {
        pod2usage({-verbose  => 99,
                   -sections => q[Synopsis|Options|Author]
                  }
        );
    },
    q[options=s%] => sub { $opts{$_[1]} = $_[2] if $_[1] =~ m[^_set] },
    q[port:i]     => \$port,
    q[torrent=s@] => \@tor,
    q[version] => sub { exit printf qq[$0 v$VERSION] },
) || pod2usage(2);
@tor = grep {-f} @tor, @ARGV;
pod2usage({-verbose  => 99,
           -sections => q[Synopsis|Author],
          }
) if !@tor;
my $bt = new Net::BitTorrent({LocalPort => $port})
    or croak q[Failed to create Net::BitTorrent object];

sub piece_status {
    my $args   = pop;
    my $t      = $args->{q[Torrent]};
    my $have   = grep {$_} split //, unpack q[b*], $t->bitfield;
    my $wanted = grep {$_} split //, unpack q[b*], $t->_wanted;
    return printf qq[%s: %04d|%s|%4d/%4d|% 3.2f%%\r],
        pop, $args->{q[Index]}, $t->as_string(), $have, $t->piece_count,
        100 - ($wanted / $t->piece_count * 100);
}

sub trans_status {
    printf qq[%-10s p:%15s:%-5d i:%4d o:%7d l:%5d  \r],
        shift, $_[0]->{q[Peer]}->host, $_[0]->{q[Peer]}->port,
        $_[0]->{q[Payload]}{q[Index]},
        $_[0]->{q[Payload]}{q[Offset]},
        $_[0]->{q[Payload]}{q[Length]};
}

sub save {
    for my $torrent (values %{$bt->torrents || {}}) {
        $torrent->save_resume_data;
    }
}
$SIG{q[INT]} = sub {
    save();
    $int = $int + 3 > time ? exit : time;
    print join qq[\n], map { $_->as_string(1) } $bt, values %{$bt->torrents};
};
END { save if $bt }
$bt->on_event(
    q[incoming_packet],
    sub {
        trans_status(q[REJECTED], $_[1]) if $_[1]{q[Type]} eq REJECT;
        trans_status(q[RECEIVED], $_[1]) if $_[1]{q[Type]} eq PIECE;
    }
);
$bt->on_event(
    q[outgoing_packet],
    sub {
        trans_status(q[REQUESTING], $_[1]) if $_[1]{q[Type]} eq REQUEST;
        trans_status(q[CANCELING],  $_[1]) if $_[1]{q[Type]} eq CANCEL;
        trans_status(q[SENDING],    $_[1]) if $_[1]{q[Type]} eq PIECE;
    }
);
$bt->on_event(q[piece_hash_pass], sub { piece_status(q[pass], $_[1]); });
$bt->on_event(q[piece_hash_fail], sub { piece_status(q[fail], $_[1]); });
for my $path (@tor) {
    my $obj = $bt->add_torrent({Path    => $path,
                                BaseDir => $dir,
                                Status  => ($chk ? START_AFTER_CHECK : ()),
                                Resume  => $path . '.resume'
                               }
    ) || next;
    $obj->status & CHECKED || $obj->hashcheck;
    printf qq[Loaded '$path' [%s...%s%s]\n],
        $obj->infohash =~ m[^(.{4}).+(.{4})$], $obj->private ? q[] : q[|DHT];
}
$bt->on_event(q[file_error], sub { carp $_[1]->{q[Message]} });
for my $obj ($bt, values %{$bt->torrents}) {
    for my $opt (keys %opts) { $obj->$opt($opts{$opt}) if $obj->can($opt); }
}
$bt->do_one_loop(0.25) && sleep(0.50) while 1;

=pod

=head1 NAME

005-console.pl - A quick demo of what can be accomplished in (slightly) less than 100 lines

=head1 Description

In truth, this is still a B<very> basic demonstration of a full
C<Net::BitTorrent>-based client but I wanted to fit this into C<100>
comfortable lines.

It's certainly enough to get you started.

=head1 Synopsis

005-console.pl - (Sorta) Complete Net::BitTorrent client in under 100 lines

 005-console.pl file.torrent
   or
 005-console.pl [options] [file ...]

 Options:
   -t     --torrent     .torrent file to load
   -p     --port        TCP/UDP port opened for incoming connections
   -d     --directory   Base directory to store downloaded files
   --no-check           Skip integrity check at start
   --options            Advanced settings
   -?     --help        Display full documentation
   --version            Display version information

To get client-wide progress updates, press C<Ctrl+C>.  For more, see
perldoc.

=head1 Options

=over 8

=item B<--torrent>

Open this .torrent file.

You may pass several -torrent parameters and load more than one .torrent
torrent.

=item B<--port>

Port number opened to the world for incoming connections.  This defaults
to C<0> and lets L<Net::BitTorrent|Net::BitTorrent> bind to a random,
unused port.

=item B<--directory>

Relative or absolute directory used as a base directory for storage.  By
default, this is the current working directory.

Please see L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> for
related information.

=item B<--no-check>

If found, the files will not be checked for integrity and we assume that
we have none of the data of this torrent.

=item B<--options>

Allows otherwise private settings to be changed.  For example, to set the
upload bandwidth limit...

  005-console.pl --options _set_max_ul_rate=8192 [...]

You may pass several C<--options> parameters.

=item B<--version>

Guess.

=back

=head1 Lowdown

This section only makes sense when you view the source.

=over

=item Line 8

If encryption is enabled, L<Net::BitTorrent::Peer|Net::BitTorrent::Peer>
relies on L<Math::BigInt|Math::BigInt> to do all the 96bit math the MSE
specification requires. This math is done for each and every encrypted
connection so, using the slow, stock libraries will cause you all sorts
of headaches.

Here, we prioritize using the easy-to-build Pari library. I suggest you
do the same in your scripts if you leave encryption enabled.

=item Line 16

Uses L<Getopt::Long|Getopt::Long> to parse any L<options|/"Options"> and,
if none are found, falls back to L<Pod::Usage|Pod::Usage> and lists all
available options.

=item Line 30

Shoves everything L<Getopt::Long|Getopt::Long> couldn't parse and looks
like a file on the system into the list of potential .torrent files.

=item Line 31

Prints usage info and exits if no torrents are in the aforementioned
list.

=item Line 35

Creates L<Net::BitTorrent|Net::BitTorrent> object which opens on the port
defined with the C<-p> command line parameter (falls back to C<0>).

If L<N::B|Net::BitTorrent> fails to create the new object, the script
croaks here with an error message.

=item Line 38

This is the function used later by the C<piece_hash_pass> and
C<piece_hash_pass> callbacks.

It prints (among other things) the piece's index, the related infohash,
and a rough estimate of the torrent's completion.

=item Line 48

This function is used by the C<incoming_packet> and C<outgoing_packet>
callbacks to report various block-level status updates in both
directions.

=item Line 56

This function saves resume data for every torrent loaded. For more
information on resume data and how it's used, see
L<004-resume.pl|004-resume.pl>.

=item Line 61

Sets a handler to catch C<Ctrl+C> key combinations. When triggered, it
L<saves|/"Line 56"> the resume data and dumps
L<"verbose information"|Net::BitTorrent::Torrent/"as_string ( [ VERBOSE ] )">
about each loaded torrent.

If this is triggered more than once in a C<3> second period, the script
will exit.

=item Line 66

Saves resume data on script exit.

=item Lines 67-83

Sets client-wide callbacks for C<incoming_packet>, C<outgoing_packet>,
C<piece_hash_pass>, and C<piece_hash_fail> events. These in turn hand
most of their data to functions described earlier.

=item Lines 84-94

Loops through each torrent file listed on the commandline...

=over

=item Line 85

Attempts to load the torrent into a new
L<Net::BitTorrent::Torrent object|Net::BitTorrent::Torrent>. The new
object stores related data in the L<directory|/"--directory"> defined on
the command line, if the user decided to
L<skip hash checking|/"--no-check">, the torrent's
L<status|Net::BitTorrent::Torrent/"status ( )"> is set to C<START>
otherwise, it defaults to C<START_AFTER_CHECK>. The
L<Resume|Net::BitTorrent::Torrent/"Resume"> parameter is set to
C<[.torrent's filename].resume>.

If creating the new object fails, the script skips to the next potential
torrent.

=item Line 91

Validates the new L<Net::BitTorrent::Torrent object|Net::BitTorrent::Torrent>
object's data if the user hasn't disabled it on the command line.

=item Line 92

Prints a quick status line which includes the torrent's path, a snippet
of the infohash, and an indication of whether or not the torrent allows
the use or the DHT swarm.

=back

=item Line 95

Sets a client-wide callback for C<file_error> events.

Note that this callback is set I<after> the torrents are hashchecked.
I've done this because this event is triggered every time
L<Net::BitTorrent::Torrent::File|Net::BitTorrent::Torrent::File> attempts
to open the file and fails. So, unless the files are preexisting, the
script would dump screens full of useless error messages.

=item Line 96-98

This nested loop is really more of a hack than useful code... it allows
users to set otherwise private data in each loaded torrent. In the wrong
hands, this can be dangerous, in the right hands, it's a great way to
test activity in the swarm under various conditions without digging too
deeply into the source. For more, see the
L<C<--options> ...option|/"--options">.

You'll probably not need anything that messes with C<N::B>'s internals in
your script.

=item Line 99

Goes to work and takes a short nap between loops to save the CPU.

=back

=head1 Notes

This script I<used> to be installed with L<Net::BitTorrent|Net::BitTorrent>
as C<bittorrent.pl>.

=head1 See Also

For more examples, see the files under the C</tatoeba/> directory.

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

=for svn $Id: 005-console.pl d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
