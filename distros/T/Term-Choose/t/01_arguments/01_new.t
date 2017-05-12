use 5.008003;
use warnings;
use strict;
use Test::More;
use Test::Fatal;

use Term::Choose;

use FindBin qw( $RealBin );
use lib $RealBin;
use Data_Test_Arguments;


my $new1;
my $exception = exception { $new1 = Term::Choose->new() };
ok( ! defined $exception, '$new = Term::Choose->new()' );
ok( $new1, '$new = Term::Choose->new()' );

my $new;
$exception = exception { $new = Term::Choose->new( {} ) };
ok( ! defined $exception, '$new = Term::Choose->new( {} )' );


my %new;
my $n = 1; # ?

my $valid_values = Data_Test_Arguments::valid_values();

for my $opt ( sort keys %$valid_values ) {
    for my $val ( @{$valid_values->{$opt}}, undef ) {
        my $exception = exception { $new{$n++} = Term::Choose->new( { $opt => $val } ) };
        my $value = defined $val ? $val : 'undef';
        ok( ! defined $exception, "\$new = Term::Choose->new( { $opt => $value } )" );
    }
}


my $mixed_options_1 = Data_Test_Arguments::mixed_options_1();
$exception = exception { $new{$n++} = Term::Choose->new( $mixed_options_1 ) };
ok( ! defined $exception, "\$new = Term::Choose->new( { >>> } )"  );


my $mixed_options_2 = Data_Test_Arguments::mixed_options_2();
$exception = exception { $new{$n++} = Term::Choose->new( $mixed_options_2 ) };
ok( ! defined $exception, "\$new = Term::Choose->new( { <<< } )" );



done_testing();
