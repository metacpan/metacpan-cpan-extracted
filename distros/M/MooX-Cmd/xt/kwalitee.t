#!perl

use strict;
use warnings;

use Test::More;

# kwalitee checks require a built distribution (Makefile.PL, MANIFEST, META.yml)
plan skip_all => "kwalitee test only works on a built distribution"
  unless -f 'Makefile.PL' || -f 'Build.PL';

BEGIN
{
    eval { require Test::Kwalitee }
      or plan skip_all => "Test::Kwalitee required for this test";
}

use Test::Kwalitee 'kwalitee_ok';

kwalitee_ok();

done_testing;
