#!perl -T

use Test::More tests => 9;
BEGIN { use_ok('Taint::Runtime') };

Taint::Runtime->import(qw(taint_enabled
                          taint
                          untaint
                          is_tainted
                          ));

ok(taint_enabled(), "Taint is On");

my $data = "foo\nbar";
ok(! is_tainted($data), "No false positive on is_tainted");

my $copy = taint($data);
ok(is_tainted($copy), "Made a tainted copy");

taint(\$data);
ok(is_tainted($data), "Tainted it directly");

$copy = untaint($data);
ok(! is_tainted($copy), "Made a clean copy");
ok($copy eq $data, "And i got all of the data back");

ok(is_tainted($data), "Data is still tainted");

untaint(\$data);
ok(! is_tainted($data), "Clean it directly");
