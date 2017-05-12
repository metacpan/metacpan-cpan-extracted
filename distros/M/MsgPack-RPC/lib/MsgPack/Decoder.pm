package MsgPack::Decoder;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Decode data from a MessagePack stream
$MsgPack::Decoder::VERSION = '1.0.1';

use 5.20.0;

use strict;
use warnings;

use MsgPack::Type::Boolean;

use Moose;

use List::AllUtils qw/ reduce first first_index any /;

use experimental 'signatures', 'postderef';

with 'MooseX::Role::Loggable' => {
    -excludes => [ 'Bool' ],
};


sub read($self,@values) {
    $self->log_debug( [ "raw bytes: %s", \@values ] );

    my @new;
    $self->gen_next( 
        reduce {
            my $g = $a->($b);
            is_gen($g) or do { push @new, $$g; gen_new_value() }
        } $self->gen_next => map { ord } map { split '' } @values
    );

    $self->add_to_buffer(@new);

    return scalar @new;
}




has buffer => (
    is => 'rw',
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        'has_buffer' => 'count',
        next => 'shift',
        all => 'elements',
        add_to_buffer => 'push',
    },
);

after all => sub($self) {
    $self->buffer([]);
};

has gen_next => (
    is =>  'rw',
    clearer => 'clear_gen_next',
    default => sub { 
        gen_new_value();
    }

);


sub read_all($self,@vals){
    $self->read(@vals);
    $self->all;
}


sub read_next($self,@vals){
    $self->read(@vals);
    die "buffer is empty" unless $self->has_buffer;
    $self->next;
}

sub is_gen($val) { ref $val eq 'CODE' and $val }

use Types::Standard qw/ Str ArrayRef Int Any InstanceOf Ref /;
use Type::Tiny;

my $MessagePackGenerator  = Type::Tiny->new(
    parent => Ref,
    name   => 'MessagePackGenerator',
);

my @msgpack_types = (
    [ PositiveFixInt => [    0, 0x7f ], \&gen_positive_fixint ],
    [ NegativeFixInt => [  0xe0, 0xff ], \&gen_negative_fixint ],
    [ UInt8          => [  0xcc ], \&gen_uint8 ],
    [ UInt16         => [  0xcd ], \&gen_uint16 ],
    [ UInt32         => [  0xce ], \&gen_uint32 ],
    [ Uint64         => [ 0xcf ], \&gen_uint64 ],
    [ Int8           => [ 0xd0 ], \&gen_int8 ],
    [ Int16           => [ 0xd1 ], \&gen_int16 ],
    [ Int32           => [ 0xd2 ], \&gen_int32 ],
    [ Int64           => [ 0xd3 ], \&gen_int64 ],
    [ FixArray       => [ 0x90, 0x9f ], \&gen_fixarray ],
    [ Array16       => [ 0xdc ], \&gen_array16 ],
    [ Array32       => [ 0xdd ], \&gen_array32 ],
    [ FixMap         => [ 0x80, 0x8f ], \&gen_fixmap ],
    [ Map16         => [ 0xde ], \&gen_map16 ],
    [ Map32         => [ 0xdf ], \&gen_map32 ],
    [ FixStr         => [ 0xa0, 0xbf ], \&gen_fixstr ],
    [ Str8           => [ 0xd9 ], \&gen_str8 ],
    [ Str16           => [ 0xda ], \&gen_str16 ],
    [ Str32           => [ 0xdb ], \&gen_str32 ],
    [ Bin8           => [ 0xc4 ], \&gen_bin8 ],
    [ Bin16          => [ 0xc5 ], \&gen_bin16 ],
    [ Bin32          => [ 0xc6 ], \&gen_bin32 ],
    [ Nil            => [ 0xc0 ], \&gen_nil ],
    [ True           => [ 0xc3 ], \&gen_true ],
    [ False          => [ 0xc2 ], \&gen_false ],
    [ FixExt1        => [ 0xd4 ], \&gen_fixext1 ],
    [ FixExt2        => [ 0xd5 ], \&gen_fixext2 ],
    [ FixExt4        => [ 0xd6 ], \&gen_fixext4 ],
    [ FixExt8        => [ 0xd7 ], \&gen_fixext8 ],
    [ FixExt16       => [ 0xd8 ], \&gen_fixext16 ],
    [ Ext8           => [ 0xc7 ], \&gen_ext8 ],
    [ Ext16          => [ 0xc8 ], \&gen_ext16 ],
    [ Ext32          => [ 0xc9 ], \&gen_ext32 ],
    [ Float32        => [ 0xca ], \&gen_float32 ],
    [ Float64        => [ 0xcb ], \&gen_float64 ],
);

