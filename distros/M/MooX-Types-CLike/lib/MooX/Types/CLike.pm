package MooX::Types::CLike;

our $VERSION = '0.92'; # VERSION
# ABSTRACT: C-like data types for Moo

use sanity;

use parent 'Exporter';
our @EXPORT_OK = ();

use MooX::Types::MooseLike 0.06;
use MooX::Types::MooseLike::Base 'is_Num';
use Scalar::Util qw(blessed);
use Config;
use POSIX qw(ceil);
use Math::BigInt;
use Math::BigFloat;
use Data::Float;
use constant {
   _BASE2_LOG => log(2) / log(10),
};

# these get repeated a lot
my $true = sub { 1 };
sub __alias_subtype {
   return {
      name       => $_[0],
      subtype_of => $_[1],
      from       => __PACKAGE__,
      test       => $true,
      message    => $true,
   };
};

my $bigtwo = Math::BigFloat->new(2);
my $bigten = Math::BigFloat->new(10);

sub __integer_builder {
   my ($bits, $signed_names, $unsigned_names) = @_;

   my   $signed = shift   @$signed_names;
   my $unsigned = shift @$unsigned_names;
   my $sbits = $bits - 1;

   # Some pre-processing math
   my $is_perl_safe = $Config{ivsize} >= ceil($bits / 8);
   my ($neg, $spos, $upos) = (
      $bigtwo->copy->bpow($sbits)->bmul(-1),
      $bigtwo->copy->bpow($sbits)->bsub(1),
      $bigtwo->copy->bpow( $bits)->bsub(1),
   );
   my $sdigits = ceil( $sbits * _BASE2_LOG );
   my $udigits = ceil(  $bits * _BASE2_LOG );

   return (
      {
         name       => $signed,
         subtype_of => 'Int',
         from       => 'MooX::Types::MooseLike::Base',
         test       => $is_perl_safe ?
            sub { $_[0] >= $neg and $_[0] <= $spos and !is_NaNInf($_[0]) } :
            sub {
               my $val = $_[0];
               blessed($val) and blessed($val) =~ /^Math::Big(?:Int|Float)|^big(?:int|num)/ and
               ( $val->accuracy || $val->precision || $val->div_scale ) >= $udigits and
               $val >= $neg and $val <= $spos and !is_NaNInf($val);
            },
         message    => sub { "$_[0] is not a $bits-bit signed integer!" },
      },
      (map { __alias_subtype($_, $signed) } @$signed_names),
      {
         name       => $unsigned,
         subtype_of => 'Int',
         from       => 'MooX::Types::MooseLike::Base',
         test       => $is_perl_safe ?
            sub { $_[0] >= 0 and $_[0] <= $upos and !is_NaNInf($_[0]) } :
            sub {
               my $val = $_[0];
               blessed($val) and blessed($val) =~ /^Math::Big(?:Int|Float)|^big(?:int|num)/ and
               ( $val->accuracy || $val->precision || $val->div_scale ) >= $udigits and
               $val >= 0 and $val <= $upos and !is_NaNInf($val);
            },
         message    => sub { "$_[0] is not a $bits-bit unsigned integer!" },
      },
      (map { __alias_subtype($_, $unsigned) } @$unsigned_names),
   );
};

# Looks like a float, stores like an int
sub __money_builder {
   my ($bits, $scale, $names) = @_;
   my $name = shift @$names;
   my $sbits = $bits - 1;

   # So, we have a base-10 scale and a base-2 set of $bits.  Lovely.
   # We can't actually figure out if it's Perl safe until we find the
   # $max, adjust with the $scale, and then go BACK to base-2 limits.
   my $div = $bigten->copy->bpow($scale);
   my ($neg, $pos) = (
      # bdiv returns (quo,rem) in list context :/
      scalar $bigtwo->copy->bpow($sbits)->bmul(-1)->bdiv($div),
      scalar $bigtwo->copy->bpow($sbits)->bsub(1)->bdiv($div),
   );

   my $digits = ceil( $sbits * _BASE2_LOG );
   my $emin2  = ceil( $scale / _BASE2_LOG );

   my $is_perl_safe = (
      Data::Float::significand_bits >= $sbits &&
      Data::Float::min_finite_exp   <= -$emin2
   );

   return (
      {
         name       => $name,
         subtype_of => 'Num',
         from       => 'MooX::Types::MooseLike::Base',
         test       => $is_perl_safe ?
            sub { $_[0] >= $neg and $_[0] <= $pos } :
            sub {
               my $val = $_[0];
               blessed($val) and blessed($val) =~ /^Math::BigFloat|^bignum/ and
               ( $val->accuracy || $val->precision || $val->div_scale ) >= $digits and
               $val >= $neg and $val <= $pos
            },
         message    => sub { "$_[0] is not a $bits-bit money number!" },
      },
      (map { __alias_subtype($_, $name) } @$names),
   );
};

