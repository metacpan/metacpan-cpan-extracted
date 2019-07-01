package MsgPack::Encoder;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Encode a structure into a MessagePack binary string
$MsgPack::Encoder::VERSION = '2.0.3';

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;

use Exporter::Tiny;

extends 'Exporter::Tiny';

use experimental 'postderef', 'signatures';

use overload '""' => \&encoded;

use Types::Standard qw/ Str ArrayRef Ref Int Any InstanceOf Undef HashRef Num StrictNum /;
use Type::Tiny;

use MsgPack::Type::Ext;

our @EXPORT = qw/
    msgpack
    msgpack_nil
    msgpack_bool
    msgpack_positive_fixnum
    msgpack_negative_fixnum
    msgpack_uint8
    msgpack_uint16
    msgpack_uint32
    msgpack_uint64

    msgpack_int8
    msgpack_int16
    msgpack_int32
    msgpack_int64

    msgpack_bin8
    msgpack_bin16
    msgpack_bin32
    msgpack_float32
    msgpack_float64

    msgpack_fixstr
    msgpack_str8
    msgpack_str16
    msgpack_str32

    msgpack_fixarray
    msgpack_array16
    msgpack_array32

    msgpack_fixmap
    msgpack_map16
    msgpack_map32

    msgpack_fixext1
    msgpack_fixext2
    msgpack_fixext4
    msgpack_fixext8
    msgpack_fixext16

    msgpack_ext8
    msgpack_ext16
    msgpack_ext32
/;

my $UInt64 = Type::Tiny->new(
    parent => Int,
    name => 'UInt64',
    constraint => sub { $_ >= 0 },
);

my $UInt32 = Type::Tiny->new(
    parent => $UInt64,
    name => 'UInt32',
    constraint => sub { $_ < 2**32 },
);

my $UInt16 = Type::Tiny->new(
    parent => $UInt32,
    name => 'UInt16',
    constraint => sub { $_ < 2**16 },
);

my $UInt8 = Type::Tiny->new(
    parent => $UInt16,
    name => 'UInt16',
    constraint => sub { $_ < 2**8 },
);

my $PositiveFixInt = Type::Tiny->new(
    parent => $UInt8,
    name => 'PositiveFixint',
    constraint => sub { $_ < 2**7 },
);

my $Int64 = Type::Tiny->new(
    parent => Int,
    name => 'Int64',
);

my $Int32 = Type::Tiny->new(
    parent => $Int64,
    name => 'Int32',
    constraint => sub { abs($_) < 2**31 },
);

my $Int16 = Type::Tiny->new(
    parent => $Int32,
    name => 'Int16',
    constraint => sub { abs($_) < 2**15 },
);

my $Int8 = Type::Tiny->new(
    parent => $Int16,
    name => 'Int8',
    constraint => sub { abs($_) < 2**7 },
);

my $NegativeFixInt = Type::Tiny->new(
    parent => $Int8,
    name => 'NegativeFixint',
    constraint => sub { $_ < 0 and $_ > -2**5 },
);

my $Str32 = Type::Tiny->new(
    parent => Str,
    name => 'Str32',
);

my $Str16 = Type::Tiny->new(
    parent => $Str32,
    name => 'Str16',
    constraint => sub { length $_ < 2**16 }
);

my $Str8 = Type::Tiny->new(
    parent => $Str16,
    name => 'Str8',
    constraint => sub { length $_ < 2**8 }
);

my $FixStr = Type::Tiny->new(
    parent => $Str8,
    name => 'FixStr',
    constraint => sub { length $_ <= 31 }
);

my $Array32 = Type::Tiny->new(
    parent => ArrayRef,
    name => 'Array32',
);

my $Array16 = Type::Tiny->new(
    parent => $Array32,
    name => 'Array16',
    constraint => sub { @$_ < 2**16 },
);

my $FixArray = Type::Tiny->new(
    parent => ArrayRef,
    name => 'FixArray',
    constraint => sub { @$_ < 16 },
);

my $Nil = Type::Tiny->new(
    parent => Undef,
    name => 'Nil',
);

my $Map32 = Type::Tiny->new(
    parent => HashRef,
    name => 'Map32',
);

my $Map16 = Type::Tiny->new(
    parent => $Map32,
    name => 'Map16',
    constraint => sub { keys %$_ < 2**16 },
);

my $FixMap = Type::Tiny->new(
    parent => $Map16,
    name => 'FixMap',
    constraint => sub { keys %$_ < 16 }
);

