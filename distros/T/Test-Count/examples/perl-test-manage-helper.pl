#!/usr/bin/perl

use strict;
use warnings;

use Test::Count::Filter;
use Getopt::Long;

my $filetype = "perl";
GetOptions('ft=s' => \$filetype);

my $filter =
    Test::Count::Filter->new(
        {
            ($filetype eq "arc") ?
            (
                assert_prefix_regex => qr{; TEST},
                plan_prefix_regex => qr{\(plan\s+},
            ) :
            ()
        }
    );

$filter->process();
