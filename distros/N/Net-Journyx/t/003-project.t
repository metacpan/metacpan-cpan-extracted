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

use Net::Journyx::Project;

{
    my $project = Net::Journyx::Project->new(jx => $jx)->load( name => 'test_project' );
    ok( $project );
    $project->delete if $project->is_loaded;
}

{
    my $project = Net::Journyx::Project->new(jx => $jx)->create( name => 'test_project' );
    ok( $project );
    is( $project->name, 'test_project' );
    is( $project->type, 1 );
    $project->delete;
}

