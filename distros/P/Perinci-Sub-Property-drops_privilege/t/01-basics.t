#!perl

use 5.010;
use strict;
use warnings;

use List::Util qw(sum);
use Perinci::Sub::Wrapper qw(wrap_sub);
use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

if ($< || $>) {
    plan skip_all => "This test requires running as root";
}

my ($sub, $meta);

$sub = sub {$>=1000; [200,"OK"]};
$meta = {v=>1.1};
test_wrap(
    name => 'privilege not restored',
    wrap_args => {sub => $sub, meta => $meta},
    wrap_status => 200,
    call_argsr => [],
    call_status => 200,
    posttest => sub {
        ok($>, "becomes normal user");
    },
);
test_wrap(
    name => 'privilege restored (temp)',
    wrap_args => {sub => $sub, meta => $meta,
                  convert=>{drops_privilege=>"temp"}},
    wrap_status => 200,
    call_argsr => [],
    call_status => 200,
    posttest => sub {
        ok(!$>, "still root");
    },
);
test_wrap(
    name => 'privilege not restored (perm)',
    wrap_args => {sub => $sub, meta => $meta,
                  convert=>{drops_privilege=>"perm"}},
    wrap_status => 200,
    call_argsr => [],
    call_status => 200,
    posttest => sub {
        ok($>, "becomes normal user");
    },
);

test_wrap(
    name => 'invalid value -> dies',
    wrap_args => {sub => $sub, meta => $meta,
                  convert=>{drops_privilege=>1}},
    wrap_dies => 1,
);

done_testing();
