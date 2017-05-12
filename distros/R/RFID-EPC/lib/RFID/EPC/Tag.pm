package RFID::EPC::Tag;
$VERSION=0.002;
@ISA = qw(RFID::Tag);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.
=head1 NAME

RFID::EPC::Tag - An EPC tag.

=head1 SYNOPSIS

This class implements an EPC tag based on L<RFID::Tag|RFID::Tag>.  It
allows tags to be created based on the fields of the various EPC tag
types, and allows tag IDs to be parsed into their EPC components.

Generally, you'll get these objects returend from an EPC RFID reader:

    use RFID::Gumbo::Reader::TCP;
    my $reader = 
      RFID::Gumbo::Reader::TCP->new(PeerAddr => 10.20.30.40,
                                    PeerPort => 4001)
        or die "Couldn't create Blammo reader";
    my @tags = $reader->readtags();
    foreach my $tag (@tags)
    {
	if ($tag->type eq 'epc')
	{
	    my $epc_type = $tag->get('epc_type');
	    print "I see EPC tag ",$tag->id," of type $epc_type\n";
	}
    }

But you can also create a tag yourself, either with an ID string:

    my $tag = RFID::EPC::Tag->new(id => '357777777666666999999999');

or with the various componenets:

    my $tag =
      RFID::EPC::Tag->new(epc_serial => '999999999',
			  epc_manager => '7777777',
			  epc_class => '666666',
			  epc_type => 'GID-96');
    print "Tag ID is ",$tag->id,"\n";


=head1 DESCRIPTION

The parsing and tag creation in this module are based on the
specifications in EPCGlobal's I<EPC Tag Data Standards Version 1.1
Rev.1.24>, from April 1st 2004 (although it doesn't appear to be a
joke...).  See L<http://www.epcglobalinc.com/> for more information.

=cut

use strict;
use warnings;

use Carp;
use Exporter;
use RFID::Tag;

our @EXPORT_OK = (@RFID::Tag::Export_OK);

use constant TAGTYPE => 'epc';

# Cheatsheet for fast hex conversion
our %HEXCHEAT = ( 0 => '0000', 1 => '0001', 2 => '0010', 3 => '0011',
		  4 => '0100', 5 => '0101', 6 => '0110', 7 => '0111',
		  8 => '1000', 9 => '1001', A => '1010', B => '1011',
		  C => '1100', D => '1101', E => '1110', F => '1111');

