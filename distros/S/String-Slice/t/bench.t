use strict;
use warnings;
use Test::More;

use Benchmark qw(timethese);
use String::Slice;

if ($ENV{PERL_STRING_SLICE_BENCHMARK}) {
    my $count = 200;

    my $string = 'o' x 1024 x $count;
    my $string2 = 'o' x 1024 x $count;
    # use utf8; my $string = 'ö' x 1024 x $count;
    # use utf8; my $string2 = 'ö' x 1024 x $count;

    my $slice = '';
    my $var = 0;

    timethese(1, {
        'substr' => sub {
            # substr 10 chars at a time:
            for (my $i = 0; $i < length($string2) - 10; $i += 10) {
            if (substr($string2, $i)) { $var++ }
            }
        },

        'slice' => sub {
            # slice 10 chars at a time:
            for (my $i = 0; $i < length($string) - 10; $i += 10) {
            if (slice($slice, $string, $i)) { $var++ }
            }
        },
    });
}

pass 'Just a benchmarking test';
done_testing;
