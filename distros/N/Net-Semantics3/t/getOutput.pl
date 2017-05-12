#!/usr/bin/env perl
use Net::Semantics3::Products;
use Data::Dumper;

#curl -X POST -H "api_key: SEM3XXXXXXXXXXXXXXXXXXX" --data-urlencode 'q={'webhook_uri':'http://mydomain.com:12167/sem3PriceWebhooks'}' https://api.semantics3.com/v1/webhooks/register

# Your Semantics3 API Credentials
#my $api_key = "SEM3F6AD9394E42AD5F180703CFCBE1D5BD8";
#my $api_secret = "MGJhYjJhMjZhY2NjZjNkZWIzOGFkMWFhMzI5ZGIzZGY";
my $api_key = "SEM366B1BA4C036941B5F1B827C9A3CF6775";
my $api_secret = "MGIxNzM3NjE5YzdlZGYzYjg3OGNkZDBiM2NkODUwYWM";

# Set up a client to talk to the Semantics3 API
my $sem3 = Net::Semantics3::Products->new (
  api_key => $api_key,
  api_secret => $api_secret,
#  api_base => "https://api-staging.semantics3.com/v1",
);

#Webhooks
#$sem3->add( "webhooks/register", "webhook_uri", "http://mydomain.com:12167/sem3PriceWebhooks" );
#my $webHooksRef = $sem3->run_query("webhooks/register",undef,"POST");
#print STDERR Dumper( $webHooksRef );

$sem3->add( "products", "search", "iphone");
my $searchRef = $sem3->run_query("products",undef,"GET");
print STDERR Dumper( $searchRef );
