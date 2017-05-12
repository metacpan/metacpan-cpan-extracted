use strict;
use warnings;

use Test::More;

use_ok 'Net::Fluidinfo::Value::String';

my $v;

$v = Net::Fluidinfo::Value::String->new;
ok $v->type_alias eq 'string';

foreach $v ('', 'true', 0, 100.2) {
    ok qq("$v") eq Net::Fluidinfo::Value::String->new(value => $v)->to_json;
    ok qq("$v") eq Net::Fluidinfo::Value::String->new(value => $v)->payload;
}

done_testing;
