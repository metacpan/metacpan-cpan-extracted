package ParseDomain;

use utf8;
use strict;
use warnings;

use parent qw(Test::Class);

use Modern::Perl;
use Test::More;

use Test::Exception;
#use Smart::Comments;
binmode(STDOUT, "utf8");

use ParseUtil::Domain ':parse';

sub t010_split_ascii_domain_tld : Test(35) {
    my $self         = shift;
    my $test_domains = [
        {
            raw => 'something.com.se',
            domain => 'something',
            zone => 'com.se'
        
        },

        {
            raw    => 'something.com',
            domain => 'something',
            zone   => 'com'

        },
        {
            raw    => 'neteseco.or.at',
            domain => 'neteseco',
            zone   => 'or.at'

        },
        {
            raw    => 'something.tas.gov.au',
            domain => 'something',
            zone   => 'tas.gov.au'
        },
        { raw => 'whatever.name', domain => 'whatever', zone => 'name' },
        {
            raw    => 'me.whatever.name',
            domain => 'me.whatever',
            prefix => 'me',
            zone   => 'name'
        },
        { raw => 'me@whatever.name', domain => 'me@whatever', zone => 'name' },
        {
            raw    => 'mx01.whatever.it',
            domain => 'mx01.whatever',
            prefix => 'mx01',
            zone   => 'it'
        },
        {
            raw    => 'my.domain.shop',
            domain => 'my.domain',
            prefix => 'my',
            zone   => 'shop'
        },
        { raw => 'my-domain.web',    domain => 'my-domain', zone => 'web' },
        { raw => 'my-domain.one',    domain => 'my-domain', zone => 'one' },
        { raw => 'my-domain.city',   domain => 'my-domain', zone => 'city' },
        { raw => 'my-domain.gay',    domain => 'my-domain', zone => 'gay' },
        { raw => 'my-domain.london', domain => 'my-domain', zone => 'london' },
        {
            raw    => '0.cdn.ideeli.net',
            domain => '0.cdn.ideeli',
            prefix => '0.cdn',
            zone   => 'net'
        },

    ];

    foreach my $test_domain ( @{$test_domains} ) {
        ### testing : $test_domain
        my $parsed = parse_domain( $test_domain->{raw} );
        my ( $prefix, $domain, $zone, ) = @{$parsed}{qw/prefix domain zone /};

        is(
            $domain,
            $test_domain->{domain},
            "Expected " . $test_domain->{domain}
        );
        is( $zone, $test_domain->{zone}, "Expected " . $test_domain->{zone} );
        if ( my $expected_prefix = $test_domain->{prefix} ) {
            is( $prefix, $expected_prefix, "Expected: " . $expected_prefix );
        }

    }

    throws_ok {
        parse_domain('nota.tld');

    }
    qr/Could not find tld/, 'Unknown tlds not processed.';

}

sub t020_split_unicode_domain_tld : Test(24) {
    my $self          = shift;
    my $domain_to_ace = [
        {
            raw     => 'ü.com',
            decoded => 'ü.com',
            ace     => 'xn--tda.com'

        },
        {
            raw     => 'test.香港',
            decoded => 'test.香港',
            ace     => 'test.xn--j6w193g'

        },
        {
            raw     => 'test.敎育.hk',
            decoded => 'test.敎育.hk',
            ace     => 'test.xn--lcvr32d.hk'

        },
        {
            raw     => 'test.xn--o3cw4h',
            decoded => 'test.ไทย',
            ace     => 'test.xn--o3cw4h'

        },
        {
            raw     => 'ü@somewhere.name',
            decoded => 'ü@somewhere.name',
            ace     => 'xn--tda@somewhere.name'

        },
        {
            raw     => 'ü.or.at',
            decoded => 'ü.or.at',
            ace     => 'xn--tda.or.at'

        },
        {
            decoded => 'bloß.de',
            ace     => 'xn--blo-7ka.de',
            raw     => 'xn--blo-7ka.de'

        },
        {
            raw     => 'faß.co.at',
            decoded => 'fass.co.at',
            ace     => 'fass.co.at'

        },
        {
            raw     => 'faß.de',
            decoded => 'faß.de',
            ace     => 'xn--fa-hia.de'

        },
        {
            decoded => 'faß.de',
            ace     => 'xn--fa-hia.de',
            raw     => 'xn--fa-hia.de'

        },
        {
            decoded => 'faß.fr',
            ace     => 'xn--fa-hia.fr',
            raw     => 'xn--fa-hia.fr'

        },
        {
            decoded => 'faß.yt',
            ace     => 'xn--fa-hia.yt',
            raw     => 'xn--fa-hia.yt'

        },

    ];

    foreach my $test_domain ( @{$domain_to_ace} ) {
        my $parsed = parse_domain( $test_domain->{raw} );
        my ( $domain, $domain_ace, $zone, $zone_ace ) =
          @{$parsed}{qw/domain domain_ace zone zone_ace/};

        my $decoded_domain = join "." => $domain,     $zone;
        my $ace_domain     = join "." => $domain_ace, $zone_ace;

        is( $test_domain->{decoded},
            $decoded_domain, "Got expected domain");
        is( $test_domain->{ace}, $ace_domain,
            "Expected " . $test_domain->{ace} );

    }
}

sub t100_undefined_mappings : Test(1) {
    my $self = shift;

    my $test_domain = 'xn--blo-7ka.com';
    throws_ok {
        my $result = parse_domain($test_domain);
        ### result : $result
    }
    qr/Undefined mapping/, "Mapping should not be defined.";

}

1;