sub __float_builder {
   my ($bits, $ebits, $names) = @_;
   my $name = shift @$names;
   my $sbits = $bits - 1 - $ebits;  # remove sign bit and exponent bits = significand precision

   # MAX = (2 - 2**(-$sbits-1)) * 2**($ebits-1)
   my $emax = $bigtwo->copy->bpow($ebits-1)->bsub(1);             # Y = (2**($ebits-1)-1)
   my $smin = $bigtwo->copy->bpow(-$sbits-1)->bmul(-1)->badd(2);  # Z = (2 - X) = -X + 2  (where X = 2**(-$sbits-1) )
   my $max  = $bigtwo->copy->bpow($emax)->bmul($smin);            # MAX = 2**Y * Z

   my $is_perl_safe = (
      Data::Float::significand_bits >= $sbits &&
      Data::Float::max_finite_exp   >= 2 ** $ebits - 1 &&
      Data::Float::have_infinite &&
      Data::Float::have_nan
   );
   my $digits = ceil( $sbits * _BASE2_LOG );

   return (
      {
         name       => $name,
         subtype_of => 'NumOrNaNInf',
         from       => __PACKAGE__,
         test       => $is_perl_safe ?
            sub {
               my $val = $_[0];
               $val >= -$max and $val <= $max or is_NaNInf($val);
            } :
            sub {
               my $val = $_[0];
               blessed($val) and blessed($val) =~ /^Math::BigFloat|^bignum/ and
               ( $val->accuracy || $val->precision || $val->div_scale ) >= $digits and
               (
                  $val >= -$max and $val <= $max or is_NaNInf($val)
               );
            },
         message    => sub { "$_[0] is not a $bits-bit binary floating point number!" },
      },
      (map { __alias_subtype($_, $name) } @$names),
   );
};

# Similar to float, but still different enough for another sub
sub __decimal_builder {
   my ($bits, $digits, $emax, $names) = @_;
   my $name = shift @$names;

   # We're not going to worry about the (extreme) edge case that
   # Perl might be compiled with decimal float NVs, but we still
   # need to convert to base-2.
   my $sbits = ceil( $digits / _BASE2_LOG );
   my $emax2 = ceil( $emax   / _BASE2_LOG );

   my $is_perl_safe = (
      Data::Float::significand_bits >= $sbits &&
      Data::Float::max_finite_exp   >= $emax2 &&
      Data::Float::have_infinite &&
      Data::Float::have_nan
   );

   my $max = $bigten->copy->bpow($emax)->bsub(1);

   return (
      {
         name       => $name,
         subtype_of => 'NumOrNaNInf',
         from       => __PACKAGE__,
         test       => $is_perl_safe ?
            sub {
               my $val = $_[0];
               $val >= -$max and $val <= $max or is_NaNInf($val);
            } :
            sub {
               my $val = $_[0];
               blessed($val) and blessed($val) =~ /^Math::BigFloat|^bignum/ and
               ( $val->accuracy || $val->precision || $val->div_scale ) >= $digits and
               (
                  $val >= -$max and $val <= $max or is_NaNInf($val)
               );
            },
         message    => sub { "$_[0] is not a $bits-bit decimal floating point number!" },
      },
      (map { __alias_subtype($_, $name) } @$names),
   );
};

sub __char_builder {
   my ($bits, $names) = @_;
   my $name = shift @$names;

   return (
      {
         name       => $name,
         subtype_of => 'WChar',
         from       => __PACKAGE__,
         test       => sub { ord($_[0]) < 2**$bits },
         message    => sub { "$_[0] is not a $bits-bit character!" },
      },
      (map { __alias_subtype($_, $name) } @$names),
   );
}

