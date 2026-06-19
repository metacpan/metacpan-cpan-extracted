#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Net::Whois::IP', qw(whoisip_query));
}

diag "Loaded Net::Whois::IP from $INC{'Net/Whois/IP.pm'}";

{
    no warnings 'redefine';

    my @calls;

    local *Net::Whois::IP::_do_lookup = sub {
        my ($ip, $reg, $multiple_flag, $raw_flag, $search_options) = @_;

        push @calls, {
            ip             => $ip,
            reg            => $reg,
            multiple_flag  => $multiple_flag,
            raw_flag       => $raw_flag,
            search_options => $search_options,
        };

        my $response = {
            NetRange => '8.8.8.0 - 8.8.8.255',
            OrgName  => 'Google LLC',
        };

        my $chain = [
            {
                NetRange => '8.0.0.0 - 8.255.255.255',
                OrgName  => 'ARIN',
            },
            $response,
        ];

        return ($response, $chain);
    };

    my $scalar_response = whoisip_query('8.8.8.8');

    is(ref($scalar_response), 'HASH', 'scalar context returns response hash');
    is($scalar_response->{OrgName}, 'Google LLC', 'scalar response contains expected data');

    my ($response, $chain) = whoisip_query('8.8.8.8', undef, 'true');

    is(ref($response), 'HASH', 'list context first value is response hash');
    is(ref($chain), 'ARRAY', 'list context second value is response chain arrayref');
    is(scalar @$chain, 2, 'response chain contains expected number of levels');

    is($calls[0]{reg}, 'ARIN', 'default registrar is ARIN');
    is($calls[1]{multiple_flag}, 'true', 'multiple flag is passed through');

    my $search_options = [ 'NetName', 'OrgName' ];
    whoisip_query('8.8.8.8', 'ARIN', undef, undef, $search_options);

    is_deeply(
        $calls[-1]{search_options},
        $search_options,
        'search options arrayref is passed through'
    );
}

{
    my $ok = eval {
        whoisip_query('not-an-ip-address');
        1;
    };

    ok(!$ok, 'invalid IP address dies');
    like($@, qr/not a valid ip address/i, 'invalid IP error message is useful');
}

done_testing();
