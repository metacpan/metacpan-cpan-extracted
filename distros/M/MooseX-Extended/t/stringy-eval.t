use strict;
use Test::More;

BEGIN {
	for my $i ( 1 .. 20 ) {
		my $e = do {
			local $@;
			eval qq{package Local::Class$i; use MooseX::Extended};
			$@;
		};
		ok( !$e, "Local::Class$i compiled ok" ) or diag( "Got: $e" );
	}
	
	for my $i ( 1 .. 20 ) {
		my $e = do {
			local $@;
			eval qq{package Local::Role$i; use MooseX::Extended::Role};
			$@;
		};
		ok( !$e, "Local::Role$i compiled ok" ) or diag( "Got: $e" );
	}
};

ok 1;

done_testing;