my $type_definitions = [
   ### Integer definitions ###
                             # being careful with char here...
   __integer_builder(  4, [qw(SNibble SSemiOctet Int4 Signed4)],            [qw(Nibble SemiOctet UInt4 Unsigned4)]),
   __integer_builder(  8, [qw(SByte SOctet TinyInt Int8 Signed8)],          [qw(Byte Octet UnsignedTinyInt UInt8 Unsigned8)]),
   __integer_builder( 16, [qw(Short SmallInt Int16 Signed16)],              [qw(UShort UnsignedSmallInt UInt16 Unsigned16)]),
   __integer_builder( 24, [qw(MediumInt Int24 Signed24)],                   [qw(UnsignedMediumInt UInt24 Unsigned24)]),
   __integer_builder( 32, [qw(Int Int32 Signed32)],                         [qw(UInt UnsignedInt UInt32 Unsigned32)]),
   __integer_builder( 64, [qw(Long LongLong BigInt Int64 Signed64)],        [qw(ULong ULongLong UnsignedBigInt UInt64 Unsigned64)]),
   __integer_builder(128, [qw(SOctaWord SDoubleQuadWord Int128 Signed128)], [qw(OctaWord DoubleQuadWord UInt128 Unsigned128)]),

   ### "Money" definitions ###
   __money_builder( 32, 4, [qw(SmallMoney)]),
   __money_builder( 64, 4, [qw(Money Currency)]),
   __money_builder(128, 6, [qw(BigMoney)]),

   ### Float definitions ###
   {
      name       => 'NaNInf',
      test       => sub {
         my $val = $_[0];
         blessed($val) and blessed($val) =~ /^Math::Big(?:Int|Float)|^big(?:int|num)/ and (
            $val->is_nan() or
            $val->is_inf('+') or
            $val->is_inf('-')
         ) or
         defined $_[0] and is_Num($_[0]) and (  # is_Num first, since Data::Float might give "isn't numeric" warnings
            Data::Float::float_is_infinite($val) or
            Data::Float::float_is_nan($val)
         );
      },
      message    => sub { "$_[0] is not infinity or NaN!" },
   },
   {
      name       => 'NonBigInt',
      test       => sub { (blessed($_[0]) and blessed($_[0]) =~ /^Math::BigInt|^bigint/ and not $_[0]->upgrade) ? 0 : 1; },
      message    => sub { "$_[0] is not a float safe number!" },
   },
   {
      name       => 'NumOrNaNInf',
      subtype_of => 'NonBigInt',
      from       => __PACKAGE__,
      test       => sub { is_Num($_[0]) || is_NaNInf($_[0]) },
      message    => sub { "$_[0] is not a number, infinity, or NaN!" },
   },
   __float_builder( 16,  4, [qw(ShortFloat)]),
   __float_builder( 16,  5, [qw(Half Float16 Binary16)]),
   __float_builder( 32,  8, [qw(Single Real Float Float32 Binary32)]),
   __float_builder( 40,  8, [qw(ExtendedSingle Float40)]),
   __float_builder( 64, 11, [qw(Double Float64 Binary64)]),
   __float_builder( 80, 15, [qw(ExtendedDouble Float80)]),
   __float_builder(104,  8, [qw(Decimal)]),
   __float_builder(128, 15, [qw(Quadruple Quad Float128 Binary128)]),

   ### Decimal definitions ###
   __decimal_builder( 32,  7,   96, [ 'Decimal32']),
   __decimal_builder( 64, 16,  384, [ 'Decimal64']),
   __decimal_builder(128, 34, 6144, ['Decimal128']),

   ### Char definitions ###
   {
      name       => 'WChar',
      subtype_of => 'Str',
      from       => 'MooX::Types::MooseLike::Base',
      test       => sub { length($_[0]) == 1 },  # length() will do a proper Unicode char length
      message    => sub { "$_[0] is not a single character!" },
   },
   __char_builder( 8, [qw(Char Char8)]),
   __char_builder(16, [qw(Char16)]),
   __char_builder(32, [qw(Char32)]),
   __char_builder(48, [qw(Char48)]),
   __char_builder(64, [qw(Char64)]),
];

