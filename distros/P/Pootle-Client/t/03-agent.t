# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use FindBin;
use lib "$FindBin::Bin/../";
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Data::Dumper;

use Test::More;
use Test::Exception;
use Test::MockModule;

use t::Mock::Client;
use t::Mock::Agent;


subtest "Pootle::Client connection to nowhere", \&nowhere;
sub nowhere {
  my ($papi);
  eval {

  ok($papi = t::Mock::Client::new('http://www.example.com', 'user:pass'),
    "Given a Pootle::Client connection to nowhere");

  throws_ok(sub {
      $papi->store('/api/v1/stores/7578/');
    }, 'Pootle::Exception::HTTP::NotFound',
    "Then nothing was found from nowhere");

  };
  if ($@) {
    ok(0, $@);
  }
};

subtest "Pootle::Client mocked HTTP::Response", \&mockResponse;
sub mockResponse {
  my ($papi, $store);
  eval {

  t::Mock::Agent::beginMockingWithResponse(200, 'OK', undef, '{"file": "/media/17.05/fi/fi-FI-marc-MARC21.po", "name": "fi-FI-marc-MARC21.po", "pending": null, "pootle_path": "/fi/17.05/fi-FI-marc-MARC21.po", "resource_uri": "/api/v1/stores/7578/", "state": 2, "sync_time": "2017-10-15T10:37:00", "tm": null, "translation_project": "/api/v1/translation-projects/1185/", "units": ["/api/v1/units/20043947/", "/api/v1/units/20043948/", "/api/v1/units/20043949/", "/api/v1/units/20043950/"]}');

  ok($papi = t::Mock::Client::new('http://www.example.com', 'user:pass'),
    "Given a Pootle::Client connection with a mocked response");

  ok($store = $papi->store('/api/v1/stores/7578/'),
     "When a store is fetched");

  is($store->file, "/media/17.05/fi/fi-FI-marc-MARC21.po",
     "Then we received the store we expected");

  };
  if ($@) {
    ok(0, $@);
  }
  t::Mock::Agent::stopMocking();
}

done_testing();
