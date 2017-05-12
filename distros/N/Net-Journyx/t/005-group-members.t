#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 4;

use Net::Journyx;

my $jx = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
    username => $ENV{'JOURNYX_USER'},
    password => $ENV{'JOURNYX_PASSWORD'},
);

use Net::Journyx::Code;
use Net::Journyx::Group;

{
    my $group = Net::Journyx::Group->new(jx => $jx);
    my @list = $group->object_classes;
}

my $code;
{
    $code = Net::Journyx::Code->new(jx => $jx)->load( pretty_name => 'test code' );
    ok( $code );
    unless ( $code->is_loaded ) {
        $code->create( pretty_name => 'test code' );
    }
}

my $group;
{
    $group = Net::Journyx::Group->new(jx => $jx)->load( name => 'test group' );
    ok( $group );
    unless ( $group->is_loaded ) {
        $group->create( name => 'test group' );
    }
}

{ # clean group
    my @list = $group->codes;
    $group->delete_code( $_ ) foreach @list;
}

{
    $group->add_code( $code );
    my @list = $group->codes;
    is( scalar(@list), 1 );
    is( $list[0], $code->id );
    $group->delete_code( $code );
}

