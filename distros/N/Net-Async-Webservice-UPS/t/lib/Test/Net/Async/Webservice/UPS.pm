package Test::Net::Async::Webservice::UPS;
use strict;
use warnings;
use Test::Most;
use Data::Printer;
use Net::Async::Webservice::UPS::Package;
use Net::Async::Webservice::UPS::Address;
use Net::Async::Webservice::UPS::Payment;
use Net::Async::Webservice::UPS::Shipper;
use Net::Async::Webservice::UPS::QVSubscription;

sub conf_file {
    my $upsrc = $ENV{NAWS_UPS_CONFIG} || File::Spec->catfile($ENV{HOME}, '.naws_ups.conf');
    if (not -r $upsrc) {
        plan(skip_all=>'need a ~/.naws_ups.conf file, or a NAWS_UPS_CONFIG env variable pointing to a valid config file');
        exit(0);
    }
    return $upsrc;
}

sub package_comparator {
    my (@p) = @_;

    return map {
        my $p = $_;
        all(
            isa('Net::Async::Webservice::UPS::Package'),
            methods(
                map { $_ => $p->$_ } qw(length width height weight packaging_type linear_unit weight_unit)
            )
        );
    } @p;
}

my $file_for_next_test = sub {
    my ($ua,$file) = @_;
    if ($ua->can('file_for_next_test')) {
        $ua->file_for_next_test($file);
    }
    return;
};

