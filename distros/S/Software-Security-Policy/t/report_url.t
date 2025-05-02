#!perl
use strict;
use warnings;

use Test::More tests => 13;

my $class = 'Software::Security::Policy::Individual';
require_ok($class);

my $policy = $class->new({
        maintainer  => 'X. Ample <x.example@example.com>',
        program     => 'Foo::Bar',
        timeframe   => '6 days',
        git_url     => 'https://example.com/xampl/Foo-Bar',
        report_url  => 'https://example.com/xampl/Foo-Bar/security/advisories',
        perl_support_years   => '8',
    });

# note $policy->fulltext;

is($policy->maintainer, 'X. Ample <x.example@example.com>', 'maintainer');
like($policy->name, qr/individual/i, "Individual Security Policy");
like($policy->fulltext, qr/6 days/i, 'timeframe updated in policy');
like($policy->fulltext, qr/8 years/i, 'perl_support_years updated in policy');
like($policy->fulltext, qr/maintained by a single person/i, 'Individual Security Policy');
like($policy->fulltext, qr(https://example.com/xampl/Foo-Bar/security/advisories), 'security advisories url');

$policy = $class->new({
        maintainer  => 'X. Ample <x.example@example.com>',
        perl_support_years   => '10',
    });

is($policy->maintainer, 'X. Ample <x.example@example.com>', 'maintainer');
like($policy->name, qr/individual/i, "Individual Security Policy");
like($policy->fulltext, qr/5 days/i, 'timeframe updated in policy');
like($policy->fulltext, qr/10 years/i, 'perl_support_years updated in policy');
like($policy->fulltext, qr/maintained by a single person/i, 'Individual Security Policy');

$policy = $class->new({
        maintainer  => 'X. Ample <x.example@example.com>',
        timeframe_units => 'months',
        timeframe_quantity => '23',
    });

like($policy->fulltext, qr/23 months/i, 'timeframe updated form units and quantity');
