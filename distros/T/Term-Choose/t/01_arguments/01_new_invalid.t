use 5.008003;
use warnings;
use strict;
use Test::More;
use Test::Fatal;

use Term::Choose;

use FindBin qw( $RealBin );
use lib $RealBin;
use Data_Test_Arguments;

my $exception;

my $regex = qr/^new:/;

$exception = exception { my $new = Term::Choose->new( {}, {} ) };
ok( $exception =~ $regex, "\$new = Term::Choose->new( {}, {} ) => $exception" );

$exception = exception { my $new = Term::Choose->new( 'a' ) };
ok( $exception =~ $regex, "\$new = Term::Choose->new( 'a' ) => $exception" );

$exception = exception { my $new = Term::Choose->new( { hello => 1, world => 2 } ) };
ok( $exception =~ $regex, "\$new = Term::Choose->new( { hello => 1, world => 2 } ) => $exception" );

my %new;
my $n = 1; # ?

my $invalid_values = Data_Test_Arguments::invalid_values();

for my $opt ( sort keys %$invalid_values ) {
    for my $val ( @{$invalid_values->{$opt}} ) {
        my $exception = exception { $new{$n++} = Term::Choose->new( { $opt => $val }  ) };
        ok( $exception =~ $regex, "\$new = Term::Choose->new( { $opt => $val } ) => $exception" );
    }
}


my $mixed_invalid_1 = Data_Test_Arguments::mixed_invalid_1();
$exception = exception { $new{$n++} = Term::Choose->new( $mixed_invalid_1  ) };
ok( $exception =~ $regex, "\$new = Term::Choose->new( { >>> } ) => $exception" );


my $mixed_invalid_2 = Data_Test_Arguments::mixed_invalid_2();
$exception = exception { $new{$n++} = Term::Choose->new( $mixed_invalid_2 ) };
ok( $exception =~ $regex, "\$new = Term::Choose->new( { <<< } ) => $exception" );



done_testing();
