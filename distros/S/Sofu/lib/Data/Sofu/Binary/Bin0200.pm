###############################################################################
#List.pm
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

Data::Sofu::Binary::Bin0200 - Driver for Sofu Binary version 0.2.0.0

=head1 DESCRIPTION

Driver for C<Data::Sofu::Binary> and C<Data::Sofu>

=head1 Synopsis 

See C<Data::Sofu::Binary>

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut


package Data::Sofu::Binary::Bin0200;
use strict;
use warnings;
use bytes;

our $VERSION="0.3";
#We are really going to need these modules:
use Encode;
use Carp qw/confess/;
require Data::Sofu;
use base qw/Data::Sofu::Binary/;

#$SIG{__WARN__}=sub {	confess @_;};

=head1 METHODS

See also C<Data::Sofu::Binary> for public methods.

All these methods are INTERNAL, not for use outside of this module...

Except pack().

=head2 new()

Creates a new Binary Driver using DRIVER or the latest one available.

	require Data::Sofu::Binary;
	$bsofu = Data::Sofu::Binary->new("000_002_000_000"); Taking this driver;
	#You can call it directly:
	require Data::Sofu::Binary::Bin0200;
	$bsofu = Data::Sofu::Binary::Bin0200->new(); #The same

=cut 

sub new {
	my $class=shift;
	my $self={};
	bless $self,$class;
	$self->{OBJECT}=0;
	$self->{COMMENTS}=[];
	$self->{SUPPORTED}={"000_002_000_000"=>1};
	return $self;
}

=head2 encoding(ID) 

Switches and/or detetect the encoding.

See pack() for more on encodings.

=cut

sub encoding { #Switches the Encoding
	my $self=shift;
	my $id=shift;
	my @encoding = qw/UTF-8 UTF-7 UTF-16 UTF-16BE UTF-16LE UTF-32 UTF-32BE UTF-32LE null null ascii cp1252 latin1 Latin9 Latin10/;
	my %encoding;
	@encoding{map {lc $_} @encoding} = (0 .. 12);
	if (exists $encoding{lc $id}) {
		$self->{EncID}=$encoding{lc $id};
		return $self->{Encoding}=$encoding[$self->{EncID}];
	}
	if ($encoding[int $id]) {
		$self->{EncID}=$id;
		return $self->{Encoding}=$encoding[$id];
	}
	$self->die("Unknown Encoding");
	
}

=head2 byteorder(BOM)

Internal method.

Switches the byteorder.

See pack() for more on byteorders.

=cut


sub byteorder {
	my $self=shift;
	my $bo=shift;
	if ($bo =~ m/le/i) { #little Endian
		$self->{SHORT}="v";
		$self->{LONG}="V";
		return 0;
	}
	if ($bo =~ m/be/i) { #BIG Endian
		$self->{SHORT}="n";
		$self->{LONG}="N";
		return 0;
	}
	if ($bo=~m/7/) { #7-Bit Mode
		$self->{SHORT}=undef;
		$self->{LONG}=undef;
		$self->encoding(1);
		return 1;
	}
	if ($bo=~m/Force/i) { #7-Bit Mode without UTF-7 encoding
		$self->{SHORT}=undef;
		$self->{LONG}=undef;
		#$self->encoding(1);
		return 0;
	}
	$self->{SHORT}="S";
	$self->{LONG}="L";
	return 0;

}


=head2 bom(BOM)

Internal method.

Detects the byteorder.

See pack() for more on byteorders.

=cut

sub bom {
	my $self=shift;
	my $bo=shift;
	if ($bo==1) { #Machine Order
		$self->{SHORT}="S";
		$self->{LONG}="L";
		return 0;
	}
	if ($bo==256) { #Wrong Order
		if (1 == CORE::unpack('S',pack('v',1))) {# We are little Endian
			$self->{SHORT}="n";
			$self->{LONG}="N";
		}
		else {
			$self->{SHORT}="v";
			$self->{LONG}="V";
		}
		return 0;
	}
	if ($bo==0) { #7-Bit Mode
		$self->{SHORT}=undef;
		$self->{LONG}=undef;
		$self->encoding(1);
		return 1;
	}
	$self->die("Unknown Byteorder: $bo, can't continue");
	return 0;

}

