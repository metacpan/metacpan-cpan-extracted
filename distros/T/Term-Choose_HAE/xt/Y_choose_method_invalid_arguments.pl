#!/usr/bin/env perl
use 5.008003;
use warnings;
use strict;

use Term::Choose_HAE;

use FindBin qw( $RealBin );
use lib $RealBin;
use Y_Data_Test_Arguments;


my $new = Term::Choose->new();

eval { $new->choose(           ); 1 } and die '$new->choose();';

eval { $new->choose( undef     ); 1 } and die '$new->choose( undef );';

eval { $new->choose( {}        ); 1 } and die '$new->choose( {} );';

eval { $new->choose( undef, {} ); 1 } and die '$new->choose( undef, {} );';

eval { $new->choose( 'a'       ); 1 } and die '$new->choose( "a" );';

eval { $new->choose( 1, {}     ); 1 } and die '$new->choose( 1, {} );';

eval { $new->choose( [], []    ); 1 } and die '$new->choose( [], [] );';

eval { $new->choose( [], 'b'   ); 1 } and die '$new->choose( [], "b" );';

eval { $new->choose( [], { hello => 1, world => 2 } ); 1 } and die '$new->choose( [], { hello => 1, world => 2 } );';


my $valid_values = Y_Data_Test_Arguments::invalid_values();
for my $opt ( sort keys %$valid_values ) {
    for my $val ( @{$valid_values->{$opt}} ) {
        eval { $new->choose( [], { $opt => $val } ); 1 } and die "\$new->choose( { $opt => $val } );";
    }
}

eval { $new->choose( [], Y_Data_Test_Arguments::mixed_invalid_1() ); 1 } and die '$new->choose( >>> );';
eval { $new->choose( [], Y_Data_Test_Arguments::mixed_invalid_2() ); 1 } and die '$new->choose( <<< );';


print "<End_mc_ia>\n";
