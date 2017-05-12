#!/usr/bin/perl -w

use Test::More tests => 6;

BEGIN { use_ok 'Shell::Command'; }

chdir 't';

ok !test_f "foo";
ok touch "foo";
ok test_f "foo";
ok rm_f "foo";
ok !test_f "foo";

