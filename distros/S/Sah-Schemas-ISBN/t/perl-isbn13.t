#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type => "str",
        coerce_rules => ['From_str::to_isbn13'],
        return_type=>"status+err+val",
    );

    is_deeply($c->([]), [undef, undef, []], "uncoerced: ref");

    is_deeply($c->("123"), [1, 'ISBN 13 must have 13 digits', undef]);
    is_deeply($c->("978 0 596 52724 3"), [1, 'Invalid checksum digit', undef]);
    is_deeply($c->("978-0-596-52724-2"), [1, undef, "9780596527242"]);

    is_deeply($c->("0-596-52724-1"), [1, undef, "9780596527242"]);
};

done_testing;
