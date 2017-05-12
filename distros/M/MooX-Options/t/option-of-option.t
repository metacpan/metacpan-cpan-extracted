#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use t::Test;

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
