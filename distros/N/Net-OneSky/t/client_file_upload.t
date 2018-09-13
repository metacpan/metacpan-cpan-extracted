#!/usr/bin/env perl -Tw

use strict;
use warnings;

use Test::More tests => 5;
use Test::MockModule;
use Test::MockObject;

use Net::OneSky;

my $client;

BEGIN {
  $client = Net::OneSky->new(api_key => 'key', api_secret => 'secret');
}

{
  # Localize the module mocking, it will return to normal out of this scope.
  my $ua_module = new Test::MockModule('LWP::UserAgent');
  my $ua = Test::MockObject->new();

  $ua_module->mock('new', sub { return $ua });

  $ua->mock('agent', sub { return 'my version'});
  $ua->mock('request', sub {
    my ($self, $req) = @_;
    my $url = $req->uri;
    (my $b = "$url") =~ s{my_path.*$}{};
    my %query = $url->query_form;

    is($b, Net::OneSky::BASE_URL, 'it uses the BASE_URL');
    ok($req->content =~ m{This is a test}, 'it includes the file data in the POST content');
    ok($req->content =~ m{name="api_key"}, 'it includes the api_key in the POST content');
    ok($req->content =~ m{name="timestamp"}, 'it includes the timestamp in the POST content');
    ok($req->content =~ m{name="dev_hash"}, 'it includes the dev_hash in the POST content');
  });

  $client->file_upload('/my_path', [file => [__FILE__ . 'xt', 'file_upload.txt']]);
}

done_testing
