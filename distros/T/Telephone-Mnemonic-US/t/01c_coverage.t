use Test::More;

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';
my $trustme = { trustme => [ 	  qr/^combine_one$/  
                                , qr/^combinethem$/ 
                                , qr/^str_pairs$/ 
                                , qr/^BUILD$/ 
                                , qr/dict_io$/
                                , qr/to_words$/
                                , ], };

eval 'use Test::Pod::Coverage' ;

SKIP: {        
        skip  'no Test::Pod::Coverage', scalar 1    if $@ ;
		my @modules = all_modules( "${dir}blib"  );
		pod_coverage_ok( $_, $trustme )  for  @modules;
		done_testing( scalar @modules );
};
