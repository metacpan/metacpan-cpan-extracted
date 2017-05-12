use strict;
use warnings;

use Test::More;

use_ok 'Net::Fluidinfo::Value::Boolean';

my $v;

$v = Net::Fluidinfo::Value::Boolean->new;
ok $v->type_alias eq 'boolean';

foreach $v (1, "00", 1.0, "false", []) {
    ok 'true' eq Net::Fluidinfo::Value::Boolean->new(value => $v)->to_json;
    ok 'true' eq Net::Fluidinfo::Value::Boolean->new(value => $v)->payload;
}

foreach $v (0, "0", undef, 0.0, "") {
    ok 'false' eq Net::Fluidinfo::Value::Boolean->new(value => $v)->to_json;
    ok 'false' eq Net::Fluidinfo::Value::Boolean->new(value => $v)->payload;
}

done_testing;
