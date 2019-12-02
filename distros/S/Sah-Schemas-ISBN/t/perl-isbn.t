#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type => "str",
        coerce_rules => ['From_str::to_isbn'],
        return_type=>"status+err+val",
    );

    is_deeply($c->([]), [undef, undef, []], "uncoerced: ref");

    is_deeply($c->("123"), [1, 'ISBN must be 10 or 13 digits', undef]);
    is_deeply($c->("1 56592 257 2"), [1, 'Invalid ISBN 10 checksum digit', undef]);
    is_deeply($c->("1-56592-257-3"), [1, undef, "1565922573"]);

    is_deeply($c->("978-0-596-52724-3"), [1, 'Invalid ISBN 13 checksum digit', undef]);
    is_deeply($c->("978-0-596-52724-2"), [1, undef, "9780596527242"]);
};

done_testing;
