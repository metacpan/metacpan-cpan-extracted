use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

{
    package TestAssociativeMergeOperator;
    sub new { bless {}, shift }
    sub merge {
        my ($self, $key, $existing_value, $value) = @_;
        ($existing_value || 0) + $value;
    }
}

my $merge_operator = RocksDB::AssociativeMergeOperator->new(TestAssociativeMergeOperator->new);
isa_ok $merge_operator, 'RocksDB::AssociativeMergeOperator';
my $db = RocksDB->new($name, {
    create_if_missing => 1,
    merge_operator    => $merge_operator,
});
$db->merge('counter', 1);
$db->merge('counter', 2);
$db->merge('counter', 3);
is $db->get('counter'), 6;
undef $merge_operator;
undef $db;
RocksDB->destroy_db($name);

{
    package TestMergeOperator;
    use Test::More;
    sub new { bless {}, shift }
    sub full_merge {
        my ($self, $key, $existing_value, $operand_list) = @_;
        is $key, 'foo';
        is $existing_value, undef;
        is_deeply $operand_list, ['bar', 'baz'];
        $operand_list->[-1];
    }
    sub partial_merge {
        my ($self, $key, $left_operand, $right_operand) = @_;
        is $key, 'foo';
        is $left_operand, 'bar';
        is $right_operand, 'baz';
        $right_operand;
    }
}

$name = File::Temp::tmpnam;
$merge_operator = RocksDB::MergeOperator->new(TestMergeOperator->new);
isa_ok $merge_operator, 'RocksDB::MergeOperator';
$db = RocksDB->new($name, {
    create_if_missing => 1,
    merge_operator    => $merge_operator,
});
$db->merge('foo', 'bar');
$db->merge('foo', 'baz');
is $db->get('foo'), 'baz';

undef $db;
RocksDB->destroy_db($name);

done_testing;