$MessagePackGenerator = $MessagePackGenerator->plus_coercions(
    map {
        my( $min, $max ) = $_->[1]->@*;
        Type::Tiny->new(
            parent     => Int,
            name       => $_->[0],
            constraint => sub { $max ? ( $_ >= $min and $_ <= $max ) : ( $_ == $min ) },
        ) => $_->[2]  
    } @msgpack_types
);

sub  gen_true  { my $x = MsgPack::Type::Boolean->new(1); \$x }
sub  gen_false { my $x = MsgPack::Type::Boolean->new(0); \$x }

sub read_n_bytes($size) {
    my $value = '';

    sub($byte) {
        $value .= chr $byte;
        --$size ? __SUB__ : \$value;
    }
}

sub read_n_bytes_as_int($size) {
    my $gen = read_n_bytes($size);

    sub($byte) {
        $gen = $gen->($byte);

        return __SUB__ if is_gen($gen);

        my $x = reduce { ( $a << 8 ) + $b } map { ord } split '', $$gen;
        return \$x;
    }
}

sub gen_uint8 {
    read_n_bytes_as_int(1);
}

sub gen_uint16 {
    read_n_bytes_as_int(2);
}

sub gen_str8 { gen_string(1) }
sub gen_str16 { gen_string(2) }
sub gen_str32 { gen_string(4) }

sub gen_string($size) {
    my $gen = read_n_bytes_as_int($size);

    sub($byte) {
        $gen = $gen->($byte);
        is_gen($gen) ? __SUB__ : gen_str($$gen);
    }
}

sub gen_array16 {
    my $size = read_n_bytes_as_int(2);

    sub($byte) {
        $size = $size->($byte);

        is_gen($size) ? __SUB__ : gen_array($$size);
    };
}

sub gen_array32 {
    my $size = read_n_bytes_as_int(4);

    sub($byte) {
        $size = $size->($byte);

        is_gen($size) ? __SUB__ : gen_array($$size);
    };
}

sub gen_nil {
    \my $undef;
}

sub gen_new_value { 
    sub ($byte) { $MessagePackGenerator->assert_coerce($byte); } 
}

sub gen_int8  { gen__int(1) }
sub gen_int16 { 
    my $gen = read_n_bytes(2);
    sub($byte) {
        $gen = $gen->($byte);
        return __SUB__ if is_gen($gen);
        my $val = unpack 's*', $$gen;
        return \$val;
    }
}
sub gen_int32 { 
    my $gen = read_n_bytes(4);
    sub($byte) {
        $gen = $gen->($byte);
        return __SUB__ if is_gen($gen);
        my $val = unpack 'l*', $$gen;
        return \$val;
    }
}
sub gen_int64 { 
    my $gen = read_n_bytes(8);
    sub($byte) {
        $gen = $gen->($byte);
        return __SUB__ if is_gen($gen);
        my $val = unpack 'q*', $$gen;
        return \$val;
    }
}

sub gen__int($size) {
    my $gen = read_n_bytes($size);
    sub($byte) {
        $gen = $gen->($byte);
        return __SUB__ if is_gen($gen);
        my $val = reduce { $a*(2**8) + $b } 0, unpack 'c*', $$gen;
        return \$val;
    }
}

sub gen_int($size) {
    my $gen = read_n_bytes($size);
    sub($byte) {
        $gen = $gen->($byte);
        is_gen($gen) ? __SUB__ : $gen;
    }
}

sub gen_float32 {
    my $gen = read_n_bytes(4);
    sub($byte){
        return __SUB__ if is_gen($gen=$gen->($byte));
        
        my $n = unpack 'f', $$gen;
        \$n;
    }
}

sub gen_float64 {
    my $gen = read_n_bytes(8);
    sub($byte){
        return __SUB__ if is_gen($gen=$gen->($byte));
        
        my $n = unpack 'd', $$gen;
        \$n;
    }
}

sub gen_bin8 { gen_binary(1); }
sub gen_bin16 { gen_binary(2); }
sub gen_bin32 { gen_binary(4); }

sub gen_binary($size_size) {
    my $gen = read_n_bytes_as_int($size_size);

    sub($byte) {
        is_gen( $gen = $gen->($byte) ) ? __SUB__ : read_n_bytes($$gen);
    }
}

sub gen_uint32 {
    gen_unsignedint(4);
}

sub gen_uint64 {
    gen_unsignedint(8);
}

sub gen_unsignedint {
    my $left_to_read = shift;
    my $value = 0;

    sub($byte) {
        $value = $byte + ($value << 8);
        --$left_to_read ? __SUB__ : \$value;
    }
}

sub gen_fixext1  { gen_fixext(1) }
sub gen_fixext2  { gen_fixext(2) }
sub gen_fixext4  { gen_fixext(4) }
sub gen_fixext8  { gen_fixext(8) }
sub gen_fixext16 { gen_fixext(16) }

