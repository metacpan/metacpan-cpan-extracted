use Test::More;

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';

my $trustme = { trustme => [ 
       qw/ b2d b2x c2x centre d2b sign x2b x2c x2d /,
              ]};

eval 'use Test::Pod::Coverage' ;

SKIP: {        
        skip  'no Test::Pod::Coverage', scalar 1    if $@ ;
		my @modules = all_modules( "${dir}blib"  );
		pod_coverage_ok( $_, $trustme )  for  @modules;
		done_testing( scalar @modules );
};
