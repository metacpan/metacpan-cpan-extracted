use strict;
use warnings;

use Test::More;

use_ok 'Net::Fluidinfo::Value::Null';

my $v;

$v = Net::Fluidinfo::Value::Null->new;
ok $v->type_alias eq 'null';

ok 'null' eq Net::Fluidinfo::Value::Null->new->to_json;
ok 'null' eq Net::Fluidinfo::Value::Null->new->payload;

done_testing;
