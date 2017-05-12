# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 12;

use_ok('Repository::Simple');

# Load the repository
my $repository = Repository::Simple->attach(
    FileSystem => root => 't/root',
);
ok($repository);

# Load the root node
my $root_node = $repository->root_node;
ok($root_node);

# Load the properties of the root node
my %properties = map { ($_->name => $_) } $root_node->properties;
my $fs_uid = $properties{'fs:uid'};
ok($fs_uid);

# Check property capabilities
can_ok($fs_uid, qw(
    parent
    name
    path
    value
    type
    save
));

# Check the property parent
my $parent = $fs_uid->parent;
is($parent->path, $root_node->path);

# Check the property name
is($fs_uid->name, 'fs:uid');

# Check the property path
is($fs_uid->path, '/fs:uid');

# Check the property value
my $value = $fs_uid->value;
ok($value);
isa_ok($value, 'Repository::Simple::Value');

# Check the property type
my $property_type = $fs_uid->type;
ok($property_type);
isa_ok($property_type, 'Repository::Simple::Type::Property');