=head2 packShort(INT)

Packs one int-16 to binary using the set byteorder

=cut

sub packShort {
	my $self=shift;
	my $i=shift;
	$self->die("Short too large: $i") if $i > 65535;
	return pack $self->{SHORT},$i if $self->{SHORT};
	$self->die("Can't pack that Short in 7-Bit, too large: $i") if $i > 16383;
	return pack ("CC",($i&0x7F),($i&0x3F80));
}

=head2 packLong(INT)

Packs one int-32 to binary using the set byteorder

=cut

sub packLong {
	my $self=shift;
	my $i=shift;
	$self->die("Long too large: $i") if $i > 4294967295;
	return pack $self->{LONG},$i if $self->{LONG};
	$self->die("Can't pack that Long in 7-Bit, too large: $i") if $i > 268435455;
	return pack ("CCCC",($i&0x7F),(($i&0x3F80) >> 7),(($i&0x1FC000) >> 14),(($i&0xFE00000) >> 21));
}

=head2 packendian()

Returns the byte order mark for this file.

=cut

sub packendian {
	my $self=shift;
	if ($self->{SHORT}) {
		return $self->packShort(1);
	}
	return pack("S",0);
}

=head2 packversion()

Returns the version of this driver to put in the file.

=cut

sub packversion {
	my $self=shift;
	return pack("CCCC",0,2,0,0);
}

=head2 packencoding()

Returns the current encoding to put in the output file.

=cut

sub packencoding {
	my $self=shift;
	return pack("C",$self->{EncID});
}

=head2 getType()

Tries to find out what SofuObject to deserialise next

Returns:

0 for Undefined / undef

1 for Value / Scalar

2 for List / Array

3 for Map / Hash

4 for Reference / Ref

=cut

sub getType {
	my $self=shift;
	my $type = $self->get(1);
	$self->die ("Unexpected End of File") unless $type;
	if ($type eq "S") {
		my $str = $self->get(3);
		$self->die("Incomplete Sofu-Mark") if not $str or $str ne "ofu";
		$type = $self->get(1);
	}
	$self->die("No Type found") unless defined $type;
	$type=CORE::unpack("C",$type);
	$self->die("Unknown Type: $type") if $type > 4;
	return $type;
}

=head2 objectprocess()

Postprocess the SofuObjects, sets References to their targets.

=cut

sub objectprocess {
	my $self=shift;
	$self->{Ref}->{""} = $self->{Ref}->{"->"} = $self->{Ref}->{"="};
	foreach my $e (@{$$self{References}}) {
		next if $e->valid();
		my $target = $e->follow()."";
		$target=~s/^@//;
		$target="->".$target if $target and $target !~ m/^->/;
		$e->dangle($self->{Ref}->{$target}) if $self->{Ref}->{$target};
	}
}

=head2 postprocess()

Postprocess perl datastructures , sets References to their targets.

=cut

sub postprocess {
	my $self=shift;
	$self->{Ref}->{""} = $self->{Ref}->{"->"} = $self->{Ref}->{"="};
	foreach my $e (@{$$self{References}}) {
		#next;
		#print $$e;
		my $target = $$$e;
		$target=~s/^@//;
		$target="->".$target if $target and $target !~ m/^->/;
		$$e = undef;
		$$e = $self->{Ref}->{$target} if $self->{Ref}->{$target};
	}
}

=head2 getLong()

Decodes one Int-32 from the input stream according to the byteorder and returns it.

=cut

sub getLong {
	my $self=shift;
	my $i=shift;
	return undef unless defined $i;
	return CORE::unpack($self->{LONG},$i) if $self->{LONG};
	my @i = CORE::unpack("CCCC",$i);
	#print join(", ",@i),"\n";
	return( (($i[0] & 0x7F) | (($i[1] & 0x7F) << 7)  | (($i[2] & 0x7F) << 14)  | (($i[3] & 0x7F) << 21)) );
}


=head2 getText()

Decodes one String according to encoding from the inputstream and returns it

=cut

sub getText {
	my $self=shift;
	my $len=$self->getLong($self->get(4));
	return undef unless defined $len;
	return "" if $len == 0;
	my $text = $self->get($len);
	return Encode::decode($self->{Encoding},$text,Encode::FB_CROAK);
	
}

