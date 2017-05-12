package RFID::Matrics::Reader;
our $VERSION = '0.002';
@ISA = qw(RFID::Reader Exporter);
use strict;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Matrics::Reader - Abstract base class for a Matrics RFID reader

=head1 SYNOPSIS

This abstract base class provides most of the methods required for
interfacing Perl with a Matrics RFID reader.  To actually create an
object, use
L<RFID::Matrics::Reader::Serial|RFID::Matrics::Reader::Serial> or
L<RFID::Matrics::Reader::TCP|RFID::Matrics::Reader::TCP>.  It is based
on L<RFID::Reader|RFID::Reader>.

    use RFID::Matrics::Reader::Serial;
    my $reader = 
      RFID::Matrics::Reader::Serial->new(Port => $com_port_object,
				         Node => 4,
					 Antenna => 1)
        or die "Couldn't create reader object\n";

    my @err = $reader->set(PowerLevel => 0xff,
		           Environment => 4) == 0
        or die "Couldn't set params: @err\n";

    my @tags = $reader->readtags;
    foreach my $tag (@tags)
    {
	my $tag_info = $tag->get('Antenna','ID','Type');
	print "I see tag $tag_info{Type}.$tag_info{ID} ".
              "at antenna $tag_info{Antenna}.\n";
    }

=head1 DESCRIPTION

This abstract base class implements the commands for communicating
with a Matrics reader.  It is written according to the specifications
in Matrics' I<Stationary Reader / Host Protocol (RS-485)
Specification>, using version 2.8 from October 19th 2003.  It was
tested with an RDR-001 model reader.

To actually create a reader object, use
L<RFID::Matrics::Reader::Serial|RFID::Matrics::Reader::Serial> or
L<RFID::Matrics::Reader::TCP|RFID::Matrics::Reader::TCP>.  Those
classes inherit from this one.

This class inherits some methods and settings from
L<RFID::Reader|RFID::Reader>.

=cut

use RFID::Reader qw(hexdump);
use Exporter;
use Carp qw(cluck croak carp);
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);
# You shouldn't use the antenna constants anymore, just use numbers 1-4.
@EXPORT_OK = qw(MATRICS_ANT_1 MATRICS_ANT_2 MATRICS_ANT_3 MATRICS_ANT_4 hexdump);
%EXPORT_TAGS = (ant => [ qw(MATRICS_ANT_1 MATRICS_ANT_2 MATRICS_ANT_3 MATRICS_ANT_4)]);

use RFID::Matrics::CRC qw(crc);
use RFID::EPC::Tag;
use RFID::Matrics::Tag;

use constant MATRICS_ANT_1 => 0xa0;
use constant MATRICS_ANT_2 => 0xb0;
use constant MATRICS_ANT_3 => 0xc0;
use constant MATRICS_ANT_4 => 0xd0;

our %antname = (
		&MATRICS_ANT_1 => 1,
		&MATRICS_ANT_2 => 2,
		&MATRICS_ANT_3 => 3,
		&MATRICS_ANT_4 => 4,
		);

our %paramblock_setting = (power_level => 1,
                           environment => 1,
                          );
our %paramblock_rename = (PowerLevel => 'power_level',
                          Environment => 'environment',
                          Mask => 'Mask',
                         );
our %readerstatus_rename = (ReaderVersion => 'version',
                            ReaderSerialNum => 'serialnum',
                           );

our %antid = (1 => MATRICS_ANT_1,
              2 => MATRICS_ANT_2,
              3 => MATRICS_ANT_3,
              4 => MATRICS_ANT_4);

# Initializer used by derived objects
sub _init
{
    my $self = shift;
    my(%p)=@_;

    $self->{default_node} = $p{Node}||$p{node};
    $self->{timeout} = $p{timeout}||$p{Timeout}
        unless ($self->{timeout});

    # This can't be set again, so let's delete it.
    delete $p{node};
    delete $p{Node};

    my @errs = $self->set(%p);
    if (grep { $_ !~ /Unknown setting/ } @errs)
    {
	die "Error setting properties: @errs\n";
    }

    $self->{default_antenna} = $p{Antenna}||$p{antenna};
    if (!defined($self->{default_antenna}))
    {
	 if (defined($self->{_antenna_sequence}))
	 {
	     $self->{default_antenna} = $self->{_antenna_sequence}[0];
	 }
	 else
	 {
	     $self->{default_antenna} = 1;
	 }
    }
    $self->{_antenna_sequence} = [$self->{default_antenna}]
	if (!$self->{_antenna_sequence});


    $self->stop_constant_read(node => $self->{default_node})
	if ($self->{default_node} and (!$p{noinit}));

    $self->SUPER::_init(%p);
}




