#!perl

use strict;
use warnings;

use Test::More;

## TESTS ##
plan tests => 5;

use_ok('Module::Version::App');

{
    no warnings qw/redefine once/;
    *Module::Version::App::help = sub {
        ok( 1, 'help' );
    };

    *Module::Version::App::process = sub {
        ok( 1, 'process' );
    };

    *Module::Version::App::error = sub {
        like( $_[1], qr/^could not parse options/, 'error' );
    };
}

my $app = Module::Version::App->new;
isa_ok( $app, 'Module::Version::App' );
@ARGV = '--help';
$app->parse_opts;

@ARGV = 'Var';
$app->parse_opts;

@ARGV = '--input';
$app->parse_opts;

