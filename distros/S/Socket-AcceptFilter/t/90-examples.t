#!/usr/bin/env perl -w

use strict;
use Test::More;
use lib::abs "../lib";

$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';
our $dist = lib::abs::path('..');
eval "use File::Find; 1" or plan skip_all => "File::Find required";

plan tests => 1;

my $found = 0;
opendir my ($dir), $dist;
while (defined ( $_ = readdir $dir )) {
	$found='d', last if -d "$dist/$_" and /^(bin|ex|eg|examples?|scripts?|samples?|demos?)$/;
	$found='f', last if -f "$dist/$_" and /^(examples?|samples?|demos?)\.p(m|od)$/i;
}
ok($found, 'have example'.($found ? ': '.$found.':'.$_ : ''));
closedir $dir;