=head2 METHODS

=cut

our %_errmsgs = (
		0xF0 => "READER - Invalid command parameter(s)",
		0xF1 => "READER - Insufficient data",
		0xF2 => "READER - Command not supported",
		0xF3 => "READER - Antenna Fault (not present or shorted)",
		0xF4 => "READER - DSP Timeout",
		0xF5 => "READER - DSP Error",
		0xF6 => "READER - DSP Idle",
		0xF7 => "READER - Zero Power",
		0xFF => "READER - Undefined error",
		);

# Prototype
sub uniq(&@);

sub _setdefaults
{
    my $self = shift;
    my($p)=@_;
    $p->{node} = $self->{default_node}
      unless defined($p->{node});
    $p->{antenna} = $self->{default_antenna}
      unless defined($p->{antenna});
    $p->{antenna} = $antid{$p->{antenna}}
      if (defined($p->{antenna}) and $p->{antenna} < 10);
    $p;
}

sub _makepacket
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);
    
    $p{data}||="";
    my $packet = pack("CCCa*",$p{node},length($p{data})+5,$p{cmd},$p{data});
    return pack("Ca*v",1,$packet,crc($packet));
}

sub _parsepacket
{
    my $self = shift;
    my($packet)=@_;
    my %dat;
    my $sof;
    
    my $dl = length($packet)-7;
    ($sof,@dat{qw(node len cmd status data crc)}) = unpack("CCCCCa${dl}v",$packet);
    unless ($sof==1)
    {
	return $self->error("No start of frame byte in packet!");
    }
    unless (crc(substr($packet,1,-2)) == $dat{crc})
    {
	return $self->error("Bad CRC in packet!\n");
    }
    if ( ($dat{status} & 0x80)==0x80 or ($dat{status} & 0xC0)==0xC0)
    {
	my $ec = unpack("C",$dat{data});
	return $self->error($_errmsgs{$ec},$ec);
    }
    return \%dat;
}

sub _getpacket
{
    my($self)=@_;
    my $data = $self->_readbytes(3)
	or die "Couldn't read data: $!\n";
    length($data) == 3
	or die "Data short read!\n";
    my($sof,$addr,$len)=unpack("CCC",$data);
    
    my $moredata = $self->_readbytes($len-2)
	or die "Couldn't read data: $!\n";
    length($moredata) == ($len-2)
	or die "Data short read!\n";
    
    $self->debug(" RECV: ",hexdump($data.$moredata),"\n")
	if ($self->{_debug});
    return $data.$moredata;
}

sub _sendpacket
{
    my $self = shift;
    my($data)=@_;

    $self->debug(" SEND: ",hexdump($data),"\n")
	if ($self->{_debug});
    $self->_writebytes($data)
	or die "Couldn't write to COM port: $^E";
}

sub _do_something
{
    my $self = shift;
    my($cmd_sub,$resp_sub,%p)=@_;
    my @ret ;

    my $cmd = $cmd_sub->($self,%p)
	or return undef;
    $self->_sendpacket($cmd)
	or die "Couldn't write command: $!\n";

    while(1)
    {
	my $resp = $self->_getpacket()
	    or die "Couldn't read response: $!\n";
	my $pr = $resp_sub->($self,$resp)
	    or return undef;
	push(@ret,$pr);
	last unless ($pr->{status} & 0x01);
    }
    return wantarray?@ret:$ret[0];
}

=head3 get

Get various properties of the reader or the internal state of the
object.  The syntax is described in L<the RFID::Reader get
method|RFID::Reader/get> documentation.  See L<Matrics Properties|/Properties> 
and L<Generic Properties|RFID::Reader/Properties> for the properties
that can be retreived.

=cut

