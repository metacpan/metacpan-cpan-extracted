use 5.008003;
use warnings;
use strict;
use Test::More;
use Test::Fatal;

use Term::Choose;

use FindBin qw( $RealBin );
use lib $RealBin;
use Data_Test_Arguments;


my $new = Term::Choose->new();
my $exception;

$exception = exception { $new->config() };
ok( ! defined $exception, '$new->config()' );

$exception = exception { $new->config( {} ) };
ok( ! defined $exception, '$new->config( {} )' );


my $valid_values = Data_Test_Arguments::valid_values();
my $new1  = Term::Choose->new( { order => 1, layout => 2, mouse => 3 } ); # ?

for my $opt ( sort keys %$valid_values ) {
    for my $val ( @{$valid_values->{$opt}}, undef ) {
        my $exception = exception { $new1->config( { $opt => $val } ) };
        my $value = defined $val ? $val : 'undef';
        ok( ! defined $exception, "\$new->config( { $opt => $value } )"  );
    }
}


my $mixed_options_1 = Data_Test_Arguments::mixed_options_1();
$exception = exception { $new1->config( $mixed_options_1 ) };
ok( ! defined $exception, "\$new->config( { >>> } )"  );


my $mixed_options_2 = Data_Test_Arguments::mixed_options_2();
$exception = exception { $new1->config( $mixed_options_2 ) };
ok( ! defined $exception, "\$new->config( { <<< } )" );



done_testing();
