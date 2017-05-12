use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => 'Test::Pod::Coverage 1.00 required for testing POD coverage' if $@;
plan skip_all => 'Set PERL_TEST_POD to enable Pod coverage tests' unless $ENV{'PERL_TEST_POD'};
all_pod_coverage_ok( { also_private => [ qr/^irc_(hyb|p10)/ ] } );