sub get
{
    my $self = shift;
    my %get;
    my %ret;
    my %paramblocks;
    my $readerstatus;

    foreach my $g (@_)
    {
	if ($paramblock_rename{$g} or ($g =~ /^(\w+)_Antenna(\d+)$/ and $paramblock_rename{$1}))
	{
	    my($ant,$asv);
	    if ($paramblock_rename{$g})
	    {
		$ant = $self->{default_antenna};
		$asv = $paramblock_rename{$g};
	    }
	    else
	    {
		$ant = $2;
		$asv = $paramblock_rename{$1};
	    }
	    if (!$paramblocks{$ant})
	    {
		$paramblocks{$ant} = $self->getparamblock(antenna => $antid{$ant})
		    or die "Couldn't getparamblock for antenna $ant!";
	    }
	    if ($g eq 'Mask')
	    {
		my $masktype = $paramblocks{$ant}{filter_type};
		if ($masktype == 0)
		{
		    $ret{$g}='';
		}
		else
		{
		    my $mask = bin2hex_big_endian($paramblocks{$ant}{filter_bits});
		    $mask =~ s/\s//g;
		    if ($masktype == 1)
		    {
			$ret{$g} = substr($mask,0,2)."/8";
		    }
		    elsif ($masktype == 2)
		    {
			$ret{$g} = substr($mask,0,10)."/40";
		    }
		    elsif ($masktype == 3)
		    {
			$ret{g} = substr($mask,0,16)."/64";
		    }
		    else
		    {
			# Error
			$ret{g} = undef;
		    }
		}
	    }
	    else
	    {
		$ret{$g} = $paramblocks{$ant}{$asv};
	    }
	}
	elsif ($g eq 'AntennaSequence')
	{
	    $ret{$g} = [$self->{_antenna_sequence}];
	}
	elsif ($readerstatus_rename{$g})
	{
	    if (!$readerstatus)
	    {
		my %p;
		$self->_setdefaults(\%p);
		$readerstatus = $self->getreaderstatus(%p)
		    or die "Couldn't get reader status: $self->{error}";
	    }
	    $ret{$g}=$readerstatus->{$readerstatus_rename{$g}};
	}
	else
	{
	    croak "Unknown setting '$g'";
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

sub getparamblock
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);
    $self->_do_something(\&_cmd_getparamblock,\&_resp_getparamblock,@_);
}


sub _cmd_getparamblock
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);
    $self->_makepacket(%p,
		       cmd => 0x24,
		       data => pack("C",$p{antenna}),
		       );
}

sub _resp_getparamblock
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
    (@$pp{qw(power_level environment combine_antenna_bits protocol_speed filter_type tagtype reserved_bits filter_bits reserved_bits)}) =
	unpack("CCa1CCCa2a8a*",$pp->{data});
    $pp->{combine_antenna}=[];
    my $ca = ord $pp->{combine_antenna_bits};
    foreach my $i (0..3)
    {
	my @antarr = (MATRICS_ANT_1, MATRICS_ANT_2, MATRICS_ANT_3, MATRICS_ANT_4);
	if ($ca & (1 << $i))
	{
	    push(@{$pp->{combine_antenna}},$antarr[$i]);
	}
    }
    $pp;
}


=head3 set

Set one or more properties associated with a reader.  Depending on
implementation, this may send one or more commands to the reader, set
an internal flag, or take some other action.  

This method takes a hash with the properties to be set as keys, and
their new values as values.  It returns a list of errors that occured;
if no errors occured, it will return an empty list. In a scalar
context, that evaluates to the number of errors that occured, so you
can test for errors like this:

    my @errs = $reader->set(SomeVariable => "New Value") == 0
      or die "Couldn't set SomeVariable: @errs";

See L<Properties|/Properties> for the properties that can be set.

=cut

