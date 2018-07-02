use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Path qw( mkpath );
use PkgConfig::LibPkgConf::Client;
use PkgConfig::LibPkgConf::Util qw( path_sep path_relocate );
use File::Basename qw( basename );
use Data::Dumper ();

sub _dump
{
  Data::Dumper
    ->new([$_[0]], ['$x'])
    ->Terse(1)
    ->Sortkeys(1)
    ->Dump;
}

sub _is_deeply
{
  my($got, $expected, $name) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $ok = is_deeply($got, $expected, $name);
  unless($ok)
  {
    diag "got:      @{[ _dump($got)      ]}";
    diag "expected: @{[ _dump($expected) ]}";
  }
  $ok;
}

subtest 'basic create and destroy' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new;
  isa_ok $client, 'PkgConfig::LibPkgConf::Client';

  my $sysroot = $client->sysroot_dir;
  $sysroot = 'undef' unless defined $sysroot;

  note "sysroot = $sysroot";

  my $buildroot = $client->buildroot_dir;
  $buildroot = 'undef' unless defined $buildroot;

  note "buildroot = $buildroot";

  if(eval { require YAML; 1 })
  {
    note YAML::Dump("$client", $client);
  }

  undef $client;

  ok 1, 'did not crash on undef';

};

subtest 'set sysroot' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new;

  my $dir = File::Temp::tempdir( CLEANUP => 1 );

  is $client->sysroot_dir($dir), $dir;
  is $client->sysroot_dir, $dir;

};

subtest 'set buildroot' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new;

  my $dir = File::Temp::tempdir( CLEANUP => 1 );

  is $client->buildroot_dir($dir), $dir;
  is $client->buildroot_dir, $dir;

};

subtest 'subclass client' => sub {

  {
    package
      MyClient;

    use base qw( PkgConfig::LibPkgConf::Client );
  }

  my $client = MyClient->new;

  isa_ok $client, 'MyClient';
  isa_ok $client, 'PkgConfig::LibPkgConf::Client';

  undef $client;

  ok 1, 'did not crash on undef';
};

subtest 'find' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new( path => 'corpus/lib1' );

  is( $client->find('completely-bogus-non-existent'), undef);

  isa_ok( $client->find('foo'), 'PkgConfig::LibPkgConf::Package' );

};

subtest 'error' => sub {

  plan tests => 2;

  use PkgConfig::LibPkgConf::Test qw( send_error );

  no warnings 'redefine';
  local *PkgConfig::LibPkgConf::Client::error = sub {
    my($self, $msg) = @_;
    isa_ok $self, 'PkgConfig::LibPkgConf::Client';
    is $msg, 'this is an error sent';
  };

  my $client = PkgConfig::LibPkgConf::Client->new;
  eval { send_error($client, "this is an error sent") };
  note "exception: $@" if $@;

};

subtest 'error in subclass' => sub {

  plan tests => 3;

  use PkgConfig::LibPkgConf::Test qw( send_error );

  {
    package
      MyClient2;

    use base qw( PkgConfig::LibPkgConf::Client );

    sub error {
      my($self, $msg) = @_;
      Test::More::isa_ok $self, 'PkgConfig::LibPkgConf::Client';
      Test::More::isa_ok $self, 'MyClient2';
      Test::More::is $msg, 'this is an error sent2';

    }
  }

  my $client = MyClient2->new;
  eval { send_error($client, "this is an error sent2") };
  note "exception: $@" if $@;

};

subtest 'audit log' => sub {

  use PkgConfig::LibPkgConf::Test qw( send_log );

  my $client = PkgConfig::LibPkgConf::Client->new;
  $client->audit_set_log("test.log", "w");

  send_log $client, "line1\n";
  send_log $client, "line2\n";

  undef $client;

  open my $fh, '<', 'test.log';
  my $data = do { local $/; <$fh> };
  close $fh;

  note "[data]$data\n";
  ok $data;

};

