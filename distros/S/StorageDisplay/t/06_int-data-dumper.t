#!/usr/bin/perl
#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2020 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test2::V0;

use Data::Dumper;

my $size=3999264768;
my $used=0;
my $h = {
    'free' => $size - $used,
};

$Data::Dumper::Indent = 0;       # turn off all pretty print

my $res='$VAR1 = {\'free\' => 3999264768};';
my $res2='$VAR1 = {\'free\' => \'3999264768\'};';

is( Dumper($h), $res, "Data::Dumper dumping integer");

$Data::Dumper::Purity = 1;

is( Dumper($h), $res, "Data::Dumper dumping integer with purity set");

$Data::Dumper::Useperl = 1;

is( Dumper($h), $res2, "Data::Dumper dumping integer with useperl set");

done_testing;   # reached the end safely

