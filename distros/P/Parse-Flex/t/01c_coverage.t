use Test::More tests=> 2 ;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for POD coverage" if $@;

#all_pod_coverage_ok();

my $trustme = { trustme => [ 	qr/^inlinefiles$/  , 
				qr/^open$/         ,
                             	qr/^create_push$/  , 
				qr/^manual$/       , 
			     	qr/^typeme$/       ,
                           ],
              };
pod_coverage_ok( 'Parse::Flex', { trustme => [ 	
				qr/^inlinefiles$/  , 
				qr/^open$/         ,
                             	qr/^create_push$/  , 
				qr/^manual$/       , 
			     	qr/^typeme$/       ,
]});

pod_coverage_ok( 'Parse::Flex::Generate', { trustme => [    	
				qr/^Usage$/            , 
				qr/^check_argv$/       ,
                             	qr/^makefile_content$/ , 
				qr/^pm_content$/       , 
			     	qr/^xs_content$/       ,
]});

