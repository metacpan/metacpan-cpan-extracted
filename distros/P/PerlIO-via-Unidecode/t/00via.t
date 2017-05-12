# -*- coding:utf-8; mode:CPerl -*-
use strict;  use warnings;  use Test;  BEGIN {plan tests => 2};

print "#\n# I am ", __FILE__, "\n#  ",
  q[ with Time-stamp: "2014-07-27 02:25:03 MDT sburke@cpan.org"],
  "\n#\n",
;

ok 1;
require PerlIO::via::Unidecode;
$PerlIO::via::Unidecode::VERSION
 and print "# Pod::Perldoc version $PerlIO::via::Unidecode::VERSION\n";
$Text::Unidecode::VERSION
 and print "# Text::Unidecode version $Text::Unidecode::VERSION\n";
require PerlIO::via;
$PerlIO::via::VERSION
 and print "# PerlIO::via version $PerlIO::via::VERSION\n";

print "# Running under perl version $] for $^O",
      (chr(65) eq 'A') ? "\n" : " in a non-ASCII world\n";
print "# Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
      if defined(&Win32::BuildNumber) and defined &Win32::BuildNumber();
print "# MacPerl verison $MacPerl::Version\n"
      if defined $MacPerl::Version;
printf "# Current time local: %s\n# Current time GMT:   %s\n",
      scalar(   gmtime($^T)), scalar(localtime($^T));
print "# Using Test.pm version ", $Test::VERSION || "nil", "\n";

ok 1;

