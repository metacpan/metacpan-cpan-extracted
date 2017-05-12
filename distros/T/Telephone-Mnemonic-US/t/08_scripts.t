use Test::More ;
use Test::Script ;

my $version = '5.01000';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? '../script' : 'script';
my @scripts =  <$dir/*\.pl>;

eval 'use Test::Script';

SKIP: {
	skip 'Test::Script not installed', 1 if $@;
	if ( @scripts ) {
		script_compiles $_    for @scripts;
		done_testing  scalar @scripts  ;
	}else{
		ok( 1, 'no scripts'), done_testing( 1 ), exit 0    
	}
}
