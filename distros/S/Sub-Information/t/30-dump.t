#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

BEGIN {
    use_ok 'Sub::Information', as => 'peek'
      or die;
}

my $info = peek sub {1};

can_ok $info, 'dump';
like $info->dump, qr/REFCNT/, "... and it should return the Devel::Peek dump";
