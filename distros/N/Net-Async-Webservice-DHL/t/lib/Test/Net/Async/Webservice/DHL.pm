package Test::Net::Async::Webservice::DHL;
use strict;
use warnings;
use Test::Most;
use Test::File::ShareDir -share => {
    -dist => { 'Net-Async-Webservice-DHL' => 'share/' },
};
use Data::Printer;
use Net::Async::Webservice::DHL::Address;

sub conf_file {
    my $dhlrc = $ENV{NAWS_DHL_CONFIG} || File::Spec->catfile($ENV{HOME}, '.naws_dhl.conf');
    if (not -r $dhlrc) {
        plan(skip_all=>'need a ~/.naws_dhl.conf file, or a NAWS_DHL_CONFIG env variable pointing to a valid config file');
        exit(0);
    }
    return $dhlrc;
}

sub test_it {
    my ($dhl) = @_;

    subtest 'setting live / testing' => sub {
        is($dhl->live_mode,0,'starts in testing');
        my $test_url = $dhl->base_url;

        $dhl->live_mode(1);
        is($dhl->live_mode,1,'can be set live');
        isnt($dhl->base_url,$test_url,'live proxy different than test one');

        $dhl->live_mode(0);
        is($dhl->live_mode,0,'can be set back to testing');
        is($dhl->base_url,$test_url,'test proxy same as before');
    };

    subtest 'capability' => sub {
        my $from = Net::Async::Webservice::DHL::Address->new({
            country_code => 'GB',
            postal_code => 'SE7 7RU',
            city => 'London',
        });
        my $to = Net::Async::Webservice::DHL::Address->new({
            country_code => 'DE',
            postal_code => '40217',
            city => "D\x{fc}sseldorf",
        });

        $dhl->get_capability({
            from => $from,
            to => $to,
            is_dutiable => 0,
            currency_code => 'GBP',
            shipment_value => 100,
        })->then(
            sub {
                my ($response) = @_;
                cmp_deeply(
                    $response,
                    {
                        GetCapabilityResponse => {
                            BkgDetails => [{
                                DestinationServiceArea => {
                                    FacilityCode    => "DUS",
                                    ServiceAreaCode => "DUS"
                                },
                                OriginServiceArea      => {
                                    FacilityCode    => "LCY",
                                    ServiceAreaCode => "LCY"
                                },
                                QtdShp => ignore(),
                            }],
                            Response => ignore(),
                            Srvs => {
                                Srv => superbagof(
                                    {
                                        GlobalProductCode => 'K',
                                        MrkSrv => ignore(),
                                    },
                                    {
                                        GlobalProductCode => 'C',
                                        MrkSrv => ignore(),
                                    },
                                    {
                                        GlobalProductCode => 'T',
                                        MrkSrv => ignore(),
                                    },
                                    {
                                        GlobalProductCode => 'U',
                                        MrkSrv => ignore(),
                                    },
                                ),
                            },
                        },
                    },
                    'response is shaped ok',
                );
                return Future->wrap();
            }
        )->get;

        $dhl->get_capability({
            from => $from,
            to => $to,
            is_dutiable => 0,
            product_code => 'C',
            currency_code => 'GBP',
            shipment_value => 100,
        })->then(
            sub {
                my ($response) = @_;
                cmp_deeply(
                    $response,
                    {
                        GetCapabilityResponse => {
                            BkgDetails => [{
                                DestinationServiceArea => {
                                    FacilityCode    => "DUS",
                                    ServiceAreaCode => "DUS"
                                },
                                OriginServiceArea      => {
                                    FacilityCode    => "LCY",
                                    ServiceAreaCode => "LCY"
                                },
                                QtdShp => ignore(),
                            }],
                            Response => ignore(),
                            Srvs => {
                                Srv => [
                                    superhashof({
                                        GlobalProductCode => 'C',
                                        MrkSrv => ignore(),
                                    }),
                                ],
                            },
                        },
                    },
                    'response with product_code is shaped ok',
                );
                return Future->wrap();
            }
        )->get;
    };

    subtest 'capability, bad address' => sub {
        my $from = Net::Async::Webservice::DHL::Address->new({
            country_code => 'GB',
            postal_code => 'SE7 7RU',
            city => 'London',
        });
        my $to = Net::Async::Webservice::DHL::Address->new({
            country_code => 'GB',
            postal_code => 'XX7 6YY',
            city => 'NotExisting',
        });

        $dhl->get_capability({
            from => $from,
            to => $to,
            is_dutiable => 0,
            currency_code => 'GBP',
            shipment_value => 100,
        })->then(
            sub {
                my ($response) = @_;
                cmp_deeply(
                    $response,
                    {
                        GetCapabilityResponse => {
                            Note => [{
                                Condition => [{
                                    ConditionCode => any(3006,3021),
                                    ConditionData => ignore(),
                                }],
                            }],
                            Response => ignore(),
                        },
                    },
                    'response signals address failure',
                );
                return Future->wrap();
            }
        )->get;
    };

    subtest 'route request' => sub {
        my $addr = Net::Async::Webservice::DHL::Address->new({
            country_code => 'GB',
            postal_code => 'SE7 7RU',
            city => 'London',
        });

        $dhl->route_request({
            region_code => 'EU',
            address => $addr,
            routing_type => 'D',
            origin_country_code => 'GB',
        })->then(
            sub {
                my ($response) = @_;
                cmp_deeply(
                    $response,
                    {
                        RegionCode => 'EU',
                        GMTNegativeIndicator => 'N',
                        GMTOffset => any('01:00','00:00'),
                        ServiceArea => {
                            ServiceAreaCode => 'LCY',
                            Description => ignore(),
                        },
                        Response => ignore(),
                    },
                    'response is shaped ok',
                );
                return Future->wrap();
            },
            sub {
                note p @_;
                fail 'Got an error response';
                return Future->wrap();
            },
        )->get;

        $addr = Net::Async::Webservice::DHL::Address->new({
            country_code => 'GB',
            postal_code => 'XX1 2YY',
            city => 'London',
        });

        $dhl->route_request({
            region_code => 'EU',
            address => $addr,
            routing_type => 'D',
            origin_country_code => 'GB',
        })->then(
            sub {
                note p @_;
                fail 'Got a non-error response';
                return Future->wrap();
            },
            sub {
                my ($exception) = @_;
                cmp_deeply(
                    $exception,
                    all(
                        isa('Net::Async::Webservice::DHL::Exception::DHLError'),
                        methods(
                            error => superhashof({
                                Condition => superbagof(
                                    map { superhashof({ConditionCode=>$_}) }
                                        qw(RT0007 RT0004),
                                ),
                            }),
                        ),
                    ),
                    'exception is shaped ok',
                );
                return Future->wrap();
            }
        )->get;
    };
}

1;
