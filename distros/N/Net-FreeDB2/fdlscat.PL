# -*- perl -*-

use strict;

my $script = <<'SCRIPT';
~startperl~ -w

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

use strict;
use Error qw (:try);

# Default options
my $client_name_def = 'fdcmds';
my $client_version_def = '0.5.0';

# Usage
use File::Basename;
my $basename=basename($0);
sub Usage {
	print STDERR <<EOF;
Usage: $basename [--h] [--i <infile>] [--o <outfile>] [--dev <device>]
            [--span <span>] [--protocol <protocol>]
            [--client_name <client_name>] [--client_version <client_version>]
            [--freedb_host <freedb_host>] [--freedb_port <freedb_port>]
            [--freedb_cgi <freedb_cgi>]
            [--proxy_host <proxy_host>] [--proxy_port <proxy_port>]
            [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]
  NOTES:
     --h shows this message
     --i no default
     --o defaults to STDOUT
     --dev defaults to Net::FreeDB2's default
     --span defaults to all tracks
     --protocol defaults to Net::FreeDB2's default
     --client_name defaults to $client_name_def
     --client_version defaults to $client_version_def
     --freedb_host defaults to Net::FreeDB2's default
     --freedb_port defaults to Net::FreeDB2's default
     --freedb_cgi defaults to Net::FreeDB2's default
     --proxy_host defaults to Net::FreeDB2's default
     --proxy_port defaults to Net::FreeDB2's default
     --proxy_user
     --proxy_passwd if empty is asked during processing if --proxy_host
       and --proxy_user set.
EOF
}

# Get options
my $h = 0;
my $i;
my $o;
my $dev;
my $span;
my $oggenc_b;
my $protocol;
my $client_name = $client_name_def;
my $client_version = $client_version_def;
my $freedb_host;
my $freedb_port;
my $freedb_cgi;
my $proxy_host;
my $proxy_port;
my $proxy_user;
my $proxy_passwd;
use Getopt::Long;
if (! GetOptions (
	'h' => \$h,
	'i=s' => \$i,
	'o=s' => \$o,
	'dev=s' => \$dev,
	'oggenc_b=s' => \$oggenc_b,
	'span=s' => \$span,
	'protocol=s' => \$protocol,
	'client_name=s' => \$client_name,
	'client_version=s' => \$client_version,
	'freedb_host=s' => \$freedb_host,
	'freedb_port=s' => \$freedb_port,
	'freedb_cgi=s' => \$freedb_cgi,
	'proxy_host=s' => \$proxy_host,
	'proxy_port=s' => \$proxy_port,
	'proxy_user=s' => \$proxy_user,
	'proxy_passwd=s' => \$proxy_passwd,
)) {
	&Usage;
	exit (1);
}

# Show usage
if ($h) {
	&Usage;
	exit (0);
}

# Open output file
my $fh;
if ($o) {
	use IO::File;
	$fh = IO::File->new ("> $o");
	defined ($fh) || throw Error::Simple ("ERROR: $basename: Failed to open file '$o' for writing.");
} else {
	use IO::File;
	$fh = IO::Handle->new_from_fd (fileno(STDOUT), 'w');
}

# Make connection
use Net::FreeDB2;
my $conn = Net::FreeDB2->connection ({
	protocol => $protocol,
	client_name => $client_name,
	client_version => $client_version,
	freedb_host => $freedb_host,
	freedb_port => $freedb_port,
	freedb_cgi => $freedb_cgi,
	proxy_host => $proxy_host,
	proxy_port => $proxy_port,
	proxy_user => $proxy_user,
	proxy_passwd => $proxy_passwd,
});

