#!/usr/bin/env perl
use 5.008003;
use warnings;
use strict;

use Term::Choose_HAE qw( choose );

use FindBin qw( $RealBin );
use lib $RealBin;
use Y_Data_Test_Arguments;


eval { choose(           ); 1 } and die 'choose();';

eval { choose( undef     ); 1 } and die 'choose( undef );';

eval { choose( {}        ); 1 } and die 'choose( {} );';

eval { choose( undef, {} ); 1 } and die 'choose( undef, {} );';

eval { choose( 'a'       ); 1 } and die 'choose( "a" );';

eval { choose( 1, {}     ); 1 } and die 'choose( 1, {} );';

eval { choose( [], []    ); 1 } and die 'choose( [], [] );';

eval { choose( [], 'b'   ); 1 } and die 'choose( [], "b" );';

eval { choose( [], { hello => 1, world => 2 } ); 1 } and die 'choose( [], { hello => 1, world => 2 } );';


my $valid_values = Y_Data_Test_Arguments::invalid_values();
for my $opt ( sort keys %$valid_values ) {
    for my $val ( @{$valid_values->{$opt}} ) {
        eval { choose( [], { $opt => $val } ); 1 } and die "choose( { $opt => $val } );";
    }
}

eval { choose( [], Y_Data_Test_Arguments::mixed_invalid_1() ); 1 } and die 'choose( >>> );';
eval { choose( [], Y_Data_Test_Arguments::mixed_invalid_2() ); 1 } and die 'choose( <<< );';


print "<End_fc_ia>\n";
