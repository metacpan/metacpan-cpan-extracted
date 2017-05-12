#!/usr/bin/perl

use strict;
use warnings;

use Net::FreshBooks::API;
use Net::FreshBooks::API::InvoiceLine;
use DateTime;

# auth_token and account_name come from FreshBooks
my $fb = Net::FreshBooks::API->new(
    {   auth_token   => 'd2d6c5a50b023d95e1c804416d1ec15d',
        account_name => 'netfreshbooksapi',
    }
);

# find the first client
my $client = $fb->client->list->next;

# create a recurring item

my $line = Net::FreshBooks::API::InvoiceLine->new({
    name         => "Widget",
    description  => "Net::FreshBooks::API Widget",
    unit_cost    => '1.99',
    quantity     => 1,
    tax1_name    => "GST",
    tax1_percent => 5,
});

my $recurring_item = $fb->recurring->create({
    client_id   => $client->client_id,
    date        => DateTime->now->add( days => 2 )->ymd, # YYYY-MM-DD
    frequency   => 'monthly',
    lines       => [ $line ],
    notes       => 'Created by Net::FreshBooks::API',
});

$recurring_item->po_number( 999 );
$recurring_item->update;

print "recurring item id: " . $recurring_item->recurring_id . "\n";