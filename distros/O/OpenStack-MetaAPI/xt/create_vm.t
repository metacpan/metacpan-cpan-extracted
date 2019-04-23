#!/usr/bin/env perl

use strict;
use warnings;
use OpenStack::MetaAPI ();

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockModule;
use JSON ();

use FindBin;
use lib "$FindBin::Bin/../t/lib";

use Test::OpenStack::MetaAPI qw{:all};

my $VALID_ID = match qr{^[a-f0-9\-]+$};

my $IMAGE_UID  = '170fafa5-1329-44a3-9c27-9bb77b77206d';
my $IMAGE_NAME = 'myimage';

# name of the VM we are creating as part of this testsuite
#my $SERVER_NAME = 'testsuite autobuild c7 11.81.9999.42';
my $SERVER_NAME = 'testsuite OpenStack::MetaAPI';

SKIP: {
    skip "OS_AUTH_URL unset, please source one openrc.sh file before."
      unless $ENV{OS_AUTH_URL};

    mock_lwp_useragent();    # allow some debug output
                             #$Test::OpenStack::MetaAPI::UA_DISPLAY_OUTPUT = 1;

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

    {
        note "delete servers from previous run";
        delete_test_servers($api);
    }

    {
        note "create a server from one image";

        my $vm = $api->create_vm(
            name     => $SERVER_NAME,        # vm name
            image    => $IMAGE_UID,          # image used to create the VM
            flavor   => 'small',
            key_name => 'openStack nico',    # optional key to set
              #security_group => 'default', # security group to use, by default use 'default'
            network => 'Dev Infra initial gre network',   # network group to use
                 # or network  => qr{Dev Infra}',
                 # or network  => 'fb5c81fd-0a05-46bc-8a7e-cb94dc851bb4 ',

            #--network fb5c81fd-0a05-46bc-8a7e-cb94dc851bb4
            #wait => 1,
            network_for_floating_ip => 'vlan3340-product',

        );

        #note explain $vm;

        like $vm, hash {
            field id                  => $VALID_ID;
            field name                => $SERVER_NAME;
            field floating_ip_address => match qr/^\d+\.\d+\.\d+\.\d+$/a;
            field floating_ip_id      => $VALID_ID;
            field status              => 'ACTIVE';
            etc;
        }, "created a vm with a floating ip" or diag explain $vm;
    }

    # for now keep the server alive so we can play with it...
    #note "delete_test_servers after test";
    #delete_test_servers( $api );
}

done_testing;
exit;

sub delete_test_servers {
    my ($api) = @_;

    my @servers = $api->servers(name => $SERVER_NAME);
    foreach my $server (@servers) {
        next unless defined $server->{id} && length $server->{id};
        note "delete server - ", "id: ", $server->{id}, " ; name: ",
          $server->{name};

        $api->delete_server($server->{id});
    }

    return;
}

__END__

