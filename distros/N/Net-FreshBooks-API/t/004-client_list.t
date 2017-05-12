#!/usr/bin/env perl

use strict;
use Test::More tests => 8;
use File::Slurp;
use Sub::Override;
use Test::XML;

use_ok 'Net::FreshBooks::API';

my @caught_out_xml = ();
my @fake_return_xml = map { read_file( $_ ) . '' } (
    't/test_data/client.list.res.xml',    #
    't/test_data/client.get.res.xml',
);

# Intercept the call to freshbooks with our own data
my $override = Sub::Override->new(
    'Net::FreshBooks::API::Base::send_xml_to_freshbooks' => sub {
        my $class = shift;
        push @caught_out_xml, shift;

        # warn $caught_out_xml[-1];
        return shift @fake_return_xml;
    }
);

my $fb = Net::FreshBooks::API->new(
    {   auth_token   => 'foo',
        account_name => 'bar',
    }
);
ok $fb, "created the FB object";

# create the list object.
my $list = $fb->client->list(
    {   email    => 'janedoe@freshbooks.com',
        username => 'janedoe',
    }
);
ok $list,     "got a list";
isa_ok $list, 'Net::FreshBooks::API::Iterator';

# check that the correct xml was sent out.
is_xml(
    $caught_out_xml[0],
    read_file( 't/test_data/client.list.req.xml' ) . '',
    "xml sent was correct for list"
);

# check that we have the correct number of results
is $list->total, 2, "got 2 entries in total";
is $list->pages, 1, "only one page of results";

# Get the first entry
my $client = $list->next;
ok $client, "got a client";

#is $client->credit, 123.45, "got correct credit";
