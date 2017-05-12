# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 12;

use_ok('Repository::Simple');

my $repository = Repository::Simple->attach(
    FileSystem => root => 't/root',
);
ok($repository);

my $root_node = $repository->root_node;
ok($root_node);

my $node_type = $root_node->type;
ok($node_type);

my %properties = $node_type->property_types;
my $fs_uid = $repository->property_type($properties{'fs:uid'});
ok($fs_uid);
isa_ok($fs_uid, 'Repository::Simple::Type::Property');

is($fs_uid->name, 'fs:scalar');

ok($fs_uid->auto_created);
ok($fs_uid->updatable);
ok(!$fs_uid->removable);

my $value_type = $fs_uid->value_type;
ok($value_type);
isa_ok($value_type, 'Repository::Simple::Type::Value');
