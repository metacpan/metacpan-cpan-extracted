#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

use Regexp::Wildcards;

my $rw = Regexp::Wildcards->new();

my $wc     = 'a,b{c,d}e*f?(g)';
my $none   = quotemeta $wc;
my $unix   = 'a\\,b(?:c|d)e.*f.\\(g\\)';
my $win32  = '(?:a|b\{c|d\}e.*f.\\(g\\))';
my $jokers = 'a\\,b\\{c\\,d\\}e.*f.\\(g\\)';
my $groups = 'a\\,b\\{c\\,d\\}e\\*f\\?(g)';
my $jok_gr = 'a\\,b\\{c\\,d\\}e.*f.(g)';

is($rw->convert($wc), $unix,  'nothing defaults to unix');
$rw->type('win32');
is($rw->convert($wc), $win32, 'set to win32');
$rw->type('darwin');
is($rw->convert($wc), $unix,  'set to darwin');
$rw->type('MSWin32');
is($rw->convert($wc), $win32, 'reset to win32');
$rw->type();
is($rw->convert($wc), $unix,  'reset to unix');

$rw = Regexp::Wildcards->new(do => [ qw<jokers> ], type => 'win32');
is($rw->convert($wc), $jokers, 'do overrides type in new');
$rw->do(add => 'groups');
is($rw->convert($wc), $jok_gr, 'added groups to jokers');
$rw->do(add => 'jokers');
is($rw->convert($wc), $jok_gr, 'added jokers but it already exists');
$rw->do(rem => 'jokers');
is($rw->convert($wc), $groups, 'removed jokers, only groups remains');
$rw->do();
is($rw->convert($wc), $none,   'reset do');