subtest 'scan all' => sub {

  my $client = PkgConfig::LibPkgConf::Client->new( path => 'corpus/lib1' );

  # er.  Just make sure.
  subtest 'path' => sub {
    my @path = $client->path;
    is( scalar(@path), 1);
    ok -f "$path[0]/$_" for qw( foo.pc  foo1.pc  foo1a.pc );
    is( basename($path[0]), 'lib1' );
  };

  my %p;

  $client->scan_all(sub {
    my($client, $package) = @_;
    $p{$package->id}++;
    0;
  });

  _is_deeply \%p, { foo => 1, foo1 => 1, foo1a => 1 };

};

subtest 'path attributes' => sub {

  my $sep = path_sep();

  my $root = File::Temp::tempdir( CLEANUP => 1 );

  mkpath "$root/$_", 0, 0700 for qw(
    foo bar baz ralph trans formers foo/lib bar/lib trans/lib formers/lib
    foo/include bar/include trans/include formers/include
  );

  subtest 'search path' => sub {

    local $ENV{PKG_CONFIG_PATH} = join $sep, "$root/foo", "$root/bar";
    local $ENV{PKG_CONFIG_LIBDIR} = join $sep, "$root/baz", "$root/ralph";

    _is_deeply
      [PkgConfig::LibPkgConf::Client->new->path],
      [map { path_relocate "$root$_" } qw( /foo /bar /baz /ralph )];
    _is_deeply
      [PkgConfig::LibPkgConf::Client->new(path => join($sep, map { "$root$_" } qw( /trans /formers )))->path],
      [map { path_relocate "$root$_" } qw( /trans /formers )];
    _is_deeply
      [PkgConfig::LibPkgConf::Client->new(path => [map { "$root$_" } qw( /trans /formers )])->path],
      [map { path_relocate "$root$_" } qw( /trans /formers )];

  };

  subtest 'filter lib dirs' => sub {

    local $ENV{PKG_CONFIG_SYSTEM_LIBRARY_PATH} = join $sep, map { "$root$_" } '/foo/lib', '/bar/lib';

    _is_deeply
      [PkgConfig::LibPkgConf::Client->new->filter_lib_dirs],
      [map { path_relocate "$root$_" } qw( /foo/lib /bar/lib )];
    _is_deeply
      [PkgConfig::LibPkgConf::Client->new(filter_lib_dirs => [map { "$root$_" } qw( /trans/lib /formers/lib )])->filter_lib_dirs],
      [map { path_relocate "$root$_" } qw( /trans/lib /formers/lib )];

  };

  subtest 'filter include dirs' => sub {

    local $ENV{PKG_CONFIG_SYSTEM_INCLUDE_PATH} = join $sep, map { "$root$_" } '/foo/include', '/bar/include';

    _is_deeply
      [PkgConfig::LibPkgConf::Client->new->filter_include_dirs],
      [map { path_relocate "$root$_" } qw( /foo/include /bar/include )];
    _is_deeply
      [PkgConfig::LibPkgConf::Client->new(filter_include_dirs => [map { "$root$_" } qw( /trans/include /formers/include )])->filter_include_dirs],
      [map { path_relocate "$root$_" } qw( /trans/include /formers/include )];

  };

};

subtest 'maxdepth' => sub {

  is [PkgConfig::LibPkgConf::Client->new->maxdepth]->[0], 2000;
  is [PkgConfig::LibPkgConf::Client->new(maxdepth => 22)->maxdepth]->[0], 22;

  my $client = PkgConfig::LibPkgConf::Client->new;
  $client->maxdepth(42);
  is [$client->maxdepth]->[0], 42;

};

subtest 'global' => sub {

  subtest 'constructor' => sub {

    my $client = PkgConfig::LibPkgConf::Client->new( global => { foo => 'bar' } );

    _is_deeply [$client->global('foo')], ['bar'];

  };

  subtest 'after constructor' => sub {

    my $client = PkgConfig::LibPkgConf::Client->new;

    _is_deeply [$client->global('foo')], [];
    $client->global(foo => 'bar');
    _is_deeply [$client->global('foo')], ['bar'];
  };

  subtest 'expands' => sub {

    my $client = PkgConfig::LibPkgConf::Client->new( path => 'corpus/lib1', global => { prefix => '/klingon/autobot/force' } );
    my $pkg = $client->find('foo');

    is( $pkg->cflags, '-fPIC -I/klingon/autobot/force/include/foo ' );

  };

};

done_testing;
