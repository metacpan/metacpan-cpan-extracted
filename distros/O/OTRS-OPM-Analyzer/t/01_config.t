#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use OTRS::OPM::Analyzer::Utils::Config;

use File::Basename;
use File::Spec;

my $data_dir  = File::Spec->catdir( dirname( __FILE__ ), 'data' );
my $config    = File::Spec->catfile( $data_dir, 'config.yml' );
my $not_there = File::Spec->catfile( $data_dir, 'not_there.yml' );

{
    my $obj = OTRS::OPM::Analyzer::Utils::Config->new( $config );
    is $obj->get( 'app.path' ), '/opt/otrs/', 'multilevel key';
    is_deeply $obj->get( 'app' ), { path => '/opt/otrs/' }, 'single key';
    is $obj->get, undef, 'no key given';
    is $obj->get('invalid_key'), undef, 'invalid key';
    is $obj->get('invalid.key'), undef, 'invalid multi level key';

    $obj->set( 'app.version', 3 );
    is $obj->get( 'app.version' ), 3, 'set config';
    is_deeply $obj->get( 'app' ), { path => '/opt/otrs/', version => 3 }, 'single key with two values';

    $obj->set( 'app.path.lib', 'test' );
    is $obj->get( 'app.path.lib' ), undef, 'set did not succeed';

    throws_ok { $obj->load } qr/no config file given/, 'load undef';
}

{
    my $obj = OTRS::OPM::Analyzer::Utils::Config->new( $not_there );
    is $obj->get('invalid_key'), undef, 'invalid key (2)';
    is $obj->get('invalid.key'), undef, 'invalid multi level key (2)';

    $obj->set( 'app.version', 3 );
    is $obj->get( 'app.version' ), 3, 'set config (2)';
    is_deeply $obj->get( 'app' ), { version => 3 }, 'single key with one value';

    $obj->set( 'app.path.lib', 'test' );
    is $obj->get( 'app.path.lib' ), 'test', 'multilevel set (2)'
}

done_testing();
