# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 8;

use_ok('Repository::Simple');

my $repository = Repository::Simple->attach(
    FileSystem => root => 't/root',
);
ok($repository);

my $root_node = $repository->root_node;
ok($root_node);

my %properties = map { ( $_->name => $_) } $root_node->properties;
my $fs_uid = $properties{'fs:uid'};
ok($fs_uid);

my $property_type = $fs_uid->type;
ok($property_type);

my $value_type = $property_type->value_type;
ok($value_type);
isa_ok($value_type, 'Repository::Simple::Type::Value::Scalar');
is($value_type->name, 'rs:scalar');
