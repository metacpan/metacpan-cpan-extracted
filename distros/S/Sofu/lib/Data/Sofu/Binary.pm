###############################################################################
#Binary.pm
#Last Change: 2009-28-01
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.3
####################
#This file is part of the sofu.pm project, a parser library for an all-purpose
#ASCII file format. More information can be found on the project web site
#at http://sofu.sourceforge.net/ .
#
#sofu.pm is published under the terms of the MIT license, which basically means
#"Do with it whatever you want". For more information, see the license.txt
#file that should be enclosed with libsofu distributions. A copy of the license
#is (at the time of this writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################

=head1 NAME

Data::Sofu::Binary - Interface to various binary drivers

=head1 DESCRIPTION

This module can be used to convert complex data structures and SofuObject trees to binary files and streams.

=head1 Synopsis 

	use Data::Sofu qw/readSofu writeSofuBinary/;
	my $tree = [%ENV];
	$tree->{Foo}=@INC;
	writeSofuBinary("env.sofu",$tree); #Write as a binary sofu file
	my $tree2=readSofu("env.sofu"); #Reading doesn't care if its binary or normal sofu.

	#Or using just this module:
	my $tree = [%ENV];
	$tree->{Foo}=@INC;
	require Data::Sofu::Binary;
	my $bsofu=Data::Sofu::Binary->new();
	my $bstream = $bsofu->pack($tree);
	my $tree2=$bsofu->read(\$tree); # This can only read binary data.

	#More detailed:
	writeSofuBinary("env.sofu",$tree,$comments,$encoding,$byteorder,$mark); #For details on these parameters see the pack() Method.

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut


package Data::Sofu::Binary;
use strict;
use warnings;

our $VERSION="0.3";
#We are really going to need these modules:
use Encode;
use Carp qw/confess/;
require Data::Sofu;

=head1 Binary Drivers

These are the known binary drivers (for now):

=over

=item "000_002_000_000" 

C<Data::Sofu::Binary::Bin0200>

Sofu binary version 0.2.0.0 Driver.

=back



B<Note>

Data::Sofu's writeBinary will always take the latest stable one.

=cut

my %versions = (
	"000_002_000_000"=>"Data::Sofu::Binary::Bin0200"
);

=head1 METHODS

These Methods are also avaiable for the returned binary driver.

Also see the C<Data::Sofu::Binary::Bin0200> or whatever driver you are using for more methods.

=head2 new([DRIVER])

Creates a new Binary Driver using DRIVER or the latest one available.

	require Data::Sofu::Binary;
	$bsofu = Data::Sofu::Binary->new(); #Using the latest.
	$bsofu = Data::Sofu::Binary->new("000_002_000_000"); Taking a specific one.
	#You can call it directly:
	require C<Data::Sofu::Binary::Bin0200>;
	$bsofu = C<Data::Sofu::Binary::Bin0200>->new(); #The same

=cut 

sub new {
	my $class=shift;
	my $version = shift;
	$version = "000_002_000_000" unless $version;
	$version = $versions{$version};
	$version = "0200.pm" unless $version;
	eval "require $version";
	confess $@ if $@;
	return $version->new();
}

=head2 warn()

Internal method, will throw an exception containing a stacktrace and the offset of the file where it happened.

=cut


sub warn {
	my $self=shift;
	#croak "Sofu Warning, Binary decoder: @_";
	confess "Sofu Warning, Binary mode: @_ at offset $self->{OFFSET}";
}

=head2 die()

Internal method, will throw an exception containing a stacktrace and the offset of the file where it happened.

=cut


sub die {
	my $self=shift;
	confess "Sofu Error, Binary mode: @_ at offset $self->{OFFSET}";
}

=head2 open(FILE)

A helper method to open files

File can be:

A filename, (the file will be opened in raw mode)

a filehandle, (will be set to binmode)

