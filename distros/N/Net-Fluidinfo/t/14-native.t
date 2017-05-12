use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::Fluidinfo::TestUtils;

use_ok 'Net::Fluidinfo::Value::Native';

my $v;

ok(Net::Fluidinfo::Value::Native->new->is_native);
ok(!Net::Fluidinfo::Value::Native->new->is_non_native);

ok(Net::Fluidinfo::Value::Native->mime_type eq $Net::Fluidinfo::Value::Native::MIME_TYPE);

ok(Net::Fluidinfo::Value::Native->is_mime_type($Net::Fluidinfo::Value::Native::MIME_TYPE));
ok(!Net::Fluidinfo::Value::Native->is_mime_type('text/html'));
ok(!Net::Fluidinfo::Value::Native->is_mime_type(undef));

ok 'Net::Fluidinfo::Value::Null'          eq Net::Fluidinfo::Value::Native->class_for_fin_type('null');
ok 'Net::Fluidinfo::Value::Boolean'       eq Net::Fluidinfo::Value::Native->class_for_fin_type('boolean');
ok 'Net::Fluidinfo::Value::Integer'       eq Net::Fluidinfo::Value::Native->class_for_fin_type('int');
ok 'Net::Fluidinfo::Value::Float'         eq Net::Fluidinfo::Value::Native->class_for_fin_type('float');
ok 'Net::Fluidinfo::Value::String'        eq Net::Fluidinfo::Value::Native->class_for_fin_type('string');
ok 'Net::Fluidinfo::Value::ListOfStrings' eq Net::Fluidinfo::Value::Native->class_for_fin_type('list-of-strings');

ok "Net::Fluidinfo::Value::Null"          eq Net::Fluidinfo::Value::Native->type_from_alias('null');
ok "Net::Fluidinfo::Value::Boolean"       eq Net::Fluidinfo::Value::Native->type_from_alias('boolean');
ok "Net::Fluidinfo::Value::Integer"       eq Net::Fluidinfo::Value::Native->type_from_alias('integer');
ok "Net::Fluidinfo::Value::Float"         eq Net::Fluidinfo::Value::Native->type_from_alias('float');
ok "Net::Fluidinfo::Value::String"        eq Net::Fluidinfo::Value::Native->type_from_alias('string');
ok "Net::Fluidinfo::Value::ListOfStrings" eq Net::Fluidinfo::Value::Native->type_from_alias('list_of_strings');
ok !Net::Fluidinfo::Value::Native->type_from_alias('unknown alias');

done_testing;
