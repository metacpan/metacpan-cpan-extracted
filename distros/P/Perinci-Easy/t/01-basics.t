#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Perinci::Easy qw(defsub);

our %SPEC;

defsub name => 'foo', summary => 'Foo summary',
    code => sub {
        [200, "OK"];
    };
is($SPEC{foo}{v}, 1.1, "metadata property v");
is($SPEC{foo}{summary}, "Foo summary", "metadata property v");
is_deeply(foo(), [200, "OK"], "result");

done_testing;
