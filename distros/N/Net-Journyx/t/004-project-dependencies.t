#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 13;

use Net::Journyx;

my $jx = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
    username => $ENV{'JOURNYX_USER'},
    password => $ENV{'JOURNYX_PASSWORD'},
);

use Net::Journyx::Code;
use Net::Journyx::Project;

sub load_or_create_code {
    my $name = shift;

    my $code = Net::Journyx::Code->new(jx => $jx)->load( pretty_name => $name );
    unless ( $code->is_loaded ) {
        $code->create( pretty_name => $name );
    }
    return $code;
}

my $project;
{
    $project = Net::Journyx::Project->new(jx => $jx)->load( name => 'test_project' );
    ok( $project );
    unless ( $project->is_loaded ) {
        $project->create( name => 'test_project' );
        ok( $project->id );
    } else {
        ok( $project->id );
    }
}

{
    my @deps = $project->dependencies('code');
    $project->delete_dependency( code => $_ )
        foreach @deps;

    @deps = $project->dependencies('code');
    is( scalar(@deps), 0 );
}

{
    my $code = load_or_create_code('test code 1');
    $project->add_dependency( code => $code );
    my @deps = $project->dependencies('code');
    is( scalar(@deps), 1 );
    isa_ok( $deps[0], 'Net::Journyx::Code' );
    is( $deps[0]->pretty_name, 'test code 1' );

    $project->delete_dependency( code => $_ )
        foreach @deps;

    @deps = $project->dependencies('code');
    is( scalar(@deps), 0 );
}

{
    my $code1 = load_or_create_code('test code 1');
    my $code2 = load_or_create_code('test code 2');
    $project->add_dependency( code => $code1 );
    $project->add_dependency( code => $code2 );
    my @deps = $project->dependencies('code');
    is( scalar(@deps), 2 );
    isa_ok( $deps[0], 'Net::Journyx::Code' );
    isa_ok( $deps[1], 'Net::Journyx::Code' );
    like( $deps[0]->pretty_name, qr/^test code [12]$/ );
    like( $deps[1]->pretty_name, qr/^test code [12]$/ );

    $project->delete_dependency( code => $_ )
        foreach @deps;

    @deps = $project->dependencies('code');
    is( scalar(@deps), 0 );
}

