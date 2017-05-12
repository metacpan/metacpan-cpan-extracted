#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use Perinci::Object;

my $risub = risub { };

is($risub->type, "function", "type");

# ---

is($risub->v, 1.0, "1.0 v");
ok(!$risub->feature('foo'), "1.0 feature");
ok(!$risub->arg('j'), "1.0 arg");
dies_ok { $risub->feature('foo', 2) } "1.0 can't set feature";
dies_ok { $risub->arg('j', 'str')   } "1.0 can't set arg";

$risub = risub { features => {undo=>1}, args => {i=>'int'} };
is($risub->feature('undo'), 1, "1.0 feature (2)");
is($risub->arg('i'), 'int', "1.0 arg (2)");

# ---

$risub = risub { v=>1.1 };

is($risub->v, 1.1, "1.1 v");

ok(!$risub->feature('foo'), "1.1 feature");
ok(!$risub->arg('j'), "1.1 arg");
ok(!$risub->feature('foo', 2), "1.1 feature, set returns old value");
is($risub->feature('foo'), 2, "1.1 feature, set");
ok(!$risub->arg('j', {schema=>'str'}), '1.1 arg, set returns old value');
is_deeply($risub->arg('j'), {schema=>'str'}, "1.1 arg, set")
     or diag explain $risub->arg('j');
is_deeply($risub->as_struct,
          {v=>1.1, features=>{foo=>2}, args=>{j=>{schema=>'str'}}},
          "1.1 as_struct") or diag explain $risub->as_struct;

$risub = risub { v=>1.1, features => {undo=>1}, args => {i=>{schema=>'int'}} };
is($risub->feature('undo'), 1, "1.1 feature (2)");
is_deeply($risub->arg('i'), {schema=>'int'}, "1.1 arg (2)");

subtest "features" => sub {
    $risub = risub { v=>1.1 };
    is_deeply($risub->features, {}, "empty");
    $risub = risub { v=>1.1, features => {undo=>1} };
    is_deeply($risub->features, {undo=>1}, "empty");
};

subtest "can_dry_run" => sub {
    $risub = risub { v=>1.1, features => {dry_run=>1}};
    ok($risub->can_dry_run, "from dry_run feature");
    $risub = risub { v=>1.1, features => {tx=>{v=>2}}};
    ok($risub->can_dry_run, "from tx feature");
};

subtest "default_dry_run" => sub {
    $risub = risub { v=>1.1, features => {dry_run=>0}};
    ok(!$risub->default_dry_run, "dry_run=0 -> no");
    $risub = risub { v=>1.1, features => {dry_run=>1}};
    ok(!$risub->default_dry_run, "dry_run=1 -> no");
    $risub = risub { v=>1.1, features => {dry_run=>{default=>0}}};
    ok(!$risub->default_dry_run, "dry_run={default=>0} -> no");
    $risub = risub { v=>1.1, features => {dry_run=>{default=>1}}};
    ok( $risub->default_dry_run, "dry_run={default=>1} -> yes");
};

# ---

done_testing();
