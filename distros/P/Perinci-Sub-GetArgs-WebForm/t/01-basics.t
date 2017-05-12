#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Perinci::Sub::GetArgs::WebForm qw(get_args_from_webform);

test_getargs(
    form => {},
    args => {},
);
test_getargs(
    form => {a=>1, b=>2, "c/a"=>3, "c/b"=>4},
    args => {a=>1, b=>2, c=>{a=>3, b=>4}},
);
test_getargs(
    form => {a=>1, b=>2, "c/c/c/a"=>3},
    args => {a=>1, b=>2, c=>{c=>{c=>{a=>3}}}},
);


DONE_TESTING:
done_testing();

sub test_getargs {
    my (%args) = @_;

    subtest +($args{name} // '') => sub {
        my $res = get_args_from_webform($args{form});
        if ($args{args}) {
            is_deeply($res, $args{args}, "result")
                or diag explain $res;
        }
        #if ($args{posttest}) {
        #    $args{posttest}->();
        #}

        done_testing();
    };
}
