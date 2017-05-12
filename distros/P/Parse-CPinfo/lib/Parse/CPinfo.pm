package Parse::CPinfo;

use 5.006_001;
use strict;
no warnings;
use base qw/Exporter/;
use Carp;
use IO::File;
require Exporter;

our $VERSION = '0.882';

# extracted from Regexp::Common
my $re_mac =
'(?:(?:[0-9a-fA-F]{1,2}):(?:[0-9a-fA-F]{1,2}):(?:[0-9a-fA-F]{1,2}):(?:[0-9a-fA-F]{1,2}):(?:[0-9a-fA-F]{1,2}):(?:[0-9a-fA-F]{1,2}))';
my $re_net_ipv4 =
'(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))';

sub new {
	my $class = shift;
	my $self  = {};
	bless $self, $class;
	return $self;
}

sub readfile {
	my $self     = shift;
	my $filename = shift;

	# keep copy of filename in object
	$self->{'_filename'} = $filename;
	my $fh = new IO::File($filename, 'r');
	if (!defined($fh)) {
		croak "Unable to open $filename for reading";
	}

	# ensure we are in binary mode as some system (win32 for example)
	# will assume we are handling text otherwise.
	binmode $fh, ':raw';

	my @lines = <$fh>;
	chomp @lines;
	my $linenumber = 0;
	while ($linenumber < $#lines) {
		$linenumber++;
		if ($lines[$linenumber] =~ m/^\={46}$/o) {
			$linenumber++;
			my $section = $lines[$linenumber];
			$linenumber++;

			foreach (0 .. $linenumber) {
				$linenumber++;
				if ($lines[$linenumber] !~ m/^\={46}$/o) {
					$lines[$linenumber] =~ s/\r\n//g;
					$lines[$linenumber] =~ s/\r//g;
					$lines[$linenumber] =~ s/\n//g;
					$self->{'config'}->{$section} = $self->{'config'}->{$section} . "$lines[$linenumber]\n";
				}
				else {
					$linenumber--;
					last;
				}
			}
		}
	}
	$self->_parseinterfacelist();
	return 1;
}

sub _parseinterfacelist {
	my $self         = shift;
	my $ifconfigtext = $self->{'config'}->{'IP Interfaces'};
	if (!$ifconfigtext) {
		return;
	}
	my @s = split /\n/, $ifconfigtext;
	my ($int);
	foreach my $line (@s) {
		chomp $line;
		if ($line =~ m/^(\w+)\s+/o) {
			my $match = $1;
			if ($match !~ m/ifconfig/o) {
				$int = $1;
				$self->{'interface'}->{$int}->{'name'} = $int;
			}
		}
		if ($line =~ m/Link encap:(\w+)\s+/io) {
			$self->{'interface'}->{$int}->{'encap'} = $1;
		}
		if ($line =~ m/HWaddr ($re_mac)/io) {
			$self->{'interface'}->{$int}->{'hwaddr'} = $1;
		}
		if ($line =~ m/inet addr:($re_net_ipv4)/io) {
			$self->{'interface'}->{$int}->{'inetaddr'} = $1;
		}
		if ($line =~ m/bcast:($re_net_ipv4)/io) {
			$self->{'interface'}->{$int}->{'broadcast'} = $1;
		}
		if ($line =~ m/mask:($re_net_ipv4)/io) {
			$self->{'interface'}->{$int}->{'mask'}       = $1;
			$self->{'interface'}->{$int}->{'masklength'} = $self->_ipv4_msk2cidr($self->{'interface'}->{$int}->{'mask'});
		}
		if ($line =~ m/MTU:(\d+)/io) {
			$self->{'interface'}->{$int}->{'mtu'} = $1;
		}
	}
	return 1;
}

sub _ipv4_msk2cidr {
	my $self = shift;
	my $mask = shift;
	($mask) = $mask =~ m/(\d+\.\d+\.\d+\.\d+)/o;

	if (! defined($mask)) {
		return undef;
	}

	for (split /\./, $mask) {
		if ($_ < 0 or $_ > 255) {
			return undef;
		}
	}
	my @bytes = split /\./, $mask;

	my $cidr = 0;
	for (@bytes) {
		my $bits = unpack("B*", pack("C", $_));
		$cidr += $bits =~ tr /1/1/;
	}
	return $cidr;
}

sub getInterfaceList {
	my $self = shift;
	return keys %{$self->{'interface'}};
}

sub getInterfaceInfo {
	my $self      = shift;
	my $interface = shift;
	return $self->{'interface'}{$interface};
}

sub getSectionList {
	my $self = shift;
	my @r;
	foreach my $section (sort keys %{$self->{config}}) {
		push @r, $section;
	}
	return @r;
}

sub getSection {
	my $self    = shift;
	my $query   = shift;
	my $section = $self->{'config'}->{$query};
	return $section;
}

sub getHostname {
	my $self = shift;
	my @section = split(/\n/, $self->getSection('System Information'));
	my $hostname;
	foreach my $linenumber (0 .. $#section) {
		if ($section[$linenumber] =~ m/Issuing 'hostname'/i) {
			$hostname = $section[$linenumber + 2];
			chomp $hostname;
			last;
		}
	}
	if (defined($hostname)) {
		return $hostname;
	}
	else {
		return undef;
	}
}

1;
__END__

=head1 NAME

Parse::CPinfo - Perl extension to parse output from cpinfo 

=head1 SYNOPSIS

  use Parse::CPinfo;
  my $p = Parse::CPinfo->new();
  $p->readfile('cpinfofile');

  # print the section containing the fwm version string 
  print $p->getSection('FireWall-1 Management (fwm) Version Information');

  # Get a list of interfaces
  my @l = $p->getInterfaceList();

  foreach my $int(@l) {
      print "Interface $int\n";
	  print "IP Address: " . $int->{'inetaddr'} . "\n";
  }


=head1 DESCRIPTION

This module parses the output from B<cpinfo>.  B<cpinfo> is a utility provided
by Check Point Software, used for diagnostic purposes.


=head1 SUBROUTINES/METHODS

The following are the object methods:

=head2 new

Create a new parser object like this:
my $p = Parse::CPinfo->new();

=head2 readfile

After creating the parser object, ask it to read the B<cpinfo> file
for you:
$parser->readfile('/full/path/to/cpinfofile');

=head2 getSectionList

Use this method to get a list of valid sections.  Returns an array.

=head2 getSection

Use this method to get a section of the cpinfo file.  Returns a scalar.

=head2 getHostname

Use this method to get the hostname of the server.  Returns a scalar.

=head2 getInterfaceList

Use this method to get a list of the active interfaces.  Returns an array.

=head2 getInterfaceInfo

Use this method to get information about a specific interface.  Takes a
scalar (interface name) and returns a hash.

=head1 SEE ALSO

Check Point Software Technologies, Ltd., at
http://www.checkpoint.com/

=head1 AUTHOR

Matthew M. Lange, E<lt>mmlange@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

This library hasn't been extensively tested.  I'm sure there are bugs in the code.
Please file a bug report at http://rt.cpan.org/ if you find a bug.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Matthew M. Lange

This library is released under the GNU Public License.

=cut

