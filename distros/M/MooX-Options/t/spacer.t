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
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

{

    package t;
    use Moo;
    use MooX::Options spacer => '+';

    option 'a' => ( is => 'ro' );
    option 'b' => ( is => 'ro', spacer_before => 1, spacer_after => 1 );
    option 'c' => ( is => 'ro' );

    1;
}

my $opt = t->new_with_options;
my @usages;

trap { $opt->options_usage };
@usages = grep {/\-[abc]\s+|\+/} split( /\n/, $trap->stdout );
like $usages[0], qr/a/,   'a is first';
like $usages[1], qr/\++/, 'then the spacer';
like $usages[2], qr/b/,   'b is next';
like $usages[3], qr/\++/, 'then the spacer';
like $usages[4], qr/c/,   'c is last';

trap { $opt->options_help };
@usages = grep {/[abc]:|\+/} split( /\n/, $trap->stdout );
like $usages[0], qr/a:/,  'a is first';
like $usages[1], qr/\++/, 'then the spacer';
like $usages[2], qr/b:/,  'b is next';
like $usages[3], qr/\++/, 'then the spacer';
like $usages[4], qr/c:/,  'c is last';

done_testing;
