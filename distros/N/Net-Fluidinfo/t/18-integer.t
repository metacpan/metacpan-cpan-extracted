use strict;
use warnings;

use Test::More;

use_ok 'Net::Fluidinfo::Value::Integer';

my $v;

$v = Net::Fluidinfo::Value::Integer->new;
ok $v->type_alias eq 'integer';

foreach $v (123, "+123", "123.0", 123.45) {
    ok '123' eq Net::Fluidinfo::Value::Integer->new(value => $v)->to_json;
    ok '123' eq Net::Fluidinfo::Value::Integer->new(value => $v)->payload;
}

foreach $v (-123, "-123", "-123.0") {
    ok '-123' eq Net::Fluidinfo::Value::Integer->new(value => $v)->to_json;
    ok '-123' eq Net::Fluidinfo::Value::Integer->new(value => $v)->payload;
}

done_testing;
