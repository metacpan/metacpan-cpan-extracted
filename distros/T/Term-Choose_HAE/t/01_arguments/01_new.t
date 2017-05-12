use 5.010001;
use warnings;
use strict;
use Test::More;
use Test::Fatal;

use Term::Choose_HAE;

use FindBin qw( $RealBin );
use lib $RealBin;
use Data_Test_Arguments;


my $new1;
my $exception = exception { $new1 = Term::Choose_HAE->new() };
ok( ! defined $exception, '$new = Term::Choose_HAE->new()' );
ok( $new1, '$new = Term::Choose_HAE->new()' );

my $new;
$exception = exception { $new = Term::Choose_HAE->new( {} ) };
ok( ! defined $exception, '$new = Term::Choose_HAE->new( {} )' );


my %new;
my $n = 1; # ?

my $valid_values = Data_Test_Arguments::valid_values();

for my $opt ( sort keys %$valid_values ) {
    for my $val ( @{$valid_values->{$opt}}, undef ) {
        my $exception = exception { $new{$n++} = Term::Choose_HAE->new( { $opt => $val } ) };
        my $value = defined $val ? $val : 'undef';
        ok( ! defined $exception, "\$new = Term::Choose_HAE->new( { $opt => $value } )" );
    }
}


my $mixed_options_1 = Data_Test_Arguments::mixed_options_1();
$exception = exception { $new{$n++} = Term::Choose_HAE->new( $mixed_options_1 ) };
ok( ! defined $exception, "\$new = Term::Choose_HAE->new( { >>> } )"  );


my $mixed_options_2 = Data_Test_Arguments::mixed_options_2();
$exception = exception { $new{$n++} = Term::Choose_HAE->new( $mixed_options_2 ) };
ok( ! defined $exception, "\$new = Term::Choose_HAE->new( { <<< } )" );



done_testing();