# Switch application
if ($basename =~ /lscat/) {
	# Get categories
	my @cat = $conn->lscat ();

	# Print the categories
	$fh->print ("@cat\n");
} elsif ($basename =~ /motd/) {
	# Print motd
	foreach my $line ($conn->motd ()) {
		$fh->print ($line, "\n");
	}
} elsif ($basename =~ /sites/) {
	# Print sites
	foreach my $site ($conn->sites ()->getSites ()) {
		print join (' ',
			$site->getSite (),
			$site->getPort (),
			$site->getLatitude (),
			$site->getLongitude (),
			$site->getDescription (),
		), "\n";
	}
} elsif ($basename =~ /query/) {
	# Read entry
	use Net::FreeDB2::Entry;
	my $entry;
	if ($i) {
		$entry = Net::FreeDB2::Entry->new ({fn => $i});
	} elsif ($dev) {
		$entry = Net::FreeDB2::Entry->new ({dev => $dev});
	} else {
		$entry = Net::FreeDB2::Entry->new ();
		$entry->readDev ();
	}

	# Query
	&getPasswd ();
	my $res = $conn->query ($entry);
	$res->hasError () && die ('Oops, error quering FreeDB/CDDB');

	# Get match
	my $match = &getMatch ($res);

	# Read match
	$res = $conn->read ($match);
	$res->hasError () && die ('Oops, error reading FreeDB/CDDB');
	$entry = $res->getEntry ();

	# Write entry
	$entry->write ({fh => $fh});
} elsif ($basename =~ /rip/) {
	# Read entry
	use Net::FreeDB2::Entry;
	my $entry;
	if ($i) {
		$entry = Net::FreeDB2::Entry->new ({fn => $i});
	} else {
		my $entry_dev;
		if ($dev) {
			$entry_dev = Net::FreeDB2::Entry->new ({dev => $dev});
		} else {
			$entry_dev = Net::FreeDB2::Entry->new ();
			$entry_dev->readDev ();
		}

		# Query
		&getPasswd ();
		my $res = $conn->query ($entry_dev);
		$res->hasError () && die ('Oops, error quering FreeDB/CDDB');

		# Get match
		my $match = &getMatch ($res);

		# Read match
		$res = $conn->read ($match);
		$res->hasError () && die ('Oops, error reading FreeDB/CDDB');
		$entry = $res->getEntry ();

		# Write entry
		$entry->write ({fh => $fh});
	}

	# Rip the CD
	my $tracks = scalar ($entry->getFrameOffset ());
	my ($min, $max) = &parseRange ($tracks);
	my @cmd = qw (cdparanoia);
	push (@cmd, '-d', $dev) if ($dev);
	push (@cmd, '-B');
	for (my $i = $min; $i <= $max; $i++) {
		my $title = $entry->getTtitlen ($i);
		$title =~ s/\s+/-/g;
		my @cmd = (@cmd, $i);

		# Execute command
		print STDERR "@cmd\n";
		system (@cmd);
		die ('Oops, command failed') if ($?>>8);

		# Rename output file
		my $src = sprintf ("track%02d.cdda.wav", $i);
		my $dest = sprintf ("%02d-%s.wav", $i, $title);
		print STDERR "mv $src $dest\n";
		rename ($src, $dest);
	}
} elsif ($basename =~ /oggenc/) {
	# Read entry
	use Net::FreeDB2::Entry;
	my $entry;
	if ($i) {
		$entry = Net::FreeDB2::Entry->new ({fn => $i});
	} else {
		my $entry_dev;
		if ($dev) {
			$entry_dev = Net::FreeDB2::Entry->new ({dev => $dev});
		} else {
			$entry_dev = Net::FreeDB2::Entry->new ();
			$entry_dev->readDev ();
		}

		# Query
		&getPasswd ();
		my $res = $conn->query ($entry_dev);
		$res->hasError () && die ('Oops, error quering FreeDB/CDDB');

		# Get match
		my $match = &getMatch ($res);

		# Read match
		$res = $conn->read ($match);
		$res->hasError () && die ('Oops, error reading FreeDB/CDDB');
		$entry = $res->getEntry ();

		# Write entry
		$entry->write ({fh => $fh});
	}

	# Encode the tracks
	my $tracks = scalar ($entry->getFrameOffset ());
	my ($min, $max) = &parseRange ($tracks);
	my @cmd = qw (oggenc);
	push (@cmd, '-b', $oggenc_b) if ($oggenc_b);
	for (my $i = $min; $i <= $max; $i++) {
		my $title = $entry->getTtitlen ($i);
		$title =~ s/\s+/-/g;
		my @cmd = (@cmd, sprintf ("%02d-%s.wav", $i, $title));

		push (@cmd, '-t', $entry->getTtitlen ($i)) if ($entry->getTtitlen ($i));
		push (@cmd, '-t', $entry->getArtist ()) if ($entry->getArtist ());
		push (@cmd, '-l', $entry->getTitle ()) if ($entry->getTitle ());
		push (@cmd, '-o', sprintf ("%02d-%s.ogg", $i, $title));

		# Execute command
		print STDERR "@cmd\n";
		system (@cmd);
		die ('Oops, command failed') if ($?>>8);
	}
}