my $Boolean = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Boolean'],
    name => 'Boolean'
);

my $FixExt1 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'FixExt1',
    constraint => sub { $_->fix and $_->size == 1 },
);
my $FixExt2 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'FixExt2',
    constraint => sub { $_->fix and $_->size == 2 },
);
my $FixExt4 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'FixExt4',
    constraint => sub { $_->fix and $_->size == 4 },
);
my $FixExt8 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'FixExt8',
    constraint => sub { $_->fix and $_->size == 8 },
);
my $FixExt16 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'FixExt16',
    constraint => sub { $_->fix and $_->size == 16 },
);

my $Ext8 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'Ext8',
    constraint => sub { !$_->fix and $_->size == 8 },
);
my $Ext16 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'Ext16',
    constraint => sub { !$_->fix and $_->size == 16 },
);
my $Ext32 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'Ext32',
    constraint => sub { !$_->fix and $_->size == 32 },
);

my $Float64 = Type::Tiny->new(
    parent => StrictNum,
    name => 'Float64',
);

sub _packed($value) { bless \$value, 'MessagePacked' }

sub msgpack_float32($number) { pack 'Cf', 0xca, $number }
sub msgpack_float64($number) { pack 'Cd', 0xcb, $number }

sub msgpack_bin8($binary) { ${ encode_bin8($binary) } }
sub msgpack_bin16($binary) { ${ encode_bin16($binary) } }
sub msgpack_bin32($binary) { ${ encode_bin32($binary) } }

sub msgpack_nil { pack 'C', 0xc0 }

sub msgpack_bool($bool) { chr 0xc2 + $bool }

sub msgpack_positive_fixnum($num) { chr $num }
sub msgpack_negative_fixnum($num) { chr 0xe0 - $num }

sub msgpack_uint8($num) { pack 'C*', 0xcc, $num }
sub msgpack_uint16($num) { pack 'Cn*', 0xcd, $num }
sub msgpack_uint32($num) { pack 'CN*', 0xce, $num }
sub msgpack_uint64($num) { pack 'CN*', 0xcf, int($num/(2**32)), $num%(2**32) }

sub msgpack_int8($num) { pack 'Cc*', 0xd0, $num }
sub msgpack_int16($num) { pack 'Cs*', 0xd1, $num }
sub msgpack_int32($num) { pack 'Cl*', 0xd2, $num }
sub msgpack_int64($num) { pack 'Cq*', 0xd3, $num }


sub msgpack_fixext1 {
    my $ext = @_ == 1 ? shift
        : MsgPack::Type::Ext->new( fix => 1, size => 1, type => $_[0], data => $_[1] );
    chr( 0xd4 ) . chr( $ext->type ) . $ext->padded_data;
}
sub msgpack_fixext2 {
    my $ext = @_ == 1 ? shift
        : MsgPack::Type::Ext->new( fix => 1, size => 2, type => $_[0], data => $_[1] );
    chr( 0xd5 ) . chr( $ext->type ) . $ext->padded_data;
}
sub msgpack_fixext4 {
    my $ext = @_ == 1 ? shift
        : MsgPack::Type::Ext->new( fix => 1, size => 4, type => $_[0], data => $_[1] );
    chr( 0xd6 ) . chr( $ext->type ) . $ext->padded_data;
}
sub msgpack_fixext8 {
    my $ext = @_ == 1 ? shift
        : MsgPack::Type::Ext->new( fix => 1, size => 8, type => $_[0], data => $_[1] );
    chr( 0xd7 ) . chr( $ext->type ) . $ext->padded_data;
}
sub msgpack_fixext16 {
    my $ext = @_ == 1 ? shift
        : MsgPack::Type::Ext->new( fix => 1, size => 16, type => $_[0], data => $_[1] );
    chr( 0xd8 ) . chr( $ext->type ) . $ext->padded_data;
}
sub msgpack_ext8 {
    my $ext = @_ == 1 ? shift
        : MsgPack::Type::Ext->new( fix => 0, type => $_[0], data => $_[1] );
    chr( 0xc7 ) . chr( $ext->size ), chr( $ext->type ) . $ext->padded_data;
}
sub msgpack_ext16 {
    my $ext = @_ == 1 ? shift
        : MsgPack::Type::Ext->new( fix => 0, type => $_[0], data => $_[1] );
    pack( 'CS>C', 0xc8, $ext->size, $ext->type ) . $ext->padded_data;
}
sub msgpack_ext32 {
    my $ext = @_ == 1 ? shift
        : MsgPack::Type::Ext->new( fix => 0, type => $_[0], data => $_[1] );
    pack( 'CL>C', 0xc9, $ext->size, $ext->type ) . $ext->padded_data;
}

