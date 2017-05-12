use Test::More tests => 1;
use Test::Warn;
use RDF::Prefixes;

warning_like {
	RDF::Prefixes->new({
		'-x' => 'http://www.example.com/',
	})
} qr{^Ignored suggestion -x\b};

