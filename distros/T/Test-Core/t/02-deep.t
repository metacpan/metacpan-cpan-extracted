use Test::Core;

my $got1      = { foo => 1 };
my $got2      = { bar => 2 };
my $expected  = { foo => 1, bar => 2 };
cmp_deeply($got1, subhashof($expected), '$got1 subhashof $expected');
cmp_deeply($got2, subhashof($expected), '$got2 subhashof $expected');

done_testing;