sub set
{
    my $self = shift;
    my(%p)=@_;
    my %antset;
    my %ant_specific;
    my %unknown;
    my @errs;

    # First pass through settings.
    # Settings that can be grouped into a single command are collected,
    # and set efficiently in a second pass.
    while(my($k,$v)=each(%p))
    {
	if ($paramblock_rename{$k} or ($k =~ /^(\w+)_Antenna(\d+)$/ and $paramblock_rename{$1}))
	{
	    my($ant,$param);
	    if ($paramblock_rename{$k})
	    {
		($ant,$param)=('ALL',$paramblock_rename{$k});
	    }
	    else
	    {
		($ant,$param)=($2,$paramblock_rename{$1});
	    }
	    if ($param eq 'Mask')
	    {
		if ($v eq '')
		{
		    $antset{$ant}{filter_type}=0;
		    $antset{$ant}{filter_bits}="\0"x8;
		}
		else
		{
		    my($mask,$len,$start)=split(/\//,$v);
		    if ($start)
		    {
			push(@errs,"Matrics reader doesn't support mask start bit");
			next;
		    }
		    if (!defined($len))
		    {
			$len = length($mask) * 4;
		    }
		    $antset{$ant}{filter_bits} = hex2bin_big_endian($mask);
		    if ($len == 0)
		    {
			$antset{$ant}{filter_type} = 0;
		    }
		    elsif ($len == 8)
		    {
			$antset{$ant}{filter_type} = 1;
		    }
		    elsif ($len == 40)
		    {
			$antset{$ant}{filter_type} = 2;
		    }
		    elsif ($len == 64)
		    {
			$antset{$ant}{filter_type} = 3;
		    }
		    else
		    {
			push(@errs,"Matrics reader only supports mask len of 0, 8, 40, and 64.");
			next;
		    }
		    $antset{$ant}{filter_bits} = substr($antset{$ant}{filter_bits},0,$len/8) . "\0" x (8-($len/8));
		}
	    }
	    $antset{$ant}{$param} = $v;
	}
	elsif ($k eq 'AntennaSequence')
	{
	    $self->{_antenna_sequence} = $v;
	}
	elsif ($k eq 'node')
	{
	    push(@errs, "Can't set node (yet)!");
	    next;
	}
	elsif ($k eq 'baudrate')
	{
	    push(@errs,"Can't set baudrate (yet)!");
	    next;
	}
	else
	{
	    $unknown{$k}=$v;
	}
    }
    if (keys %unknown)
    {
	push(@errs,$self->SUPER::set(%unknown));
    }

    # Copy options for all antennas into each individual antenna
    while (my($k,$v)=each(%{$antset{ALL}}))
    {
	foreach my $a (@{$self->{_antenna_sequence}})
	{
	    $antset{$a}{$k} = $v;
	}
    }

    foreach my $ant (1..4)
    {
	if ($antset{$ant})
	{
	    $antset{$ant}{antenna} = $antid{$ant};
	    $self->_setdefaults($antset{$ant});
	    $self->changeparamblock(%{$antset{$ant}})
		or push(@errs, "Error changing params: $self->{error}");
	}
    }
    @errs;
}


sub setparamblock
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);

    $self->_do_something(\&_cmd_setparamblock,\&_resp_setparamblock,@_);
}

sub _cmd_setparamblock
{
    my $self = shift;
    my(%p)=@_;

    $self->_makepacket(%p,
		       cmd => 0x23,
		       data => pack("CCCCCCCCCCx2a8x16",
				    $self->_make_confwhich_ant(\%p), # Returns 4 bytes
				    defined($p{power_level})?$p{power_level}:0xff,
				    defined($p{environment})?$p{environment}:0x00,
				    $self->_make_combine_antenna_bits(\%p),
				    $p{protocol_speed}||0,
				    $p{filter_type}||0,
				    $p{tagtype}||0,
				    $p{filter_bits}||"\0"x8,
				    )
		       );
}

sub _resp_setparamblock
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
}

sub changeparamblock
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);

    croak "changeparamblock: The required parameter 'antenna' is missing.\n"
	unless ($p{antenna});
    my $curparam = $self->getparamblock(@_)
	or return undef;
    if ($p{combine_antennas})
    {
	delete $curparam->{combine_antenna_bits};
    }
    return $self->setparamblock(%$curparam, @_);
}

=head3 readtags

Read all of the tags in the reader's field, honoring any settings
affecting the reading and filtering of tags.  This returns a (possibly
empty) list of tags, which will be of type
L<RFID::EPC::Tag|RFID::EPC::Tag> or
L<RFID::Tag::Matrics|RFID::Matrics::Tag>.  See L<the RFID::Reader
readtags method documentation|RFID::Reader/readtags> for more
information.

=cut

sub readtags
{
    my $self = shift;
    my @tags;
    
    foreach my $ant (@{$self->{_antenna_sequence}})
    {
	my $r = $self->readfullfield(antenna => $ant);
	push(@tags,@{$r->{tags}})
	    if ($r->{tags});
    }
    return $self->filter_tags(@tags);
}

sub readfullfield
{
    my $self = shift;
    my @resp = $self->_do_something(\&_cmd_readfullfield,\&_resp_readfullfield,@_)
	or return undef;
    my $ret = shift(@resp);
    foreach my $r (@resp)
    {
	$ret->{numtags} += $r->{numtags};
	push(@{$ret->{tags}}, @{$r->{tags}});
    }
    $ret;
}

sub _cmd_readfullfield
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);
    
    $self->_makepacket(%p,
		       cmd => 0x22,
		       data => pack("C",$p{antenna}),
		       );
}