# The names and specifications for all of the EPC tags we know about.
our %TAGTYPES =
    (
     'SGTIN-96' => {
	            bits => 96,
		    type_bits => 8,
		    type_val => 0b00110000,
		    fields => [
			       epc_header => 8,
			       epc_filter => 3,
			       epc_partition => 3,
			       epc_company => '?',
			       epc_item => '?',
			       epc_serial => 38
			      ],
		    partition_fields => [qw(epc_company epc_item)],
		    partitions => [
				   [40,4],
				   [37,7],
				   [34,10],
				   [30,14],
				   [27,17],
				   [24,20],
				   [20,24],
			       ],
		   },
     'GID-96' => {
	          bits => 96,
		  type_bits => 8,
		  type_val => 0b00110101,
		  fields => [
			     epc_header => 8,
			     epc_manager => 28,
			     epc_class => 24,
			     epc_serial => 36
			     ]
		  },
     'SGTIN-64' => {
                    bits => 64,
		    type_bits => 2,
		    type_val => 0b10000000,
		    fields => [
			       epc_header => 2,
			       epc_filter => 3,
			       epc_company => 14,
			       epc_item => 20,
			       epc_serial => 25
			       ]
		   },
     'SSCC-64' => {
                   bits => 64,
		   type_bits => 8,
		   type_val => 0b00001000,
		   fields => [
			      epc_header => 8,
			      epc_filter => 3,
			      epc_company => 14,
			      epc_serial => 39
			      ]
		   },
     'SSCC-96' => {
	            bits => 96,
		    type_bits => 8,
		    type_val => 0b00110001,
		    fields => [
			       epc_header => 8,
			       epc_filter => 3,
			       epc_partition => 3,
			       epc_company => '?',
			       epc_serial => '?',
			       epc_unallocated => 25
			      ],
		    partition_fields => [qw(epc_company epc_serial)],
		    partitions => [
				   [40,17],
				   [37,20],
				   [34,23],
				   [30,27],
				   [27,30],
				   [24,33],
				   [20,37],
			       ],
		   },
     'GRAI-64' => {
                   bits => 64,
		   type_bits => 8,
		   type_val => 0b00001010,
		   fields => [
			      epc_header => 8,
			      epc_filter => 3,
			      epc_company => 14,
			      epc_asset_type => 20,
			      epc_serial => 19
			      ]
		   },
     'GRAI-96' => {
	            bits => 96,
		    type_bits => 8,
		    type_val => 0b00110011,
		    fields => [
			       epc_header => 8,
			       epc_filter => 3,
			       epc_partition => 3,
			       epc_company => '?',
			       epc_asset_type => '?',
			       epc_serial => 38
			      ],
		    partition_fields => [qw(epc_company epc_asset_type)],
		    partitions => [
				   [40,4],
				   [37,7],
				   [34,10],
				   [30,14],
				   [27,17],
				   [24,20],
				   [20,24],
			       ],
		   },
     'SGLN-64' => {
                   bits => 64,
		   type_bits => 8,
		   type_val => 0b00001001,
		   fields => [
			      epc_header => 8,
			      epc_filter => 3,
			      epc_company => 14,
			      epc_location => 20,
			      epc_serial => 19
			      ]
		   },
     'SGLN-96' => {
	            bits => 96,
		    type_bits => 8,
		    type_val => 0b00110010,
		    fields => [
			       epc_header => 8,
			       epc_filter => 3,
			       epc_partition => 3,
			       epc_company => '?',
			       epc_location => '?',
			       epc_serial => 41
			      ],
		    partition_fields => [qw(epc_company epc_location)],
		    partitions => [
				   [40,1],
				   [37,4],
				   [34,7],
				   [30,11],
				   [27,14],
				   [24,17],
				   [20,21],
			       ],
		   },
     'GIAI-64' => {
                   bits => 64,
		   type_bits => 8,
		   type_val => 0b00001011,
		   fields => [
			      epc_header => 8,
			      epc_filter => 3,
			      epc_company => 14,
			      epc_asset => 39,
			      ]
		   },
     'GIAI-96' => {
	            bits => 96,
		    type_bits => 8,
		    type_val => 0b00110100,
		    fields => [
			       epc_header => 8,
			       epc_filter => 3,
			       epc_partition => 3,
			       epc_company => '?',
			       epc_asset => '?',
			      ],
		    partition_fields => [qw(epc_company epc_asset)],
		    partitions => [
				   [40,42],
				   [37,45],
				   [34,48],
				   [30,52],
				   [27,55],
				   [24,58],
				   [20,62],
			       ],
		   },
     'UNKNOWN1-64' => { 
		       bits => 64,
		       type_bits => 2,
		       type_val => 0b01000000,
		       fields => [
				  epc_header => 2,
				  epc_unknown => 62,
				  ]
		      },
     'UNKNOWN2-64' => { 
		       bits => 64,
		       type_bits => 2,
		       type_val => 0b11000000,
		       fields => [
				  epc_header => 2,
				  epc_unknown => 62,
				  ]
		      },
     'UNKNOWN3-64' => { 
		       bits => 64,
		       type_bits => 5,
		       type_val => 0b00001111,
		       fields => [
				  epc_header => 8,
				  epc_unknown => 56,
				  ]
		      },
     'UNKNOWN-96' => {
		      bits => 96,
		      type_bits => 4,
		      type_val => 0b00111111,
		      fields => [
				 epc_header => 8,
				 epc_unknown => 88,
				 ]
		     },
     'UNKNOWN' => {
		   type_bits => 0,
		   type_val => 0b00000111,
		   fields => [
			      epc_header => 8,
			      epc_unknown => '*',
			      ],
		  },
			      
    );

				   
