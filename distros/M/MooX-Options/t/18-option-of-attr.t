#!perl

use strict;
use warnings all => 'FATAL';
use Test::More;

{

    package RoleOptOfAttr;
    use Moo::Role;
    use MooX::Options;

    has 'opt' => ( is => 'ro' );
    1;
}

{

    package TestOptOfAttr;
    use Moo;
    use MooX::Options;

    with "RoleOptOfAttr";

    option '+opt' => ( format => 's' );
}

local @ARGV = ( '--opt', 'foo' );
my $opt = TestOptOfAttr->new_with_options;

is $opt->opt, 'foo', 'option of option is not changed for separated args';

local @ARGV = ('--opt=bar');
my $opt2 = TestOptOfAttr->new_with_options;

is $opt2->opt, 'bar', 'option of option is not changed for glued args';

done_testing;
