# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 33;

use_ok('Repository::Simple');

my $repository = Repository::Simple->attach(
    FileSystem => root => 't/root',
);
ok($repository, 'repository');

my $root_node = $repository->root_node;
ok($root_node, 'root_node');
isa_ok($root_node, 'Repository::Simple::Node', 'root_node isa node');

ok($root_node->repository);
isa_ok($root_node->repository, 'Repository::Simple', 
    'node repository isa repository');

ok($root_node->parent, 'parent');
isa_ok($root_node->parent, 'Repository::Simple::Node', 'parent isa node');
is($root_node->parent->path, '/', '/ parent is /');

is($root_node->name, '/', 'name');
is($root_node->path, '/', 'path');

my %child_nodes = map { $_->path => $_ } $root_node->nodes;

ok($child_nodes{'/foo'}, 'child /foo');
ok($child_nodes{'/bar'}, 'child /bar');
ok($child_nodes{'/baz'}, 'child /baz');

is($child_nodes{'/foo'}->name, 'foo', 'child /foo name');
is($child_nodes{'/bar'}->name, 'bar', 'child /bar name');
is($child_nodes{'/baz'}->name, 'baz', 'child /baz name');

my %properties = map { $_->name => $_ } $root_node->properties;

ok(defined $properties{'fs:dev'}, 'fs:dev');
ok(defined $properties{'fs:ino'}, 'fs:ino');
ok(defined $properties{'fs:mode'}, 'fs:mode');
ok(defined $properties{'fs:nlink'}, 'fs:nlink');
ok(defined $properties{'fs:uid'}, 'fs:uid');
ok(defined $properties{'fs:gid'}, 'fs:gid');
ok(defined $properties{'fs:rdev'}, 'fs:rdev');
ok(defined $properties{'fs:size'}, 'fs:size');
ok(defined $properties{'fs:atime'}, 'fs:atime');
ok(defined $properties{'fs:mtime'}, 'fs:mtime');
ok(defined $properties{'fs:ctime'}, 'fs:ctime');
ok(defined $properties{'fs:blksize'}, 'fs:blksize');
ok(defined $properties{'fs:blocks'}, 'fs:blocks');

my $node_type = $root_node->type;
ok($node_type, 'type');
isa_ok($node_type, 'Repository::Simple::Type::Node', 'type is node type');
is($node_type->name, 'fs:directory', 'node type is fs:directory');
