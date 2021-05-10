use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Myriad::Util::Secret;

subtest 'basic secret handling' => sub {
    my $secret = new_ok('Myriad::Util::Secret' => [ "example" ]);
    is("$secret", '***', 'string returns placeholder value');
    cmp_ok($secret, 'ne', '***', 'but string is not equal to placeholder value');
    cmp_ok($secret, 'eq', 'example', 'and string is equal to original value');
    is($secret->secret_value, 'example', 'and real value is accessible via dedicated method');
    unlike(Data::Dumper::Dumper($secret), qr/example/, 'and Data::Dumper doesn\'t give away any secrets');
    done_testing;
};

subtest 'edge cases for secrets and comparisons' => sub {
    for my $case (
        '',
        0,
        1,
        '0e0',
        'short',
        'a bit longer',
        'quite a lot longer but not really excessive for a secret value',
        ('x' x 1024),
    ) {
        # note $case;
        my $secret = new_ok('Myriad::Util::Secret' => [ $case ]);
        is($secret, $case, 'secret matches original value');
        is($secret->secret_value, $case, 'and ->secret_value returns expected content');
        ok($secret->equal($case), 'and ->equal is happy');
        is($secret, Myriad::Util::Secret->new($case), 'can also match against another instance');
    }
    done_testing;
};

done_testing;

