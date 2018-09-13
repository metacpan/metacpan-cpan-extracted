#!/usr/bin/env perl -Tw

use strict;
use warnings;

use Test::More tests => 8;
use Test::MockModule;
use Test::MockObject;

use Net::OneSky;

my $client;
my $with_base;
my $base_url;

BEGIN {
  # Define this inside the BEGIN block
  $base_url = 'http://base.url/';
  $client = Net::OneSky->new(api_key => 'key', api_secret => 'secret');
  $with_base = Net::OneSky->new(api_key => 'key', api_secret => 'secret', base_url => URI->new($base_url));
}

{
  # Localize the module mocking, it will return to normal out of this scope.
  my $ua_module = new Test::MockModule('LWP::UserAgent');
  my $ua = Test::MockObject->new();

  $ua_module->mock('new', sub { return $ua });
  $ua->mock('agent', sub { return 'my version'});

  foreach my $tuple ([$client, Net::OneSky::BASE_URL, ''], [$with_base, $base_url, 'out']) {
    my ($c, $base, $type) = @$tuple;

    $ua->mock('request', sub {
      my ($self, $req) = @_;
      my $url = $req->uri;
      (my $b = "$url") =~ s{my_path.*$}{};
      my %query = $url->query_form;

      is($b, $base, "it uses the base_url with$type passed base URL");
      is($query{api_key}, 'key', "it passes the api_key as a query param with$type passed base URL");
      ok($query{timestamp} =~ /^\d{10,}$/, "it passes a numeric timestamp with$type passed base URL");
      ok($query{dev_hash} =~ /^[\da-f]{32}$/, "it passes a hex MD5 dev_hash with$type passed base URL");
    });

    $c->get('/my_path');
  }
}

done_testing