# Exit OK
exit (0);

sub getPasswd {
	# Get proxy password if necessary
	if ($proxy_host && $proxy_user && !$proxy_passwd) {
		print STDERR "Enter password for $proxy_user\@$proxy_host: ";
		if ( system('stty -echo') != 0) {
			system('stty echo'); 
			die "Error setting terminal to not echo"; 
		}
		$proxy_passwd = <>;
		system('stty echo');
		print STDERR "\n";
		chomp ($proxy_passwd);
		$conn->setProxyPasswd ($proxy_passwd);
	}
}

sub getMatch {
	my $res = shift;

	my $match;

	if (scalar ($res->getMatches ()) == 0) {
		warn ('No matches found');
		exit (0);
	} elsif (scalar ($res->getMatches ()) == 1) {
		print STDERR "Single match found.\n";
		$match = ($res->getMatches ())[0];
	} else {
		print STDERR "Multiple matches found:\n";
		my $max = 0;
		foreach my $match ($res->getMatches ()) {
			$max++;
			print STDERR join (' ', "$max: ", $match->getCateg (), $match->getDiscid (), $match->getDtitle ()), "\n";
		}
		my $sel = 0;
		while (1) {
			print STDERR 'Select one (q for quit): ';
			$sel = <>;
			$sel =~ /^\s*q\s*$/ && exit (0);
			$sel = int ($sel);
			$sel > 0 && $sel <= $max && last;
		}
		$match = ($res->getMatches ())[$sel - 1];

	}
	return ($match);
}

sub parseRange {
	my $max = int (shift);

	# Return full span if $span not defined
	defined ($span) || return (1, $max);

	# Check for single span
	if ($span =~ /^[0-9]+$/ && int ($span) > 0) {
		if (int ($span) > $max) {
			throw Error::Simple ("ERROR: basename: Range failure.");
		} else {
			return (int ($span), int ($span));
		}
	}

	# Split the span parameter
	my @span = split (/-/, $span);

	# Check amount of parts
	(scalar (@span) > 2 || scalar (@span) < 1) && throw Error::Simple ("ERROR: basename: Range failure.");

	# Replace undefined values
	$span[0] = 1 if (! defined ($span[0]) || $span[0] eq '');
	$span[1] = $max if (! defined ($span[1]));

	# Check if $span[0] <= $span[1]
	$span[0] <= $span[1] || throw Error::Simple ("ERROR: basename: Range failure.");

	# Ckech the span
	$span[0] <= 0 && throw Error::Simple ("ERROR: basename: Range failure.");
	$span[1] > $max && throw Error::Simple ("ERROR: basename: Range failure.");

	# Return
	return (@span);
}
__END__

=head1 NAME

=over

=item fdlscat

Run a C<cddb lscat> command on a FreeDB/CDDB server

=item fdmotd

Run a C<motd> command on a FreeDB/CDDB server

=item fdquery

Run a C<cddb query> command on a FreeDB/CDDB server

=item fdrip

Rip a CD using FreeDB/CDDB info

=item fdsites

Run a C<sites> command on a FreeDB/CDDB server

=back

=head1 SYNOPSIS

=over

=item fdlscat | fdmotd | fdsites

[--h] [--o <outfile>] [--protocol <protocol>] [--client_name <client_name>] [--client_version <client_version>] [--freedb_host <freedb_host>] [--freedb_port <freedb_port>] [--freedb_cgi <freedb_cgi>] [--proxy_host <proxy_host>] [--proxy_port <proxy_port>] [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]

=item fdquery

[--h] [--i <infile>] [--o <outfile>] [--dev <device>] [--protocol <protocol>] [--client_name <client_name>] [--client_version <client_version>] [--freedb_host <freedb_host>] [--freedb_port <freedb_port>] [--freedb_cgi <freedb_cgi>] [--proxy_host <proxy_host>] [--proxy_port <proxy_port>] [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]

