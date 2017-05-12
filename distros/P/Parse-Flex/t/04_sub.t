use Test::More ;
use Parse::Flex;
use Parse::Flex::Generate;

my @flex =  qw( typeme );
my @gen  =  qw( pm_content  makefile_content  xs_content Usage check_argv );
 


plan tests=> scalar @flex + scalar @gen ;


ok UNIVERSAL::can( Parse::Flex,           $_ )    for @flex;
ok UNIVERSAL::can( Parse::Flex::Generate, $_ )    for @gen;
