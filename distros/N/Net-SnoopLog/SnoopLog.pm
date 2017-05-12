#!/bin/perl -w
#
# SnoopLog.pm - Net::SnoopLog library to read snoop ver 2 files (RFC1761).
#
# 17-Oct-2003	Brendan Gregg

package Net::SnoopLog;

use strict;
use vars qw($VERSION);

$VERSION = '0.12';

# new - create the snoop object
#
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{version} = undef;
	$self->{datalink} = undef;
	$self->{data} = [];
	$self->{length_orig} = [];
	$self->{length_inc} = [];
	$self->{drops} = [];
	$self->{seconds} = [];
	$self->{msecs} = [];
	$self->{count} = 0;

	bless($self,$class);
	return $self;
}

# read - read the snoop file into memory
#
sub read {
	my $self = shift;
	my $file = shift;
	my ($header,$length,$ident,$version,$datalink,$header_rec,
	 $record_length_orig,$record_length_inc,$record_length_rec,
	 $record_drops,$record_seconds,$record_msecs,$record_data,$skip,$pad);
	$self->{count} = 0;
	my $num = 0;

	### Open snoop file
	open(SNOOPFILE,"$file") || 
	 die "ERROR: Can't read snoop log $file: $!\n";
	binmode(SNOOPFILE);		# backward OSs

	### Fetch snoop header
	$length = read(SNOOPFILE,$header,16);
	die "ERROR: Can't read from snoop log $file\n" if $length < 16;

	### Check file really is a snoop file
	($ident,$version,$datalink) = unpack('A8NN',$header);
	die "ERROR: Not a snoop file $file\n" if $ident ne "snoop";

	### Store values
	$self->{version} = $version;
	$self->{datalink} = $datalink;

	#
	#  Read all packets into memory
	#
	$num = 0;
	while (1) {
		### Fetch record header
		$length = read(SNOOPFILE,$header_rec,24);

		### Quit loop if at end of file
	        last if $length < 24;

		### Unpack header
        	($record_length_orig,$record_length_inc,$record_length_rec,
		 $record_drops,$record_seconds,$record_msecs) = 
		 unpack('NNNNNN',$header_rec);

		### Skip padding
		$length = read(SNOOPFILE,$record_data,$record_length_inc);
		$skip = read(SNOOPFILE,$pad,($record_length_rec - 
		 $record_length_inc - 24));

		### Store values in memory
		$self->{data}[$num] = $record_data;
		$self->{length_orig}[$num] = $record_length_orig;
		$self->{length_inc}[$num] = $record_length_inc;
		$self->{drops}[$num] = $record_drops;
		$self->{seconds}[$num] = $record_seconds;
		$self->{msecs}[$num] = $record_msecs;
		$self->{count}++;
		$num++;
	}

	close SNOOPFILE;
}

# indexes - return a list of index numbers for the packets.
#		indexes start at "0"
#
sub indexes {
	my $self = shift;
	my $max = $self->{count} - 1;
	return (0..$max);
}

# maxindex - return the index number for the last packet.
#		indexes start at "0"
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

# version - return snoop file version
#
sub version {
	my $self = shift;
	return sprintf("%u",$self->{version});
}

# datalink - return snoop datalink type
#
sub datalink {
	my $self = shift;
	return sprintf("%u",$self->{datalink});
}

# clear - clear snoop file from memory
#
sub clear {
	my $self = shift;
	delete $self->{data};
	$self
}


1;
__END__


=head1 NAME

Net::SnoopLog - Read snoop network packet logs, from RFC1761 snoop ver 2. 
Perl implementation (not an interface).

=head1 SYNOPSIS

use Net::SnoopLog;

$log = Net::SnoopLog->new();
$log->read("/tmp/out01");

@Indexes = $log->indexes;

foreach $index (@Indexes) {
     ($length_orig,$length_incl,$drops,$secs,$msecs) = 
                                 $log->header($index);
     $data = $log->data($index);

     # your code here
}

=head1 DESCRIPTION

This module can read the data and headers from snoop ver 2 logs (those
that obey RFC1761 - try "man snoop").

=head1 METHODS

=over 4

=item new ()

Constructor, return a SnoopLog object.

=item read (FILENAME)

Read the snoop file indicated into memory.

=item indexes ()

Return an array of index numbers for the packets loaded from the
snoop file. The indexes start at 0.

=item maxindex ()

Return the number of the last index. More memory efficient than 
indexes(). Add 1 to get the packet count. The indexes start at 0.

=item header (INDEX)

Takes an integer index number and returns the packet header. This is:
   Length of original packet,
   Length actually included in the snoop log,
   Cumulative drops (since the snoop log began),
   Packet arrival time as seconds since Jan 1st 1970,
   Microseconds
   
=item data (INDEX)

Takes an integer index number and returns the raw packet data. 
(This is usually Ethernet/IP/TCP data).

=item version ()

Returns a string containing the numeric snoop log version,
which is expected to be "2".

=item datalink ()

Returns a strings containing the numeric datalink type, see RFC 1761
for a table of these. (4 is Ethernet).

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

This reads snoop version 2 logs (the most common). There could be a 
new version in the distant future with a move to 64-bit timestamps 
- at which point this module will need updating.

=head1 TODO

Future versions should include the ability to write as well as read 
snoop logs. Also a memory efficient technique to process very large
snoop logs (where the log size is greater than available virtual 
memory).

=head1 SEE ALSO

RFC 1761

=head1 COPYRIGHT

Copyright (c) 2003 Brendan Gregg. All rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=head1 AUTHORS

Brendan Gregg <brendan.gregg@tpg.com.au>
[Sydney, Australia]

=cut
