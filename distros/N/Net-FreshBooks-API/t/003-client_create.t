#!/usr/bin/env perl

use strict;
use Data::Dump qw( dump );
use Test::More;
use File::Slurp;
use Sub::Override;
use Test::XML;

use_ok 'Net::FreshBooks::API';

my $client_create_args = {
    first_name   => 'Jane',
    last_name    => 'Doe',
    organization => 'ABC Corp',
    email        => 'janedoe@freshbooks.com',
    username     => 'janedoe',
    password     => 'seCret!7',
    work_phone   => '(555) 123-4567',
    home_phone   => '(555) 234-5678',
    mobile       => undef,
    fax          => undef,
    notes        => undef,
    p_street1    => '123 Fake St.',
    p_street2    => 'Unit 555',
    p_city       => 'New York',
    p_state      => 'New York',
    p_country    => 'United States',
    p_code       => '553132',
    s_street1    => undef,
    s_street2    => undef,
    s_city       => undef,
    s_state      => undef,
    s_country    => undef,
    s_code       => undef,
};

my @caught_out_xml = ();
my @fake_return_xml = map { read_file( $_ ) . '' }
    ( 't/test_data/client.create.res.xml', 't/test_data/client.get.res.xml' );

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

foreach my $method ( sort keys %{ $fb->client->_fields() } ) {
    can_ok( $fb->client, $method );
}

my $client = $fb->client->create( $client_create_args );
ok $client,     "Got a client back";
isa_ok $client, 'Net::FreshBooks::API::Client';

# Check that the xml sent was correct.
is_xml(
    $caught_out_xml[0],
    read_file( 't/test_data/client.create.req.xml' ) . '',
    "xml sent was correct for create"
);
is_xml(
    $caught_out_xml[1],
    read_file( 't/test_data/client.get.req.xml' ) . '',
    "xml sent was correct for get"
);

# add in bits that would have been missing on create
$client_create_args = {
    client_id => 13,
    credit    => 123.45,
    %$client_create_args,

};

# we don't get sent the password.
delete $client_create_args->{password};

# change all the undefs to ''
$_ ||= '' for values %$client_create_args;

foreach my $key ( $client->field_names ) {
    next unless exists $client_create_args->{$key};
    is $client->$key, $client_create_args->{$key},
        "got correct value for $key";
}

# Check that the links got created correctly
is $client->links->client_view,
    'https://sample.freshbooks.com/client/12345-1-98969',
    "client_view correct";

done_testing();
