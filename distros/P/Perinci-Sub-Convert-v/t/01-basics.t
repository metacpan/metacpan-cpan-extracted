#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Perinci::Sub::Convert::v qw(convert_property_v);

my $v10meta = {
    args=>{
        a=>[str => {default=>'x', arg_pos=>0, arg_greedy=>1,
                    arg_aliases=>{a1=>{}}}],
        b=>'int',
    },
    result=>'int',
};

my $v11meta = {
    v => 1.1,
    args => {
        a => {
            schema => [str => {default=>'x'}],
            pos => 0,
            greedy => 1,
            cmdline_aliases => {
                a1=>{},
            },
        },
        b => {
            schema => 'int',
        },
    },
    result => {
        schema => 'int',
    },
};

my $res = convert_property_v(meta=>$v10meta);
delete $res->{_note};
is_deeply($res, $v11meta) or diag explain $res;

DONE_TESTING:
done_testing;
