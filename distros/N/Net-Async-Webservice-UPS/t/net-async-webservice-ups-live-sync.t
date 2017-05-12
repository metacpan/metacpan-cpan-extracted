#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::Net::Async::Webservice::UPS;
use Test::Net::Async::Webservice::UPS::Factory;

my ($ups,$ua) = Test::Net::Async::Webservice::UPS::Factory::from_config_sync;

Test::Net::Async::Webservice::UPS::test_it($ups);

subtest 'connection failures' => sub {
    $ups->{base_url} = 'http://bad.hostname/';
    $ups->validate_address('1234')->then(
        sub { my ($response) = @_;
              fail "it connected to a non-existing host?";
              Future->wrap();
          },
        sub { cmp_deeply(\@_,
                         [ all(
                             isa('Net::Async::Webservice::Common::Exception::HTTPError'),
                             methods(
                                 request => isa('HTTP::Request'),
                                 response => isa('HTTP::Response'),
                             ),
                         ),'webservice'],
                         'correctly failed to connect',
                     );
              Future->wrap();
          },
    )->get;
};

done_testing();
