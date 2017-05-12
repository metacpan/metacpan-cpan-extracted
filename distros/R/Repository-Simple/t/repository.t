# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 25;

use_ok('Repository::Simple');
use_ok('Repository::Simple::Permission');

use vars qw( $ADD_NODE $SET_PROPERTY $REMOVE $READ );

# Attach to the repository
my $repository = Repository::Simple->attach(
    FileSystem => root => 't/root',
);
ok($repository);

# Check engine()
my $engine = $repository->engine;
ok($engine);
isa_ok($engine, 'Repository::Simple::Engine::FileSystem');

# Check namespaces()
my %namespaces = $repository->namespaces;
is_deeply(\%namespaces, { 
    'fs' => 'http://contentment.org/Repository/Simple/Engine/FileSystem' 
});

# Check node_type()
my $fs_object = $repository->node_type('fs:object');
ok($fs_object);
isa_ok($fs_object, 'Repository::Simple::Type::Node');

# Check property_type()
my $fs_scalar = $repository->property_type('fs:scalar');
ok($fs_scalar);
isa_ok($fs_scalar, 'Repository::Simple::Type::Property');

# Check root_node()
my $root_node = $repository->root_node;
ok($root_node);
isa_ok($root_node, 'Repository::Simple::Node');

# Check get_item() node
my $node = $repository->get_item('/baz/qux');
ok($node);
isa_ok($node, 'Repository::Simple::Node');

# Check get_item() property
my $property = $repository->get_item('/baz/qux/fs:content');
ok($property);
isa_ok($property, 'Repository::Simple::Property');
is($property->value->get_scalar, "Your mom goes to college!\n");

# check_permission($ADD_NODE) on directory
eval { $repository->check_permission("/baz/blah", $ADD_NODE); };
ok(!$@); if ($@) { diag($@) }

# check_permission($ADD_NODE) on file
eval { $repository->check_permission("/foo/blah", $ADD_NODE); };
ok($@);

# check_permission($SET_PROPERTY) on mutable property
eval { $repository->check_permission("/baz/fs:mode", $SET_PROPERTY); };
ok(!$@); if ($@) { diag($@) }

# check_permission($SET_PROPERTY) on immutable property
eval { $repository->check_permission("/baz/fs:rdev", $SET_PROPERTY); };
ok($@);

# check_permission($REMOVE) on node
eval { $repository->check_permission("/foo", $REMOVE); };
ok(!$@); if ($@) { diag($@) }

# check_permission($REMOVE) on property
eval { $repository->check_permission("/baz/fs:rdev", $REMOVE); };
ok($@);

# check_permission($READ) on node
eval { $repository->check_permission("/foo", $READ); };
ok(!$@); if ($@) { diag($@) }

# check_permission($READ) on non-existent item
eval { $repository->check_permission("/foo/blah", $READ); };
ok($@);
