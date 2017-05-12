package SWF::BinStream;

use strict;
use vars qw($VERSION);

$VERSION="0.11";

##

package SWF::BinStream::Read;

use Carp;
use Data::TemporaryBag;


sub new {
    my ($class, $initialdata, $shortsub, $version) = @_;
    my $self = bless {
	    '_bits'  => '',
	    '_stream'   =>Data::TemporaryBag->new,
	    '_shortsub' =>$shortsub||sub{0},
	    '_pos'      => 0,
	    '_codec' => [],
	    '_version' => $version||5,
	    '_lock_version' => 0,
	  }, $class;
    $self->add_stream($initialdata) if $initialdata ne '';
    $self;
}

sub Version {
    my ($self, $ver) = @_;

    if (defined $ver) {
	croak "Can't change SWF version " if $self->{_lock_version};
	$self->{_version} = $ver;
    }
    $self->{_version};
}

sub _lock_version {
    shift->{_lock_version} = 1;
}

sub add_stream {
    my ($self, $data) = @_;

    for my $codec ( @{$self->{'_codec'}} ) {
	$data = $codec->decode($data);
    }
    $self->{'_stream'}->add($data);
}

sub _require {
    my ($self, $bytes) = @_;
    {
	my $len=$self->{'_stream'}->length;

	if ($len < $bytes) {
	    $self->{'_shortsub'}->($self, $bytes-$len) and redo;
	    croak "Stream ran short ";
	}
    }

}

sub Length {
    return $_[0]->{'_stream'}->length;
}

sub tell {$_[0]->{'_pos'}};

sub get_string {
    my ($self, $bytes, $fNoFlush) = @_;

    flush_bits($self) unless $fNoFlush;
    _require($self, $bytes);
    $self->{'_pos'}+=$bytes;
    $self->{'_stream'}->substr(0, $bytes, '');
}

sub lookahead_string {
    my ($self, $offset, $bytes) = @_;

    _require($self, $offset);
    $self->{'_stream'}->substr($offset, $bytes);
}

sub get_UI8 {
    unpack 'C', get_string(shift, 1);
}

sub lookahead_UI8 {
    unpack 'C', lookahead_string(@_[0, 1], 1);
}

sub get_SI8 {
    unpack 'c', get_string(shift, 1);
}

sub lookahead_SI8 {
    unpack 'c', lookahead_string(@_[0, 1], 1);
}

sub get_UI16 {
    unpack 'v', get_string(shift, 2);
}

sub lookahead_UI16 {
    unpack 'v', lookahead_string(@_[0, 1], 2);
}

sub get_SI16 {
    my $w = &get_UI16;
    $w -= (1<<16) if $w>=(1<<15);
    $w;
}

sub lookahead_SI16 {
    my $w = &lookahead_UI16;
    $w -= (1<<16) if $w>=(1<<15);
    $w;
}

sub get_UI32 {
    unpack 'V', get_string(shift, 4);
}

sub lookahead_UI32 {
    unpack 'V', lookahead_string(@_[0, 1], 4);
}

sub get_SI32 {
    my $ww = &get_UI32;
    $ww -= (2**32) if $ww>=(2**31);
    $ww;
}

sub lookahead_SI32 {
    my $ww = &lookahead_UI32;
    $ww -= (2**32) if $ww>=(2**31);
    $ww;
}

sub flush_bits {
    $_[0]->{'_bits'}='';
}

sub get_bits {
    my ($self, $bits) = @_;
    my $len = length($self->{'_bits'});

    if ( $len < $bits) {
	my $slen = (($bits - $len - 1) >>3) + 1;
	$self->{'_bits'}.=join '', unpack('B8' x $slen, $self->get_string($slen, 'NoFlush'));
    }
    unpack('N', pack('B32', '0' x (32-$bits).substr($self->{'_bits'}, 0, $bits, '')));
}

sub get_sbits {
    my ($self, $bits) = @_;

    my $b = &get_bits;
    $b -= (2**$bits) if $b>=(2**($bits-1));
    $b;
}

