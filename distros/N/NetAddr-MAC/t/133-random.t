#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More import => [qw( diag done_testing like ok require_ok subtest )];
use Test::Exception;

require_ok('NetAddr::MAC')
    or die "# NetAddr::MAC not available\n";

subtest 'Random MAC generation test cases (EUI-48 & EUI-64)' => sub {
    my @cases = (
        {
            args => [ '00:16:3e' ],
            expect_defined => 1,
            match => qr/^00:16:3e:/i,
            desc => 'EUI-48: OUI prefix correct',
        },
        {
            args => [ '00:16:3e:12' ],
            expect_defined => 1,
            match => qr/^00:16:3e:12:/i,
            desc => 'EUI-48: 4 octet OUI prefix correct',
        },
        {
            args => [ prefix => '00:16:3e:12:34' ],
            expect_defined => 1,
            match => qr/^00:16:3e:12:34:/i,
            desc => 'EUI-48: 5 octet OUI prefix correct',
        },
        {
            args => [ prefix => '00:16:3e:12', eui64 => 1 ],
            expect_defined => 1,
            match => qr/^00:16:3e:12:/i,
            desc => 'EUI-64: 4 octet OUI prefix correct',
        },
        {
            args => [ prefix => '00:16:3e:12:34:56:78', eui64 => 1 ],
            expect_defined => 1,
            match => qr/^00:16:3e:12:34:56:78:/i,
            desc => 'EUI-64: 7 octet OUI prefix correct',
        },
        {
            args => [ prefix => '00-16-3e' ],
            expect_defined => 1,
            match => qr/^00:16:3e:/i,
            desc => 'EUI-48: OUI prefix with dashes',
        },
        {
            args => [ prefix => '0016.3e12' ],
            expect_defined => 1,
            match => qr/^00:16:3e:12:/i,
            desc => 'EUI-48: OUI prefix with dots',
        },
        {
            args => [ prefix => '00163e12' ],
            expect_defined => 1,
            match => qr/^00:16:3e:12:/i,
            desc => 'EUI-48: OUI prefix with no delimiters',
        },
        {
            args => [ prefix => '00:16' ],
            expect_defined => 0,
            desc => 'Too short OUI prefix returns undef',
        },
        {
            args => [ prefix => '00:16:3e:12:34:56:78:9a', eui64 => 1 ],
            expect_defined => 0,
            desc => 'Too long OUI prefix returns undef',
        },
    );

    for my $case (@cases) {

        my $mac = NetAddr::MAC->random(@{$case->{args}});

        if ($case->{expect_defined}) {

            ok(defined $mac, "$case->{desc} (object defined)")
                or diag( 'Error: ' . ( NetAddr::MAC->errstr // 'undef' ) );
            if (defined $mac && $case->{match}) {
                my $mac_str = $mac->as_ieee;
                my %args = (@{$case->{args}} % 2 == 0)
                    ? @{$case->{args}}
                    : ('prefix', @{$case->{args}});
                like($mac_str, $case->{match}, "$mac_str has prefix $args{prefix}");
            }

        }
        else {

            ok(!defined $mac, $case->{desc});

        }
    }
};

subtest 'Random generation error handling and die_on_error' => sub {
    dies_ok { NetAddr::MAC->random(prefix => '00:16', die_on_error => 1) } 'random() croaks on invalid prefix with die_on_error => 1';
    dies_ok { NetAddr::MAC->random(die_on_error => 1) } 'random() croaks on missing prefix with die_on_error => 1';

    {
        no warnings 'once';
        local $NetAddr::MAC::die_on_error = 1;
        dies_ok { NetAddr::MAC->random(prefix => '00:16') } 'random() croaks on invalid prefix with global die_on_error';
        dies_ok { NetAddr::MAC->random() } 'random() croaks on missing prefix with global die_on_error';
    }
};

done_testing();
exit;