=head2 getComment(TREE)

decodes one comment and sets it to TREE

TREE can be a string describing the tree or a Data::Sofu::Object.

=cut

sub getComment {
	my $self=shift;
	my $tree=shift;
	my $t = $self->getText();
	$self->die("Can't get Comment, EOF!") unless defined $t;
	return if $t eq "";
	if (ref $tree) {
		$tree->setComment([split /\n/,$t]);
	}
	else {
		$self->{COMMENTS}->{$tree}=[split /\n/,$t];
	}
	
}

=head2 unpackUndef(TREE) 

Returns undef and packs it comment

=cut

sub unpackUndef {
	my $self=shift;
	my $tree=shift;
	$self->getComment($tree);
	return undef;

}

=head2 unpackScalar(TREE)

Decodes one scalar and its comment.

=cut


sub unpackScalar {
	my $self=shift;
	my $tree=shift;
	$self->getComment($tree);
	return $self->getText();

}

=head2 unpackRef(TREE)

Decodes one ref and its comment.

=cut


sub unpackRef {
	my $self=shift;
	my $tree=shift;
	$self->getComment($tree);
	my $x = $self->getText();
	return \$x;

}


=head2 unpackHash(TREE)

Decodes a hash, its comment and its content

=cut

sub unpackHash {
	my $self=shift;
	my $tree=shift;
	my %result=();
	$self->getComment($tree);
	my $len=$self->getLong($self->get(4));
	$self->die("Error while reading maplength, maybe EOF") unless defined $len;
	return {} if $len == 0;
	keys(%result) = $len; #Presetting the Hashsize
	for (my $i = 0;$i < $len;$i++) {
		my $key = $self->getText();
		$self->die("Error while reading key, maybe EOF") unless defined $key;
		my $kkey = Data::Sofu::Sofukeyescape($key);
		my $type = $self->getType();
		$result{$key} = $self->unpackType($type,"$tree->$kkey");
		$self->{Ref}->{"$tree->$kkey"}=$result{$key};
		push @{$self->{References}},\$result{$key} if ($type == 4);
	}
	return \%result;
	
}


=head2 unpackArray(TREE)

Decodes an array, its comment and its content

=cut


sub unpackArray {
	my $self=shift;
	my $tree=shift;
	my @result=();
	$self->getComment($tree);
	my $len=$self->getLong($self->get(4));
	$self->die("Error while reading listlength, maybe EOF") unless defined $len;
	return {} if $len == 0;
	#die $len,"\n";
	$#result = $len-1; #Grow the Array :)
	for (my $i = 0;$i < $len;$i++) {
		my $type = $self->getType();
		$result[$i] = $self->unpackType($type,"$tree->$i");
		$self->{Ref}->{"$tree->$i"}=$result[$i];
		push @{$self->{References}},\$result[$i] if ($type == 4);
	}
	return \@result;
	
}


=head2 unpackType(TYPE,TREE)

Decodes a datastructure of TYPE.

=cut


sub unpackType {
	my $self=shift;
	my $type=shift;
	my $tree=shift;
	if ($type == 0) {
		return $self->unpackUndef($tree);
	}
	elsif ($type == 1) {
		return $self->unpackScalar($tree);
	}
	elsif ($type == 2) {
		return $self->unpackArray($tree);
	}
	elsif ($type == 3) {
		return $self->unpackHash($tree);
	}
	elsif ($type == 4) {
		return $self->unpackRef($tree);
	}
}


=head2 unpack(BOM)

Starts unpacking using BOM, gets encoding and the contents

=cut


sub unpack {
	my $self=shift;
	my $bom=shift;
	$self->{COMMENTS}={};
	$self->{References}=[];
	$self->{Ref}={};
	$self->bom($bom);
	my $encoding = $self->get(1);
	$self->die("No Encoding!") unless defined $encoding;
	$self->encoding(CORE::unpack("C",$encoding));
	my $tree="";
	my %result=();
	$self->getComment("=");
	while (defined (my $key = $self->getText())) {
		my $kkey = Data::Sofu::Sofukeyescape($key);
		my $type = $self->getType();
		$result{$key} = $self->unpackType($type,"$tree->$kkey");
		$self->{Ref}->{"$tree->$kkey"}=$result{$key};
		push @{$self->{References}},\$result{$key} if ($type == 4);
	}
	$self->{Ref}->{"="}=\%result;
	$self->postprocess(); #Setting References right.
	return (\%result,$self->{COMMENTS});
	
}