sub close {
    my $self = shift;

    for my $codec ( @{$self->{'_codec'}} ) {
	$codec->close;
    }
    $self->{'_stream'}->clear;
}


sub add_codec {
    my ($self, $codec) = @_;

    require "SWF/BinStream/Codec/${codec}.pm" or croak "Can't find codec '$codec'";

    my $m = "SWF::BinStream::Codec::${codec}::Read"->new or croak "Can't find codec '$codec' ";

    push @{$self->{'_codec'}}, $m;

    if (( my $old_stream = $self->{'_stream'})->length > 0) {
	my $new_stream = Data::TemporaryBag->new;

	while ($old_stream->length > 0) {
	    $new_stream->add($m->decode($old_stream->substr(0, 1024, '')));
	}
	$self->{'_stream'} = $new_stream;
    }
}

1;

package SWF::BinStream::Write;

use Carp;
use Data::TemporaryBag;

sub new {
    my ($class, $version) = @_;
    bless { '_bits'    => '',
	    '_stream'  => Data::TemporaryBag->new,
	    '_pos' => 0,
	    '_flushsize' => 0,
	    '_mark' => {},
	    '_codec' => [],
	    '_version' => $version || 5,
	    '_lock_version' => 0,
	    '_framecount' => 0,
	  }, $class;
}

sub Version {
    my ($self, $ver) = @_;

    if (defined $ver) {
	croak "Can't change SWF version " if $self->{_lock_version};
	$self->{_version} = $ver;
    }
    $self->{_version};
}

sub _lock_version {
    shift->{_lock_version} = 1;
}

sub autoflush {
    my ($self, $size, $flushsub)=@_;

    $self->{'_flushsize'}=$size;
    $self->{'_flushsub'}=$flushsub;
}

sub _write_stream {
    my ($self, $data) = @_;

    for my $codec ( @{$self->{'_codec'}} ) {
	$data = $codec->encode($data);
    }
    return if $data eq '';

    $self->{'_stream'}->add($data);

    if ($self->{'_flushsize'}>0 and $self->{'_stream'}->length >= $self->{'_flushsize'}) {
	$self->flush_stream($self->{'_flushsize'});
    }
}

sub flush_stream {
    my ($self, $size)=@_;
    my $str;

    if ( !$size or $size>$self->Length ) {
	$self->flush_bits;
    }

    if ($size) {
	$str = $self->{'_stream'}->substr( 0, $size, '');
	$self->{'_pos'} += length($str);
    } else {
	$str=$self->{'_stream'}->value;
	$self->{'_pos'}+=length($str);
	$self->{'_stream'}=Data::TemporaryBag->new;
    }

    $self->{'_flushsub'}->($self, $str) if defined $self->{'_flushsub'};

    $str;
}

sub flush_bits {
    my $self = $_[0];
    my $bits = $self->{'_bits'};
    my $len  = length($bits);

    return if $len<=0;
    $self->{'_bits'}='';
    $self->_write_stream(pack('B8', $bits.('0'x(8-$len))));
}

sub Length {
    return $_[0]->{'_stream'}->length;
}

sub tell {
    my $self=shift;
    my $pos= $self->{'_pos'} + $self->Length;
    $pos++ if length($self->{'_bits'})>0;
    $pos;
}

sub mark {
    my ($self, $key, $obj)=@_;

    if (not defined $key) {
	return %{$self->{_mark}};
    } elsif (not defined $obj) {
	return wantarray ? $self->{_mark}{$key}[0] : @{$self->{_mark}{$key}};
    } else {
	push @{$self->{_mark}{$key}}, $self->tell, $obj;
    }
}

sub sub_stream {
    my $self=shift;
    my $sub_stream=SWF::BinStream::Write->new($self->Version);
    $sub_stream->{_parent}=$self;
    bless $sub_stream, 'SWF::BinStream::Write::SubStream';
}

sub set_string {
    my ($self, $str) = @_;

    $self->flush_bits;
    $self->_write_stream($str);
}

sub _round {
    my $a=shift;

    return 0 unless $a;
    return int($a+0.5*($a<=>0));
}