or a scalarref (data will be written to/form the referenced scalar

=cut

sub open { #Opens the data;
	local $_;
	my $self=shift;
	my $data=shift;
	$self->{OFFSET}=0;
	if (ref $data eq "GLOB") {
		binmode $data;
		$self->{IN} = $data;
	}
	elsif (ref $data eq "SCALAR") {
		CORE::open my $in, '<:utf8', $data;
		binmode $in;
		$self->{IN}=$in;	
	}
	elsif (ref $data) {
		$self->warn("Unsupported Data Input Method:",ref $data);
	}
	else {
		CORE::open (my $in,'<:raw',$data) or $self->die("Can't open input file $data: $!");
		binmode $in;
		$self->{IN}=$in;
	}
}

=head2 openout(FILE)

Same as open() for output.

=cut

sub openout { #Opens the data;
	local $_;
	my $self=shift;
	my $data=shift;
	$self->{OFFSET}=0;
	if (ref $data eq "GLOB") {
		binmode $data;
		$self->{OUT} = $data;
	}
	elsif (ref $data eq "SCALAR") {
		CORE::open my $out, '>:utf8', $data;
		binmode $out;
		$self->{OUT}=$out;	
	}
	elsif (ref $data) {
		$self->warn("Unsupported Data Input Method:",ref $data);
	}
	else {
		CORE::open (my $out,'>:raw',$data) or $self->die("Can't open output file $data: $!");
		binmode $out;
		$self->{OUT}=$out;
	}
}

=head2 get(AMOUNT)

Internal method, used to read AMOUNT bytes from the filestream.

=cut

sub get { #Reads some bytes..
	local $_;
	my $self=shift;
	my $in =$self->{IN};
	my $amount = shift;
	my $data;
	my $read = CORE::read($in,$data,$amount);
	$self->die("Error while reading: $!") unless defined $read;
	return undef unless $read;
	$self->{OFFSET}+=$read;
	$self->die("Can't read any more bytes, file corrupt?") if $read < $amount; 
	return $data;
}

=head2 unpackHeader()

Internal method, determines endianess and version the binary file was written in.

Returns ByteOrderMark and Sofu Version.

=cut

sub unpackHeader {
	my $self=shift;
	my $end = $self->get(2);
	if ($end eq "So") {
		my $t = $self->get(2);
		$self->die("Incomplete Mark: $t") if $t ne "fu";
		$end = $self->get(2)
	}
	my $bom = unpack("S",$end);
	my $version = $self->get(4);
	$self->die("Can't read version, incomplete Header!") unless defined $version;
	my @v = unpack ("CCCC",$version);
	return ($bom,join("_",map {sprintf("%03d",$_)} @v));

}

=head2 read(FILE)

Reads FILE in binary mode and returns a perl datastructure (Hashes, Arrays, Scalars)

See open() for info on the FILE parameter.

Loads automatically the right driver for FILE, no matter what driver is in use right now. But it will keep the current driver if it can read it.

Will not change the driver you are currently using!

=cut


sub read { #Perl Structure Parser
	local $_;	
	my $self=shift;
	$self->{COMMENTS}=[];
	$self->open(shift);
	my ($bom, $ver) = $self->unpackHeader();
	return $self->unpack($bom) if ($self->{SUPPORTED}->{$ver});
	my $module=$versions{$ver};
	$self->die("Unknown Version: $ver") unless $module;
	eval "require $module";
	confess $@ if $@;
	my $m = "$module"->new();
	return $m->unpack($bom);
	

}


=head2 load(FILE)

Reads FILE in binary mode and returns a Sofu datastructure (Data::Sofu::Object's, Maps, Lists and Values)

See open() for info on the FILE parameter.

Loads automatically the right driver for FILE, no matter what driver is in use right now. But it will keep the current driver if it can read it.

Will not change the driver you are currently using!

=cut


sub load { #Object parser
	local $_;
	require Data::Sofu::Object;
	my $self=shift;
	$self->open(shift);
	my ($bom, $ver) = $self->unpackHeader();
	return $self->unpackObject($bom) if ($self->{SUPPORTED}->{$ver});
	my $module=$versions{$ver};
	$self->die("Unknown Version: $ver") unless $module;
	eval "require $module";
	confess $@ if $@;
	my $m = "$module"->new();
	return $m->unpackObject($bom);
}

=head2 write(FILE,TREE,[COMMENTS,[ENCODING,[BYTEORDER,[SOFUMARK,[...]]]]])

Writes TREE to FILE.

See open() for FILE.

See pack() for COMMENTS,ENCODING,BYTEORDER,SOFUMARK,...

TREE can be a perl datastructure or a Data::Sofu::Object or derived.

=cut

sub write {
	local $_;
	my $self=shift;
	$self->openout(shift);
	my $fh=$self->{OUT};
	print $fh $self->pack(@_);

}

=head2 pack(TREE,[COMMENTS,[ENCODING,[BYTEORDER,[SOFUMARK,[...]]]]])

This method is implemented only in the driver, but it is important to discuss the arguments here.

Note: These arguments are the ones used in drivers up to the default C<Data::Sofu::Binary::Bin0200>. Later drivers might add more arguments (therefore ...), and earlier drivers might support fewer.

	print FH, $bsofu->pack(readSofu("something.sofu"),getSofucomments(),"UTF-32","LE","0.4");

=over

=item TREE

First driver to support: C<Data::Sofu::Binary::Bin0200>

Perl datastructure to pack. Can be a hash, array or scalar (or array of hashes of hashes of arrays or whatever). Anything NOT a hash will be converted to TREE={Value=>TREE};

It can also be a Data::Sofu::Object or derived (Data::Sofu::Map, Data::Sofu::List, Data::Sofu::Value, Data::Sofu::...).
Anything not a Data::Sofu::Map will be converted to one (A Map with one attribute called "Value" that holds TREE).

=item COMMENTS

First driver to support: C<Data::Sofu::Binary::Bin0200>

Comment hash (as returned by Data::Sofu::getSofucomments() or Data::Sofu->new()->comments() after any file was read).

Can be undef or {}.

=item ENCODING

First driver to support: C<Data::Sofu::Binary::Bin0200>

Specifies the encoding of the strings in the binary sofu file, which can be: 

=over

=item C<"0"> or C<"UTF-8">

First driver to support: C<Data::Sofu::Binary::Bin0200>

This is default.

Normal UTF-8 encoding (supports almost all chars)

=item C<"1"> or C<"UTF-7">

First driver to support: C<Data::Sofu::Binary::Bin0200>

This is default for byteorder = 7Bit (See below)

7Bit encoding (if your transport stream isn't 8-Bit safe

=item C<"2"> or C<"UTF-16">

First driver to support: C<Data::Sofu::Binary::Bin0200>

UTF 16 with byte order mark in EVERY string.

Byteoder depends on your machine

=item C<"3"> or C<"UTF-16BE">

First driver to support: C<Data::Sofu::Binary::Bin0200>

No BOM, always BigEndian

=item C<"4"> or C<"UTF-16LE">

First driver to support: C<Data::Sofu::Binary::Bin0200>

No BOM, always LittleEndian

=item C<"5"> or C<"UTF-32">

First driver to support: C<Data::Sofu::Binary::Bin0200>

UTF-32 with byte order mark in EVERY string.

Byteoder depends on your machine

=item C<"6"> or C<"UTF-32BE">

First driver to support: C<Data::Sofu::Binary::Bin0200>

No BOM, always BigEndian

=item C<"7"> or C<"UTF-32LE">

First driver to support: C<Data::Sofu::Binary::Bin0200>

No BOM, always LittleEndian

=item C<"8","9">

Reserved for future use

=item C<"10"> or C<"ascii">

First driver to support: C<Data::Sofu::Binary::Bin0200>

Normal ASCII encoding

Might not support all characters and will warn about that.

=item C<"11"> or C<"cp1252">

First driver to support: C<Data::Sofu::Binary::Bin0200>

Windows Codepage 1252 

Might not support all characters and will warn about that.

=item C<"12"> or C<"latin1">

First driver to support: C<Data::Sofu::Binary::Bin0200>

ISO Latin 1 

Might not support all characters and will warn about that.

=item C<"13"> or C<"latin9">

First driver to support: C<Data::Sofu::Binary::Bin0200>

ISO Latin 9

Might not support all characters and will warn about that.

=item C<"14"> or C<"latin10">

First driver to support: C<Data::Sofu::Binary::Bin0200>

ISO Latin 10

Might not support all characters and will warn about that.

=back

=item BYTEORDER

First driver to support: C<Data::Sofu::Binary::Bin0200>

Defines how the integers of the binary file are encoded.

=over

=item C<undef>

First driver to support: C<Data::Sofu::Binary::Bin0200>

Maschine order

This is Default. 

BOM is placed to detect the order used.

=item C<"LE">

First driver to support: C<Data::Sofu::Binary::Bin0200>

Little Endian

BOM is placed to detect the order used.

Use this to give it to machines which are using Little Endian and have to read the file alot

=item C<"BE">

First driver to support: C<Data::Sofu::Binary::Bin0200>

Big Endian

BOM is placed to detect the order used.

Use this to give it to machines which are using Big Endian and have to read the file alot

=item C<"7Bit">

First driver to support: C<Data::Sofu::Binary::Bin0200>

Use this byteorder if you can't trust your transport stream to be 8-Bit save.

Encoding is forced to be UTF-7. No byte in the file will be > 127.

BOM is set to 00 00.

=item C<"NOFORCE7Bit">

First driver to support: C<Data::Sofu::Binary::Bin0200>

Use this byteorder if you can't trust your transport stream to be 8-Bit save but you want another enconding than UTF-7

Encoding is NOT forced to be UTF-7.

BOM is set to 00 00.

=back

=item SOFUMARK

First driver to support: C<Data::Sofu::Binary::Bin0200>

Defines how often the string "Sofu" is placed in the file (to tell any user with a text-editor what type of file this one is).

=over

=item C<undef>

First driver to support: C<Data::Sofu::Binary::Bin0200>

Only place one "Sofu" at the beginning of the file.

This is default.

=item C<"0" or "">

First driver to support: C<Data::Sofu::Binary::Bin0200>

Place no string anywhere.

=item C<< "1" or >1 >>

First driver to support: C<Data::Sofu::Binary::Bin0200>

Place a string on every place it is possible 

Warning, the file might get big.

=item C<"0.000001" - "0.99999">

First driver to support: C<Data::Sofu::Binary::Bin0200>

Place strings randomly.

=back

=back

B<NOTE:>

Encoding, Byteorder and encoding driver (and Sofumark of course) are saved in the binary file. So you don't need to specify them for reading files, in fact just give them the Data::Sofu's readSofu() and all will be fine.

=head1 BUGS

C<< Data::Sofu::Object->writeBinary() >> will only use the Bin0200 driver, no other. 

	$map = new Data::Sofu::Map;
	.....
	$map->writeBinary($file); #Bin0200 driver always.
	use Data::Sofu;
	writeSofuBinary($file,$map); #Will use the latest driver.

=head1 SEE ALSO

perl(1),L<http://sofu.sf.net>

L<Data::Sofu::Object>, L<Data::Sofu>, L<Data::Sofu::Binary::Bin0200>


=cut
1;
