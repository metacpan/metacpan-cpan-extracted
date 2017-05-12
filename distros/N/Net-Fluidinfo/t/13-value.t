use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;

use_ok 'Net::Fluidinfo::Value';

use Net::Fluidinfo::Value::Native;
use Net::Fluidinfo::TestUtils;

my $v;
my $nmt = Net::Fluidinfo::Value::Native->mime_type;

$v = Net::Fluidinfo::Value->new;
ok !$v->is_native;
ok !$v->is_non_native;
ok !$v->type;

$v = Net::Fluidinfo::Value->new_from_types_and_content($nmt, 'null', 'null');
ok $v->is_native;
ok $v->type eq 'null';
ok !defined $v->value;

$v = Net::Fluidinfo::Value->new_from_types_and_content($nmt, 'boolean', 'true');
ok $v->is_native;
ok $v->type eq 'boolean';
ok $v->value;

$v = Net::Fluidinfo::Value->new_from_types_and_content($nmt, 'boolean', 'false');
ok $v->is_native;
ok $v->type eq 'boolean';
ok !$v->value;

$v = Net::Fluidinfo::Value->new_from_types_and_content($nmt, 'int', '0');
ok $v->is_native;
ok $v->type eq 'integer';
ok $v->value == 0;

$v = Net::Fluidinfo::Value->new_from_types_and_content($nmt, 'float', '0.0');
ok $v->is_native;
ok $v->type eq 'float';
ok $v->value == 0;

$v = Net::Fluidinfo::Value->new_from_types_and_content($nmt, 'string', '"foo"');
ok $v->is_native;
ok $v->type eq 'string';
ok $v->value eq 'foo';

$v = Net::Fluidinfo::Value->new_from_types_and_content($nmt, 'list-of-strings', '["foo"]');
ok $v->is_native;
ok $v->type eq 'list_of_strings';
ok_sets_cmp $v->value, ['foo'];

$v = Net::Fluidinfo::Value->new_from_types_and_content('text/plain', undef, '0');
ok $v->is_non_native;
ok $v->value eq '0';
ok $v->type eq 'text/plain';

done_testing;
