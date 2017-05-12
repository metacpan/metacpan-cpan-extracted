#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 17;

use Net::Journyx;

my $jx = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
    username => $ENV{'JOURNYX_USER'},
    password => $ENV{'JOURNYX_PASSWORD'},
);

use Net::Journyx::Attribute;
use Net::Journyx::Project;


{
    my $attr = Net::Journyx::Attribute->new(jx => $jx);
    ok( $attr );
    my $list = $attr->valid_object_types;
    ok( scalar(@$list) );
}

{
    my $attr = Net::Journyx::Attribute->new(jx => $jx);
    ok( $attr );
    ok( $attr->is_valid_type('INTEGER') );
    ok( $attr->is_valid_type('NUMBER') );
    ok( $attr->is_valid_type('DATE') );
    ok( $attr->is_valid_type('STRING') );
    ok( $attr->is_valid_type('CHAR') );
    ok( !$attr->is_valid_type('some crazy type') );
}

my $attr;
{
    my $project = Net::Journyx::Project->new(jx => $jx);
    $attr = Net::Journyx::Attribute->new(jx => $jx);
    $attr->load( object => $project, name => 'ticket #' );
    if ( $attr->is_loaded ) {
        ok(1);
    } else {
        $attr->create( object => $project, name => 'ticket #', type => 'NUMBER' );
        ok(1)
    }
    ok( $attr->is_loaded );
    is( $attr->data_type, 'NUMBER' );
}

{
    my $project = Net::Journyx::Project->new(jx => $jx)->load( name => 'test_project' );
    ok( $project );
    $project->delete if $project->is_loaded;
}

{
    my $project = Net::Journyx::Project->new(jx => $jx)->create( name => 'test_project' );
    ok( $project );

    is( $project->get_attribute('ticket #'), undef );
        $project->set_attribute('ticket #', 1 );
    is( $project->get_attribute('ticket #'), 1 );
        $project->del_attribute('ticket #');
    is( $project->get_attribute('ticket #'), undef );
}

