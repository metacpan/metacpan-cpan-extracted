#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;

{

    package TestOptOfOpt;
    use Moo;
    use MooX::Options;

    option 'opt' => ( is => 'ro', format => 's' );
    1;
}

local @ARGV = ( '--opt', '--opt -y -my-options' );
my $opt = TestOptOfOpt->new_with_options;

is $opt->opt, '--opt -y -my-options',
    'option of option is not changed for separated args';

local @ARGV = ('--opt=--opt -y -my-options');
my $opt2 = TestOptOfOpt->new_with_options;

is $opt2->opt, '--opt -y -my-options',
    'option of option is not changed for glued args';

local @ARGV = ('--op=--opt -y -my-options');
my $opt3 = TestOptOfOpt->new_with_options;

is $opt3->opt, '--opt -y -my-options',
    'option of option is not changed for shortened args';

done_testing;
