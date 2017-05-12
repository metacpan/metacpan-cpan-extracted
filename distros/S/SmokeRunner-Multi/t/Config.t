use strict;
use warnings;
no warnings 'redefine';

use Test::More tests => 7;

use File::Spec;
use File::Temp qw( tempdir );
use SmokeRunner::Multi::Config;
use YAML::Syck qw( DumpFile );

# make the user's homedir, in case he already has
# SR::M installed
*SmokeRunner::Multi::Config::_config_from_home = sub { };

eval { SmokeRunner::Multi::Config->instance() };

like( $@, qr/Cannot find a config file for the smoke-runner/,
        'exception with no config file' );

local $ENV{SMOKERUNNER_CONFIG} = '/does/not/exist.conf';
eval { SmokeRunner::Multi::Config->instance() };
like( $@, qr/Cannot find a config file for the smoke-runner/,
        'exception with non-existent path in $ENV{SMOKERUNNER_CONFIG}' );

my $file
    = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'smokerunner.conf' );

my $root ='/home/smokerunner/root';

open my $fh, '>', $file
    or die "Cannot write to $file: $!";
# A 0-byte file causes a warning inside YAML::Syck;
print $fh q{ }
    or die "Cannot write to $file: $!";
close $fh
    or die "Cannot write to $file: $!";

local $ENV{SMOKERUNNER_CONFIG} = $file;
eval { SmokeRunner::Multi::Config->instance() };
like( $@, qr/was not valid/,
        'exception with empty config file' );

DumpFile( $file, { root => $root, reporter => 'Smolder' } );

my $conf = eval { SmokeRunner::Multi::Config->instance() };

is( $@, '', 'no exception with valid config file' );
ok( $conf, 'got config object with valid config file' );
is( $conf->root_dir(), $root, 'root_dir() returns expected value' );
is( $conf->reporter(), 'Smolder', 'reporter() returns expected value' );