sub gen_fixext($size) {
    my $gen = read_n_bytes($size+1);
    sub($byte) {
        $gen = $gen->($byte);
        return __SUB__ if is_gen($gen);

        my($type, $data) = split '', $$gen, 2;
        $type = ord $type;
        my $ext = MsgPack::Type::Ext->new(
            fix  => 1,
            size => $size,
            data => $data,
            type => $type,
        );

        return \$ext;

    }
}

sub gen_ext8 { gen_ext(1) }
sub gen_ext16 { gen_ext(2) }
sub gen_ext32 { gen_ext(4) }

sub gen_ext($size) {
    my $gen = read_n_bytes_as_int($size);
    sub($byte) {
        $gen = $gen->($byte);
        return __SUB__ if is_gen($gen);

        $gen = read_n_bytes($$gen+1);

        sub($byte) {
            return __SUB__ if is_gen($gen=$gen->($byte));

            my($type, $data) = split '', $$gen, 2;
            $type = ord $type;
            my $ext = MsgPack::Type::Ext->new(
                fix  => 0,
                size => 8*$size,
                data => $data,
                type => $type,
            );

            return \$ext;
        }

    }
}

sub gen_positive_fixint { \$_  }
sub gen_negative_fixint { my $x = 0xe0 - $_; \$x; }

sub gen_fixarray {
    gen_array( $_ - 0x90 );
}

sub gen_fixmap {
    gen_map($_ - 0x80);
}

sub gen_map16 { 
    my $gen = read_n_bytes_as_int(2);
    sub($byte) {
        $gen = $gen->($byte);
        is_gen($gen) ? __SUB__ : gen_map($$gen);
    }
}

sub gen_map32 { 
    my $gen = read_n_bytes_as_int(4);
    sub($byte) {
        $gen = $gen->($byte);
        is_gen($gen) ? __SUB__ : gen_map($$gen);
    }
}

sub gen_fixstr {
    gen_str( $_ - 0xa0 );
}

sub gen_str($size) {
    return \'' unless $size;

    my $gen = read_n_bytes($size);
    sub($byte) {
        $gen = $gen->($byte);
        is_gen($gen) ? __SUB__ : $gen;
    }
}


sub gen_map($size) {
    return \{} unless $size;

    my $gen = gen_array( 2*$size );

    use Data::Printer;
    sub($byte) {
        $gen = $gen->($byte);
        is_gen( $gen ) ? __SUB__ : \{ @$$gen };
    }
}

sub gen_array($size) {

    return \[] unless $size;

    my @array;

    @array = map { gen_new_value() } 1..$size;

    sub($byte) {
        $_ = $_->($byte) for first { is_gen($_) } @array;

        ( any { is_gen($_) } @array ) ? __SUB__ : \[ map { $$_ } @array ];
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder - Decode data from a MessagePack stream

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    use MsgPack::Decoder;

    use MsgPack::Encoder;
    use Data::Printer;

    my $decoder = MsgPack::Decoder->new;

    my $msgpack_binary = MsgPack::Encoder->new(struct => [ "hello world" ] )->encoded;

    $decoder->read( $msgpack_binary );

    my $struct = $decode->next;  

    p $struct;    # prints [ 'hello world' ]

=head2 DESCRIPTION

C<MsgPack::Decoder> objects take in the raw binary representation of 
one or more MessagePack data structures, and convert it back into their
Perl representations.

=head2 METHODS

This class consumes L<MooseX::Role::Loggable>, and inherits all of its
methods.

=head3 read( @binary_values ) 

Reads in the raw binary to convert. The binary can be only a partial piece of the 
encoded structures.  If so, all structures that can be decoded will be
made available in the buffer, while the potentially last unterminated structure will
remain "in flight".

Returns how many structures were decoded.

=head3 has_buffer

Returns the number of decoded structures currently waiting in the buffer.

=head3 next

Returns the next structure from the buffer.

    $decoder->read( $binary );

    while( $decoder->has_buffer ) {
        my $next = $decoder->next;
        do_stuff( $next );
    }

Note that the returned structure could be C<undef>, so don't do:

    $decoder->read( $binary );

    # NO! $next could be 'undef'
    while( my $next = $decoder->next ) {
        do_stuff( $next );
    }

=head3 all 

Returns (and flush from the buffer) all the currently available structures.

=head3 read_all( @binaries )

Reads the provided binary data and returns all structures decoded so far.

    @data = $decoder->read_all($binary);

    # equivalent to
    
    $decoder->read(@binaries);
    @data = $decoder->all;

=head3 read_next( @binaries )

Reads the provided binary data and returns the next structure decoded so far.
If there is no data in the buffer, dies.

    $data = $decoder->read_next($binary);

    # roughly equivalent to
    
    $decoder->read(@binaries);
    $data = $decoder->next or die;

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