=head2 unpackUndefined(TREE)

Unpacks a Data::Sofu::Undefined and its comment.

=cut

sub unpackUndefined {
	my $self=shift;
	my $tree=shift;
	my $und = Data::Sofu::Undefined->new();
	$self->getComment($und);
	return $und;

}


=head2 unpackValue(TREE)

Unpacks a Data::Sofu::Value, its content and its comment.

=cut

sub unpackValue {
	my $self=shift;
	my $tree=shift;
	my $value = Data::Sofu::Value->new("");
	$self->getComment($value);
	$value->set($self->getText());
	return $value;

}


=head2 unpackReference(TREE)

Unpacks a Data::Sofu::Reference, its content and its comment.

=cut

sub unpackReference {
	my $self=shift;
	my $tree=shift;
	my $ref = Data::Sofu::Reference->new();
	$self->getComment($ref);
	$ref->dangle($self->getText());
	return $ref;

}


=head2 unpackMap(TREE)

Unpacks a Data::Sofu::Map, its content and its comment.

=cut

sub unpackMap {
	my $self=shift;
	my $tree=shift;
	my $map=Data::Sofu::Map->new();
	$self->getComment($map);
	my $len=$self->getLong($self->get(4));
	$self->die("Error while reading maplength, maybe EOF") unless defined $len;
	return $map if $len == 0;
	for (my $i = 0;$i < $len;$i++) {
		my $key = $self->getText();
		$self->die("Error while reading key, maybe EOF") unless defined $key;
		my $kkey = Data::Sofu::Sofukeyescape($key);
		my $type = $self->getType();
		my $res = $self->unpackObjectType($type,"$tree->$kkey");
		$self->{Ref}->{"$tree->$kkey"}=$res;
		push @{$self->{References}},$res if ($type == 4);
		$map->setAttribute($key,$res);
	}
	return $map;
	
}


=head2 unpackMap2(TREE)

Unpacks a Data::Sofu::Map, its content and its comment.

(Speed optimized, but uses dirty tricks)

=cut

sub unpackMap2 { #faster version, using the perlinterface
	my $self=shift;
	my $tree=shift;
	my %result=();
	my @order=();
	my $map=Data::Sofu::Map->new();
	$self->getComment($map);
	my $len=$self->getLong($self->get(4));
	$self->die("Error while reading maplength, maybe EOF") unless defined $len;
	return $map if $len == 0;
	keys(%result) = $len; #Presetting the Hashsize
	$#order=($len-1);
	for (my $i = 0;$i < $len;$i++) {
		my $key = $self->getText();
		$self->die("Error while reading key, maybe EOF") unless defined $key;
		my $kkey = Data::Sofu::Sofukeyescape($key);
		my $type = $self->getType();
		$result{$key} = $self->unpackObjectType($type,"$tree->$kkey");
		#push @order,$key;
		$order[$i] = $key;
		$self->{Ref}->{"$tree->$kkey"}=$result{$key};
		push @{$self->{References}},$result{$key} if ($type == 4);
	}
	$map->{Order}=\@order;
	$map->{Map}=\%result;
	return $map;
	
}

=head2 unpackList(TREE)

Unpacks a Data::Sofu::List, its content and its comment.

=cut

sub unpackList {
	my $self=shift;
	my $tree=shift;
	my $list=Data::Sofu::List->new();
	$self->getComment($list);
	my $len=$self->getLong($self->get(4));
	$self->die("Error while reading listlength, maybe EOF") unless defined $len;
	return $list if $len == 0;
	for (my $i = 0;$i < $len;$i++) {
		my $type = $self->getType();
		my $res = $self->unpackObjectType($type,"$tree->$i");
		$self->{Ref}->{"$tree->$i"}=$res;
		push @{$self->{References}},$res if ($type == 4);
		$list->appendElement($res);
	}
	return $list;
	
}