sub set_UI8 {
    $_[0]->set_string(pack('C', _round($_[1])));
}

sub set_SI8 {
    $_[0]->set_string(pack('c', _round($_[1])));
}

sub set_UI16 {
    $_[0]->set_string(pack('v', _round($_[1])));
}

*set_SI16 = \&set_UI16;

#sub set_SI16 {
#    my ($self, $num) = @_;
#    $num += (1<<16) if $num<0;
#    $self->set_UI16($num);
#}

sub set_UI32 {
    $_[0]->set_string(pack('V', _round($_[1])));
}

*set_SI32 = \&set_UI32;

#sub set_SI32 {
#    my ($self, $num) = @_;
#    $num += (2**32) if $num<0;
#    $self->set_UI32($num);
#}

sub set_bits {
    my ($self, $num, $nbits) = @_;
    return unless $nbits;
    $self->{'_bits'} .= substr(unpack('B*',pack('N', _round($num))), -$nbits);
    my $s = '';
    while (length($self->{'_bits'})>=8) {
	$s .= pack('B8', substr($self->{'_bits'}, 0,8, ''));
    }
    $self->{'_stream'}->add($s) if $s ne '';
}

sub set_sbits {
    my ($self, $num, $nbits) = @_;
    $num=_round($num);
    $num += (2**$nbits) if $num<0;
    $self->set_bits($num, $nbits);
}

sub set_bits_list {
    my ($self, $nbitsbit, @param) = @_;
    my $nbits=get_maxbits_of_bits_list(@param);
    my $i;

    $self->set_bits($nbits, $nbitsbit);
    foreach $i (@param) {
	$self->set_bits($i, $nbits);
    }
}

sub set_sbits_list {
    my ($self, $nbitsbit, @param) = @_;
    my $nbits=get_maxbits_of_sbits_list(@param);
    my $i;

    $self->set_bits($nbits, $nbitsbit);
    foreach $i (@param) {
	$self->set_sbits($i, $nbits);
    }
}

sub get_maxbits_of_bits_list {
    my (@param)=@_;
    my $max=shift;
    my $i;

    foreach $i(@param) {
	$max=$i if $max<$i;
    }
    $i = 0;
    $i++ while ($max >= 2**$i);
    return $i;
}

sub get_maxbits_of_sbits_list {
    my $z = 0;
    return (get_maxbits_of_bits_list(map{my $r=_round($_);$z ||= ($r!=0);($r<0)?(~$r):$r} @_)+$z);
}

sub close {
    my $self = shift;

    my $data = $self->flush_stream;
    my $rest = '';
    for my $codec ( @{$self->{'_codec'}} ) {
	$rest = $codec->close($rest);
    }
    $self->{'_flushsub'}->($self, $rest) if defined $self->{'_flushsub'};

    $data .= $rest;
    $data;
}

sub add_codec {
    my ($self, $codec) = @_;

    require "SWF/BinStream/Codec/${codec}.pm" or croak "Can't find codec '$codec'";

    my $m = "SWF::BinStream::Codec::${codec}::Write"->new or croak "Can't find codec '$codec'";

    push @{$self->{'_codec'}}, $m;
}

package SWF::BinStream::Write::SubStream;

use vars qw(@ISA);

@ISA=('SWF::BinStream::Write');

sub flush_stream {
    my $self = shift;
    my $p_tell = $self->{_parent}->tell;

    while ((my $data = $self->SUPER::flush_stream(1024)) ne '') {
	$self->{_parent}->set_string($data);
    }

    my @marks=$self->mark;
    while (@marks) {
	my $key = shift @marks;
	my $mark = shift @marks;
	$mark->[$_*2] += $p_tell for (0..@$mark/2-1);
	push @{$self->{_parent}->{_mark}{$key}}, @$mark;
    }
    undef $self;
}

sub autoflush {} # Ignore autoflush.
sub add_codec {warn "Can't add codec to the sub stream"}
*SWF::BinStream::Write::SubStream::close = \&flush_stream;

1;

__END__

=head1 NAME

