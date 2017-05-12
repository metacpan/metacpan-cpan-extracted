use Test::More;

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';

my $trustme = { trustme => [ qr/^inlinefiles$/  , qr/^open$/  , qr/^/ ,]
              };

eval 'use Test::Pod::Coverage' ;

SKIP: {        
        skip  'no Test::Pod::Coverage', scalar 1    if $@ ;
		my @modules = all_modules( "${dir}blib"  );
		pod_coverage_ok( $_, $trustme )  for  @modules;
		done_testing( scalar @modules );
};