=item fdrip

[--h] [--i <infile>] [--dev <device>] [--span <span>] [--protocol <protocol>] [--client_name <client_name>] [--client_version <client_version>] [--freedb_host <freedb_host>] [--freedb_port <freedb_port>] [--freedb_cgi <freedb_cgi>] [--proxy_host <proxy_host>] [--proxy_port <proxy_port>] [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]

=item fdoggenc

[--h] [--i <infile>] [--dev <device>] [--oggenc_b <bitrate>] [--span <span>] [--protocol <protocol>] [--client_name <client_name>] [--client_version <client_version>] [--freedb_host <freedb_host>] [--freedb_port <freedb_port>] [--freedb_cgi <freedb_cgi>] [--proxy_host <proxy_host>] [--proxy_port <proxy_port>] [--proxy_user <proxy_user>] [--proxy_passwd <proxy_passwd>]

=back

=head1 DESCRIPTION

The programs C<fdlscat>, C<fdmotd>, C<fdquery>, C<fdrip>, C<fdsites> and C<fdoggenc> use L<Net::FreeDB2> modules to obtain information from FreeDB/CDDB servers and to process it.

All these programs are implemented with a single C<Perl> script which is intended as an example on how to use the L<Net::FreeDB2> modules. Hence there is a ceratin degree of simplification in the options parsing.

=head2 Options:

=over

=item --h

Show usage.

=item --i

Input file. No default.

=item --o

Output file. Defaults to C<STDOUT>.

=item --dev

CD device. Defaults to C<Net::FreeDB2's> default.

=item --oggenc_b

Bitrate for OGG encoding. See L<oggenc>.

=item --span

Span to rip or encode. Defaults to all tracks on CD.

Examples:
 3-7 : from 3 until 7
 -7  : from 1 until 7
 7-  : from 7 until the end of the CD
 7   : 7 only
 7-7 : 7 only

=item --protocol

The communication protocol: C<HTTP> or C<CDDBP>. Defaults to C<Net::FreeDB2's> default.

=item --client_name

Client name. Defaults to C<fdcmds>.

=item --client_version

Client version. Defaults to C<0.5.0>.

=item --freedb_host

FreeDB/CDDB host. Defaults to C<Net::FreeDB2's> default.

=item --freedb_port

Port on FreeDB/CDDB host. Defaults to C<Net::FreeDB2's> default.

=item --freedb_cgi

Cgi on FreeDB/CDDB B<HTTP> host. Defaults to C<Net::FreeDB2's> default.

=item --proxy_host

Proxy host.

=item --proxy_port

Port on proxy host. Defaults to C<Net::FreeDB2's> default.

=item --proxy_user

User name for proxy host.

=item --proxy_passwd

Password for user on proxy host. Prompted for if empty and B<--proxy_host> and B<--proxy_user> are set.

=back

=head1 SEE ALSO

L<fdcdi>

=head1 EXAMPLE

Quick and dirty rip:
 $ fdrip

Slightly more sophisticated rip:
 $ fdcdi --o cd-tech.cddb
 $ fdquery --i cd-tech.cddb --o cd-query.cddb
 $ # Edit file cd-query.cddb
 $ fdrip --i cd-query.cddb

=head1 BUGS

None known (yet).

=head1 HISTORY

First development: September 2002

=head1 AUTHOR

Vincenzo Zocca E<lt>Vincenzo@Zocca.comE<gt>

=head1 COPYRIGHT

Copyright 2002, Vincenzo Zocca.

=head1 LICENSE

This file is part of the C<Net::FreeDB2> module hierarchy for Perl by
Vincenzo Zocca.

The Net::FreeDB2 module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The Net::FreeDB2 module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Net::FreeDB2 module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut
SCRIPT

use Config;

my $file = __FILE__; $file =~ s/\.PL$//;

$script =~ s/\~(\w+)\~/$Config{$1}/eg;
if (!(open(FILE, ">$file")) ||
	!(print FILE $script) ||
	!(close(FILE))) {
	die "Error while writing $file: $!\n";
}
print "Extracted $file from ",__FILE__," with variable substitutions.\n";

# end