# Sort from longest type_bits to shortest.
our @TAGSEARCH = sort 
                   { -1 * ($TAGTYPES{$a}{type_bits} <=> $TAGTYPES{$b}{type_bits}) }
                   keys %TAGTYPES;

=head2 Constructor

=head3 new

Creates a new EPC tag object with the requested properties.

There are two general ways to create an EPC tag.  First, you can pass
in the tag ID number as a hex string with the parameter name I<id>.
Second, you can pass in various components specific to your L<Tag
Type|/Tag Types>, including at least I<epc_type>.

    my $tag1 = RFID::EPC::Tag->new(id => '357777777666666999999999');

    my $tag2 =
      RFID::EPC::Tag->new(epc_serial => '999999999',
			  epc_manager => '7777777',
			  epc_class => '666666',
			  epc_type => 'GID-96');

    print "The two tags are ",
          ($tag1->tagcmp($tag2)==0?"the same":"different"),
          "\n";

=cut

sub new
{
    my $self = bless {}, shift;
    my(%p)=@_;

    $self->_init(%p);

    if (defined($p{id}))
    {
	# Construct a tag from its ID
	$self->{id} = uc $p{id};
	$self->{id} =~ tr/0-9A-Z//cd;
	$self->{id} =~ /^[0-9A-F]+$/
	    or croak "RFID::EPC::Tag id format is invalid (must be a hex number)";
    }
    elsif (defined($p{epc_type}))
    {
	# Construct a tag from its components.
	_maketag($self,\%p);
    }
    else
    {
	croak "Cannot create RFID::EPC::Tag with no id or parts";
    }

    $self;
}

=head2 Methods

The following methods are supported.  In addition, 
L<methods from RFID::Tag|RFID::Tag/Methods> are inherited.

=head3 get

Get a property of this tag.  In addition to the L<properties inherited
from RFID::Tag|RFID::Tag/Properties>, the following fields are
supported.  Note that whether a particular field is supported depends
on the tag type.  All fields are represented as hex strings.

=over 4

=item epc_type

The EPC type of this tag.

=item epc_serial

The EPC serial number of this tag.

=item epc_manager

The EPC manager number of this tag.

=item epc_class

The EPC class of this tag.

=item epc_header

The EPC header bits for this tag.

=item epc_filter

The EPC filter for this tag.

=item epc_partition

The EPC partition number for this tag.  This field determines the size
of later fields; see the EPC specification for more information.

=item epc_item

The EPC item number for this tag.

=item epc_company

The EPC company number for this tag.

=item epc_asset_type

The EPC asset type number for this tag.

=item epc_location

The EPC location number for this tag.

=item epc_asset

The EPC asset number for this tag.

=item epc_unknown

For tags of unrecognized type, all of the bytes that could not be
parsed.

=back

=cut

