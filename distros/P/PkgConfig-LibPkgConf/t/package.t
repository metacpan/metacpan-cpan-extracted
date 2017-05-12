use strict;
use warnings;
use Test::More;
use File::Temp ();
use PkgConfig::LibPkgConf::Package;
use PkgConfig::LibPkgConf::Client;
use File::Basename qw( basename );

subtest 'find' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new(
    path => [ 'corpus/lib1' ],
    filter_lib_dirs => [],
    filter_include_dirs => [],
  );

  my $pkg = $client->find('foo');
  
  ok $pkg, "pkg = $pkg";

  note "refcount       = @{[ $pkg->refcount ]}";
  note "id             = @{[ $pkg->id ]}";
  note "filename       = @{[ $pkg->filename ]}";
  note "realname       = @{[ $pkg->realname ]}";
  note "version        = @{[ $pkg->version ]}";
  note "description    = @{[ $pkg->description ]}";
  note "libs           = @{[ $pkg->libs ]}";
  note "libs_static    = @{[ $pkg->libs_static ]}";
  note "cflags         = @{[ $pkg->cflags ]}";
  note "cflags_static  = @{[ $pkg->cflags_static ]}";

  is $pkg->refcount, 2, 'refcount';
  is $pkg->id, 'foo', 'id';

  subtest 'path' => sub {
    my @path = $client->path;
    is( scalar(@path), 1);
    ok -f "$path[0]/$_" for qw( foo.pc  foo1.pc  foo1a.pc );
    is( basename($path[0]), 'lib1' );
  };

  is $pkg->realname, 'foo', 'realname';
  is $pkg->version, '1.2.3', 'version';
  is $pkg->description, 'A testing pkg-config file', 'description';

  is $pkg->libs, '-L/test/lib -lfoo ', 'libs';
  is $pkg->cflags, '-fPIC -I/test/include/foo ', 'cflags';
  is $pkg->cflags_static, '-fPIC -I/test/include/foo -DFOO_STATIC ', 'cflags_static';

  my @libs           = $pkg->list_libs;
  my @cflags         = $pkg->list_cflags;
  my @cflags_static  = $pkg->list_cflags_static;
  
  is_deeply [map { ref $_ } @libs], [map { 'PkgConfig::LibPkgConf::Fragment' } 1..2 ];
  is_deeply [map { ref $_ } @cflags], [map { 'PkgConfig::LibPkgConf::Fragment' } 1..2 ];
  is_deeply [map { ref $_ } @cflags_static], [map { 'PkgConfig::LibPkgConf::Fragment' } 1..3 ];
  
  is $libs[0]->type, 'L';
  is $libs[0]->data, '/test/lib';
  is $libs[1]->type, 'l';
  is $libs[1]->data, 'foo';
  is $cflags[0]->type, 'f';
  is $cflags[0]->data, 'PIC';
  is $cflags[1]->type, 'I';
  is $cflags[1]->data, '/test/include/foo';
  is $cflags_static[2]->type, 'D';
  is $cflags_static[2]->data, 'FOO_STATIC';

  is_deeply [$pkg->variable('prefix')], ['/test'];
  is_deeply [$pkg->variable('prefixx')], [];
  
};

