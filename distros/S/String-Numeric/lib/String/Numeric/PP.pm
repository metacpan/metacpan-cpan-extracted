package String::Numeric::PP;
use strict;
use warnings;

use Carp qw[croak];

BEGIN {
    our $VERSION   = 0.9;
    our @EXPORT_OK = qw(
      is_numeric
      is_float
      is_decimal
      is_integer
      is_int
      is_int8
      is_int16
      is_int32
      is_int64
      is_int128
      is_uint
      is_uint8
      is_uint16
      is_uint32
      is_uint64
      is_uint128
    );

    require Exporter;
    *import = \&Exporter::import;
}

sub INT8_MIN    () { '128' }
sub INT16_MIN   () { '32768' }
sub INT32_MIN   () { '2147483648' }
sub INT64_MIN   () { '9223372036854775808' }
sub INT128_MIN  () { '170141183460469231731687303715884105728' }

sub INT8_MAX    () { '127' }
sub INT16_MAX   () { '32767' }
sub INT32_MAX   () { '2147483647' }
sub INT64_MAX   () { '9223372036854775807' }
sub INT128_MAX  () { '170141183460469231731687303715884105727' }

sub UINT8_MAX   () { '255' }
sub UINT16_MAX  () { '65535' }
sub UINT32_MAX  () { '4294967295' }
sub UINT64_MAX  () { '18446744073709551615' }
sub UINT128_MAX () { '340282366920938463463374607431768211455' }

*is_numeric = \&is_float;
*is_integer = \&is_int;

sub is_float {
    @_ == 1 || croak(q/Usage: is_float(string)/);
    local $_ = $_[0];
    return ( defined && /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z/ );
}

sub is_decimal {
    @_ == 1 || croak(q/Usage: is_decimal(string)/);
    local $_ = $_[0];
    return ( defined && /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?\z/ );
}

sub is_int {
    @_ == 1 || croak(q/Usage: is_int(string)/);
    local $_ = $_[0];
    return ( defined && /\A-?(?:0|[1-9][0-9]*)\z/ );
}

sub is_int8 {
    @_ == 1 || croak(q/Usage: is_int8(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(-?)(0|[1-9][0-9]{0,2})\z/
          && ( length $2 < 3 || ( $1 ? $2 le INT8_MIN : $2 le INT8_MAX ) ) );
}

sub is_int16 {
    @_ == 1 || croak(q/Usage: is_int16(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(-?)(0|[1-9][0-9]{0,4})\z/
          && ( length $2 < 5 || ( $1 ? $2 le INT16_MIN : $2 le INT16_MAX ) ) );
}

sub is_int32 {
    @_ == 1 || croak(q/Usage: is_int32(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(-?)(0|[1-9][0-9]{0,9})\z/
          && ( length $2 < 10 || ( $1 ? $2 le INT32_MIN : $2 le INT32_MAX ) ) );
}

sub is_int64 {
    @_ == 1 || croak(q/Usage: is_int64(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(-?)(0|[1-9][0-9]{0,18})\z/
          && ( length $2 < 19 || ( $1 ? $2 le INT64_MIN : $2 le INT64_MAX ) ) );
}

sub is_int128 {
    @_ == 1 || croak(q/Usage: is_int128(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(-?)(0|[1-9][0-9]{0,38})\z/
          && ( length $2 < 39 || ( $1 ? $2 le INT128_MIN : $2 le INT128_MAX ) ) );
}

sub is_uint {
    @_ == 1 || croak(q/Usage: is_uint(string)/);
    local $_ = $_[0];
    return ( defined && /\A(?:0|[1-9][0-9]*)\z/ );
}

sub is_uint8 {
    @_ == 1 || croak(q/Usage: is_uint8(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(0|[1-9][0-9]{0,2})\z/
          && ( length $1 < 3 || $1 le UINT8_MAX ) );
}

sub is_uint16 {
    @_ == 1 || croak(q/Usage: is_uint16(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(0|[1-9][0-9]{0,4})\z/
          && ( length $1 < 5 || $1 le UINT16_MAX ) );
}

sub is_uint32 {
    @_ == 1 || croak(q/Usage: is_uint32(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(0|[1-9][0-9]{0,9})\z/
          && ( length $1 < 10 || $1 le UINT32_MAX ) );
}

sub is_uint64 {
    @_ == 1 || croak(q/Usage: is_uint64(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(0|[1-9][0-9]{0,19})\z/
          && ( length $1 < 20 || $1 le UINT64_MAX ) );
}

sub is_uint128 {
    @_ == 1 || croak(q/Usage: is_uint128(string)/);
    local $_ = $_[0];
    return ( defined
          && /\A(0|[1-9][0-9]{0,38})\z/
          && ( length $1 < 39 || $1 le UINT128_MAX ) );
}

1;