sub _resp_readfullfield
{
    my $self = shift;
    my $pp =$self->_parsepacket(@_)
	or return undef;
    my $dc = $pp->{data};
    (@$pp{qw(antenna numtags)}) = unpack("CC",substr($dc,0,2,""));
    $pp->{tags} = [$self->_parsetags($pp->{numtags},$dc,Antenna => $antname{$pp->{antenna}})];
    $pp;
}

sub readfullfield_unique
{
    my $self = shift;
    my $pp = $self->readfullfield(@_);

    @{$pp->{utags}} = uniq { $a->tagcmp($b) }
                       sort { $a->tagcmp($b) } 
                        @{$pp->{tags}};
    $pp->{unumtags}=scalar(@{$pp->{utags}});
    $pp;
}

sub start_constant_read
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);

    my $cmd = $self->_cmd_start_constant_read(%p);
    $self->_sendpacket($cmd)
	or die "Couldn't read command: $!\n";
    $self->{_constant_read}{$p{node}}=1;
}

sub _cmd_start_constant_read
{
    my $self = shift;
    my(%p)=@_;

    $self->_setdefaults(\%p);
#    $antflag{$_}=1
#	foreach grep { defined } ($p{antenna1}||$p{antenna}||MATRICS_ANT_1,
#				  @$p{qw(antenna2 antenna3 antenna4)});
    $self->_makepacket(%p,
		       cmd => 0x25,
		       data => pack("CCCCCCCCCCCCa8",
				    $p{antenna1}||$p{antenna}||0,
				    $p{antenna2}||0,
				    $p{antenna3}||0,
				    $p{antenna4}||0,
				    $p{antenna1_power}||0xff,
				    $p{antenna2_power}||$p{antenna2}?0xff:0,
				    $p{antenna3_power}||$p{antenna3}?0xff:0,
				    $p{antenna4_power}||$p{antenna4}?0xff:0,
				    $p{dwell_time}||150,
				    $p{channel}||8,
				    $p{maskbits}||0,$p{masktype}||0,
				    $p{mask}||"\0\0\0\0\0\0\0\0",
				    ),
		       );
}

sub _epc_parsetags
{
    my $self = shift;
    my($count,$dc,%tagprops)=@_;
    my @tags;

    foreach my $i (1..$count)
    {
	my $type = ord(substr($dc,0,1));
	my $tag;
	if ($type == 0x0C)
	{
	    # Proprietary Matrics Tag
	    $tag = RFID::Matrics::Tag->new(id => bin2hex_little_endian(unpack("a8",substr($dc,1,8))),
					   %tagprops);
	}
	else
	{
	    # EPC tag
	    $tag = RFID::EPC::Tag->new(id => bin2hex_little_endian(unpack("a12",substr($dc,0,13))),
				       %tagprops);
	}
	push(@tags,$tag);
    }
    @tags;
}

sub constant_read
{
    my $self = shift;
    my(%p)=@_;
    
    $self->_setdefaults(\%p);

    croak "Please call start_constant_read before constant_read\n"
	unless ($self->{_constant_read}{$p{node}});

    my $resp = $self->_getpacket()
	or die "Couldn't read response: $!\n";
    my $pr = $self->_resp_constant_read($resp);
    return $pr;
}

sub _resp_constant_read
{
    my $self = shift;

    my $pp = $self->_parsepacket(@_);
    if (!$pp)
    {
	return { numtags => 0,
		 tags => [],
		 error => $self->{error},
		 errcode => $self->{errcode},
	     };

    }
    
    if ($pp->{error})
    {
	$pp->{numtags} = 0;
	$pp->{tags} = [];
	return $pp;
    }
    my $dc = $pp->{data};
    @$pp{qw(antenna numtags)} = unpack("CC",substr($dc,0,2,""));
    $pp->{tags} = [$self->_parsetags($pp->{numtags},$dc)];
    return $pp;
}

sub _parsetags
{
    my $self = shift;
    my($count,$dc,%tagprops)=@_;
    my @tags;

    foreach my $i (1..$count)
    {
	my $type_len_bits = unpack("C",substr($dc,0,1,""));
	my $len = ($type_len_bits & 0x10) ? 12 : 8;
	my $type = ($type_len_bits & 0x0f);
	my $id_bits = unpack("a*",substr($dc,0,$len,""));
	my $tag;
	if ($type == 0)
	{
	    # EPC tag
	    $tag = RFID::EPC::Tag->new(id => bin2hex_little_endian($id_bits),
				       %tagprops);
	}
	else
	{
	    # Proprietary Matrics Tag
	    $tag = RFID::Matrics::Tag->new(id => bin2hex_little_endian($id_bits),
					   %tagprops);
	}
	push(@tags,$tag);
    }
    @tags;
}

