# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 21;

use_ok('Repository::Simple');

my $repository = Repository::Simple->attach(
    FileSystem => root => 't/root',
);
ok($repository);

my $node_type = $repository->node_type('fs:object');

is($node_type->name, 'fs:object');
ok(!$node_type->super_types);
ok(!$node_type->node_types);

my %properties = $node_type->property_types;
ok($properties{'fs:dev'});
ok($properties{'fs:ino'});
ok($properties{'fs:mode'});
ok($properties{'fs:nlink'});
ok($properties{'fs:uid'});
ok($properties{'fs:gid'});
ok($properties{'fs:rdev'});
ok($properties{'fs:size'});
ok($properties{'fs:atime'});
ok($properties{'fs:mtime'});
ok($properties{'fs:ctime'});
ok($properties{'fs:blksize'});
ok($properties{'fs:blocks'});

ok(!$node_type->auto_created, 'auto_created');
ok($node_type->updatable, 'updatable');
ok($node_type->removable, 'removable');
