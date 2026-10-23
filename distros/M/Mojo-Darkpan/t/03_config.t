use strict;
use warnings;
use Test::More 0.98;
use Cwd ();
use File::Temp ();
use Mojo::File qw(path);
use Mojo::Darkpan::Config;

my $work = path( File::Temp::tempdir( CLEANUP => 1 ) );

sub clean_env { delete $ENV{$_} for grep { /^DARKPAN_/ } keys %ENV }

sub config_file {
    my $file = $work->child('config.json');
    $file->spurt( $_[0] );
    $ENV{DARKPAN_CONFIG_FILE} = $file->to_string;
}

subtest 'defaults' => sub {
    clean_env();
    my $c = Mojo::Darkpan::Config->new;
    is $c->path,      'darkpan', 'path';
    is $c->directory, Cwd::getcwd() . '/darkpan', 'directory is resolved against the working directory';
    ok $c->compressIndex, 'compression is on';
    ok !$c->no_compress, 'no_compress is off';
    ok !$c->basic_auth,  'no basic auth';
};

subtest 'values from the config file' => sub {
    clean_env();
    config_file(<<'JSON');
{
  "directory": "./repo",
  "path": "mirror",
  "compress_index": false,
  "basic_auth": { "My Realm": { "username": "u", "password": "p" } }
}
JSON
    my $c = Mojo::Darkpan::Config->new;
    is $c->directory, Cwd::getcwd() . '/repo', 'relative directory loses ./ and is made absolute';
    is $c->path, 'mirror', 'path';
    ok $c->no_compress, 'compress_index false';
    is_deeply $c->basic_auth,
      { realm => 'My Realm', config => { username => 'u', password => 'p' } },
      'basic auth realm and settings';
};

subtest 'environment variables win over the config file' => sub {
    clean_env();
    config_file('{"directory":"/from/file","path":"file-path","compress_index":true}');
    $ENV{DARKPAN_DIRECTORY}      = '/from/env';
    $ENV{DARKPAN_PATH}           = 'env-path';
    $ENV{DARKPAN_COMPRESS_INDEX} = '0';
    my $c = Mojo::Darkpan::Config->new;
    is $c->directory, '/from/env', 'directory';
    is $c->path, 'env-path', 'path';
    ok $c->no_compress, 'DARKPAN_COMPRESS_INDEX=0 disables compression';
};

subtest 'an empty DARKPAN_COMPRESS_INDEX falls back to the file' => sub {
    clean_env();
    config_file('{"compress_index":false}');
    $ENV{DARKPAN_COMPRESS_INDEX} = '';
    ok( Mojo::Darkpan::Config->new->no_compress, 'file value is used' );
};

subtest 'basic auth from the environment' => sub {
    clean_env();
    config_file('{"basic_auth":{"File Realm":{"username":"file"}}}');
    $ENV{DARKPAN_AUTH_REALM}    = 'Env Realm';
    $ENV{DARKPAN_AUTH_username} = 'env';
    $ENV{DARKPAN_AUTH_password} = 'secret';
    my $auth = Mojo::Darkpan::Config->new->basic_auth;
    is $auth->{realm}, 'Env Realm', 'env realm wins over the file';
    is $auth->{config}{username}, 'env',    'DARKPAN_AUTH_* keys are lowercased';
    is $auth->{config}{password}, 'secret', 'password';
};

subtest 'unreadable configuration' => sub {
    clean_env();
    $ENV{DARKPAN_CONFIG_FILE} = $work->child('missing.json')->to_string;
    ok !eval { Mojo::Darkpan::Config->new->path; 1 }, 'a missing config file dies';

    config_file('{ not json');
    ok !eval { Mojo::Darkpan::Config->new->path; 1 }, 'invalid JSON dies';
};

clean_env();
done_testing;