MooX::Types::MooseLike::register_types($type_definitions, __PACKAGE__);  ### TODO: MooseX translation ###

my %base_tags = (
   'c'       => [qw(Char Byte Short UShort Int UInt Long ULong Float Double ExtendedDouble)],
   'stdint'  => [ map { ('Int'.$_, 'UInt'.$_) } (4,8,16,32,64,128) ],
   'c#'      => [qw(SByte Byte Char16 Short UShort Int UInt Long ULong Float Double Decimal)],
   'ieee754' => ['Binary16', map { ('Binary'.$_, 'Decimal'.$_) } (32,64,128) ],
   'tsql'    => [qw(TinyInt SmallInt Int BigInt SmallMoney Money Float64 Real)],
   'mysql'   => [ (map { ($_, 'Unsigned'.$_) } qw(TinyInt SmallInt MediumInt Int BigInt)), qw(Float Double)],
   'ansisql' => [qw(SmallInt Int Float Real Double)],
);
my %is_tags = (
   map {
      my $k = $_;
      'is_'.$k => [ map { 'is_'.$_ } @{$base_tags{$k}} ];
   } keys %base_tags
);

our %EXPORT_TAGS = (
   %base_tags,
   %is_tags,
   ( map { $_.'+is' => [ @{$base_tags{$_}}, @{$is_tags{'is_'.$_}} ] } keys %base_tags ),
   'all' => \@EXPORT_OK,
);

1;



=pod

=encoding utf-8

=head1 NAME

MooX::Types::CLike - C-like data types for Moo

=head1 SYNOPSIS

   package MyPackage;
   use Moo;
   use MooX::Types::CLike qw(:all);

   has 'foo' => (
      isa => Int     # or Int32, Signed32
   );
   has 'bar' => (
      isa => Short   # or SmallInt, Int16, Signed16
   );

   use Scalar::Util qw(blessed);
   use Math::BigFloat;
   use Sub::Quote;

   has 'baz' => (
      isa => Double  # or Float64, Binary64

      # A Double number gets pretty big, so make sure we use big numbers
      coerce => quote_sub q{
         Math::BigFloat->new($_[0])
            unless (blessed $_[0] =~ /^Math::BigFloat|^bignum/);
      },
   );

=head1 DESCRIPTION

Given the popularity of various byte-sized data types in C-based languages, databases, and
computers in general, there's a need for validating those data types in Perl & Moo(se).  This
module covers the gamut of the various number and character types in all of those forms.

