use v5.30;
use strict;
use warnings;
use utf8;

use Test::More;

my $ok = eval <<'PERL';
    package Local::Prelude::Smoke;

    use Modern::Perl::Prelude;

    our %RESULT;

    sub run {
        state $counter = 0;
        $counter++;

        my $out = '';
        {
            open my $fh, '>', \$out or die "open scalar fh failed: $!";
            local *STDOUT = $fh;
            say 'hello';
        }

        my $trimmed = trim("  hello \n");
        my $folded  = fc("Straße");

        my $obj = bless {}, 'Local::Prelude::Smoke::Object';

        my $caught = '';
        try {
            die "boom\n";
        }
        catch ($e) {
            $caught = $e;
        }

        my $tmp = [];
        my $ref = $tmp;

        my $weak_before = is_weak($ref) ? 1 : 0;
        weaken($ref);
        my $weak_after = is_weak($ref) ? 1 : 0;
        unweaken($ref);
        my $weak_restored = is_weak($ref) ? 1 : 0;

        %RESULT = (
            said            => $out,
            trimmed         => $trimmed,
            folded          => $folded,
            blessed         => blessed($obj),
            caught_like     => ($caught =~ /boom/) ? 1 : 0,
            true_value      => true  ? 1 : 0,
            false_value     => false ? 1 : 0,
            ceil_value      => ceil(1.2),
            floor_value     => floor(1.8),
            refaddr_defined => defined refaddr($obj) ? 1 : 0,
            reftype         => reftype($obj),
            state_counter   => $counter,
            weak_before     => $weak_before,
            weak_after      => $weak_after,
            weak_restored   => $weak_restored,
        );

        return 1;
    }

    run();
PERL

ok($ok, 'module imports compile and run')
    or diag $@;

is($Local::Prelude::Smoke::RESULT{said},    "hello\n", 'say imported');
is($Local::Prelude::Smoke::RESULT{trimmed}, 'hello',   'trim imported');
is($Local::Prelude::Smoke::RESULT{folded},  'strasse', 'fc imported');

is(
    $Local::Prelude::Smoke::RESULT{blessed},
    'Local::Prelude::Smoke::Object',
    'blessed imported',
);

ok($Local::Prelude::Smoke::RESULT{caught_like}, 'try/catch imported');
is($Local::Prelude::Smoke::RESULT{true_value},  1, 'true imported');
is($Local::Prelude::Smoke::RESULT{false_value}, 0, 'false imported');

is($Local::Prelude::Smoke::RESULT{ceil_value},  2, 'ceil imported');
is($Local::Prelude::Smoke::RESULT{floor_value}, 1, 'floor imported');

ok($Local::Prelude::Smoke::RESULT{refaddr_defined}, 'refaddr imported');
is($Local::Prelude::Smoke::RESULT{reftype}, 'HASH', 'reftype imported');

is($Local::Prelude::Smoke::RESULT{state_counter}, 1, 'state feature enabled');

is($Local::Prelude::Smoke::RESULT{weak_before},   0, 'is_weak before weaken');
is($Local::Prelude::Smoke::RESULT{weak_after},    1, 'weaken/is_weak imported');
is($Local::Prelude::Smoke::RESULT{weak_restored}, 0, 'unweaken imported');

done_testing;
