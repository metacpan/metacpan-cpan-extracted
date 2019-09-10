#!/usr/bin/env perl

use warnings;
use strict;
use v5.10;

use FindBin;

use Sweat;

use Test::More;

# For now, just run a very basic test with silly options and make sure that
# the transcript looks as expected.

my $sweat = Sweat->new(
    drill_count => 13,
    speech_program => "$FindBin::Bin/bin/noop",
    drill_length => 0,
    rest_length => 0,
    side_switch_length => 0,
    drill_prep_length => 0,
    entertainment => 0,
);

my $transcript;
open (my $fh, '>', \$transcript);
my $old_fh = select $fh;
$sweat->sweat;
select $old_fh;
close $fh;

is (length $transcript, 718, 'Basic transcript looks correct.');

done_testing();
