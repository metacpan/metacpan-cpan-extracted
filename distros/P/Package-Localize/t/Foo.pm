package Foo;
our $var = 42;
our @var = ( 42, [43] );
our %var = ( foo => {bar => 42});
sub inc { $var++ }
sub var_ar { \@var }
sub var_h { \%var }
1;