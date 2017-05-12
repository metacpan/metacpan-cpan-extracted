#!/bin/perl -w
#
# TcpDumpLog.pm - Net::TcpDumpLog library to read tcpdump/libpcap files.
#
# 17-Oct-2003   Brendan Gregg
# 19-Oct-2003	Brendan Gregg	Added code to check endian of files.

package Net::TcpDumpLog;

use strict;
use vars qw($VERSION);

$VERSION = '0.11';

# new - create the tcpdump object.
# 	An optional argument is the number of bits this OS uses to store
#	times. Without this argument, this will use whatever the OS thinks
#	it should use. By using this argument (32/64) you can force 
#	behaviour, which may be useful when transferring logs from one
#	OS to another. Why this is so important is that the actual 
#	tcpdump/libpcap file format changes depending on the bits.
#
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	my $bits = shift;
	my $skip = shift;

	$self->{major} = undef;
	$self->{minor} = undef;
	$self->{zoneoffset} = undef;
	$self->{accuracy} = undef;
	$self->{dumplength} = undef;
	$self->{linktype} = undef;
	$self->{bigendian} = undef;
	$self->{data} = [];
	$self->{length_orig} = [];
	$self->{length_inc} = [];
	$self->{drops} = [];
	$self->{seconds} = [];
	$self->{msecs} = [];
	$self->{count} = 0;
	$self->{sizeint} = length(pack("I",0));

	if (defined $bits && $bits == 64) {
		$self->{bits} = 64;
	} elsif (defined $bits && $bits == 32) {
		$self->{bits} = 32;	
	} else {
		$self->{bits} = 0;	# Use native OS bits
	}

	if (defined $skip && $skip > 0) {
		$self->{skip} = $skip;
	}

	bless($self,$class);
	return $self;
}

