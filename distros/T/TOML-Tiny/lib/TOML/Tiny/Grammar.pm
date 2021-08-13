package TOML::Tiny::Grammar;
# ABSTRACT: exports regex definitions used to parse TOML source
$TOML::Tiny::Grammar::VERSION = '0.15';
use strict;
use warnings;
use v5.18;

use parent 'Exporter';

our @EXPORT = qw(
  $WS
  $CRLF
  $EOL
  $Comment
  $NonASCII

  $BareKey
  $QuotedKey
  $SimpleKey
  $DottedKey
  $Key

  $Boolean

  $Escape
  $StringLiteral
  $MultiLineStringLiteral
  $BasicString
  $MultiLineString
  $String

  $Date
  $Time
  $DateTime
  $TimeOffset

  $Hex
  $Oct
  $Bin
  $Dec
  $Integer

  $Float
  $SpecialFloat
);

#-------------------------------------------------------------------------------
# Primitives
#-------------------------------------------------------------------------------
our $WS          = qr/[\x20\x09]/;          # space, tab
our $CRLF        = qr/\x0D?\x0A/;           # cr? lf
our $CommentChar = qr/(?>[^[:cntrl:]]|\t)/; # non-control chars other than tab
our $Comment     = qr/\x23$CommentChar*/;   # #comment
our $EOL         = qr/$Comment?$CRLF/;      # crlf or comment + crlf
our $Boolean     = qr/\b(?:true)|(?:false)\b/;
our $NonASCII    = qr/[\x80-\x{D7FF}\x{E000}-\x{10FFFF}]/;