SWF::BinStream - Read and write binary stream.

=head1 SYNOPSIS

  use SWF::BinStream;

  $read_stream = SWF::BinStream::Read->new($binary_data, \&adddata);
  $byte = $read_stream->get_UI8;
  $signedbyte = $read_stream->get_SI8;
  $string = $read_stream->get_string($length);
  $bits = $read_stream->get_bits($bitlength);
  ....

  sub adddata {
      if ($nextdata) {
	  shift->add_stream($nextdata);
      } else {
	  die "The stream ran short ";
      }
  }

  $write_stream = SWF::BinStream::Write->new;
  $write_stream->set_UI8($byte);
  $write_stream->set_SI8($signedbyte);
  $write_stream->set_string($string);
  $write_stream->set_bits($bits, $bitlength);
  $binary_data=$write_stream->flush_stream;
  ....

=head1 DESCRIPTION

I<SWF::BinStream> module provides a binary byte and bit data stream.
It can handle bit-compressed data such as SWF file.

=head2 SWF::BinStream::Read

Provides a read stream. Add the binary data to the stream, and you 
get byte and bit data. The stream calls a user subroutine when the 
stream data runs short.
I<get_UI16>, I<get_SI16>, I<get_UI32>, and I<get_SI32> get a number
in VAX byte order from the stream.
I<get_bits> and I<get_sbits> get the bits from MSB to LSB.
I<get_UI*>, I<get_SI*>, and I<get_string> skip the remaining bits in 
the current byte and read data from the next byte.
If you want to skip remaining bits manually, use I<flush_bits>.

=head2 METHODS

=over 4

=item SWF::BinStream::Read->new( [ $initialdata, \&callback_in_short, $version ] )

Creates a read stream. It takes three optional arguments. The first arg 
is a binary string to set as initial data of the stream. The second is
a reference of a subroutine which is called when the stream data runs
short.  The subroutine is called with two ARGS, the first is I<$stream>
itself, and the second is how many bytes wanted.  
The third arg is SWF version number.  Default is 5.  It is necessary to
set proper version because some SWF tags change their structure by the 
version number. 

=item $stream->Version

returns SWF version number of the stream.

=item $stream->add_codec( $codec_name )

Adds stream decoder.
Decoder 'Zlib' is only available now.

=item $stream->add_stream( $binary_data )

Adds binary data to the stream.

=item $stream->Length

Returns how many bytes remain in the stream.

=item $stream->tell

Returns how many bytes have been read from the stream.

=item $stream->get_string( $num )

Returns $num bytes as a string.

=item $stream->get_UI8

Returns an unsigned byte number.

=item $stream->get_SI8

Returns a signed byte number.

=item $stream->get_UI16

Returns an unsigned word (2 bytes) number.

=item $stream->get_SI16

Returns a signed word (2 bytes) number.

=item $stream->get_UI32

Returns an unsigned double word (4 bytes) number.

=item $stream->get_SI32

Returns a signed double word (4 bytes) number.

=item $stream->get_bits( $num )

Returns the $num bit unsigned number.

=item $stream->get_sbits( $num )

Returns the $num bit signed number.

=item $stream->lookahead_string( $offset, $num )

=item $stream->lookahead_UI8( $offset )

=item $stream->lookahead_SI8( $offset )

=item $stream->lookahead_UI16( $offset )

=item $stream->lookahead_SI16( $offset )

=item $stream->lookahead_UI32( $offset )

=item $stream->lookahead_SI32( $offset )

Returns the stream data $offset bytes ahead of the current read point.
The read pointer does not move.

=item $stream->flush_bits

Skips the rest bits in the byte and aligned read pointer to the next byte.
It does not anything when the read pointer already byte-aligned.

=back

=head2 SWF::BinStream::Write