=head2 unpackList2(TREE)

Unpacks a Data::Sofu::List, its content and its comment.

(Speed optimized, but uses dirty tricks)

=cut


sub unpackList2 { #faster version, using the perlinterface
	my $self=shift;
	my $tree=shift;
	my $list=Data::Sofu::List->new();
	$self->getComment($list);
	my @result;
	my $len=$self->getLong($self->get(4));
	$self->die("Error while reading listlength, maybe EOF") unless defined $len;
	return $list if $len == 0;
	#die $len,"\n";
	$#result = $len-1; #Grow the Array :)
	for (my $i = 0;$i < $len;$i++) {
		my $type = $self->getType();
		$result[$i] = $self->unpackObjectType($type,"$tree->$i");
		$self->{Ref}->{"$tree->$i"}=$result[$i];
		push @{$self->{References}},$result[$i] if ($type == 4);
	}
	$list->{List}=\@result;
	return $list;
	
}

=head2 unpackObjectType(TYPE,TREE)

Unpacks a datastructure defined by TYPE

=cut

sub unpackObjectType {
	my $self=shift;
	my $type=shift;
	my $tree=shift;
	if ($type == 0) {
		return $self->unpackUndefined($tree);
	}
	elsif ($type == 1) {
		return $self->unpackValue($tree);
	}
	elsif ($type == 2) {
		return $self->unpackList2($tree);
	}
	elsif ($type == 3) {
		return $self->unpackMap2($tree);
	}
	elsif ($type == 4) {
		return $self->unpackReference($tree);
	}
}


=head2 unpackObject(BOM)

Starts unpacking into a Data::Sofu::Object structure using BOM, gets encoding and the contents

=cut


sub unpackObject {
	my $self=shift;
	my $bom=shift;
	$self->{References}=[];
	$self->{Ref}={};
	$self->bom($bom);
	my $encoding = $self->get(1);
	$self->die("No Encoding!") unless defined $encoding;
	$self->encoding(CORE::unpack("C",$encoding));
	my $tree="";
	my $map = Data::Sofu::Map->new();
	$self->getComment($map);
	while (defined (my $key = $self->getText())) {
		my $kkey = Data::Sofu::Sofukeyescape($key);
		my $type = $self->getType();
		my $res = $self->unpackObjectType($type,"$tree->$kkey");
		$self->{Ref}->{"$tree->$kkey"}=$res;
		push @{$self->{References}},$res if ($type == 4);
		$map->setAttribute($key,$res);

	}
	$self->{Ref}->{"="}=$map;
	$self->objectprocess(); #Setting References right.
	return $map;
	
}


=head2 packType(TYPE) 

Encodes Type information and returns it.

=cut

sub packType {
	my $self=shift;
	my $type=shift;
	my $str="";
	if ($self->{Mark}) {
		$str="Sofu" if rand() < $self->{Mark};
	}
	return $str.pack("C",$type);
}

=head2 packText(STRING)

Encodes a STRING using Encoding and returns it.

=cut 

sub packText {
	my $self=shift;
	my $text=shift;
	return $self->packLong(0) if not defined $text or $text eq "";
	$text = Encode::encode($self->{Encoding},$text,Encode::FB_CROAK);
	return $self->packLong(length($text)).$text;
}

=head2 packData(DATA,TREE)

Encodes one perl datastructure and its contents and returns it.

=cut

sub packData {
	my $self=shift;
	my $data=shift;
	my $tree=shift;
	my $type=1;
	if (ref $data) {
		my $r=ref $data;
		if ($r eq "ARRAY") {
			$type=2;
		}
		elsif ($r eq "HASH") {
			$type=3;
		}
		else {
			$self->die("Unknown Datastructure, can only work with Arrays and Hashes but not $r");
		}
		if ($self->{SEEN}->{$data}) {
			return $self->packType(4).$self->packComment($tree).$self->packText("@".$self->{SEEN}->{$data});
		}
	}
	else {
		if (defined ($data)) {
			return $self->packType(1).$self->packComment($tree).$self->packText($data);
		}
		else {
			return $self->packType(0).$self->packComment($tree);
		}
	}
	$self->{SEEN}->{$data}=$tree;
	if ($type==3) {
		return $self->packType(3).$self->packComment($tree).$self->packHash($data,$tree);
	}
	return $self->packType(2).$self->packComment($tree).$self->packArray($data,$tree);
}

