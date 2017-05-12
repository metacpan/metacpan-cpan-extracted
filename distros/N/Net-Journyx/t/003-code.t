#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 8;

use Net::Journyx;

my $jx = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
    username => $ENV{'JOURNYX_USER'},
    password => $ENV{'JOURNYX_PASSWORD'},
);

use Net::Journyx::Code;

{
    my $defaults = Net::Journyx::Code->new(jx => $jx)->record_template;
    ok( $defaults );
}

{
    my $code = Net::Journyx::Code->new(jx => $jx)->load( pretty_name => 'test code' );
    ok( $code );
    $code->delete if $code->is_loaded;
}

{
    my $code = Net::Journyx::Code->new(jx => $jx)->create( pretty_name => 'test code' );
    ok( $code );
    ok( $code->is_loaded );
    ok( $code->id );
    is( $code->pretty_name, 'test code' );

    $code->delete;
    ok( !$code->is_loaded );

    $code->load( pretty_name => 'test code' );
    ok( !$code->is_loaded );
}
