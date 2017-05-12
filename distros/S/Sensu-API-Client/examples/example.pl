#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Try::Tiny;
use Sensu::API::Client;

#my $api = Sensu::API::Client->new(url => 'http://user:pass@host:port');
my $api = Sensu::API::Client->new(url => $ENV{SENSU_API_URL});

# Retrieve current events
my $events = $api->events;
foreach my $e (@$events) {
    printf("%s, %s, %d\n", $e->{client}, $e->{check}, $e->{status});

    # Resolve them
    $api->resolve($e->{client}, $e->{check});
}

# Retrieve envents for a single client
my $client_events = $api->events('my-client');

# Get a list of clients
my $clients = $api->clients;
foreach my $c (@$clients) {
    printf("%s, %s\n", $c->{name}, $c->{address});
}

# Get a single client
my $client;
try {
    # Some methods throw an exception if the object is not found
    $client = $api->client('my-client');
} catch {
    if ($_ =~ /404/) {
        warn 'my-client not found';
    } else {
        warn "Something bad happened: $_";
    }
};

# Get check result history for a client
my $hist = $api->client_history('my-client');

# Delete it
try {
    $api->delete_client('my-client');
} catch {
    if ($_ =~ /404/) {
        warn 'my-client not found';
    } else {
        warn "Something bad happened: $_";
    }
};

# Get info about the API service
my $info = $api->info;
printf(
    "Rabbit connected: %s\nRedis connected: %s\nSensu version: %s\n",
    $info->{rabbitmq}->{connected},
    $info->{redis}->{connected},
    $info->{sensu}->{version},
);

# Create stashes
$api->create_stash(
    path    => '/example/path',
    content => { key => 'value' },
    expire  => 60,    # optional
);

# List and delete
my $stashes = $api->stashes;
$api->delete_stash('/example/path');
