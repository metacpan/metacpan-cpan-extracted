#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::Net::Async::Webservice::DHL;
use Net::Async::Webservice::DHL::Address;
use Test::Net::Async::Webservice::DHL::Factory;

my ($dhl,$loop) = Test::Net::Async::Webservice::DHL::Factory::from_config_sync;

Test::Net::Async::Webservice::DHL::test_it($dhl);

subtest 'connection failures' => sub {
    $dhl->{base_url} = 'http://bad.hostname/';
    $dhl->get_capability({
        from => Net::Async::Webservice::DHL::Address->new(country_code=>'UK'),
        to => Net::Async::Webservice::DHL::Address->new(country_code=>'IT'),
        is_dutiable => 0,
        product_code => 'N',
        currency_code => 'GBP',
        shipment_value => 1,
    })->then(
        sub { my ($response) = @_;
              fail "it connected to a non-existing host?";
              Future->wrap();
          },
        sub { my ($fail) = @_;
              cmp_deeply($fail,
                         all(
                             isa('Net::Async::Webservice::Common::Exception::HTTPError'),
                             methods(
                                 request => isa('HTTP::Request'),
                                 response => isa('HTTP::Response'),
                             ),
                         ),
                         'correctly failed to connect',
                     );
              Future->wrap();
          },
    )->get;
};

done_testing();
