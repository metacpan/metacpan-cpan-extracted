use Test::More  ;
plan tests=>1;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for POD coverage" if $@;

#all_pod_coverage_ok();
pod_coverage_ok( 'String::Rexx', { trustme => [
					qr/^ b2d $/x,
					qr/^ b2x $/x,
					qr/^ c2x $/x,
					qr/^ centre $/x,
					qr/^ d2b $/x,
					qr/^ sign $/x,
					qr/^ x2b $/x,
					qr/^ x2c $/x,
					qr/^ x2d $/x,
			]});