sub test_it {
    my ($ups) = @_;

    subtest 'setting live / testing' => sub {
        is($ups->live_mode,0,'starts in testing');
        my $test_url = $ups->base_url;

        $ups->live_mode(1);
        is($ups->live_mode,1,'can be set live');
        isnt($ups->base_url,$test_url,'live proxy different than test one');

        $ups->live_mode(0);
        is($ups->live_mode,0,'can be set back to testing');
        is($ups->base_url,$test_url,'test proxy same as before');
    };

    my @postal_codes = ( 15241, 48823 );
    my @addresses = map { Net::Async::Webservice::UPS::Address->new(postal_code=>$_) } @postal_codes;
    my @address_comparators = map {
        all(
            isa('Net::Async::Webservice::UPS::Address'),
            methods(
                postal_code => $_,
            ),
        ),
    } @postal_codes;

    my @street_addresses = (Net::Async::Webservice::UPS::Address->new({
        name        => 'Some Place',
        address     => '2231 E State Route 78',
        city        => 'East Lansing',
        state       => 'MI',
        country_code=> 'US',
        postal_code => '48823',
    }), Net::Async::Webservice::UPS::Address->new({
        name        => 'John Doe',
        building_name => 'Pearl Hotel',
        address     => '233 W 49th St',
        city        => 'New York',
        state       => "NY",
        country_code=> "US",
        postal_code => "10019",
    }) );

    my @packages = (
        Net::Async::Webservice::UPS::Package->new(
            length=>34, width=>24, height=>1.5,
            weight=>10,
            measurement_system => 'english',
            description => 'some stuff',
        ),
        Net::Async::Webservice::UPS::Package->new(
            length=>34, width=>24, height=>1.5,
            weight=>20,
            measurement_system => 'english',
        ),
    );

    my @rate_comparators = map {
        methods(
            warnings => undef,
            services => [
                all(
                    isa('Net::Async::Webservice::UPS::Service'),
                    methods(
                        label => 'GROUND',
                        code => '03',
                        rates => [
                            all(
                                isa('Net::Async::Webservice::UPS::Rate'),
                                methods(
                                    rated_package => package_comparator($_),
                                    from => $address_comparators[0],
                                    to => $address_comparators[1],
                                    billing_weight => num($_->weight,0.01),
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    } @packages;

    my $full_rate_comparator = methods(
        warnings => undef,
        services => [
            all(
                isa('Net::Async::Webservice::UPS::Service'),
                methods(
                    label => 'GROUND',
                    code => '03',
                    rated_packages => bag(map {package_comparator($_)} @packages),
                    rates => bag(map {
                        all(
                            isa('Net::Async::Webservice::UPS::Rate'),
                            methods(
                                rated_package => package_comparator($_),
                                from => $address_comparators[0],
                                to => $address_comparators[1],
                                billing_weight => num($_->weight,0.01),
                            ),
                        ),
                    } @packages),
                ),
            ),
        ],
    );

    my $rate1;
    subtest 'rating a package via postcodes' => sub {
        $ups->user_agent->$file_for_next_test('t/data/rate-1-package');
        $ups->request_rate({
            customer_context => 'test 1',
            from => $postal_codes[0],
            to => $postal_codes[1],
            packages => $packages[0],
        })->then(
            sub {
                ($rate1) = @_;

                cmp_deeply(
                    $rate1,
                    $rate_comparators[0],
                    'sensible rate returned',
                ) or note p $rate1;
                cmp_deeply(
                    $rate1->services->[0]->rated_packages,
                    [package_comparator($packages[0])],
                    'service refers to the right package'
                );
                cmp_deeply($rate1->customer_context,'test 1','context passed ok');
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            }
        )->get;
    };

    subtest 'rating a package via addresss' => sub {
        $ups->user_agent->$file_for_next_test('t/data/rate-1-package-addr');
        $ups->request_rate({
            # need this, otherwise the result is different from $rate1
            customer_context => 'test 1',
            from => $addresses[0],
            to => $addresses[1],
            packages => $packages[0],
        })->then(
            sub {
                my ($rate2) = @_;

                cmp_deeply(
                    $rate1,
                    $rate_comparators[0],
                    'sensible rate returned',
                ) or note p $rate2;
                cmp_deeply(
                    $rate2->services->[0]->rated_packages,
                    [package_comparator($packages[0])],
                    'service refers to the right package'
                );

                cmp_deeply($rate2,$rate1,'same result as with postcodes');
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            },
        )->get;
    };

    subtest 'rating multiple packages' => sub {
        $ups->user_agent->$file_for_next_test('t/data/rate-2-packages');
        $ups->request_rate({
            from => $postal_codes[0],
            to => $postal_codes[1],
            packages => \@packages,
        })->then(
            sub {
                my ($rate) = @_;

                cmp_deeply(
                    $rate,
                    $full_rate_comparator,
                    'sensible rate returned',
                ) or note p $rate;

                my $service = $rate->services->[0];
                cmp_deeply(
                    $service->rated_packages,
                    [package_comparator(@packages)],
                    'service refers to the both packages'
                );
                my $rates = $rate->services->[0]->rates;
                cmp_deeply(
                    $service->total_charges,
                    num($rates->[0]->total_charges + $rates->[1]->total_charges,0.01),
                    'total charges add up',
                );
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            },
        )->get;
    };

    subtest 'shop for rates, single package' => sub {
        $ups->user_agent->$file_for_next_test('t/data/shop-1-package');
        $ups->request_rate({
            from => $addresses[0],
            to => $addresses[1],
            packages => $packages[0],
            mode => 'shop',
        })->then(
            sub {
                my ($services) = @_;

                cmp_deeply(
                    $services,
                    methods(
                        warnings => undef,
                        services => all(
                            array_each(all(
                                isa('Net::Async::Webservice::UPS::Service'),
                                methods(
                                    rated_packages => [package_comparator($packages[0])],
                                ),
                            )),
                            superbagof(all(
                                isa('Net::Async::Webservice::UPS::Service'),
                                methods(
                                    label => 'GROUND',
                                    code => '03',
                                ),
                            )),
                        ),
                    ),
                    'services are returned, including ground',
                );

                my $services_aref = $services->services;
                cmp_deeply(
                    $services_aref,
                    [ sort { $a->total_charges <=> $b->total_charges } @$services_aref ],
                    'sorted by total_charges',
                );
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            },
        )->get
    };

    subtest 'shop for rates, multiple packages' => sub {
        $ups->user_agent->$file_for_next_test('t/data/shop-2-packages');
        $ups->request_rate({
            from => $addresses[0],
            to => $addresses[1],
            packages => \@packages,
            mode => 'shop',
        })->then(
            sub {
                my ($services) = @_;

                cmp_deeply(
                    $services,
                    methods(
                        warnings => undef,
                        services => all(
                            array_each(all(
                                isa('Net::Async::Webservice::UPS::Service'),
                                methods(
                                    rated_packages => [package_comparator(@packages)],
                                    rates => bag(
                                        map {
                                            all(
                                                isa('Net::Async::Webservice::UPS::Rate'),
                                                methods(
                                                    rated_package => package_comparator($_),
                                                    from => $address_comparators[0],
                                                    to => $address_comparators[1],
                                                ),
                                            ),
                                        } @packages,
                                    ),
                                ),
                            )),
                            superbagof(all(
                                isa('Net::Async::Webservice::UPS::Service'),
                                methods(
                                    label => 'GROUND',
                                    code => '03',
                                ),
                            )),
                        ),
                    ),
                    'services are returned, including ground, with multiple rates each',
                ) or note p $services;

                my $services_aref = $services->services;
                cmp_deeply(
                    $services_aref,
                    [ sort { $a->total_charges <=> $b->total_charges } @$services_aref ],
                    'sorted by total_charges',
                );

                for my $service (@$services_aref) {
                    my $rates = $service->rates;
                    cmp_deeply(
                        $service->total_charges,
                        num($rates->[0]->total_charges + $rates->[1]->total_charges,0.01),
                        'total charges add up',
                    );
                }
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            },
        )->get;
    };

    subtest 'validate address' => sub {
        my $address = Net::Async::Webservice::UPS::Address->new({
            city        => "East Lansing",
            state       => "MI",
            country_code=> "US",
            postal_code => "48823",
            is_residential=>1
        });
        $ups->user_agent->$file_for_next_test('t/data/address');
        $ups->validate_address($address, 0)->then(
            sub {
                my ($addresses) = @_;

                cmp_deeply(
                    $addresses,
                    methods(
                        warnings => undef,
                        addresses => all(
                            array_each( all(
                                isa('Net::Async::Webservice::UPS::Address'),
                                methods(
                                    city => "EAST LANSING",
                                    state => "MI",
                                    country_code=> "US",
                                    quality => num(1,0.01),
                                ),
                            ) ),
                            superbagof( all(
                                isa('Net::Async::Webservice::UPS::Address'),
                                methods(
                                    city => "EAST LANSING",
                                    state => "MI",
                                    country_code=> "US",
                                    quality => num(1,0.01),
                                ),
                            ) ),
                        ),
                    ),
                    'sensible addresses returned',
                ) or note p $addresses;
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            },
        )->get;
    };

    subtest 'validate address, failure' => sub {
        my $address = Net::Async::Webservice::UPS::Address->new({
            city        => "Bad Place",
            state       => "NY",
            country_code=> "US",
            postal_code => "998877",
            is_residential=>1
        });
        $ups->user_agent->$file_for_next_test('t/data/address-bad');
        $ups->validate_address($address, 0)->then(
            sub {
                my ($addresses) = @_;

                cmp_deeply(
                    $addresses,
                    methods(
                        warnings => undef,
                        addresses => [],
                    ),
                    'sensible failure returned',
                ) or note p $addresses;
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            },
        )->get;
    };

    subtest 'validate address, street-level' => sub {
        $ups->user_agent->$file_for_next_test('t/data/address-street-level');
        $ups->validate_street_address($street_addresses[1])->then(
            sub {
                my ($addresses) = @_;

                cmp_deeply(
                    $addresses,
                    methods(
                        warnings => undef,
                        addresses => [
                            all(
                                isa('Net::Async::Webservice::UPS::Address'),
                                methods(
                                    city => re(qr{\ANew York\z}i),
                                    state => "NY",
                                    country_code=> "US",
                                    postal_code_extended => '7404',
                                    quality => 1,
                                ),
                            ),
                        ],
                    ),
                    'sensible address returned',
                ) or note p $addresses;
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            },
        )->get;
    };

    subtest 'validate address, street-level, failure' => sub {
        my $address = Net::Async::Webservice::UPS::Address->new({
            name        => 'Bad Place',
            address     => '999 Not a Road',
            city        => 'Bad City',
            state       => 'NY',
            country_code=> 'US',
            postal_code => '998877',
        });
        $ups->user_agent->$file_for_next_test('t/data/address-street-level-bad');
        $ups->validate_street_address($address)->then(
            sub {
                fail("unexpected success: @_");
                return Future->wrap();
            },
            sub {
                my ($failure) = @_;

                cmp_deeply(
                    $failure,
                    methods(
                        error_code => 'NoCandidates',
                    ),
                    'sensible failure returned',
                ) or note p $failure;
                return Future->wrap();
            },
        )->get;
    };

    subtest 'validate address, non-ASCII' => sub {
        my $address = Net::Async::Webservice::UPS::Address->new({
            name        => "Snowman \x{2603}",
        address     => '233 W 49th St',
        city        => 'New York',
        state       => "NY",
        country_code=> "US",
        postal_code => "10019",
#            address     => "St\x{e4}ndehausstra\x{df}e 1",
#            city        => "D\x{fc}sseldorf",
#            country_code=> 'DE',
#            postal_code => '40217',
        });
        $ups->user_agent->$file_for_next_test('t/data/address-non-ascii');
        $ups->validate_street_address($address)->then(
            sub {
                my ($validated) = @_;

                cmp_deeply(
                    $validated,
                    methods(
                        warnings => undef,
                        addresses => [
                            all(
                                isa('Net::Async::Webservice::UPS::Address'),
                                methods(
                                    city => re(qr{\ANew York\z}i),
                                    state => "NY",
                                    country_code=> "US",
                                    postal_code_extended => '7404',
                                    quality => 1,
                                ),
                            ),
                        ],
                    ),
                    'sensible address returned',
                ) or note p $validated;
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();
            },
        )->get;
    };

    my $bill_shipper = Net::Async::Webservice::UPS::Payment->new({
        method => 'prepaid',
        account_number => $ups->account_number,
    });

    my $shipper = Net::Async::Webservice::UPS::Shipper->new({
        name => 'Test Shipper',
        company_name => 'Test Shipper Company',
        address => $street_addresses[0],
        account_number => $ups->account_number,
    });

    my $destination = Net::Async::Webservice::UPS::Contact->new({
        name => 'Test Contact',
        company_name => 'Test Contact Company',
        address => $street_addresses[1],
    });

    subtest 'book shipment' => sub {
        $ups->user_agent->$file_for_next_test('t/data/ship-confirm-1');
        $ups->ship_confirm({
            customer_context => 'test ship1',
            from => $shipper,
            to => $destination,
            shipper => $shipper,
            packages => \@packages,
            description => 'Testing packages',
            payment => $bill_shipper,
            label => 'EPL',
        })->then(
            sub {
                my ($confirm) = @_;

                cmp_deeply(
                    $confirm,
                    methods(
                        billing_weight => num(30,0.01),
                        unit => 'LBS',
                        currency => 'USD',
                        customer_context => 'test ship1',
                    ),
                    'shipment confirm worked',
                );
                cmp_deeply(
                    $confirm->transportation_charges + $confirm->service_option_charges,
                    num($confirm->total_charges,0.01),
                    'charges add up',
                );
                ok($confirm->shipment_digest,'we have a digest');
                ok($confirm->shipment_identification_number,'we have an id number');
                $ups->user_agent->$file_for_next_test('t/data/ship-accept-1');
                return $ups->ship_accept({
                    customer_context => 'test acc1',
                    confirm => $confirm,
                })->then(sub{return Future->wrap($confirm,@_)});
            },
            sub {
                fail("@_");diag p @_;
                return Future->fail('test');
            },
        )->then(
            sub {
                my ($confirm,$accept) = @_;

                cmp_deeply(
                    $accept,
                    methods(
                        customer_context => 'test acc1',
                        billing_weight => num(30,0.01),
                        unit => 'LBS',
                        currency => 'USD',
                        service_option_charges => num($confirm->service_option_charges),
                        transportation_charges => num($confirm->transportation_charges),
                        total_charges => num($confirm->total_charges),
                        shipment_identification_number => $confirm->shipment_identification_number,
                        package_results => [ map {
                            all(
                                isa('Net::Async::Webservice::UPS::Response::PackageResult'),
                                methods(
                                    label => isa('Net::Async::Webservice::UPS::Response::Image'),
                                    package => $_,
                                ),
                            )
                        } @packages ],
                    ),
                    'shipment accept worked',
                );
                return Future->wrap();
            },
            sub {
                if ($_[0] ne 'test') {
                    # failure in ->accept, not in ->confirm
                    fail("@_");diag p @_;
                }
                return Future->wrap();
            },
        )->get;
    };

    subtest 'book shipment, 1 package' => sub {
        $ups->user_agent->$file_for_next_test('t/data/ship-confirm-2');
        $ups->ship_confirm({
            from => $shipper,
            to => $destination,
            shipper => $shipper,
            packages => $packages[0],
            description => 'Testing 1 package',
            payment => $bill_shipper,
            label => 'EPL',
        })->then(
            sub {
                my ($confirm) = @_;

                cmp_deeply(
                    $confirm,
                    methods(
                        billing_weight => num(10,0.01),
                        unit => 'LBS',
                        currency => 'USD',
                    ),
                    'shipment confirm worked',
                );
                cmp_deeply(
                    $confirm->transportation_charges + $confirm->service_option_charges,
                    num($confirm->total_charges,0.01),
                    'charges add up',
                );
                ok($confirm->shipment_digest,'we have a digest');
                ok($confirm->shipment_identification_number,'we have an id number');

                $ups->user_agent->$file_for_next_test('t/data/ship-accept-2');
                return $ups->ship_accept({
                    confirm => $confirm,
                })->then(sub{return Future->wrap($confirm,@_)});
            },
            sub {
                fail("@_");diag p @_;
                return Future->fail('test');
            },
        )->then(
            sub {
                my ($confirm,$accept) = @_;

                cmp_deeply(
                    $accept,
                    methods(
                        billing_weight => num(10,0.01),
                        unit => 'LBS',
                        currency => 'USD',
                        service_option_charges => num($confirm->service_option_charges),
                        transportation_charges => num($confirm->transportation_charges),
                        total_charges => num($confirm->total_charges),
                        shipment_identification_number => $confirm->shipment_identification_number,
                        package_results => [
                            all(
                                isa('Net::Async::Webservice::UPS::Response::PackageResult'),
                                methods(
                                    label => isa('Net::Async::Webservice::UPS::Response::Image'),
                                    package => $packages[0],
                                ),
                            )
                        ],
                    ),
                    'shipment accept worked',
                );
                return Future->wrap();
            },
            sub {
                if ($_[0] ne 'test') {
                    # failure in ->accept, not in ->confirm
                    fail("@_");diag p @_;
                }
                return Future->wrap();
            },
        )->get;
    };

    subtest 'book return shipment, 1 package' => sub {
        $ups->user_agent->$file_for_next_test('t/data/ship-confirm-3');
        $ups->ship_confirm({
            from => $destination,
            to => $shipper,
            shipper => $shipper,
            packages => $packages[0],
            description => 'Testing 1 package return',
            payment => $bill_shipper,
            return_service => 'PRL',
            label => 'EPL',
        })->then(
            sub {
                my ($confirm) = @_;

                cmp_deeply(
                    $confirm,
                    methods(
                        billing_weight => num(10,0.01),
                        unit => 'LBS',
                        currency => 'USD',
                    ),
                    'shipment confirm worked',
                );
                cmp_deeply(
                    $confirm->transportation_charges + $confirm->service_option_charges,
                    num($confirm->total_charges,0.01),
                    'charges add up',
                );
                ok($confirm->shipment_digest,'we have a digest');
                ok($confirm->shipment_identification_number,'we have an id number');
                $ups->user_agent->$file_for_next_test('t/data/ship-accept-3');
                return $ups->ship_accept({
                    confirm => $confirm,
                })->then(sub{return Future->wrap($confirm,@_)});
            },
            sub {
                fail("@_");diag p @_;
                return Future->fail('test');
            },
        )->then(
            sub {
                my ($confirm,$accept) = @_;

                cmp_deeply(
                    $accept,
                    methods(
                        billing_weight => num(10,0.01),
                        unit => 'LBS',
                        currency => 'USD',
                        service_option_charges => num($confirm->service_option_charges),
                        transportation_charges => num($confirm->transportation_charges),
                        total_charges => num($confirm->total_charges),
                        shipment_identification_number => $confirm->shipment_identification_number,
                        package_results => [
                            all(
                                isa('Net::Async::Webservice::UPS::Response::PackageResult'),
                                methods(
                                    label => isa('Net::Async::Webservice::UPS::Response::Image'),
                                    package => $packages[0],
                                ),
                            )
                        ],
                    ),
                    'shipment accept worked',
                );
                return Future->wrap();
            },
            sub {
                if ($_[0] ne 'test') {
                    # failure in ->accept, not in ->confirm
                    fail("@_");diag p @_;
                }
                return Future->wrap();
            },
        )->get;
    };

    subtest 'quantum view, no args' => sub {
        $ups->user_agent->$file_for_next_test('t/data/qv-1');
        $ups->qv_events({})->then(
            sub {
                my ($events) = @_;
                cmp_deeply(
                    $events,
                    all(
                        isa('Net::Async::Webservice::UPS::Response::QV'),
                        methods(
                            subscriber_id => $ups->user_id,
                            events => array_each(all(
                                isa('Net::Async::Webservice::UPS::Response::QV::Event'),
                                methods(
                                    files => array_each(all(
                                        isa('Net::Async::Webservice::UPS::Response::QV::File'),
                                        methods(
                                            filename => ignore(),
                                        ),
                                    )),
                                ),
                            )),
                            warnings => superhashof({
                                ErrorCode => 336000,
                            }),
                        ),
                    ),
                    'sensible response',
                );
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();

            },
        )->get;
    };

    my $bookmark;

    subtest 'quantum view, date-time' => sub {
        $ups->user_agent->$file_for_next_test('t/data/qv-datetime-1');

        $ups->qv_events({
            subscriptions => [
                Net::Async::Webservice::UPS::QVSubscription->new({
                    begin_date => '2002-02-08T00:00:00',
                    end_date => '2002-02-08T13:32:48',
                }),
            ],
        })->then(
            sub {
                my ($events) = @_;
                cmp_deeply(
                    $events,
                    all(
                        isa('Net::Async::Webservice::UPS::Response::QV'),
                        methods(
                            subscriber_id => $ups->user_id,
                            events => array_each(all(
                                isa('Net::Async::Webservice::UPS::Response::QV::Event'),
                                methods(
                                    files => array_each(all(
                                        isa('Net::Async::Webservice::UPS::Response::QV::File'),
                                        methods(
                                            filename => ignore(),
                                        ),
                                    )),
                                ),
                            )),
                            warnings => superhashof({
                                ErrorCode => 336000,
                            }),
                            bookmark => re(qr{\A.+\z}),
                        ),
                    ),
                    'sensible response',
                );
                $bookmark = $events->bookmark;
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();

            },
        )->get;
    };

    subtest 'quantum view, bookmark' => sub {
        $ups->user_agent->$file_for_next_test('t/data/qv-bookmark-fail');

        $ups->qv_events({
            bookmark => $bookmark,
        })->then(
            sub {
                fail("unexpected success: @_");
                diag p @_;
                return Future->wrap();
            },
            sub {
                my ($failure) = @_;

                cmp_deeply(
                    $failure,
                    methods(
                        error_code => 330015,
                    ),
                    'bookmark correctly invalid without subscription specs',
                ) or note p $failure;

                return Future->wrap();
            },
        )->get;

        $ups->user_agent->$file_for_next_test('t/data/qv-bookmark');
        $ups->qv_events({
            subscriptions => [
                Net::Async::Webservice::UPS::QVSubscription->new({
                    begin_date => '2002-02-08T00:00:00',
                    end_date => '2002-02-08T13:32:48',
                }),
            ],
            bookmark => $bookmark,
        })->then(
            sub {
                my ($events) = @_;
                cmp_deeply(
                    $events,
                    all(
                        isa('Net::Async::Webservice::UPS::Response::QV'),
                        methods(
                            subscriber_id => $ups->user_id,
                            events => array_each(all(
                                isa('Net::Async::Webservice::UPS::Response::QV::Event'),
                                methods(
                                    files => array_each(all(
                                        isa('Net::Async::Webservice::UPS::Response::QV::File'),
                                        methods(
                                            filename => ignore(),
                                        ),
                                    )),
                                ),
                            )),
                            warnings => superhashof({
                                ErrorCode => 336000,
                            }),
                            bookmark => undef,
                        ),
                    ),
                    'sensible response',
                );
                $bookmark = $events->bookmark;
                return Future->wrap();
            },
            sub {
                fail("@_");diag p @_;
                return Future->wrap();

            },
        )->get;
    };
}

1;