=head2 packArray(DATA,TREE)

Encodes one perl array and its contents and returns it.

=cut

sub packArray {
	my $self=shift;
	my $data=shift;
	my $tree=shift;
	my $str=$self->packLong(scalar @{$data});
	my $i=0;
	foreach my $element (@{$data}) {
		$str.=$self->packData($element,"$tree->".$i++);
	}
	return $str;
}

=head2 packHash(DATA,TREE)

Encodes one perl hash and its contents and returns it.

=cut

sub packHash {
	my $self=shift;
	my $data=shift;
	my $tree=shift;
	my $str=$self->packLong(scalar keys %{$data});
	foreach my $key (keys %{$data}) {
		my $kkey = Data::Sofu::Sofukeyescape($key);
		$str.=$self->packText($key);
		$str.=$self->packData($data->{$key},"$tree->$kkey");
	}
	return $str;
}

=head2 pack(TREE,[COMMENTS,[ENCODING,[BYTEORDER,[SOFUMARK]]]])

Packs a structure (TREE) into a string using the Sofu binary file format.

Returns a string representing TREE.

=over

=item TREE

Perl datastructure to pack. Can be a hash, array or scalar (or array of hashes of hashes of arrays or whatever). Anything NOT a hash will be converted to TREE={Value=>TREE};

It can also be a Data::Sofu::Object or derived (Data::Sofu::Map, Data::Sofu::List, Data::Sofu::Value, Data::Sofu::...).
Anything not a Data::Sofu::Map will be converted to one (A Map with one attribute called "Value" that holds TREE).

=item COMMENTS

Comment hash (as returned by Data::Sofu::getSofucomments() or Data::Sofu->new()->comments() after any file was read).

Can be undef or {}.

=item ENCODING

Specifies the encoding of the strings in the binary sofu file, which can be: 

=over

=item C<"0"> or C<"UTF-8">

This is default.

Normal UTF-8 encoding (supports almost all chars)

=item C<"1"> or C<"UTF-7">

This is default for byteorder = 7Bit (See below)