sub stop_constant_read
{
    my $self = shift;
    my(%p)=@_;

    $self->_setdefaults(\%p);
    delete $self->{_constant_read}{$p{node}};
    $self->_do_something(\&_cmd_stop_constant_read,\&_resp_stop_constant_read,@_);
}


sub _cmd_stop_constant_read
{
    my $self = shift;
    my(%p)=@_;
    
    $self->_makepacket(%p,
		       cmd => 0x26,
		       data => "",
		       );
}

sub _resp_stop_constant_read
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
    return $pp;
}

sub stop_all_constant_read
{
    my $self = shift;
    
    if ($self->{_constant_read} && $self->_connected)
    {
	foreach my $node (keys %{$self->{_constant_read}})
	{
	    $self->stop_constant_read(node => $node);
	}
    }
    1;
}

sub _make_confwhich_ant
{
    my $self = shift;
    my($p)=@_;
    my %antflag;

    
    foreach my $a (grep { defined($p->{"antenna".$_}) }
		   (1..4))
    {
	$antflag{$antid{$a}} = 1;
    }
    if (!(keys %antflag))
    {
	$antflag{$p->{antenna}||MATRICS_ANT_1} = 1;
    }
    return ($antflag{MATRICS_ANT_1()}?1:0,
	    $antflag{MATRICS_ANT_2()}?1:0,
	    $antflag{MATRICS_ANT_3()}?1:0,
	    $antflag{MATRICS_ANT_4()}?1:0,
	    );
}

sub _make_combine_antenna_bits
{
    my $self = shift;
    my($p)=@_;
    my %antbit = (
		  MATRICS_ANT_1() => 1,
		  MATRICS_ANT_2() => 2,
		  MATRICS_ANT_3() => 4,
		  MATRICS_ANT_4() => 8,
		  );

    if (!$p->{combine_antenna_bits})
    {
	my $cab = 0;
	if ($p->{combine_antennas})
	{
	    $cab |= $antbit{$_}
   	        foreach (@{$p->{combine_antennas}});
	}
	$p->{combine_antenna_bits}=chr($cab);
    }
    return ord($p->{combine_antenna_bits});
}

sub epc_readfullfield
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);
    
    my @resp = $self->_do_something(\&_cmd_epc_readfullfield,
				    \&_resp_epc_readfullfield,
				    %p)
	or return undef;

    my $ret = shift(@resp);
    foreach my $r (@resp)
    {
	$ret->{numtags} += $r->{numtags};
	push(@{$ret->{tags}},@{$r->{tags}});
    }
    $ret;
}

sub _cmd_epc_readfullfield
{
    my $self = shift;
    my(%p)=@_;
    
    $self->_makepacket(%p,
		       cmd => 0x10,
		       data => pack("C",$p{antenna}),
		       );
}

sub _resp_epc_readfullfield
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
    my $dc = $pp->{data};
    (@$pp{qw(antenna numtags)}) = unpack("CC",substr($dc,0,2,""));
    $pp->{tags} = [$self->_epc_parsetags($pp->{numtags},$dc)];
    $pp;
}

sub epc_readfullfield_unique
{
    my $self = shift;
    my $ret = $self->epc_readfullfield;

    @{$ret->{utags}} = uniq { $a->tagcmp($b) }
                       sort { $a->tagcmp($b) } 
                        @{$ret->{tags}};
    $ret->{unumtags}=scalar(@{$ret->{utags}});

    $ret;
}

sub epc_getparamblock
{
    my $self = shift;
    $self->_do_something(\&_cmd_epc_getparamblock,\&_resp_epc_getparamblock,@_);
}

sub _cmd_epc_getparamblock
{
    my $self = shift;
    my(%p)=@_;
    
    $self->_makepacket(%p,
		       cmd => 0x16,
		       data => pack("C",$p{antenna}),
		       );
}

sub _resp_epc_getparamblock
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
    
    @$pp{qw(power_level environment combine_antenna_bits protocol_speed filter_type reserved1_bits filter_bits reserved2_bits)} =
	unpack("CCCCCa3a8a16",$pp->{data});
    $pp;
}

sub epc_setparamblock
{
    my $self = shift;
    $self->_do_something(\&_cmd_epc_setparamblock,\&_resp_epc_setparamblock,@_);
}