sub get
{
    my $self = shift;
    my(@p)=@_;
    my(%ret);

    foreach my $p (@p)
    {
	if (lc $p eq 'type')
	{
	    $ret{$p} = TAGTYPE;
	}
	elsif ($p =~ /^epc_/)
	{
	    $self->{_epc_parsed} = $self->_epc_parse
		unless ($self->{_epc_parsed});
	    if ($p eq 'epc_all')
	    {
		$ret{$p} = { %{$self->{_epc_parsed}} }
	    }
	    else
	    {
		$ret{$p}=$self->{_epc_parsed}{$p};
	    }
	}
	else
	{
	    $ret{$p} = $self->SUPER::get($p);
	}
    }
    
    if (wantarray)
    {
	return %ret;
    }
    else
    {
	# Return last value
	return $ret{$_[$#_]};
    }

}

# Create a tag from its various components
sub _maketag
{
    my($tag,$p)=@_;
    
    _packbits($tag,$p,$p->{epc_type});
    $tag;
}

# Helper function for _maketag
sub _packbits
{
    my($tag,$p,$type)=@_;
    my $spec = $TAGTYPES{$type}
        or die "Unknown tag type '$type'";
    my $bits = "";
    my %calc_fieldsize;

    # Create the header byte, with the bits right-justified in the
    # epc_header field, so they'll parse properly.
    $p->{epc_header} = sprintf "%x", $spec->{type_val} >> (8 - $spec->{fields}[1])
        unless (defined($p->{epc_header}));

    # Now build the tag ID based on the specs.
    my @fields = @{$spec->{fields}};
    while (@fields)
    {
	my $field = shift @fields;
	my $numbits = shift @fields;

	# Get the value for this field in hex, then clean it up.
	my $fieldval = defined($p->{$field}) 
	                 ? uc $p->{$field} 
                         : '';
	$fieldval =~ tr/0-9A-Z//cd;
	$fieldval =~ /^[0-9A-F]*$/
	    or croak "field '$field' must be in hex for tag type $tag->{epc_type}";
	if (length($fieldval) % 2)
	{
	    $fieldval = "0".$fieldval;
	}

	# Deal with special cases
	if ($field eq 'epc_partition')
	{
	    # The epc_partition field is an index into an array of
	    # sizes for fields that aren't yet defined (are set to ?)
	    my $partlist = $spec->{partitions}[hex $fieldval]
		or die "Invalid EPC partition size\n";
	    foreach my $i (0..$#{$partlist})
	    {
		$calc_fieldsize{$spec->{partition_fields}[$i]} = $partlist->[$i];
	    }
	}
	elsif ($numbits eq '?')
	{
	    # We should have already precalculated this from epc_partition
	    $numbits = $calc_fieldsize{$field}
	        or die "Couldn't figure out fieldsize for '$field'\n";
	}
	elsif ($numbits eq '*')
	{
	    # Just use all of the bits available.
	    # This is only used for the UNKNOWN type, where we don't
	    # know the size and have to guess.
	    $numbits = length($fieldval)*4;
	}
	
	# Convert into binary and append to current bits
	my $fieldbits=substr(unpack("B*",pack("H*",$fieldval)),-$numbits);
	$bits .= "0" x ($numbits-length($fieldbits)) . $fieldbits;
    }
    # Convert bitstring into hex.
    $tag->{id} = unpack("H*",pack("B*",$bits));
}

# Return a hash with the components of a tag's ID
sub _epc_parse
{
    my $self = shift;
    my $id = $self->id;
    my $byte1 = hex substr($id,0,2);
    my $taglen;
    
    # Find the match for the header with the longest mask
    foreach my $name (@TAGSEARCH)
    {
	my $spec = $TAGTYPES{$name};
	my $mask;
	if (!defined($mask=$spec->{type_mask}))
	{
	    $mask=$spec->{type_mask} = 2**($spec->{type_bits})-1 << (8 - $spec->{type_bits});
	}
	if (($byte1 & $mask) == ($spec->{type_val} & $mask))
	{
	    return _splitbits($id,$name);
	}
    }

    # This should never happen, since the UNKNOWN tag type should
    # always match.
    die "Couldn't figure out tag type '$byte1'!\n";
}

# Helper function for _epc_parse
sub _splitbits
{
    my($hex,$name)=@_;
    my $spec = $TAGTYPES{$name}
        or die "Unknown tag type '$name'";
    my %r = (epc_type => $name);
    my %calc_fieldsize;
    
    # Convert hex to a string of bits
    my $bits = unpack("B*",pack("H*",$hex));

    # Now deconstruct the ID field-by-field.
    my @fields = @{$spec->{fields}};
    while (@fields)
    {
	my $field = shift @fields;
	my $numbits = shift @fields;

	if ($numbits eq '?')
	{
	    $numbits = $calc_fieldsize{$field}
  	        or die "Couldn't figure out fieldsize for '$field'\n";
	}
	elsif ($numbits eq '*')
	{
	    $numbits = length($bits);
	}

	my $thesebits = substr($bits,0,$numbits,'');
	
	# Pad with 0's so that unpack can parse it properly.
	if ($numbits % 4)
	{
	    $thesebits = "0"x(4-$numbits%4) . $thesebits;
	}

	# Now convert the bits into hex
	$r{$field} = unpack("H*",(pack("B*",$thesebits)));
	if (($numbits % 8) and ($numbits % 8) <= 4)
	{
	    # Remove trailing zero.
	    chop($r{$field});
	}

	# Handle the special partition case, which determines the sizes
	# of later fields.
	if ($field eq 'epc_partition')
	{
	    my $partition = hex($r{$field});
	    my $partlist = $spec->{partitions}[$partition]
		or die "Invalid EPC partition size\n";
	    foreach my $i (0..$#{$partlist})
	    {
		$calc_fieldsize{$spec->{partition_fields}[$i]} = $partlist->[$i];
	    }
	}
	
    }

    return \%r;
}

=head3 type

This method returns the general type of this tag (always C<epc>).

=cut

sub type
{
    return TAGTYPE;
}

=head2 Tag Types

The EPC Tag Data Standards document defines many specific types of EPC
tags.  We do our best to parse these out, and return the appropriate
fields.  This isn't very well tested, since we don't have access to a
large number of different types of EPC tags, but it tries to follow
the spec, and should be easy to correct if any errors are found.

The purpose of the fields is beyond the scope of this document; we
assume you know what the fields are for, and just want to know what
names they are given in this code.  Mostly that's because it took EPC
78 pages to describe exactly what the tag types are, and I don't want
to repeat that here.  Look up the I<EPC Tag Data Standards> document
referenced at the top of this documentation for more information.

=over 4

=item GIAI-64

64-bit Global Individual Asset Identifier.  Fields are epc_header,
epc_filter, epc_company, epc_asset.

=item GIAI-96

96-bit Global Individual Asset Identifier.  Fields are epc_header,
epc_filter, epc_partition, epc_company, epc_asset.

=item GID-96

96-bit General Identifier.  Fields are epc_header, epc_manager,
epc_class, epc_serial.

=item GRAI-64

64-bit Global Returnable Asset Identifier.  Fields are epc_header,
epc_filter, epc_company, epc_asset_type, epc_serial.

=item GRAI-96

96-bit Global Returnable Asset Identifier.  Fields are epc_header,
epc_filter, epc_partition, epc_company, epc_asset_type, epc_serial.

=item SGLN-64

64-bit Serialized Global Location Number.  Fields are epc_header,
epc_filter, epc_company, epc_location, epc_serial.

=item SGLN-96

96-bit Serialized Global Location Number.  Fields are epc_header,
epc_filter, epc_partition, epc_company, epc_location, epc_serial.

=item SGTIN-64

64-bit Serialized Global Trade Identification Number.  Fields are
epc_header, epc_filter, epc_company, epc_item, epc_serial.

=item SGTIN-96

96-bit Serialized Global Trade Identification Number.  Fields are
epc_header, epc_filter, epc_partition, epc_company, epc_item,
epc_serial.

=item SSCC-64

64-bit Serial Shipping Container Code.  Fields are epc_header,
epc_filter, epc_company, epc_serial.

=item SSCC-96

96-bit Serial Shipping Container Code.  Fields are epc_header,
epc_filter, epc_partition, epc_company, epc_serial, epc_unallocated.

=item UNKNOWNI<x>-64

64-bit tag without any type recognized by this software, but with a
header indicating it is 64 bits.  Fields are epc_header and
epc_unknown.

=item UNKNOWN-96

96-bit tag without any type recognized by this software, but with a
header indicating it is 96 bits.  Fields are epc_header and
epc_unknown.

=item UNKNOWN

Tag without any type recognized by this software, and with no
indication of its size in the header.  Fields are epc_header and
epc_unknown.

=back

=head1 SEE ALSO

L<RFID::Tag>, L<RFID::Reader>,
L<http://www.eecs.umich.edu/~wherefid/code/rfid-perl/>,
L<http://www.epcglobalinc.com/>, The manual for your particular RFID
reader.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut


1;
