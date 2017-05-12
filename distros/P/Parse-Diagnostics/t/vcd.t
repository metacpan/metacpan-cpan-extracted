use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Parse::Diagnostics 'parse_diagnostics';
TODO: {
# https://github.com/benkasminbullock/parse-diagnostics/issues/1
local $TODO = 'Improve parsing of diagnostics';
# https://metacpan.org/source/GSULLIVAN/Verilog-VCD-0.07/lib/Verilog/VCD.pm
my $in = "$Bin/VCD_pm";
my $d = parse_diagnostics ($in);
cmp_ok ($d, '==', 11, "Got 11 diagnostics from VCD.pm");
};
done_testing ();