sub _cmd_epc_setparamblock
{
    my $self = shift;
    my(%p)=@_;
    

    $self->_makepacket(%p,
		       cmd => 0x15,
		       data => pack("CCCCCCCCCa3a8a16",
				    $self->_make_confwhich_ant(\%p), # Returns 4 bytes
				    defined($p{power_level})?$p{power_level}:0xff,
				    $p{environment}||0x00,
				    $self->_make_combine_antenna_bits(\%p),
				    $p{protocol_speeed}||0x00,
				    $p{filter_type}||0x00,
				    $p{reserved1_bits}||("\0"x3),
				    $p{filter_bits}||("\0"x8),
				    $p{reserved2_bits}||("\0"x16),
				    )
		       );
}

sub _resp_epc_setparamblock
{
    my $self = shift;

    my $pp = $self->_parsepacket(@_)
	or return undef;
}


sub epc_changeparamblock
{
    my $self = shift;
    my(%p)=@_;

    croak "changeparam: The required parameter 'antenna' is missing.\n"
	unless ($p{antenna});
    my $curparam = $self->epc_getparamblock(@_)
	or return undef;
    return $self->epc_setparamblock(%$curparam, @_);
}

sub setnodeaddress
{
    my $self = shift;
    my(%p)=@_;
    
    my $node = $p{oldnode}||0xFF;
    if ($p{oldnode}==0xFF or !$p{oldnode})
    {
	# No response to broadcast commands, just send it.
	my $cmd = _cmd_setnodeaddress($self, @_)
	    or return undef;
	$self->_sendpacket($cmd)
	    or die "Couldn't write command: $!\n";
	return { noresponse => 1 };
    }
    else
    {
	$self->_do_something(\&_cmd_setnodeaddress,\&_resp_setnodeaddress,@_);
    }
}

sub _cmd_setnodeaddress
{
    my $self = shift;
    my(%p)=@_;
    $self->_setdefaults(\%p);
    
    if (!$p{serialnum_bits})
    {
	defined($p{serialnum}) or return $self->error("Missing required parameter serialnum or serialnum_bits");
	$p{serialnum_bits} = hex2bin_little_endian($p{serialnum});
    }
    $p{newnode} or $p{node} or return $self->error("Missing required parameter newnode or node");

    $self->_makepacket(%p,
		       node => $p{oldnode}||0xFF,
		       cmd => 0x12,
		       data => pack("Ca8",
				    $p{newnode}||$p{node},
				    $p{serialnum_bits},
				    ),
		       );
}

sub _resp_setnodeaddress
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
}

sub getreaderstatus
{
    my $self = shift;
    $self->_do_something(\&_cmd_getreaderstatus,\&_resp_getreaderstatus,@_);
}

sub _cmd_getreaderstatus
{
    my $self = shift;
    my(%p)=@_;

    $self->_makepacket(%p,
		       cmd => 0x14,
		       );
}

sub _resp_getreaderstatus
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
    
    @$pp{qw(serialnum_bits version_major version_minor version_eng 
	    reset_flag combine_antenna_bits antenna_status_bits
	    last_error reserved)} =
		unpack("a8CCCCa4a4Ca11",$pp->{data});
    $pp->{version}=join(".",@$pp{qw(version_major version_minor version_eng)});
    $pp->{serialnum} = bin2hex_little_endian($pp->{serialnum_bits});
    $pp;
}

sub getnodeaddress
{
    my $self = shift;
    $self->_do_something(\&_cmd_getnodeaddress,\&_resp_getnodeaddress,@_);
}


sub _cmd_getnodeaddress
{
    my $self = shift;
    my(%p)=@_;

    if (!$p{serialnum_bits})
    {
	defined($p{serialnum}) or return $self->error("Missing required parameter serialnum or serialnum_bits");
	$p{serialnum_bits} = hex2bin_little_endian($p{serialnum});
    }
    $self->_makepacket(%p,
		      node => 0xff,
		      cmd => 0x19,
		       data => pack("a8",
				    $p{serialnum_bits},
				    ),
		       );
}

sub _resp_getnodeaddress
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
}

# NOT FINISHED
our %baudnum = (
		230400 => 0,
		115200 => 1,
		57600 => 2,
		38400 => 3,
		19200 => 4,
		9600 => 5,
		);
		 