#-------------------------------------------------------------------------------
# Strings
#-------------------------------------------------------------------------------
our $Escape = qr{
  \x5C                       # leading \
  (?>
      [\x5C"btfnr]           # escapes: \\ \" \b \t \n \f \r
    | (?> u [_0-9a-fA-F]{4}) # unicode (4 bytes)
    | (?> U [_0-9a-fA-F]{8}) # unicode (8 bytes)
  )
}x;

our $LiteralChar            = qr{ [\x09\x20-\x26\x28-\x7E] | $NonASCII }x;
our $StringLiteral          = qr{ ' (?: $LiteralChar )* ' }x;

our $MLLChar                = qr{ [\x09\x20-\x26\x28-\x7E] | $NonASCII }x;
our $MLLContent             = qr{ $MLLChar | $CRLF }x;
our $MLLQuotes              = qr{ '{1,2} }x;
our $MLLBody                = qr{ $MLLContent* (?: $MLLQuotes | $MLLContent{0,1} )*?  $MLLQuotes?  }x;
our $MultiLineStringLiteral = qr{ ''' (?: $CRLF? $MLLBody ) ''' }x;

our $BasicChar              = qr{ $WS | [\x21\x23-\x5B\x5D-\x7E] | $NonASCII | $Escape }x;
our $BasicString            = qr{ " (?: $BasicChar )* " }x;

our $MLBEscapedNL           = qr{ \x5c $WS* $CRLF (?: $WS | $CRLF)* }x;
our $MLBUnescaped           = qr{ $WS | [\x21\x23-\x5B\x5D-\x7E] | $NonASCII }x;
our $MLBQuotes              = qr{ "{1,2} }x;
our $MLBChar                = qr{ $MLBUnescaped | $Escape }x;
our $MLBContent             = qr{ $MLBChar | $CRLF | $MLBEscapedNL }x;
our $MLBasicBody            = qr{ $MLBContent* (?: $MLBQuotes | $MLBContent{0,1} )*? $MLBQuotes? }x;
our $MultiLineString        = qr{ """ $CRLF? $MLBasicBody """ }x;

our $String                 = qr/$MultiLineString | $BasicString | $MultiLineStringLiteral | $StringLiteral/x;

#-------------------------------------------------------------------------------
# Keys
#-------------------------------------------------------------------------------
our $BareKey   = qr/[-_\p{PosixAlnum}]+/;
our $QuotedKey = qr/$BasicString|$StringLiteral/;
our $SimpleKey = qr/$QuotedKey|$BareKey/;
our $DottedKey = qr/$SimpleKey (?: $WS* \. $WS* $SimpleKey)+/x;
our $Key       = qr{ (?: $DottedKey | $SimpleKey ) }x;


#-----------------------------------------------------------------------------
# Dates (RFC 3339)
#   1985-04-12T23:20:50.52Z
#-----------------------------------------------------------------------------
our $DateFullYear   = qr{ \d{4} }x;
our $DateMonth      = qr{ (?: 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 ) }x;
our $DateDay        = qr{ (?: 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 ) }x;
our $TimeDelim      = qr{ (?: [tT] | \x20 ) }x;
our $TimeHour       = qr{ (?: 00 | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 ) }x;
our $TimeMinute     = qr{ (?: 00 | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 ) }x;
our $TimeSecond     = qr{ (?: 00 | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 ) }x; # may be 60 during leap second
our $TimeSecFrac    = qr{ \. \d+ }x;
our $TimeNumOffset  = qr{ (?: [-+] $TimeHour : $TimeMinute ) }x;
our $TimeOffset     = qr{ (?: [zZ] | $TimeNumOffset ) }x;

our $PartialTime    = qr{ (?: $TimeHour : $TimeMinute : $TimeSecond $TimeSecFrac? ) }x;
our $FullTime       = qr{ (?: $PartialTime $TimeOffset ) }x;
our $FullDate       = qr{ (?: $DateFullYear - $DateMonth - $DateDay ) }x;

our $OffsetDateTime = qr{ (?: $FullDate $TimeDelim $FullTime ) }x;
our $LocalDateTime  = qr{ (?: $FullDate $TimeDelim $PartialTime ) }x;
our $LocalDate      = qr{ (?: $FullDate ) }x;
our $LocalTime      = qr{ (?: $PartialTime ) }x;
our $DateTime       = qr{ (?: $OffsetDateTime | $LocalDateTime | $LocalDate | $LocalTime ) }x;

#-----------------------------------------------------------------------------
# Integer
#-----------------------------------------------------------------------------
our $DecFirstChar = qr/[1-9]/;
our $DecChar      = qr/[0-9]/;
our $HexChar      = qr/[0-9a-fA-F]/;
our $OctChar      = qr/[0-7]/;
our $BinChar      = qr/[01]/;

our $Zero         = qr/[-+]? 0/x;
our $Hex          = qr/0x $HexChar (?> _? $HexChar )*/x;
our $Oct          = qr/0o $OctChar (?> _? $OctChar )*/x;
our $Bin          = qr/0b $BinChar (?> _? $BinChar )*/x;
our $Dec          = qr/$Zero | (?> [-+]? $DecFirstChar (?> _?  $DecChar )* )/x;
our $Integer      = qr/$Hex | $Oct | $Bin | $Dec/x;

#-----------------------------------------------------------------------------
# Float
#-----------------------------------------------------------------------------
our $SpecialFloat = qr/[-+]? (?: (?:inf) | (?:nan) | (?:NaN) )/x;
our $Fraction     = qr/\. $DecChar (?> _? $DecChar)*/x;

our $Exponent = qr{
  [eE]
  (?>
      $Zero+  # dec matches only one zero, but toml exponents apparently accept e00
    | $Dec
  )
}x;

our $Float = qr{
    (?> $Dec (?> (?> $Fraction $Exponent?) | $Exponent ) )
  | $SpecialFloat
}x;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TOML::Tiny::Grammar - exports regex definitions used to parse TOML source

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use TOML::Tiny::Grammar;

  if ($src =~ /$MultiLineString/) {
    ...
  }

=head1 DESCRIPTION

Exports various regexex for parsing TOML source.

=head1 PATTERNS

=head2 White space and ignorables

=head3 $WS

=head3 $CRLF

=head3 $EOL

=head3 $Comment

=head2 Keys

=head3 $BareKey

=head3 $QuotedKey

=head3 $SimpleKey

=head3 $DottedKey

=head3 $Key

=head2 Values

=head3 $Boolean

=head3 $Escape

=head3 $StringLiteral

=head3 $MultiLineStringLiteral

=head3 $BasicString

=head3 $MultiLineString

=head3 $String

=head3 $Date

=head3 $Time

=head3 $DateTime

=head3 $Hex

=head3 $Oct

=head3 $Bin

=head3 $Dec

=head3 $Integer

=head3 $Float

=head2 $SpecialFloat

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
