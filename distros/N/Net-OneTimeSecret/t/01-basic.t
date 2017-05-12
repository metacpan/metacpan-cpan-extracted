#!/usr/bin/env perl

use lib 'lib';

use Net::OneTimeSecret;
use utf8;

use common::sense;
use Test::More tests => 14;

my $customerId  = 'apitest-perl@onetimesecret.com';
my $testApiKey  = 'df0de769899e5464cb70754ea4494aec1b7de7fb';

my $api = Net::OneTimeSecret->new( $customerId, $testApiKey );

my $response = $api->shareSecret("My hovercraft is full of eels.");
ok( $response && $response->{created}, "Created new secret" );

my $secretKey = $response->{secret_key};
my $metadataKey = $response->{metadata_key};
ok( $secretKey && $metadataKey, "Retrieved keys for new secret" );

my $metadata = $api->retrieveMetadata( $metadataKey );
ok( $metadata && $metadata->{created}, "Metadata retrieved" );

# status
my $status = $api->status();
ok( $status && $status->{status} eq 'nominal', "Status OK" );

# generate
my $gen = $api->generateSecret();
ok( $gen && $gen->{value}, "Generated secret" );

my $retrieved = $api->retrieveSecret( $secretKey );
ok( $retrieved && $retrieved->{value} eq "My hovercraft is full of eels.", "Secret retrieved successfully" );


my $metadata = $api->retrieveMetadata( $metadataKey );
ok( $metadata && $metadata->{created}, "Metadata retrieved" );

my $retrievedAgain = $api->retrieveSecret( $secretKey );
ok( !exists $retrievedAgain->{value} && $retrievedAgain->{message} eq "Unknown secret", "Unable to retrieve message twice" );

# Let's try some unicode
my $unicode = $api->shareSecret( "˙sʃǝǝ ɟo ʃʃnɟ sı ʇɟɐɹɔɹǝʌoɥ ʎW" );
ok( $unicode && $unicode->{created}, "Created shared secret from unicode.");

my $ru = $api->retrieveSecret( $unicode->{secret_key} );
ok( $ru && $ru->{value} eq "˙sʃǝǝ ɟo ʃʃnɟ sı ʇɟɐɹɔɹǝʌoɥ ʎW", "Retrieved unicode secret." );

$ru = $api->retrieveSecret( $unicode->{secret_key} );
ok( $ru && $ru->{message} eq "Unknown secret", "Couldn't retrieve secret twice." );

# passphrase?
$response = $api->shareSecret( "Our chief weapon is surprise.", passphrase => "herring" );
ok( $response && $response->{secret_key}, "Created secret with passphrase." );

$retrieved = $api->retrieveSecret( $response->{secret_key} );
ok( $retrieved && ! $retrieved->{value}, "Couldn't retrieve value of secret without passphrase." );

$retrieved = $api->retrieveSecret( $response->{secret_key}, passphrase => "herring" );
ok( $retrieved && $retrieved->{value} eq "Our chief weapon is surprise.", "Retrieved using passphrase" );
