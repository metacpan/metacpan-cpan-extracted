#!/usr/bin/perl -T

use Test::More tests => 22;

use strict;
use warnings;

ok( eval 'require Paranoid;',               'Loaded Paranoid' );
ok( eval 'require Paranoid::Args;',         'Loaded Paranoid::Args' );
ok( eval 'require Paranoid::Data;',         'Loaded Paranoid::Data' );
ok( eval 'require Paranoid::Debug;',        'Loaded Paranoid::Debug' );
ok( eval 'require Paranoid::Filesystem;',   'Loaded Paranoid::Filesystem' );
ok( eval 'require Paranoid::IO;',           'Loaded Paranoid::IO' );
ok( eval 'require Paranoid::IO::Line;',     'Loaded Paranoid::IO::Line' );
ok( eval 'require Paranoid::IO::Lockfile;', 'Loaded Paranoid::IO::Lockfile' );
ok( eval 'require Paranoid::Input;',        'Loaded Paranoid::Input' );
ok( eval 'require Paranoid::Log;',          'Loaded Paranoid::Lockfile' );
ok( eval 'require Paranoid::Log::Buffer;',  'Loaded Paranoid::Log::Buffer' );
ok( eval 'require Paranoid::Log::File;',    'Loaded Paranoid::Log::File' );
ok( eval 'require Paranoid::Module;',       'Loaded Paranoid::Module' );
ok( eval 'require Paranoid::Network;',      'Loaded Paranoid::Network' );
ok( eval 'require Paranoid::Network::IPv4;',
    'Loaded Paranoid::Network::IPv4'
    );
ok( eval 'require Paranoid::Network::IPv6;',
    'Loaded Paranoid::Network::IPv6'
    );
ok( eval 'require Paranoid::Network::Socket;',
    'Loaded Paranoid::Network::Socket'
    );
ok( eval 'require Paranoid::Process;', 'Loaded Paranoid::Process' );

eval 'Paranoid->import;';

ok( psecureEnv('/bin:/sbin'), 'psecureEnv 1' );
is( $ENV{PATH}, '/bin:/sbin', 'Validated PATH' );
ok( psecureEnv(), 'psecureEnv 2' );
is( $ENV{PATH}, '/bin:/usr/bin', 'Validated PATH' );

