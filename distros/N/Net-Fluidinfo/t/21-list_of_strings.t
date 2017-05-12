use strict;
use warnings;

use Test::More;

use_ok 'Net::Fluidinfo::Value::ListOfStrings';

my $v;

$v = Net::Fluidinfo::Value::ListOfStrings->new;
ok $v->type_alias eq 'list_of_strings';

ok '[]'             eq Net::Fluidinfo::Value::ListOfStrings->new(value => [])->to_json;
ok '[""]'           eq Net::Fluidinfo::Value::ListOfStrings->new(value => [''])->to_json;
ok '["true"]'       eq Net::Fluidinfo::Value::ListOfStrings->new(value => ['true'])->to_json;
ok '["0","145.32"]' eq Net::Fluidinfo::Value::ListOfStrings->new(value => [+0, 145.3200000])->to_json;

ok '[]'             eq Net::Fluidinfo::Value::ListOfStrings->new(value => [])->payload;
ok '[""]'           eq Net::Fluidinfo::Value::ListOfStrings->new(value => [''])->payload;
ok '["false"]'      eq Net::Fluidinfo::Value::ListOfStrings->new(value => ['false'])->payload;
ok '["0","foo"]'    eq Net::Fluidinfo::Value::ListOfStrings->new(value => [-0, 'foo'])->payload;

done_testing;