# read - read the tcpdump file into memory
#
sub read {
        my $self = shift;
        my $file = shift;
        my ($header,$length,$ident,$version,$linktype,$header_rec,
         $zoneoffset,$accuracy,$frame_length_inc,$frame_length_orig,
	 $frame_drops,$frame_seconds,$frame_msecs,$frame_data,
	 $pad,$major,$minor,$dumplength,$rest,$more);
        $self->{count} = 0;
        my $num = 0;

        ### Open tcpdump file
        open(TCPDUMPFILE,"$file") ||
         die "ERROR: Can't read log $file: $!\n";
	binmode(TCPDUMPFILE);		# backward OSs

        ### Fetch tcpdump header
        $length = read(TCPDUMPFILE,$header,24);
        die "ERROR: Can't read from log $file\n" if $length < 24;

        ### Check file really is a tcpdump file
	($ident,$rest) = unpack('a4a20',$header);

	if ($ident !~ /^\241\262\303\324/ &&
	    $ident !~ /^\324\303\262\241/ &&
	    $ident !~ /^\241\262\315\064/ &&
	    $ident !~ /^\064\315\262\241/){
	        die "ERROR: Not a tcpdump file (or unknown version) $file\n";
	}

	### Find out what type of tcpdump file it is
        if ($ident =~ /^\241\262\303\324/) { 
		#
		#  Standard format big endian, header "a1b2c3d4"
		#  Seen from: 
		#	Solaris tcpdump
		#	Solaris Ethereal "libpcap" format
		#
		$self->{style} = "standard1"; 
		$self->{bigendian} = 1;
        	($ident,$major,$minor,$zoneoffset,$accuracy,$dumplength,
		 $linktype) = unpack('a4nnNNNN',$header);
	}
        if ($ident =~ /^\324\303\262\241/) { 
		#
		#  Standard format little endian, header "d4c3b2a1"
		#  Seen from:
		#	Windows Ethereal "libpcap" format
		#
		$self->{style} = "standard2"; 
		$self->{bigendian} = 0;
        	($ident,$major,$minor,$zoneoffset,$accuracy,$dumplength,
		 $linktype) = unpack('a4vvVVVV',$header);
	}
        if ($ident =~ /^\241\262\315\064/) {
		#
		#  Modified format big endian, header "a1b2cd34"
		#  Seen from:
		#	Solaris Ethereal "modified" format
		#
		$self->{style} = "modified1"; 
		$self->{bigendian} = 1;
        	($ident,$major,$minor,$zoneoffset,$accuracy,$dumplength,
		 $linktype) = unpack('a4nnNNNN',$header);
	}
        if ($ident =~ /^\064\315\262\241/) { 
		#
		#  Modified format little endian, header "cd34a1b2"
		#  Seen from:
		#	Red Hat tcpdump
		#	Windows Ethereal "modified" format
		#
		$self->{style} = "modified2"; 
		$self->{bigendian} = 0;
        	($ident,$major,$minor,$zoneoffset,$accuracy,$dumplength,
		 $linktype) = unpack('a4vvVVVV',$header);
	}

        ### Store values
        $self->{version} = $version;
        $self->{major} = $major;
        $self->{minor} = $minor;
        $self->{zoneoffset} = $zoneoffset;
        $self->{accuracy} = $accuracy;
        $self->{dumplength} = $dumplength;
        $self->{linktype} = $linktype;

        #
        #  Read all packets into memory
        #
        $num = 0;
        while (1) {
	
		if ($self->{bits} == 64) {
			#
			#  64-bit timestamps, quads
			#

       		        ### Fetch record header
			$length = read(TCPDUMPFILE,$header_rec,24);

                	### Quit loop if at end of file
                	last if $length < 24;

			### Unpack header
                	($frame_seconds,$frame_msecs,$frame_length_inc,
			 $frame_length_orig) = unpack('QQLL',$header_rec);

		} elsif ($self->{bits} == 32) {
			#
			#  32-bit timestamps, big-endian
			#

	                ### Fetch record header
	                $length = read(TCPDUMPFILE,$header_rec,16);

	                ### Quit loop if at end of file
                	last if $length < 16;

			### Unpack header
			if ($self->{bigendian}) {
				($frame_seconds,$frame_msecs,
				 $frame_length_inc,$frame_length_orig) 
				 = unpack('NNNN',$header_rec);
			} else {
				($frame_seconds,$frame_msecs,
				 $frame_length_inc,$frame_length_orig) 
				 = unpack('VVVV',$header_rec);
			}

		} else {
			#
			#  Default to OS native timestamps
			#

	                ### Fetch record header
	                $length = read(TCPDUMPFILE,$header_rec,
			 ($self->{sizeint} * 2 + 8) );

	                ### Quit loop if at end of file
                	last if $length < ($self->{sizeint} * 2 + 8);

			### Unpack header
			if ($self->{sizeint} == 4) {	# 32-bit
				if ($self->{bigendian}) {
					($frame_seconds,$frame_msecs,
					 $frame_length_inc,$frame_length_orig) 
					 = unpack('NNNN',$header_rec);
				} else {
					($frame_seconds,$frame_msecs,
					 $frame_length_inc,$frame_length_orig) 
					 = unpack('VVVV',$header_rec);
				}
			} else {			# 64-bit?
				if ($self->{bigendian}) {
					($frame_seconds,$frame_msecs,
					 $frame_length_inc,$frame_length_orig) 
					 = unpack('IINN',$header_rec);
				} else {
					($frame_seconds,$frame_msecs,
					 $frame_length_inc,$frame_length_orig) 
					 = unpack('IIVV',$header_rec);
				}
			}

		}

		### Fetch extra info if in modified format
		if ($self->{style} =~ /^modified/) {
			$length = read(TCPDUMPFILE,$more,8);
		}
	
		### Check for skip bytes
		if (defined $self->{skip}) {
			$length = read(TCPDUMPFILE,$more,$self->{skip});
		}

		### Fetch the data
		$length = read(TCPDUMPFILE,$frame_data,$frame_length_inc);

		$frame_drops = $frame_length_orig - $frame_length_inc;

                ### Store values in memory
                $self->{data}[$num] = $frame_data;
                $self->{length_orig}[$num] = $frame_length_orig;
                $self->{length_inc}[$num] = $frame_length_inc;
                $self->{drops}[$num] = $frame_drops;
                $self->{seconds}[$num] = $frame_seconds;
                $self->{msecs}[$num] = $frame_msecs;
                $self->{count}++;
                $num++;
        }

        close TCPDUMPFILE;
}

# indexes - return a list of index numbers for the packets.
#               indexes start at "0"
#
sub indexes {
        my $self = shift;
        my $max = $self->{count} - 1;
        return (0..$max);
}

# maxindex - return the index number for the last packet.
#               indexes start at "0"
#
sub maxindex {
        my $self = shift;
        my $max = $self->{count} - 1;
        return $max;
}

# header - return header data for a given index
#
sub header {
        my $self = shift;
        my $num = shift;
        return ($self->{length_orig}[$num],
                $self->{length_inc}[$num],
                $self->{drops}[$num],
                $self->{seconds}[$num],
                $self->{msecs}[$num]);
}