The number types will validate that the number falls within the right bit length, that unsigned
numbers do not go below zero, and "Perl unsafe" numbers are using either Math::Big* or
bignum/bigfloat.  (Whether a number is "Perl safe" depends on your Perl's
L<http://perldoc.perl.org/Config.html#ivsize|ivsize>, or data from L<Data::Float>.)  Big
numbers are also checked to make sure they have an accuracy that supports the right number of
significant decimal digits.  (However, BigInt/Float defaults to 40 digits, which is above the
34 digits for 128-bit numbers, so you should be safe.)

Char types will validate that it's a single character, using Perl's Unicode-complaint C<length>
function.  The bit check types (all of them other than C<WChar>) will also check that the
ASCII/Unicode code (C<ord>) is the right bit length.

IEEE 754 decimal floating types are also available, which are floats that use a base-10
mantissa.  And the SQL Server "money" types, which are basically decimal numbers stored as
integers.

=head1 NAME

MooX::Types::CLike - C-like types for Moo

=head1 TYPES

All available types (including lots of aliases) are listed below:

   ### Integers ###
             [SIGNED]                                   | [UNSIGNED]
     4-bit = SNibble SSemiOctet Int4 Signed4            | Nibble SemiOctet UInt4 Unsigned4
     8-bit = SByte SOctet TinyInt Int8 Signed8          | Byte Octet UnsignedTinyInt UInt8 Unsigned8
    16-bit = Short SmallInt Int16 Signed16              | UShort UnsignedSmallInt UInt16 Unsigned16
    24-bit = MediumInt Int24 Signed24                   | UnsignedMediumInt UInt24 Unsigned24
    32-bit = Int Int32 Signed32                         | UInt UnsignedInt UInt32 Unsigned32
    64-bit = Long LongLong BigInt Int64 Signed64        | ULong ULongLong UnsignedBigInt UInt64 Unsigned64
   128-bit = SOctaWord SDoubleQuadWord Int128 Signed128 | OctaWord DoubleQuadWord UInt128 Unsigned128

   ### Floats (binary) ###
   (Total, Exponent) bits; Significand precision = Total - Exponent - 1 (sign bit)

   ( 16,  4) bits = ShortFloat
   ( 16,  5) bits = Half Float16 Binary16
   ( 32,  8) bits = Single Real Float Float32 Binary32
   ( 40,  8) bits = ExtendedSingle Float40
   ( 64, 11) bits = Double Float64 Binary64
   ( 80, 15) bits = ExtendedDouble Float80
   (104,  8) bits = Decimal    # not a IEEE 754 decimal, but C#'s bizarre "128-bit" float
   (128, 15) bits = Quadruple Quad Float128 Binary128

   ### Floats (decimal) ###
   (Digits, Exponent Max)

   ( 32,  8) = Decimal32
   ( 64, 11) = Decimal64
   (128, 15) = Decimal128

   ### "Money" ###
   (Bits, Scale)

   ( 32,  4) = SmallMoney
   ( 64,  4) = Money Currency
   (128,  6) = BigMoney  # doesn't exist; might change if it does suddenly exists

   ### Chars ###
   WChar = Single character (with Perl's natural Unicode-compliance)
   Bit check types = Char/Char8, Char16, Char32, Char48, Char64

=head1 EXPORTER TAGS

Since there are so many different aliases in this module, using C<:all> (while available) probably
isn't a good idea.  So, there are some Exporter tags available, grouped by language:

   # NOTE: Some extra types are included to fill in the gaps for signed vs. unsigned and
   # byte vs. char.

   :c       = Char Byte Short UShort Int UInt Long ULong Float Double ExtendedDouble
   :stdint  = Int4 UInt4 ... Int128 UInt128 (except 24-bit)
   :c#      = SByte Byte Char16 Short UShort Int UInt Long ULong Float Double Decimal
   :ieee754 = Binary16,32,64,128 and Decimal32,64,128
   :tsql    = TinyInt SmallInt Int BigInt SmallMoney Money Float64 Real
   :mysql   = TinyInt SmallInt MediumInt Int BigInt (and Unsigned versions) Float Double
   :ansisql = SmallInt Int Float Real Double

   :is_*    = All of the is_* functions for that tag
   :*+is    = Both the Moo and is_* functions for that tag

=head1 CAVEATS

The C<Int> type is also used by L<MooX::Types::MooseLike::Base>, and is even used (but not exported)
as a subtype for the Integer classes.  So be careful not to import both of them at the same time, as
they have different meanings.

Most C-based languages use a C<char> type to indicate both an 8-bit number and a single character,
as all strings in those languages are represented as a series of character codes.  Perl, as a dynamic
language, has a single scalar to represent both strings and numbers.  Thus, to separate the validation
of the two, the term C<Byte> or C<Octet> means the numeric 8-bit types, and the term C<Char> means the
single character string types.

The term C<long> in C/C++ is ambiguous depending on the bits of the OS: 32-bits for 32-bit OSs and
64-bits for 64-bit OSs.  Since the 64-bit version makes more sense (ie: C<short E<lt> int E<lt> long>),
that is the designation chosen.  To avoid confusion, you can just use C<LongLong> and C<ULongLong>.

The confusion is even worse for float types, with the C<long> modifier sometimes meaning absolutely
nothing in certain hardware platforms.  C<Long> isn't even used in this module for those types, in
favor of IEEE 754's "Extended" keyword.

The floats will support infinity and NaN, since C floats support this.  This may not be desirable, so
you might want to subtype the float and test for Inf/NaN if you don't want these.  Furthermore, the
"Perl safe" scalar tests for floats include checks to make sure it supports Inf/NaN.  However, the odds
of it NOT supporting those (since Perl should be using IEEE 754 floats for NV) are practically zero.

Hopefully, I've covered all possible types of floats found in the wild.  If not, let me know and I'll
add it in.  (For that matter, let me know if I'm missing I<any> type found in the wild.)

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/MooX-Types-CLike/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/MooX::Types::CLike/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #distzilla then talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/MooX-Types-CLike/issues>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

