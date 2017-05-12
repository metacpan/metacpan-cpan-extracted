#!perl

use 5.010;
use strict;
use warnings;

use DateTime;
use Perinci::Sub::Wrapper qw(wrap_sub);
use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

my ($sub, $meta);

my $re = qr/a/;
my $re_str = "$re";
my $dt = DateTime->now;
my $dt_epoch = $dt->epoch;

$sub = sub {[200,"OK", [0, $re, {k1=>$dt}, [sub{}]] ]; };
$meta = {v=>1.1};

for my $imp ("for") { # Data::Rmap as of 0.62 can't handle re & coderef yet
    local $Perinci::Sub::Wrapper::Property::result_postfilter::_implementation =
        $imp;
    test_wrap(
        name => "result_filter (implementation=$imp)",
        wrap_args => {sub => $sub, meta => $meta, convert=>{
            result_postfilter => {
                re   => 'str',
                date => 'epoch',
                code => 'str',
            },
        }},
        wrap_status => 200,
        call_argsr => [n=>1],
        call_status => 200,
        call_res => [200, "OK", [0, $re_str, {k1=>$dt_epoch}, ['CODE']] ],
    );
}

# XXX test DateTime -> mysql time
# XXX test DateTime -> YYYY-mm-dd

DONE_TESTING:
done_testing();