sub msgpack_str8 {
    my $string = shift;
    chr( 0xd9 ) . chr( length $string ) . $string;
}

sub msgpack_str16 {
    my $string = shift;
    pack( 'CS>', 0xda, length $string ). $string;
}

sub msgpack_str32 {
    my $string = shift;
    pack( 'CL>', 0xdb, length $string ). $string;
}

sub msgpack_fixstr {
    my $string = shift;
    chr( 0xa0 + length $string ) . $string;
}

my $MessagePack;

sub msgpack_fixarray {
    my @inner = @{ shift @_ };

    my $size = @inner;

    join '', chr( 0x90 + $size ), map { $$_ } map { $MessagePack->assert_coerce($_) } @inner;
}

sub msgpack_array16 {
    my @inner = @{ shift @_ };

    my $size = @inner;

    join '', pack( 'CS>', 0xdc, $size ),
        map { $$_ } map { $MessagePack->assert_coerce($_) } @inner;
}

sub msgpack_array32 {
    my @inner = @{ shift @_ };

    my $size = @inner;

    join '', pack( 'CL>', 0xdd, $size ),
        map { $$_ } map { $MessagePack->assert_coerce($_) } @inner;
}

sub msgpack_fixmap {
    my @inner = %{ shift @_ };

    my $size = @inner/2;

    join '', chr( 0x80 + $size ), map { $$_ } map { $MessagePack->assert_coerce($_) } @inner;
}

sub msgpack_map16 {
    my @inner = %{ shift @_ };

    my $size = @inner/2;

    join '', pack( 'CS>', 0xde, $size ),
        map { $$_ } map { $MessagePack->assert_coerce($_) } @inner;
}

sub msgpack_map32 {
    my @inner = %{ shift @_ };

    my $size = @inner/2;

    join '', pack( 'CL>', 0xdf, $size ),
        map { $$_ } map { $MessagePack->assert_coerce($_) } @inner;
}




$MessagePack = Type::Tiny->new(
    parent => InstanceOf['MessagePacked'],
    name => 'MessagePack',
)->plus_coercions(
    $Boolean => sub { _packed msgpack_bool $_ },
    $PositiveFixInt      => sub { _packed msgpack_positive_fixnum $_ },
    $NegativeFixInt      => sub { _packed msgpack_negative_fixnum $_ },
    $UInt8 => sub { _packed msgpack_uint8 $_ },
    $UInt16 => sub { _packed msgpack_uint16 $_ },
    $UInt32 => sub { _packed msgpack_uint32 $_ },
    $UInt64 => sub { _packed msgpack_uint64 $_ },
    $Int8                => sub { _packed msgpack_int8 $_ },
    $Int16                => sub { _packed msgpack_int16 $_ },
    $Int32                => sub { _packed msgpack_int32 $_ },
    $Int64                => sub { _packed msgpack_int64 $_ },
    $Float64 => sub { _packed msgpack_float64 $_ },
    $FixStr ,=> sub { _packed msgpack_fixstr $_ },
    $Str8 ,=> sub { _packed msgpack_str8 $_ },
    $Str16 ,=> sub { _packed msgpack_str16 $_ },
    $Str32 ,=> sub { _packed msgpack_str32 $_ },
    $FixArray => sub { _packed msgpack_fixarray $_ },
    $Array16 => sub { _packed msgpack_array16 $_ },
    $Array32 => sub { _packed msgpack_array32 $_ },
    $Nil => \&encode_nil,
    $FixMap => sub { _packed msgpack_fixmap $_ },
    $Map16 => sub { _packed msgpack_map16 $_ },
    $Map32 => sub { _packed msgpack_map32 $_ },
    $FixExt1 => sub { _packed msgpack_fixext1 $_ },
    $FixExt2 => sub { _packed msgpack_fixext2 $_ },
    $FixExt4 => sub { _packed msgpack_fixext4 $_ },
    $FixExt8 => sub { _packed msgpack_fixext8 $_ },
    $FixExt16 => sub { _packed msgpack_fixext16 $_ },
    $Ext8 => sub { _packed msgpack_ext8 $_ },
    $Ext16 => sub { _packed msgpack_ext16 $_ },
    $Ext32 => sub { _packed msgpack_ext32 $_ },
);

