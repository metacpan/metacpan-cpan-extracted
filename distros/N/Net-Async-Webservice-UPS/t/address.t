#!perl
use strict;
use warnings;
use 5.010;
use lib 't/lib';
use Test::Most;
use Net::Async::Webservice::UPS;
use Net::Async::Webservice::UPS::Address;
use File::Spec;
use Sub::Override;
use Test::Net::Async::Webservice::UPS;
use Test::Net::Async::Webservice::UPS::TestCache;
eval { require IO::Async::Loop; require Net::Async::HTTP }
    or do {
        plan(skip_all=>'this test only runs with IO::Async and Net::Async::HTTP');
        exit(0);
    };

my $loop = IO::Async::Loop->new;

my $orig_post = \&Net::Async::Webservice::UPS::post;
my @calls;
my $new_post = Sub::Override->new(
    'Net::Async::Webservice::UPS::post',
    sub {
        push @calls,[@_];
        $orig_post->(@_);
    }
);

my $cache = Test::Net::Async::Webservice::UPS::TestCache->new();
my $ups = Net::Async::Webservice::UPS->new({
    config_file => Test::Net::Async::Webservice::UPS->conf_file,
    cache => $cache,
    loop => $loop,
});

my $address = Net::Async::Webservice::UPS::Address->new({
    city => 'East Lansing',
    postal_code => '48823',
    state => 'MI',
    country_code => 'US',
    is_residential => 1,
});

my $addresses = $ups->validate_address($address)->get;

cmp_deeply($addresses->addresses,
           array_each(
               all(
                   isa('Net::Async::Webservice::UPS::Address'),
                   methods(
                       quality => num(1.0,0),
                       is_residential => undef,
                       is_exact_match => bool(1),
                       is_poor_match => bool(0),
                       is_close_match => bool(1),
                       is_very_close_match => bool(1),
                   ),
               ),
           ),
           'address validated',
) or p $addresses;
cmp_deeply(\@calls,
           [[ ignore(),re(qr{/AV$}),ignore() ]],
           'one call to the service');

my $addresses2 = $ups->validate_address($address)->get;
cmp_deeply($addresses2,$addresses,'the same answer');
cmp_deeply(\@calls,
           [[ ignore(),re(qr{/AV$}),ignore() ]],
           'still only one call to the service');

# build with no cache
$ups = Net::Async::Webservice::UPS->new({
    config_file => Test::Net::Async::Webservice::UPS->conf_file,
    loop => $loop,
});
my $addresses3 = $ups->validate_address($address)->get;
cmp_deeply($addresses3,$addresses,'the same answer');
cmp_deeply(\@calls,
           [[ ignore(),re(qr{/AV$}),ignore() ],
            [ ignore(),re(qr{/AV$}),ignore() ]],
           'two calls to the service');

subtest 'round-trip' => sub {
    my $ad = Net::Async::Webservice::UPS::Address->new({
        city => 'City',
        postal_code => 1234,
        postal_code_extended => 56,
        state => 'State',
        country_code => 'CC',
        name => 'Me',
        building_name => 'building',
        address => 'row 1',
        address2 => 'row 2',
        address3 => 'row 3',
        is_residential => 1,
    });

    subtest 'round-trip via AV' => sub {
        my $ad2 = Net::Async::Webservice::UPS::Address->new($ad->as_hash());
        for my $f (qw(country_code postal_code city state is_residential)) {
            is($ad2->$f,$ad->$f,"$f matches");
        }
    };

    subtest 'round-trip via XAV' => sub {
        my $ad2 = Net::Async::Webservice::UPS::Address->new($ad->as_hash('XAV'));
        for my $f (qw(country_code postal_code city state
                      postal_code_extended address address2 address3
                      name building_name)) {
            is($ad2->$f,$ad->$f,"$f matches");
        }
    };

    subtest 'round-trip via Ship' => sub {
        my $ad2 = Net::Async::Webservice::UPS::Address->new($ad->as_hash('Ship'));
        for my $f (qw(country_code postal_code city state
                      address address2 address3)) {
            is($ad2->$f,$ad->$f,"$f matches");
        }
    };
};

done_testing();