sub _cmd_setbaudrate
{
    my $self = shift;
    my(%p)=@_;
    
    if (!$p{baudrate_bits})
    {
	defined($p{baudrate}) or return $self->error("Missing required parameter baudrate");
	defined($p{baudrate_bits}=$baudnum{$p{baudrate}})
	    or return $self->error("Invalid baud rate.");
    }
    $self->_makepacket(%p,
		       cmd => 0x1D,
		       data => pack("C",$p{baudrate_bits}),
		       );
		      
}

sub _resp_setbaudrate
{
    my $self = shift;
    my $pp = $self->_parsepacket(@_)
	or return undef;
}

sub setbaudrate
{
    my $self = shift;

    $self->_do_something(\&_cmd_setbaudrate,\&_resp_setbaudrate,@_);
}


=head3 finish

Perform any cleanup tasks for the reader.  In particular, shut off any
constant reads that are currently running.

=cut

sub finish
{
    my $self = shift;
    $self->stop_all_constant_read()
	or warn "Couldn't stop all constant readers: $!\n";
}

sub error
{
    my $self = shift;
    my($em,$ec)=@_;

    $self->{error}=$em;
    $self->{errcode}=defined($ec)?$ec:1;
    $self->debug("Error: $em\n");
    return undef;
}

# Convert a hex string to binary, LSB first
sub hex2bin_little_endian
{
    my $hex = $_[0];
    $hex =~ tr/0-9a-fA-F//cd;
    pack("C*",map { hex } reverse unpack("a2"x(length($hex)/2),$hex));
}

sub hex2bin_big_endian
{
    my $hex = $_[0];
    $hex =~ tr/0-9a-fA-F//cd;
    pack("C*",map { hex } unpack("a2"x(length($hex)/2),$hex));
}

sub bin2hex_little_endian
{
    unpack("H*",pack("C*",reverse(unpack("C*",$_[0]))));
}

sub bin2hex_big_endian
{
    unpack("H*",$_[0]);
#    my @a = split(//,$_[0]);
#    sprintf "%02x" x scalar(@a), map {ord} @a;
}

=head2 Properties

=head3 Antenna

The default antenna for get operations; see also
L<AntennaSequence|/AntennaSequence>.  This defaults to 1 if it is not
set.

=head3 AntennaSequence

An arrayref of the antennas that should be queried, and in what order.
The antenna names for a 4-port Matrics reader are simply 1, 2, 3, and
4.  For example:

    $reader->set(AntennaSequence => [1,2,3,4]);

The default AntennaSequence is the L<default Antenna|/Antenna>.

=head3 Debug

Control the amount debugging information sent to C<STDERR>.  A higher
value for this property will cause more information to be output.

=head3 UniqueTags

A boolean value controlling whether duplicate tags should be removed
from the list returned by L<readtags|/readtags>.

=head3 Environment

How long an antenna should try to read tags during a
L<readtags|readtags> command, between 0 and 4.  0 will read for a very
short time, and is appropriate for environments where tags come and go
very quickly, and it's OK if you miss a tag somtimes.  4 will read for
longer, and is appropriate where tags stay relatively static and you
want the reader to try its best to find all of them.

When this item is retreived, you get the value for the default
antenna.  When it's set, it's set for all of the antennas in the
L<AntennaSequence|/AntennaSequence>.  To set the level for only one
antenna, use C<Environment_AntennaI<n>>, where C<I<n>> is the number
of the antenna you'd like to set.

=head3 Node

The Matrics node address associated with this object.  It defaults to
4.

=head3 PowerLevel

The amount of power an antenna should use when doing a read, between 0
and 255.  255 is full-power; the scale of this setting is logarithmic,
so 208 is about 50% power, and 0x80 is about 25% power.

When this item is retreived, you get the value for the default
antenna.  When it's set, it's set for all of the antennas in the
L<AntennaSequence|/AntennaSequence>.  To set the level for only one
antenna, use C<PowerLevel_AntennaI<n>>, where C<I<n>> is the number of
the antenna you'd like to set.

=head3 ReaderVersion

The software version running on this reader, as a string.  Cannot be
L<set|/set>.

=head3 ReaderSerialNum

The serial number of this reader, as a string.  Cannot be L<set|/set>.

=head1 SEE ALSO

L<RFID::Matrics::Reader::Serial>, L<RFID::Matrics::Reader::TCP>,
L<RFID::EPC::Tag>, L<RFID::Matrics::Tag>,
L<http://www.eecs.umich.edu/~wherefid/code/rfid-perl/>.

=head1 AUTHOR

Scott Gifford <gifford@umich.edu>, <sgifford@suspectclass.com>

Copyright (C) 2004 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
