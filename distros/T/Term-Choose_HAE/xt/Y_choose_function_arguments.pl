#!/usr/bin/env perl
use 5.008003;
use warnings;
use strict;

use Term::Choose_HAE qw( choose );

use FindBin qw( $RealBin );
use lib $RealBin;
use Y_Data_Test_Arguments;


choose( [] );
choose( [], {} );

my $valid_values = Y_Data_Test_Arguments::valid_values();
for my $opt ( sort keys %$valid_values ) {
    for my $val ( @{$valid_values->{$opt}}, undef ) {
        choose( [], { $opt => $val } );
    }
}

choose( [], Y_Data_Test_Arguments::mixed_options_1() );
choose( [], Y_Data_Test_Arguments::mixed_options_2() );


print "<End_fc_va>\n";
