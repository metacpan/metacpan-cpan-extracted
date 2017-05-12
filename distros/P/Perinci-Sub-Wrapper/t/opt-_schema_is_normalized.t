#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

subtest 'opt: _schema_is_normalized' => sub {
    my $sub  = sub {};
    my $meta = {v=>1.1, args=>{a=>{schema=>"int"},
                               b=>{cmdline_aliases=>{B=>{schema=>"bool"}}}}};
    test_wrap(
        name => "normalized",
        wrap_args => {sub => $sub, meta => $meta},
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            my $newmeta = $wrap_res->[2]{meta};
            is_deeply($newmeta->{args}{a}{schema}, [int=>{}, {}],
                      "schemas by default are normalized (a)");
            is_deeply($newmeta->{args}{b}{cmdline_aliases}{B}{schema},[bool=>{},{}],
                      "schemas in cmdline_aliases by default are normalized (b)");
        },
    );
    test_wrap(
        name => 'not normalized',
        wrap_args => {sub => $sub, meta => $meta, _schema_is_normalized=>1},
        wrap_dies => 1,
        # because Data::Sah will assume that schema is normalized, thus will die
        # trying to access scalar "int" as array.
    );
};

DONE_TESTING:
done_testing;
