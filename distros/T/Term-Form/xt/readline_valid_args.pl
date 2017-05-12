#!/usr/bin/env perl
use strict;
use warnings;
use 5.008003;

use Term::Form;

use FindBin qw( $RealBin );
use lib $RealBin;
use Data_Test_Arguments;

my $tiny  = Term::Form->new();
my $a_ref = Data_Test_Arguments::valid_args();

for my $ref ( @$a_ref  ) {
    my $args = $ref->{args};

    my $line = $tiny->readline( @$args );
    print "<$line>\n";
}