has struct => (
    isa => $MessagePack,
    is => 'ro',
    required => 1,
    coerce => 1,
);

sub BUILDARGS {
    shift;
    return { @_ == 1 ? ( struct => $_ ) : @_ };
}

sub encoded {
    my $self = shift;
    my $x = $MessagePack->assert_coerce($self->struct);
    return $$x;
}




sub encode_nil {
    _packed chr 0xc0;
}

sub encode_bin8($binary) {
    _packed join '', chr( 0xc4 ), chr length($binary), $binary;
}

sub _variable_length($number,$width=1) {
    my $final = '';
    while($width--){
        $final = chr( $number % 2**8 ) . $final;
        $number /= 2**8;
    }
    die "number too big for type\n" if $number >= 1;
    $final;
}

sub encode_bin16($binary) {
    _packed join '', chr( 0xc5 ), _variable_length( length($binary), 2 ), $binary;
}

sub encode_bin32($binary) {
    _packed join '', chr( 0xc6 ), _variable_length( length($binary), 4 ), $binary;
}


sub msgpack($data) {
    $MessagePack->assert_coerce($data)->$*;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Encoder - Encode a structure into a MessagePack binary string

=head1 VERSION

version 2.0.3

=head1 SYNOPSIS

    use MsgPack::Encoder;

    my $binary = MsgPack::Encoder->new( struct => [ "hello world" ] )->encoded;

    # using the msgpack_* functions

    my $binary = msgpack [ "hello world" ];
    # or
    my $specific = msgpack_array16 [ "hello", "world" ];

    use MsgPack::Decoder;

    my $struct = MsgPack::Decoder->new->read_all($binary);

=head1 DESCRIPTION

C<MsgPack::Encoder> objects encapsulate a Perl data structure, and provide
its MessagePack serialization.

In addition of the L<MsgPack::Encoder> class, the module exports
C<msgpack_*> helper functions that would convert data structures to their
MessagePack representations.

=head1 EXPORTED FUNCTIONS

=head2 Explicit conversion

    $packed = msgpack_nil();

    $packed = msgpack_bool($boolean);

    $packed = msgpack_positive_fixnum($num);
    $packed = msgpack_negative_fixnum($num);

    $packed = msgpack_uint8($int);
    $packed = msgpack_uint16($int);
    $packed = msgpack_uint32($int);
    $packed = msgpack_uint64($int);

    $packed = msgpack_int8($int);
    $packed = msgpack_int16($int);
    $packed = msgpack_int32($int);
    $packed = msgpack_int64($int);

    $packed = msgpack_bin8($binary);
    $packed = msgpack_bin16($binary);
    $packed = msgpack_bin32($binary);

    $packed = msgpack_float32($float);
    $packed = msgpack_float64($float);

    $packed = msgpack_fixstr($string);
    $packed = msgpack_str8($string);
    $packed = msgpack_str16($string);
    $packed = msgpack_str32($string);

    $packed = msgpack_fixarray(\@array);
    $packed = msgpack_array16(\@array);
    $packed = msgpack_array32(\@array);

    $packed = msgpack_fixmap(\%hash);
    $packed = msgpack_map16(\%hash);
    $packed = msgpack_map32(\%hash);

    $packed = msgpack_fixext1($type => $data);
    $packed = msgpack_fixext2($type => $data);
    $packed = msgpack_fixext4($type => $data);
    $packed = msgpack_fixext8($type => $data);
    $packed = msgpack_fixext16($type => $data);

    $packed = msgpack_ext8($type => $data);
    $packed = msgpack_ext16($type => $data);
    $packed = msgpack_ext32($type => $data);

=head2 Coerced conversion

    $packed = msgpack( $data )

Which is equivalent to

    $packed = MsgPack::Encoder->new(struct=>$data);

=head1 OBJECT OVERLOADING

=head2 Stringification

The stringification of a C<MsgPack::Encoder> object is its MessagePack encoding.

    print MsgPack::Encoder->new( struct => $foo );

    # equivalent to

    print MsgPack::Encoder->new( struct => $foo )->encoded;

=head1 METHODS

=head2 new( struct => $perl_struct )

The constructor accepts a single argument, C<struct>, which is the perl structure (or simple scalar)
to encode.

=head2 encoded

Returns the MessagePack representation of the structure.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
