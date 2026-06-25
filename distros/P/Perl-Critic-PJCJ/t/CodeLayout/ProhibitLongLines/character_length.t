#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;
use utf8;

use Test2::V0    qw( done_testing is subtest );
use feature      qw( signatures );
use experimental qw( signatures );

use lib                                                 qw( lib t/lib );
use Perl::Critic::Policy::CodeLayout::ProhibitLongLines ();
use ViolationFinder                                     qw( bad good );
use Encode                                              qw( encode );

my $Policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;

# PPI reads source files as bytes, so a line with multi-byte UTF-8 characters
# must be measured by its character count, not its octet count.  These tests
# hand the policy a byte string, exactly as PPI does when reading from disk.

subtest "Multi-byte characters are counted as characters not octets" => sub {
  my $line = 'my $x = "' . ("\x{e9}" x 60) . '";';
  is length($line), 71, "Line is 71 characters";

  my $bytes = encode("UTF-8", $line);
  is length($bytes), 131, "Line is 131 octets when UTF-8 encoded";

  good $Policy, $bytes,
    "Line of 71 characters does not violate the 80 character limit";
};

subtest "Character count is reported and long lines still detected" => sub {
  my $line = 'my $x = "' . ("\x{e9}" x 90) . '";';
  is length($line), 101, "Line is 101 characters";

  my $bytes = encode("UTF-8", $line);
  is length($bytes), 191, "Line is 191 octets when UTF-8 encoded";

  bad $Policy, $bytes, "Line is 101 characters long (exceeds 80)",
    "Multi-byte line over 80 characters violates with character count";
};

# Source files in a single-byte encoding (Latin-1, Windows-1252) are not valid
# UTF-8, so the policy keeps the octets.  That still gives the correct count
# because one octet is one character in these encodings.

subtest "Latin-1 source is counted by characters" => sub {
  my $line = 'my $x = "' . ("\x{e9}" x 60) . '";';
  is length($line), 71, "Line is 71 characters";

  my $bytes = encode("ISO-8859-1", $line);
  is length($bytes), 71, "Line is 71 octets when Latin-1 encoded";

  good $Policy, $bytes,
    "Latin-1 line of 71 characters does not violate the 80 character limit";

  my $long = 'my $x = "' . ("\x{e9}" x 90) . '";';
  bad $Policy, encode("ISO-8859-1", $long),
    "Line is 101 characters long (exceeds 80)",
    "Latin-1 line over 80 characters violates with character count";
};

subtest "Windows-1252 source is counted by characters" => sub {
  my $line = 'my $x = "' . ("\x{2019}" x 60) . '";';
  is length($line), 71, "Line is 71 characters";

  my $bytes = encode("cp1252", $line);
  is length($bytes), 71, "Line is 71 octets when Windows-1252 encoded";

  good $Policy, $bytes,
    "Windows-1252 line of 71 characters does not violate the 80 limit";

  my $long = 'my $x = "' . ("\x{2019}" x 90) . '";';
  bad $Policy, encode("cp1252", $long),
    "Line is 101 characters long (exceeds 80)",
    "Windows-1252 line over 80 characters violates with character count";
};

# Known limitation: only UTF-8 is decoded.  A multi-byte source in any other
# encoding (here Shift-JIS) is not valid UTF-8, so it falls back to octet
# counting and over-counts.  This characterises that behaviour: a 47 character
# line is reported as 83 because each Japanese character is two Shift-JIS
# octets.  Perl source is conventionally UTF-8 or single-byte, so this is an
# accepted trade-off rather than a bug to fix here.

subtest "Non-UTF-8 multi-byte source falls back to octet counting" => sub {
  my $line = 'my $x = "' . ("\x{3042}" x 36) . '";';
  is length($line), 47, "Line is 47 characters";

  my $bytes = encode("shiftjis", $line);
  is length($bytes), 83, "Line is 83 octets when Shift-JIS encoded";

  bad $Policy, $bytes, "Line is 83 characters long (exceeds 80)",
    "Shift-JIS line is counted by octets, not characters";
};

done_testing;