7Bit encoding (if your transport stream isn't 8-Bit safe

=item C<"2"> or C<"UTF-16">

UTF 16 with byte order mark in EVERY string.

Byteoder depends on your machine

=item C<"3"> or C<"UTF-16BE">

No BOM, always BigEndian

=item C<"4"> or C<"UTF-16LE">

No BOM, always LittleEndian

=item C<"5"> or C<"UTF-32">

UTF-32 with byte order mark in EVERY string.

Byteoder depends on your machine

=item C<"6"> or C<"UTF-32BE">

No BOM, always BigEndian

=item C<"7"> or C<"UTF-32LE">

No BOM, always LittleEndian

=item C<"8","9">

Reserved for future use

=item C<"10"> or C<"ascii">

Normal ASCII encoding

Might not support all characters and will warn about that.

=item C<"11"> or C<"cp1252">

Windows Codepage 1252 

Might not support all characters and will warn about that.

=item C<"12"> or C<"latin1">

ISO Latin 1 

Might not support all characters and will warn about that.

=item C<"13"> or C<"latin9">

ISO Latin 9

Might not support all characters and will warn about that.

=item C<"14"> or C<"latin10">

ISO Latin 10

Might not support all characters and will warn about that.

=back

=item BYTEORDER

Defines how the integers of the binary file are encoded.

=over

=item C<undef>

Maschine order

This is Default. 

BOM is placed to detect the order used.

=item C<"LE">

Little Endian

BOM is placed to detect the order used.

Use this to give it to machines which are using Little Endian and have to read the file alot

=item C<"BE">

Big Endian

BOM is placed to detect the order used.

Use this to give it to machines which are using Big Endian and have to read the file alot

=item C<"7Bit">

Use this byteorder if you can't trust your transport stream to be 8-Bit save.

Encoding is forced to be UTF-7. No byte in the file will be > 127.

BOM is set to 00 00.

=item C<"NOFORCE7Bit">

Use this byteorder if you can't trust your transport stream to be 8-Bit save but you want another enconding than UTF-7

Encoding is NOT forced to be UTF-7.

BOM is set to 00 00.

=back

=item SOFUMARK

Defines how often the string "Sofu" is placed in the file (to tell any user with a text-editor what type of file this one is).

=over

=item C<undef>

Only place one "Sofu" at the beginning of the file.

This is default.

=item C<"0" or "">

Place no string anywhere.

=item C<< "1" or >1 >>

Place a string on every place it is possible 

Warning, the file might get big.

=item C<"0.000001" - "0.99999">

Place strings randomly.

=back

=back

B<NOTE:>

Encoding, Byteorder and encoding driver (and Sofumark of course) are saved in the binary file. So you don't need to specify them for reading files, in fact just give them the Data::Sofu's readSofu() and all will be fine.

=cut

sub pack { #Built tree into b-stream
	my $self=shift;
	$self->{OFFSET}="while packing";
	$self->{SEEN}={};
	my $data=shift;
	my $r = ref $data;
	return $self->packObject($data,@_) if $r and $r =~ m/Data::Sofu::/ and $data->isa("Data::Sofu::Object"); 
	$data = {Value=>$data} unless ref $data and ref $data eq "HASH";
	#$self->die("Data format wrong, must be hashref") unless (ref $data and ref $data eq "HASH");
	$self->{SEEN}->{$data}="->";
	my $comments=shift;
	$comments = {} unless defined $comments;
	$self->die("Comment format wrong, must be hashref") unless (ref $comments and ref $comments eq "HASH");
	$self->{Comments}=$comments;
	my $tree;
	#my $encoding=shift;
	#my $byteorder=shift;
	#$encoding=0 unless $encoding;
	#$byteorder=0 unless $byteorder;
	#$self->encoding($encoding) unless $self->byteorder($byteorder);
	#my $mark=shift;
	#$mark = undef unless $mark;
	#$self->{Mark} = $mark;
	#my $str = "";
	#$str.="Sofu" if $mark or not defined $mark;
	#$str.=$self->packendian();
	#$str.=$self->packversion()
	#$comments = {} unless defined $comments;;
	#$str.=$self->packencoding();
	my $str=$self->packHeader(@_);
	$str.=$self->packComment("=");
	foreach my $key (keys %{$data}) {
		$str.=$self->packText($key);
		$str.=$self->packData($data->{$key},"->".Data::Sofu::Sofukeyescape($key));
	}

	return $str;
}

=head2 packObject(TREE,[COMMENTS,[ENCODING,[BYTEORDER,[SOFUMARK]]]])

Same as pack() but for C<Data::Sofu::Object>'s only

Will be called by pack().

Comments are taken from COMMENTS and from the Objects itself.

=cut

sub packObject { # Use the Object implemented Packer for now.
	my $self=shift;
	my $data=shift;
	my $r = ref $data;
	$self->{OFFSET}="while packing";
	$self->{SEEN}={};
	$self->die("Need an Object") unless $r and $r =~ m/Data::Sofu::/ and $data->isa("Data::Sofu::Object"); 
	#return $data->binaryPack(@_);
	#die "Not implemented for now";
	unless ($data->isMap()) {
		require Data::Sofu::Map;
		my $x = Data::Sofu::Map->new();
		$x->setAttribute("Value",$data);
		$data=$x;
	}
	$self->{SEEN}->{$data}="->";
	my $comments=shift;
	$comments = {} unless defined $comments;
	$self->die("Comment format wrong, must be hashref") unless (ref $comments and ref $comments eq "HASH");
	$self->{Comments}=$comments;
	my $str=$self->packHeader(@_);
	$str.=$self->packComment("=",$data->getComment());
	foreach my $key ($data->orderedKeys()) {
		#print $key,"\n";
		my $kkey = Data::Sofu::Sofukeyescape($key);
		$str.=$self->packText($key);
		$str.=$self->packObjectData($data->object($key),"->$kkey");
	}
	#die $str;
	return $str;
}


=head2 packObjectData(DATA,TREE)

Encodes one Data::Sofu::Object and its contents and returns it.

=cut

sub packObjectData {
	my $self=shift;
	my $data=shift;
	my $tree=shift;
	my $type=1;
	my $r = ref $data;
	#Maybe call packData on unknown Datastructures..... :)
	die ("Unknown Datastructure, can only work with Arrays and Hashes but not $r") unless $r and $r =~ m/Data::Sofu/ and $r->isa("Data::Sofu::Object");
	my $odata=$data;
	if ($data->isReference() and $data->valid()) {
		$data=$data->follow();
	}
	if ($data->isReference()) { #Reference to a Reference not yet allowed!
		confess("No Reference to a Reference allowed for now!");
		return $self->packType(4).$self->packComment($tree,$odata->getComment()).$self->packText("@".$data->follow());
	}
	if ($self->{SEEN}->{$data}) {
		#Carp::cluck();
		#print "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
		return $self->packType(4).$self->packComment($tree,$odata->getComment()).$self->packText("@".$self->{SEEN}->{$data});
	}
	$self->{SEEN}->{$data}=$tree;
	$self->{SEEN}->{$odata}=$tree;
	if ($data->isValue()) {
		return $self->packType(1).$self->packComment($tree,$odata->getComment()).$self->packText($data->toString());
	}
	if ($data->isMap()) {
		return $self->packType(3).$self->packComment($tree,$odata->getComment()).$self->packMap($data,$tree);
	}
	if ($data->isList()) {
		return $self->packType(2).$self->packComment($tree,$odata->getComment()).$self->packList($data,$tree);
	}
	return $self->packType(0).$self->packComment($tree,$odata->getComment());
}

=head2 packList(DATA,TREE)

Encodes one Data::Sofu::List and its contents and returns it.

=cut


sub packList {
	my $self=shift;
	my $data=shift;
	my $tree=shift;
	my $str=$self->packLong($data->length());
	my $i=0;
	while (my $element = $data->next()) {
		$str.=$self->packObjectData($element,"$tree->".$i++);
	}
	return $str;
}

=head2 packMap(DATA,TREE)

Encodes one Data::Sofu::Map and its contents and returns it.

=cut

sub packMap {
	my $self=shift;
	my $data=shift;
	my $tree=shift;
	my $str=$self->packLong($data->length());
	#foreach my $key (keys %{$data}) {
	#while (my ($key,$value) = $data->each()) {
	foreach my $key ($data->orderedKeys()) {
		#print $key,"\n";
		my $kkey = Data::Sofu::Sofukeyescape($key);
		$str.=$self->packText($key);
		$str.=$self->packObjectData($data->object($key),"$tree->$kkey");
	}
	return $str;
}


=head2 packComment(TREE,ADD)

Packs the comment for (TREE) + ADD and returns it.

=cut

sub packComment {
	my $self=shift;
	my $tree=shift;
	local $_;
	my $add=shift;
	if ($self->{Comments}->{$tree} or $add) {
		#$self->die("Comment format wrong for $tree, must be Arrayref");
		my @comments = ();
		@comments = @{$self->{Comments}->{$tree}} if (ref $self->{Comments}->{$tree} and ref $self->{Comments}->{$tree} eq "ARRAY");
		push @comments,@{$add} if $add and ref $add and ref $add eq "ARRAY";
		return $self->packText(join("\n",@comments));
	}
	else {
		return $self->packLong(0);
	}
	
}

=head2 packHeader([ENCODING,[BYTEORDER,[SOFUMARK]]])

Packs the header of the file and sets encoding and byteorder

=cut

sub packHeader { 
	my $self=shift;
	$self->{OFFSET}="while object packing";
	my $encoding=shift;
	my $byteorder=shift;
	$encoding=0 unless $encoding;
	$byteorder=0 unless $byteorder;
	$self->encoding($encoding) unless $self->byteorder($byteorder);
	my $mark=shift;
	#$mark = undef unless defined $mark;
	$self->{Mark} = $mark;
	#die $mark;
	my $str = "";
	$str.="Sofu" if $mark or not defined $mark;
	$str.=$self->packendian();
	$str.=$self->packversion();
	$str.=$self->packencoding();
	return $str;
}


=head1 BUGS

n/c

=head1 SEE ALSO

perl(1),L<http://sofu.sf.net>

Data::Sofu::Object, Data::Sofu, Data::Sofu::Binary::*


=cut

1;
