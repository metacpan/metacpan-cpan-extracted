use strict;
use warnings;
use Benchmark qw/cmpthese/;

cmpthese(
    10,
    {
        'Algorithm::Diff'     => sub { system 'STRING_DIFF_PP=1 perl ./tools/benchmark-script.pl' },
        'Algorithm::Diff::XS' => sub { system 'STRING_DIFF_PP=0 perl ./tools/benchmark-script.pl' },
    },
);
