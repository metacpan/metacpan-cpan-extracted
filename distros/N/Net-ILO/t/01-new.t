#!perl

use strict;

use Data::Dumper;
use Net::ILO;
use Test::More tests => 15;

my $ilo_defaults = Net::ILO->new;

ok( !$ilo_defaults->address,    'Default address is null' );
ok( !$ilo_defaults->username,   'Default username is null' );
ok( !$ilo_defaults->password,   'Default password is null' );
ok( $ilo_defaults->_debug == 0, 'Default debug level is 0' );
ok( $ilo_defaults->port == 443, 'Default port is 443' );

my $ilo_hashref = Net::ILO->new({
    address  => '127.0.0.1',
    username => 'Administrator',
    password => '12345678',
    debug    => 2,
    port     => 2381,
});

ok( $ilo_hashref->address eq '127.0.0.1',       'Specifying address in constructor (hashref)' );
ok( $ilo_hashref->username eq 'Administrator',  'Specifying username in constructor (hashref)' );
ok( $ilo_hashref->password eq '12345678',       'Specifying password in constructor (hashref)' );
ok( $ilo_hashref->_debug == 2,                  'Specifying debug level in constructor (hashref)' );
ok( $ilo_hashref->port == 2381,                 'Specifying alternate HTTPS port in constructor (hashref)' );

my $ilo_hash = Net::ILO->new(
    address  => '192.168.0.1',
    username => 'User',
    password => 'ABCDEFG',
    debug    => 3,
    port     => 4567,
);

ok( $ilo_hash->address  eq '192.168.0.1',       'Specifying address in constructor (hash)' );
ok( $ilo_hash->username eq 'User',              'Specifying username in constructor (hash)' );
ok( $ilo_hash->password eq 'ABCDEFG',           'Specifying password in constructor (hash)' );
ok( $ilo_hash->_debug == 3,                     'Specifying debug level in constructor (hash)' );
ok( $ilo_hash->port == 4567,                    'Specifying alternate HTTPS port in constructor (hash)' );

