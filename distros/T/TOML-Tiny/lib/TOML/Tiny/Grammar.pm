package TOML::Tiny::Grammar;
# ABSTRACT: exports regex definitions used to parse TOML source
$TOML::Tiny::Grammar::VERSION = '0.08';
use strict;
use warnings;
use v5.18;

use parent 'Exporter';

our @EXPORT = qw(
  $WS
  $CRLF
  $EOL
  $Comment

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

  $Hex
  $Oct
  $Bin
  $Dec
  $Integer

  $Float
);

our $WS      = qr/[\x20\x09]/;     # space, tab
our $CRLF    = qr/\x0D?\x0A/;      # cr? lf
our $Comment = qr/\x23.*/;         # #comment
our $EOL     = qr/$Comment?$CRLF/; # crlf or comment + crlf

our $Escape = qr{
  \x5C                       # leading \
  (?>
      [\x5C"btnfr]           # escapes: \\ \" \b \t \n \f \r
    | (?> u [_0-9a-fA-F]{4}) # unicode (4 bytes)
    | (?> U [_0-9a-fA-F]{8}) # unicode (8 bytes)
  )
}x;

our $StringLiteral = qr/'[^']*'/; # single quoted string (no escaped chars allowed)

our $MultiLineStringLiteral = qr{
  '''                     # opening triple-quote
  (?> [^'] | '{1,2} )*?
  '''                     # closing triple-quote
}x;

our $BasicString = qr{
    "                       # opening quote
    (?>                     # escape sequences or any char except " or \
        [^"\\]
      | $Escape
    )*
    "                       # closing quote
}x;

our $MultiLineString = qr{
  """                       # opening triple-quote
  (?>
      [^"\\]
    | "{1,2}                # 1-2 quotation marks
    | $Escape               # escape
    | (?: \\ $CRLF)         # backslash-terminated line
  )*?
  """                       # closing triple-quote
}x;

our $String = qr/$MultiLineString | $BasicString | $MultiLineStringLiteral | $StringLiteral/x;

our $BareKey   = qr/[-_a-zA-Z0-9]+/;
our $QuotedKey = qr/$BasicString|$StringLiteral/;
our $SimpleKey = qr/$BareKey|$QuotedKey/;
our $DottedKey = qr/$SimpleKey(?:\.$SimpleKey)+/;
our $Key       = qr/$BareKey|$QuotedKey|$DottedKey/;

our $Boolean   = qr/\b(?:true)|(?:false)\b/;

#-----------------------------------------------------------------------------
# Dates (RFC 3339)
#   1985-04-12T23:20:50.52Z
#-----------------------------------------------------------------------------
our $Date     = qr/\d{4}-\d{2}-\d{2}/;
our $Offset   = qr/(?: [-+] \d{2}:\d{2} ) | Z/x;
our $Time     = qr/\d{2}:\d{2}:\d{2} (?: \. \d+)? $Offset?/x;
our $DateTime = qr/(?> $Date (?> [T ] $Time )?) | $Time/x;

#-----------------------------------------------------------------------------
# Integer
#-----------------------------------------------------------------------------
our $DecFirstChar = qr/[1-9]/;
our $DecChar      = qr/[0-9]/;
our $HexChar      = qr/[0-9 a-f A-F]/;
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
our $Exponent     = qr/[eE] $Dec/x;
our $SpecialFloat = qr/[-+]? (?:inf) | (?:nan)/x;
our $Fraction     = qr/\. $DecChar (?> _? $DecChar)*/x;

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

version 0.08

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

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
