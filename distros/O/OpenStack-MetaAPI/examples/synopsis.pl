#!/usr/bin/env perl

use strict;
use warnings;

use OpenStack::MetaAPI ();

use Test::More;

SKIP: {
    skip "OS_AUTH_URL unset, please source one openrc.sh file before."
      unless $ENV{OS_AUTH_URL} && $ENV{AUTHOR_TESTING};

    # create one OpenStack::MetaAPI object
    #	this is using OpenStack::Client::Auth
    my $api = OpenStack::MetaAPI->new(
        $ENV{OS_AUTH_URL},
        username => $ENV{'OS_USERNAME'},
        password => $ENV{'OS_PASSWORD'},
        version  => 3,
        scope    => {
            project => {
                name   => $ENV{'OS_PROJECT_NAME'},
                domain => {id => 'default'},
            }
        },
    );

   # OpenStack API documentation:
   #	https://developer.openstack.org/api-guide/quick-start/#current-api-versions

    #
    # You can call most routes direclty on the main API object
    #	 without the need to know which service is providing it
    #

    # list all flavors
    my @flavors      = $api->flavors();
    my $small        = $api->flavors(name => 'small');
    my @some_flavors = $api->flavors(name => qr{^(?:small|medium)});

    # list all servers
    my @servers = $api->servers();

    # filter the server result using any keys
    # Note: known API valid request arguments are used as part of the request
    @servers = $api->servers(name => 'foo');

    # can also use a regex
    @servers = $api->servers(name => qr{^foo});

    # get a single server by one id
    my $SERVER_ID = q[aaaa-bbbb-cccc-dddd];
    my $server    = $api->server_from_uid($SERVER_ID);

    # delete a server [also delete associated floating IPs]
    $api->delete_server($SERVER_ID);

    # listing floating IPs
    my @floatingips = $api->floatingips();

    # listing all images is currently not supported
    #	[slow as multiple requests are require 'next']
    # prefer selecting one image using one of these two helpers
    my $IMAGE_UID  = '1111-2222-3456';
    my $image      = $api->image_from_uid($IMAGE_UID);
    my $IMAGE_NAME = 'MyCustomImage';
    $image = $api->image_from_name($IMAGE_NAME);

    my @security_groups = $api->security_groups();

    my $SECURITY_GROUP_ID = '12345';

    my $security_group = $api->security_groups(id => $SECURITY_GROUP_ID);
    $security_group = $api->security_groups(name => 'default');

    # you can also create one server using the create_vm helper

    my $vm = $api->create_vm(
        name     => 'SERVER_NAME',
        image    => 'IMAGE_UID or IMAGE_NAME',    # image used to create the VM
        flavor   => 'small',
        key_name => 'your ssh key name',          # optional key to set
        security_group =>
          'default',    # security group to use, by default use 'default'
        network => 'NETWORK_NAME or NETWORK_ID',    # network group to use
        network_for_floating_ip => 'NETWORK_NAME or NETWORK_ID',
    );

}

1;
