#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );

use Cwd ();
use Path::Tiny qw( path tempdir );
use Skilletor::Backend;
use Skilletor::Config;
use Skilletor::Source::Local;

my $tmp  = tempdir;
my $home = path( Cwd::abs_path("$tmp") )->child('home');
$home->child( 'dev', 'skills' )->mkpath;

subtest 'Skilletor::Source::Local' => sub {
  my $src = Skilletor::Source::Local->new( local_path => '~/dev/skills', home => "$home" );
  is( $src->dir, "$home/dev/skills", '~ expanded' );
  ok( $src->exists, 'exists' );
  is_deeply( $src->resolve, { dir => "$home/dev/skills", version => 'local' }, 'resolve' );
  ok( $src->check('local'), 'always changed' );
  is( Skilletor::Source::Local->new( local_path => '~', home => "$home" )->dir, "$home", 'a bare ~' );
  is( Skilletor::Source::Local->new( local_path => '~user/x', home => "$home" )->dir, '~user/x', '~user is not expanded' );
  my $missing = Skilletor::Source::Local->new( local_path => "$home/nope" );
  ok( !$missing->exists, 'missing' );
  is( error_of( sub { $missing->resolve } ), "local source directory does not exist: $home/nope", 'resolve error' );
};

subtest 'resolve: author mode, fallbacks, origins, path' => sub {
  is_deeply(
    Skilletor::Backend->resolve( { name => 's', git => 'https://g', ref => 'v1', local => '~/dev/skills', origins => { git => 'project', local => 'user' } }, "$home" ),
    { kind => 'local', address => "$home/dev/skills", origin => 'user' },
    'an existing local wins, its origin',
  );
  is_deeply(
    Skilletor::Backend->resolve( { name => 's', git => 'https://g', ref => 'v1', local => '~/dev/gone', path => 'skills', origins => { git => 'project', local => 'user' } }, "$home" ),
    { kind => 'git', address => 'https://g', ref => 'v1', origin => 'project', path => ['skills'] },
    'a missing local falls back to git, the project\'s origin (trust of its own)',
  );
  is_deeply(
    Skilletor::Backend->resolve( { name => 's', url => 'https://u/x.tgz', origins => {} }, "$home" ),
    { kind => 'url', address => 'https://u/x.tgz', origin => 'project' },
    'no origin counts as project',
  );
  is_deeply(
    Skilletor::Backend->resolve( { name => 's', local => '~/dev/gone/../gone2/', origins => { local => 'user' } }, "$home" ),
    { kind => 'local', address => "$home/dev/gone2", origin => 'user' },
    'a missing local alone stays local, resolved',
  );
  symlink( "$home/dev/skills", "$home/link" ) or plan skip_all => 'no symlinks';
  is( Skilletor::Backend->resolve( { name => 's', local => '~/link', origins => {} }, "$home" )->{address}, "$home/dev/skills", 'real path' );
  is( error_of( sub { Skilletor::Backend->resolve( { name => 'x', origins => {} }, "$home" ) } ), 'source x has no backend', 'none' );
};

subtest 'make and identity' => sub {
  my $git = Skilletor::Backend->make( { kind => 'git', address => 'https://g', ref => 'v1', origin => 'user' }, '/c', 5000 );
  isa_ok( $git, 'Skilletor::Source::Git' );
  is( $git->ref, 'v1', 'ref' );
  is( $git->timeout_ms, 5000, 'timeout' );
  isa_ok( Skilletor::Backend->make( { kind => 'url', address => 'https://u/x.tgz' }, '/c' ), 'Skilletor::Source::Url' );
  isa_ok( Skilletor::Backend->make( { kind => 'local', address => '/d' }, '/c' ), 'Skilletor::Source::Local' );
  ok( Skilletor::Backend->make( { kind => 'local', address => '/d' }, '/c' )->DOES('Skilletor::Role::Source'), 'the role' );
  is( Skilletor::Backend->identity( { kind => 'git', address => 'https://g' } ), '["git","https://g",null]', 'identity' );
  is_deeply( Skilletor::Backend->trust_request( s => { kind => 'local', address => '/d' } ), { name => 's', kind => 'local', url => '/d' }, 'trust request' );
};

subtest 'from a loaded config, end to end' => sub {
  my $t = SkilletorTest::home_with(
    user    => { sources => { shared => { local => '~/dev/skills' } } },
    project => { sources => { shared => { git => 'https://github.com/Getty/skills' } }, install => { skills => ['perl-moo@shared'] } },
  );
  path( $t->{home}, 'dev', 'skills' )->mkpath;
  my $c = Skilletor::Config->load( home => $t->{home}, project_dir => $t->{project} );
  my $b = Skilletor::Backend->resolve( $c->source('shared'), $t->{home} );
  is( $b->{kind}, 'local', 'author mode across files' );
  is( $b->{origin}, 'user', 'trusted as the user\'s' );
};

done_testing;