# data - return packet data for a given index
#
sub data {
        my $self = shift;
        my $num = shift;
        return $self->{data}[$num];
}

# version - return log file version
#
sub version {
        my $self = shift;
        return sprintf("%u.%u",$self->{major},$self->{minor});
}

# linktype - return linktype
#
sub linktype {
	my $self = shift;
	return sprintf("%u",$self->{linktype});
}

# zoneoffset - return zoneoffset
#
sub zoneoffset {
	my $self = shift;
	return sprintf("%u",$self->{zoneoffset});
}

# accuracy - return accuracy
#
sub accuracy {
	my $self = shift;
	return sprintf("%u",$self->{accuracy});
}

# dumplength - return dumplength
#
sub dumplength {
	my $self = shift;
	return sprintf("%u",$self->{dumplength});
}

# clear - clear tcpdump file from memory
#
sub clear {
        my $self = shift;
        delete $self->{data};
        $self
}


1;
__END__


=head1 NAME

Net::TcpDumpLog - Read tcpdump/libpcap network packet logs. 
Perl implementation (not an interface).


=head1 SYNOPSIS

use Net::TcpDumpLog;

$log = Net::TcpDumpLog->new();
$log->read("/tmp/out01");

@Indexes = $log->indexes;

foreach $index (@Indexes) {
     ($length_orig,$length_incl,$drops,$secs,$msecs) =
                                 $log->header($index);
     $data = $log->data($index);

     # your code here
}

=head1 DESCRIPTION

This module can read the data and headers from tcpdump logs
(these use the libpcap log format).

=head1 METHODS

=over 4

=item new ()

Constructor, return a TcpDumpLog object. 

=item new (BITS)

This optional argument is to force reading timestamps of that number of bits. 
eg new(32). Could be needed when processing tcpdumps from one OS on another.

=item new (BITS,SKIP)

This second options argument is how many bytes to skip for every record header.
"SuSE linux 6.3" style logs need this set to 4, everything else (so far) is 0.

=item read (FILENAME)

Read the tcpdump file indicated into memory.

=item indexes ()

Return an array of index numbers for the packets loaded from the
tcpdump file. The indexes start at 0.

=item maxindex ()

Return the number of the last index. More memory efficient than
indexes(). Add 1 to get the packet count. The indexes start at 0.

=item header (INDEX)

Takes an integer index number and returns the packet header. This is:
   Length of original packet,
   Length actually included in the tcpdump log,
   Number of bytes dropped in this packet,
   Packet arrival time as seconds since Jan 1st 1970,
   Microseconds

=item data (INDEX)

Takes an integer index number and returns the raw packet data.
(This is usually Ethernet/IP/TCP data).

=item version ()

Returns a string containing the libpcap log version,
major and minor number - which is expected to be "2.4".

=item linktype ()

Returns a strings containing the numeric linktype.

=item zoneoffset ()

Returns the zoneoffset for the packet log.

=item accuracy ()

Returns a the accuracy of the packet log.

=item dumplength ()

Returns the length of the packet log.

=back


=head1 INSTALLATION

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES


ExtUtils::MakeMaker

=head1 EXAMPLES

Once you can read the raw packet data, the next step is read through the
protocol stack. An Ethernet/802.3 example is,

($ether_dest,$ether_src,$ether_type,$ether_data) =
 unpack('H12H12H4a*',$data);

Keep an eye on CPAN for Ethernet, IP and TCP modules. 

=head1 LIMITATIONS

This reads tcpdump/libpcap version 2.4 logs (the most common). There 
could be new versions in the future, at which point this module will 
need updating.

=head1 BUGS

If this module is not reading your logs correctly, try forcing the timestamp
bits to either 32 or 64, eg "$log = Net::TcpDumpLog->new(32);". 
Also try printing out the log version using version() and checking it is "2.4".

There is a certain tcpdump log format "SuSE linux 6.3" that put extra fields
in the log without any clear identifier. If you think you have this log,
put a "4" as a second argument to new, eg "$log = Net::TcpDumpLog->new(32,4);".
(The 4 specifies how many extra header bytes to skip). 


=head1 TODO

Future versions should include the ability to write as well as read
tcpdump logs. Also a memory efficient technique to process very large
tcpdump logs (where the log size is greater than available virtual
memory).

=head1 SEE ALSO

http://www.tcpdump.org

=head1 COPYRIGHT

Copyright (c) 2003 Brendan Gregg. All rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=head1 AUTHORS

Brendan Gregg <brendan.gregg@tpg.com.au>
[Sydney, Australia]

=cut
