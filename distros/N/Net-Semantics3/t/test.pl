#!/usr/bin/env perl
use Net::Semantics3::Products;
use Data::Dumper;
use JSON::XS;

#curl -X POST -H "api_key: SEM3XXXXXXXXXXXXXXXXXXX" --data-urlencode 'q={'webhook_uri':'http://mydomain.com:12167/sem3PriceWebhooks'}' https://api.semantics3.com/v1/webhooks/register

# Your Semantics3 API Credentials
#my $api_key = "SEM3F6AD9394E42AD5F180703CFCBE1D5BD8";
#my $api_secret = "MGJhYjJhMjZhY2NjZjNkZWIzOGFkMWFhMzI5ZGIzZGY";
my $api_key = "SEM345BFBA4CDF78B1D2DF81A74A99749EBE";
my $api_secret = "YmU0ZjNhM2Y3MjE2MzliY2FiMGUzZGI1YzAzODQ4MDc";

# Set up a client to talk to the Semantics3 API
my $sem3 = Net::Semantics3::Products->new (
  api_key => $api_key,
  api_secret => $api_secret,
#  api_base => "https://api.semantics3.com/v1/",
);

#Webhooks
#$sem3->add( "webhooks/register", "webhook_uri", "http://mydomain.com:12167/sem3PriceWebhooks" );
#my $webHooksRef = $sem3->run_query("webhooks/register",undef,"POST");
#print STDERR Dumper( $webHooksRef );

#get all webhooks
#my $res = $sem3->run_query("webhooks", undef, "GET");
#print STDERR Dumper( $res ), "\n";

#to remove a webhook
#my $webhook_id = "7yX7Gdjt";
#my $endpoint = "webhooks/" . $webhook_id ;
#my $res = $sem3->run_query( $endpoint, undef, "DELETE" );
#print STDERR Dumper( $res );

#to create webhook
#my $params = { webhook_uri => "http://148.251.44.168:5000" }; 
#my $res = $sem3->run_query("webhooks", $params, "POST");
#print STDERR Dumper( $res ), "\n";

#my $params = {
#    "type" => "price.change",
#    "product" => {
#        "sem3_id" => "1QZC8wchX62eCYS2CACmka"
#    },
#    "constraints" => {
#        "gte" => 10,
#        "lte" => 100
#    }
#};
#
#my $webhook_id = "X1fXEdit";
#my $endpoint = "webhooks/" . $webhook_id . "/events";
#
#my $res = $sem3->run_query( $endpoint, $params, "POST" );
#print STDERR Dumper( $res ), "\n";

my $webhook_id = "7JcGN81u";
my $endpoint = "webhooks/" . $webhook_id . "/events";

my $res = $sem3->run_query($endpoint, undef, "GET");
