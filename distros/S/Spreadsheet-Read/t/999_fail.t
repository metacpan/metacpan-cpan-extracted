#!/usr/bin/perl

use strict;
use warnings;

BEGIN { $ENV{SPREADSHEET_READ_XLSX} = "Test::More"; }

my     $tests = 2;
use     Test::More;
require Test::NoWarnings;

use     Spreadsheet::Read;

is (Spreadsheet::Read::parses ("xlsx"), 0, "Invalid module name for xlsx");
like ($@, qr/^Test::More is not supported/, "Error reason");

my $fz3 = "bad.zzz3";
END { unlink $fz3 }
open my $fh, ">", $fz3;
say $fh "Bad file";
close $fh;
my $ss = eval { Spreadsheet::Read::new ($fz3) };

#use DP;
#diag DDumper $ss;
#diag $@;

done_testing ($tests);
