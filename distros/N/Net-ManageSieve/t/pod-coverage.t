use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok({ 
	trustme => [
		qr/^(?:authentificate|bye|dbgPrint|deep_copy|login|ok|quit)$/
	]
} , "non-documented functions in Net::ManageSieve package");
