package Test::Net::UPS;
use strict;
use warnings;
use Test::Most;
use Data::Printer;
use Net::UPS::Package;

sub test_it {
    my ($ups) = @_;

    subtest 'setting live / testing' => sub {
        is($Net::UPS::LIVE,0,'starts in testing');
        my $test_rate = $ups->rate_proxy;
        my $test_av = $ups->av_proxy;

        $ups->live(1);
        is($Net::UPS::LIVE,1,'can be set live');
        isnt($ups->rate_proxy,$test_rate,'live Rate proxy different than test one');
        isnt($ups->av_proxy,$test_av,'live AV proxy different than test one');

        $ups->live(0);
        is($Net::UPS::LIVE,0,'can be set back to testing');
        is($ups->rate_proxy,$test_rate,'test Rate proxy same as before');
        is($ups->av_proxy,$test_av,'test AV proxy same as before');
    };

    my @postal_codes = ( 15241, 48823 );
    my @addresses = map { Net::UPS::Address->new(postal_code=>$_) } @postal_codes;
    my @address_comparators = map {
        all(
            isa('Net::UPS::Address'),
            methods(
                postal_code => $_,
            ),
        ),
    } @postal_codes;

    my @packages = (
        Net::UPS::Package->new(
            length=>34, width=>24, height=>1.5,
            weight=>10,
        ),
        Net::UPS::Package->new(
            length=>34, width=>24, height=>1.5,
            weight=>20,
        ),
    );

    my @rate_comparators = map {
        all(
            isa('Net::UPS::Rate'),
            methods(
                rated_package => $_,
                from => $address_comparators[0],
                to => $address_comparators[1],
                billing_weight => num($_->weight,0.01),
                service => all(
                    isa('Net::UPS::Service'),
                    methods(
                        label => 'GROUND',
                        code => '03',
                    ),
                ),
            ),
        ),
    } @packages;

    my $rate1;
    subtest 'rating a package via postcodes' => sub {
        $rate1 = $ups->rate(@postal_codes, $packages[0]);

        cmp_deeply(
            $rate1,
            $rate_comparators[0],
            'sensible rate returned',
        ) or note p $rate1;
        cmp_deeply(
            $rate1->service->rated_packages,
            [$packages[0]],
            'service refers to the right package'
        );
    };

    subtest 'rating a package via addresss' => sub {
        my $rate2 = $ups->rate(@addresses, $packages[0]);

        cmp_deeply(
            $rate1,
            $rate_comparators[0],
            'sensible rate returned',
        ) or note p $rate2;
        cmp_deeply(
            $rate2->service->rated_packages,
            [$packages[0]],
            'service refers to the right package'
        );

        cmp_deeply($rate2,$rate1,'same result as with postcodes');
    };

    subtest 'rating multiple packages' => sub {
        my $rate = $ups->rate(@postal_codes, \@packages);

        cmp_deeply(
            $rate,
            bag(@rate_comparators),
            'sensible rate returned',
        );
        cmp_deeply(
            $rate->[0]->service,
            $rate->[1]->service,
            'same service for both rates',
        );
        my $service = $rate->[0]->service;
        cmp_deeply(
            $service->rated_packages,
            \@packages,
            'service refers to the both packages'
        );
        cmp_deeply(
            $service->total_charges,
            num($rate->[0]->total_charges + $rate->[1]->total_charges,0.01),
            'total charges add up',
        );
    };

    subtest 'shop for rates, single package' => sub {
        my $services = $ups->shop_for_rates(@addresses, $packages[0]);

        cmp_deeply(
            $services,
            all(
                array_each(all(
                    isa('Net::UPS::Service'),
                    methods(
                        rated_packages => [$packages[0]],
                    ),
                )),
                superbagof(all(
                    isa('Net::UPS::Service'),
                    methods(
                        label => 'GROUND',
                        code => '03',
                    ),
                )),
            ),
            'services are returned, including ground',
        );

        cmp_deeply(
            $services,
            [ sort { $a->total_charges <=> $b->total_charges } @$services ],
            'sorted by total_charges',
        );
    };

    subtest 'shop for rates, multiple packages' => sub {
        my $services = $ups->shop_for_rates(@addresses, \@packages);

        cmp_deeply(
            $services,
            all(
                array_each(all(
                    isa('Net::UPS::Service'),
                    methods(
                        rated_packages => \@packages,
                        rates => bag(
                            map {
                                all(
                                    isa('Net::UPS::Rate'),
                                    methods(
                                        rated_package => $_,
                                        from => $address_comparators[0],
                                        to => $address_comparators[1],
                                    ),
                                ),
                            } @packages,
                        ),
                    ),
                )),
                superbagof(all(
                    isa('Net::UPS::Service'),
                    methods(
                        label => 'GROUND',
                        code => '03',
                    ),
                )),
            ),
            'services are returned, including ground, with multiple rates each',
        ) or note p $services;

        cmp_deeply(
            $services,
            [ sort { $a->total_charges <=> $b->total_charges } @$services ],
            'sorted by total_charges',
        );

        for my $service (@$services) {
            my $rates = $service->rates;
            cmp_deeply(
                $service->total_charges,
                num($rates->[0]->total_charges + $rates->[1]->total_charges,0.01),
                'total charges add up',
            );
        }
        ;
    };

    subtest 'validate address' => sub {
        my $address = Net::UPS::Address->new(
            city        => "East Lansing",
            state       => "MI",
            country_code=> "US",
            postal_code => "48823",
            is_residential=>1
        );

        my $addresses = $ups->validate_address($address, {tolerance=>0});

        cmp_deeply(
            $addresses,
            array_each(
                all(
                    isa('Net::UPS::Address'),
                    methods(
                        city => "EAST LANSING",
                        state => "MI",
                        country_code=> "US",
                        quality => num(1,0.01),
                    ),
                ),
            ),
            'sensible addresses returned',
        ) or note p $addresses;
    };

    subtest 'validate address, failure' => sub {
        my $address = Net::UPS::Address->new(
            city        => "Bad Place",
            state       => "NY",
            country_code=> "US",
            postal_code => "998877",
            is_residential=>1
        );

        my $addresses = $ups->validate_address($address, {tolerance=>0});

        cmp_deeply(
            $addresses,
            [],
            'sensible failure returned',
        ) or note p $addresses;
    };

    subtest 'validate address, street-level' => sub {
        my $address = Net::UPS::Address->new(
            name        => 'John Doe',
            building_name => 'Pearl Hotel',
            address     => '233 W 49th St',
            city        => 'New York',
            state       => "NY",
            country_code=> "US",
            postal_code => "10019",
        );
        my $addresses = $ups->validate_street_address($address);

        cmp_deeply(
            $addresses,
            all(
                isa('Net::UPS::Address'),
                methods(
                    city => re(qr{\ANew York\z}i),
                    state => "NY",
                    country_code=> "US",
                    postal_code_extended => '7404',
                    quality => 1,
                ),
            ),
            'sensible address returned',
        ) or note p $addresses;
    };

    subtest 'validate address, street-level, failure' => sub {
        my $address = Net::UPS::Address->new(
            name        => 'Bad Place',
            address     => '999 Not a Road',
            city        => 'Bad City',
            state       => 'NY',
            country_code=> 'US',
            postal_code => '998877',
        );
        my $addresses = $ups->validate_street_address($address);

        cmp_deeply(
            $addresses,
            undef,
            'sensible failure returned',
        ) or note p $addresses;
    };

    subtest 'validate address, non-ASCII' => sub {
        my $address = Net::UPS::Address->new(
            name        => "Snowman \x{2603}",
            address     => '233 W 49th St',
            city        => 'New York',
            state       => "NY",
            country_code=> "US",
            postal_code => "10019",
        );
        my $validated = $ups->validate_street_address($address);

        cmp_deeply(
            $validated,
            all(
                isa('Net::UPS::Address'),
                methods(
                    city => re(qr{\ANew York\z}i),
                    state => "NY",
                    country_code=> "US",
                    postal_code_extended => '7404',
                    quality => 1,
                ),
            ),
            'sensible address returned',
        ) or note p $validated;
    };
}

1;

