#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests;

plan skip_all => 'Perl >= 5.028 only'
    if $] lt '5.028';

warnings_like {

    package Local::Test1;
    use MooseX::Extended;
    field 'foo';
}
qr/field 'foo' is read-only and has no init_arg or default, defined at .+\bwarnings.t line 13/;

warning_is {

    package Local::Test2;
    use MooseX::Extended;
    no warnings 'MooseX::Extended::naked_fields';
    field 'bar';
}
undef;

done_testing;
