#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 12;

use Net::Journyx;

my $jx = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
    username => $ENV{'JOURNYX_USER'},
    password => $ENV{'JOURNYX_PASSWORD'},
);

use Net::Journyx::Attribute;
use Net::Journyx::Project;


my $attr_ticket_id;
{
    my $project = Net::Journyx::Project->new(jx => $jx);
    $attr_ticket_id = Net::Journyx::Attribute->new(jx => $jx);
    $attr_ticket_id->load( object => $project, name => 'ticket #' );
    if ( $attr_ticket_id->is_loaded ) {
        ok(1);
    } else {
        $attr_ticket_id->create( object => $project, name => 'ticket #', type => 'NUMBER' );
        ok(1)
    }
    ok( $attr_ticket_id->is_loaded );
    is( $attr_ticket_id->data_type, 'NUMBER' );
}

my $attr_ticket_status;
{
    my $project = Net::Journyx::Project->new(jx => $jx);
    $attr_ticket_status = Net::Journyx::Attribute->new(jx => $jx);
    $attr_ticket_status->load( object => $project, name => 'ticket status' );
    if ( $attr_ticket_status->is_loaded ) {
        ok(1);
    } else {
        $attr_ticket_status->create( object => $project, name => 'ticket status', type => 'STRING' );
        ok(1)
    }
    ok( $attr_ticket_status->is_loaded );
    is( $attr_ticket_status->data_type, 'STRING' );
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
    $project->set_attributes( 'ticket #' => 1, 'ticket status' => 1 );
    is( $project->get_attribute('ticket #'), 1 );
    is( $project->get_attribute('ticket status'), 1 );

    # try to set only one attribute
    $project->set_attributes( 'ticket #' => 2 );
    is( $project->get_attribute('ticket #'), 2 );
}


