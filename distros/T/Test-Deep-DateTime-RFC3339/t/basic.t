use strict;
use Test::More;
use Test::Deep qw< :all >;
use Test::Deep::DateTime::RFC3339;
use DateTime::Format::RFC3339;

my $rfc3339 = DateTime::Format::RFC3339->new;
my $now     = DateTime->now( time_zone => 'UTC' );
my ($ok, $stack);

sub not_deeply($$$$) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($got, $expected, $regex, $msg) = (@_);
    my $diag_msg = "diagnostics like /$regex/";

    my ($ok, $stack) = eval { cmp_details($got, $expected) };
    diag "cmp_details died: $@" if $@;

    if (ok !$ok, $msg || "") {
        like eval { deep_diag($stack) }, $regex, $diag_msg;
        diag "deep_diag died: $@" if $@;
    } else {
        ok 0, "$diag_msg (no diagnostics on success)";
    }
}

cmp_deeply { created => '1987-12-18T00:00:00Z' },
           { created => datetime_rfc3339() },
           "parseable only, good";

not_deeply { created => '1987-12-18' },
           { created => datetime_rfc3339() },
           qr/Can't parse '1987-12-18'/,
           "parseable only, bad";

cmp_deeply { created => $rfc3339->format_datetime($now) },
           { created => datetime_rfc3339($now) },
           "exact, equal";

ok !
(eq_deeply { created => $rfc3339->format_datetime($now) },
           { created => datetime_rfc3339('1987-12-18T00:00:00Z') }),
           "exact, not equal";

cmp_deeply { created => $rfc3339->format_datetime($now->clone->add( seconds => 3 )) },
           { created => datetime_rfc3339($now, '5s') },
           "within tolerance, positive";

cmp_deeply { created => $rfc3339->format_datetime($now->clone->subtract( seconds => 3 )) },
           { created => datetime_rfc3339($now, '5s') },
           "within tolerance, negative";

ok !
(eq_deeply { created => $rfc3339->format_datetime($now->clone->add( seconds => 3 )) },
           { created => datetime_rfc3339($now, '1s') }),
           "outside tolerance, positive";

ok !
(eq_deeply { created => $rfc3339->format_datetime($now->clone->subtract( seconds => 3 )) },
           { created => datetime_rfc3339($now, '1s') }),
           "outside tolerance, negative";

cmp_deeply { created => $rfc3339->format_datetime($now->clone->add( seconds => 3 )) },
           { created => datetime_rfc3339($now, DateTime::Duration->new( seconds => 3 )) },
           "tolerance as DateTime::Duration, closed interval";

is datetime_rfc3339($now)->renderExp,
   $rfc3339->format_datetime($now),
   "rendering of expected value is RFC3339";

is datetime_rfc3339($now, '3s')->renderExp,
   $rfc3339->format_datetime($now) . " +/- 3 seconds",
   "rendering of expected value is RFC3339 +/- human readable tolerance";

my $got = $now->clone->add( seconds => 5 );
is datetime_rfc3339($now)->renderGot($got),
   $rfc3339->format_datetime($got),
   "rendering of got value is RFC3339";

ok !eval { datetime_rfc3339("bogus") }, "expected parse failure";
like $@, qr/Expected datetime/i, "error message";

ok !eval { datetime_rfc3339($now, "bogus") }, "tolerance parse failure";
like $@, qr/Expected tolerance/i, "error message";

not_deeply { created => 'bogus' },
           { created => datetime_rfc3339($now) },
           qr/Can't parse 'bogus'/,
           "failure on unparseable value";

done_testing;
