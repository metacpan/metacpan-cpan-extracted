#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type => "str",
        coerce_rules => ['str_to_isbn10'],
        return_type=>"status+err+val",
    );

    is_deeply($c->([]), [undef, undef, []], "uncoerced: ref");

    is_deeply($c->("123"), [1, 'ISBN 10 must have 10 digits', undef]);
    is_deeply($c->("1 56592 257 2"), [1, 'Invalid checksum digit', undef]);
    is_deeply($c->("1-56592-257-3"), [1, undef, "1565922573"]);

    is_deeply($c->("978-0-596-52724-2"), [1, undef, "0596527241"]);
};

done_testing;