subtest 'package_from_file' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new(
    path => [],
    filter_lib_dirs => [],
    filter_include_dirs => [],
  );

  my $pkg = $client->package_from_file('corpus/lib1/foo.pc');
  
  ok $pkg, "pkg = $pkg";

  note "refcount       = @{[ $pkg->refcount ]}";
  note "id             = @{[ $pkg->id ]}";
  note "filename       = @{[ $pkg->filename ]}";
  note "realname       = @{[ $pkg->realname ]}";
  note "version        = @{[ $pkg->version ]}";
  note "description    = @{[ $pkg->description ]}";
  note "libs           = @{[ $pkg->libs ]}";
  note "libs_static    = @{[ $pkg->libs_static ]}";
  note "cflags         = @{[ $pkg->cflags ]}";
  note "cflags_static  = @{[ $pkg->cflags_static ]}";

  is $pkg->refcount, 1, 'refcount';
  is $pkg->id, 'foo', 'id';
  is $pkg->filename, 'corpus/lib1/foo.pc', 'filename';
  is $pkg->realname, 'foo', 'realname';
  is $pkg->version, '1.2.3', 'version';
  is $pkg->description, 'A testing pkg-config file', 'description';

  is $pkg->libs, '-L/test/lib -lfoo ', 'libs';
  is $pkg->cflags, '-fPIC -I/test/include/foo ', 'cflags';
  is $pkg->cflags_static, '-fPIC -I/test/include/foo -DFOO_STATIC ', 'cflags_static';

  my @libs           = $pkg->list_libs;
  my @cflags         = $pkg->list_cflags;
  my @cflags_static  = $pkg->list_cflags_static;
  
  is_deeply [map { ref $_ } @libs], [map { 'PkgConfig::LibPkgConf::Fragment' } 1..2 ];
  is_deeply [map { ref $_ } @cflags], [map { 'PkgConfig::LibPkgConf::Fragment' } 1..2 ];
  is_deeply [map { ref $_ } @cflags_static], [map { 'PkgConfig::LibPkgConf::Fragment' } 1..3 ];
  
  is $libs[0]->type, 'L';
  is $libs[0]->data, '/test/lib';
  is $libs[1]->type, 'l';
  is $libs[1]->data, 'foo';
  is $cflags[0]->type, 'f';
  is $cflags[0]->data, 'PIC';
  is $cflags[1]->type, 'I';
  is $cflags[1]->data, '/test/include/foo';
  is $cflags_static[2]->type, 'D';
  is $cflags_static[2]->data, 'FOO_STATIC';

  is_deeply [$pkg->variable('prefix')], ['/test'];
  is_deeply [$pkg->variable('prefixx')], [];
  
};

subtest 'filte sys' => sub {

  my $prefix = File::Temp::tempdir( CLEANUP => 1 );

  mkdir "$prefix/$_" for qw( lib include include/foo );

  my $client = PkgConfig::LibPkgConf::Client->new(
    path => [ 'corpus/lib1' ],
    filter_lib_dirs => [ "$prefix/lib" ],
    filter_include_dirs => [ "$prefix/include/foo" ],
    global => {
      prefix => $prefix,
    },
  );
  
  my $pkg = $client->find('foo');

  is $pkg->libs,   '-lfoo ', 'libs';  
  is $pkg->cflags, '-fPIC ', 'cflags';

};

subtest 'quotes and spaces' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new(
    path => [ 'corpus/lib1' ],
    filter_lib_dirs => [],
    filter_include_dirs => [],
  );
  
  my $pkg = $client->find('foo1');

  TODO: { local $TODO = 'not important';
  is $pkg->libs, "-L/test/lib -LC:/Program\\ Files/Foo\\ App/lib -lfoo1 ";
  is $pkg->cflags, '-fPIC -I/test/include/foo1 -IC:/Program\\ Files/Foo\\ App/include ';
  };

  is [map { "$_" } $pkg->list_libs]->[1], '-LC:/Program Files/Foo App/lib';
  is [map { "$_" } $pkg->list_cflags]->[2], '-IC:/Program Files/Foo App/include';
};

subtest 'package with prereq' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new(
    path => [ 'corpus/lib2' ],
    filter_lib_dirs => [],
    filter_include_dirs => [],
  );
  
  my $pkg = $client->find('foo');
  
  is $pkg->libs,           '-L/test/lib -lfoo -L/test2/lib -lbar ';
  is $pkg->cflags,         '-I/test/include/foo -I/test2/include/bar ';
  is $pkg->cflags_static,  '-I/test/include/foo -I/test2/include/bar -DFOO_STATIC -DBAR_STATIC ';

  is_deeply [$pkg->list_libs],           [qw( -L/test/lib -lfoo -L/test2/lib -lbar )];
  is_deeply [$pkg->list_cflags],         [qw( -I/test/include/foo -I/test2/include/bar )];
  is_deeply [$pkg->list_cflags_static],  [qw( -I/test/include/foo -I/test2/include/bar -DFOO_STATIC -DBAR_STATIC )];
  
};

subtest 'package with static libs' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new(
    path => [ 'corpus/lib3' ],
    filter_lib_dirs => [],
    filter_include_dirs => [],
  );
  
  my $pkg = $client->find('foo');

  is $pkg->libs_static, '-L/test/lib -lfoo -lbar -lbaz ';
  is_deeply [$pkg->list_libs_static], [qw( -L/test/lib -lfoo -lbar -lbaz )];

};

done_testing;