Provides a write stream. Write byte and bit data, then get the stream
data as binary string using I<flush_stream>. I<autoflush> requests to
the stream to automatically flush the stream and call a user subroutine.
I<set_UI16>, I<set_SI16>, I<set_UI32>, and I<set_SI32> write a number in 
VAX byte order to the stream.
I<set_bits> and I<set_sbits> write the bits from MSB to LSB.
I<set_UI*>, I<set_SI*>, and I<set_string> set the rest bits in the last 
byte to 0 and write data to the next byte boundary.
If you want to write bit data and align the write pointer to byte boundary,
use I<flush_bits>.

=head2 METHODS

=over 4

=item SWF::BinStream::Write->new( [$version] )

Creates a write stream.
One optional argument is SWF version number.  Default is 5.
It is necessary to set proper version because some SWF tags change 
their structure by the version number. 

=item $stream->Version( [$version] )

returns SWF version number of the stream.
You can change the version before you write data to the stream.

=item $stream->add_codec( $codec_name )

Adds stream encoder.
Encoder 'Zlib' is only available now.

=item $stream->autoflush( $size, \&callback_when_flush )

Requests to the stream to automatically flush the stream and call sub
with the stream data when the stream size becomes larger than I<$size> bytes.

=item $stream->flush_stream( [$size] )

Flushes the stream and returns the stream data. Call with I<$size>,
it returns I<$size> bytes from the stream. When call without arg or
with larger I<$size> than the stream data size, it returns all data
including the last bit data ( by calling I<flush_bits> internally).

=item $stream->flush_bits

Sets the rest bits in the last byte to 0, and aligns write pointer 
to the next byte boundary.

=item $stream->Length

Returns how many bytes remain in the stream.

=item $stream->tell

Returns how many bytes have written.

=item $stream->mark( [$key, [$obj]] )

Keeps current I<tell> number with $key and $obj.
When called without $obj, it returns I<tell> number associated
with $key and a list of I<tell> number and object in scalar and 
list context, respectively.
When called without any parameter, it returns mark list
( KEY1, [ TELL_NUMBER1, OBJ1 ], KEY2, [...).

=item $stream->sub_stream

Creates temporaly sub stream. When I<flush_stream> the sub stream, 
it's data and marks are written to the parent stream and the sub 
stream is freed.

Ex. write various length of data following it's length.

  $sub_stream=$parent_stream->sub_stream;
  write_data($sub_stream);
  $parent_stream->set_UI32($sub_stream->Length);
  $sub_stream->flush_stream;

=item $stream->set_string( $str )

Writes string to the stream.

=item $stream->set_UI8( $num )

Writes I<$num> as an unsigned byte.

=item $stream->set_SI8( $num )

Writes I<$num> as a signed byte.

=item $stream->set_UI16( $num )

Writes I<$num> as an unsigned word.

=item $stream->set_SI16( $num )

Writes I<$num> as a signed word.

=item $stream->set_UI32( $num )

Writes I<$num> as an unsigned double word.

=item $stream->set_SI32( $num )

Writes I<$num> as an unsigned double word.

=item $stream->set_bits( $num, $nbits )

Write I<$num> as I<$nbits> length unsigned bit data.

=item $stream->set_sbits( $num, $nbits )

Write I<$num> as I<$nbits> length signed bit data.

=item $stream->set_bits_list( $nbitsbit, @list )

Makes I<@list> as unsigned bit data list.
It writes the maximal bit length of each I<@list> (I<nbits>) as
I<$nbitsbit> length unsigned bit data, and then writes each I<@list>
number as I<nbits> length unsigned bit data.

=item $stream->set_sbits_list( $nbitsbit, @list )

Makes I<@list> as signed bit data list.
It writes the maximal bit length of each I<@list> (I<nbits>) as
I<$nbitsbit> length unsigned bit data, and then writes each I<@list>
number as I<nbits>-length signed bit data.

=back

=head2 UTILITY FUNCTIONS

=over 4

=item &SWF::BinStream::Write::get_maxbits_of_bits_list( @list )

=item &SWF::BinStream::Write::get_maxbits_of_sbits_list( @list )

Gets the necessary and sufficient bit length to represent the values of 
I<@list>.  -_bits_list is for unsigned values, and -_sbits_list is for signed.

=back

=head1 COPYRIGHT

Copyright 2000 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut



