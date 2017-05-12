#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 9;

use Net::Journyx;

my $jx = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
    username => $ENV{'JOURNYX_USER'},
    password => $ENV{'JOURNYX_PASSWORD'},
);

use Net::Journyx::User;
my $user = Net::Journyx::User->new(jx => $jx)->load( id => $ENV{'JOURNYX_USER'} );
ok( $user );
is( $user->id, $ENV{'JOURNYX_USER'} );
is( $user->full_name, 'U1' );

ok( $user->update( full_name => 'UU1') );
is( $user->full_name, 'UU1' );

is( Net::Journyx::User->new(jx => $jx)->load( id => $ENV{'JOURNYX_USER'} )->full_name, 'UU1' );

ok( $user->update( full_name => 'U1') );
is( $user->full_name, 'U1' );

is( Net::Journyx::User->new(jx => $jx)->load( id => $ENV{'JOURNYX_USER'} )->full_name, 'U1' );

