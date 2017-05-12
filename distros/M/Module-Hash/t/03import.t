use strict;
use Test::More tests => 3;

{
	my $MOD;
	use Module::Hash $MOD;

	my $number = $MOD->{"Math::BigInt"}->new(42);
	ok( $number->isa("Math::BigInt") );
}

{
	my %MOD;
	use Module::Hash \%MOD;

	my $number = $MOD{"Math::BigInt"}->new(42);
	ok( $number->isa("Math::BigInt") );
}

{
	use Module::Hash \%\;

	my $number = $\{"Math::BigInt"}->new(42);
	ok( $number->isa("Math::BigInt") );
}
