#!/usr/bin/env perl

use strict;
use Data::Dump qw( dump );
use Test::More;
use File::Slurp;
use Sub::Override;
use Test::XML;

use_ok 'Net::FreshBooks::API';

my @caught_out_xml = ();
my @fake_return_xml = map { read_file( $_ ) . '' } (
    't/test_data/invoice.create.res.xml',
    't/test_data/invoice.get.res.xml'
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

my $invoice = $fb->invoice( { client_id => 1 } );
ok $invoice,     "Got a invoice back";
isa_ok $invoice, 'Net::FreshBooks::API::Invoice';

ok $invoice->add_line(
    {   name      => "Test line 1",
        unit_cost => 1,
        quantity  => 1,
    }
    ),
    "Add first line to the invoice";

ok $invoice->add_line(
    {   name      => "Test line 2",
        unit_cost => 2,
        quantity  => 2,
    }
    ),
    "Add second line to the invoice";

ok $invoice->create, "create the invoice";

# Check that the xml sent was correct.
is_xml(
    $caught_out_xml[0],
    read_file( 't/test_data/invoice.create.req.xml' ) . '',
    "xml sent was correct for create"
);
is_xml(
    $caught_out_xml[1],
    read_file( 't/test_data/invoice.get.req.xml' ) . '',
    "xml sent was correct for get"
);

# fail "check lines loaded correctly";

ok $invoice->lines, "loaded lines from response";

is $invoice->lines->[0]->name, 'Test line 1', "got first line";
is $invoice->amount, 5, "amount is correct";

is $invoice->status, 'draft', 'status is correct';

is $invoice->links->client_view,
    'https://hinuhinutest.freshbooks.com/inv/106252-2-80cad',
    "client_view correct";

ok( $invoice->die_on_server_error, "invoice will die" );

$invoice->die_on_server_error( 0 );
ok( !$invoice->die_on_server_error, "die on error turned off" );

done_testing();
