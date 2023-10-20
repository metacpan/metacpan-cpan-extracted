use strict;
use warnings;
use utf8;
use Test::More;

use String::IRC;

my $si;
my $ctrl_b = "\x02";
my $ctrl_o = "\x0f";

$si = String::IRC->new('1');
is ''.$si->bold, "${ctrl_b}1${ctrl_o}", "string one";

$si = String::IRC->new('0');
is ''.$si->bold, "${ctrl_b}0${ctrl_o}", "string zero";

$si = String::IRC->new(1);
is ''.$si->bold, "${ctrl_b}1${ctrl_o}", "int one";

$si = String::IRC->new(0);
is ''.$si->bold, "${ctrl_b}0${ctrl_o}", "int zero";

done_testing;
