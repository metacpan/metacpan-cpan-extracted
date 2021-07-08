use Test2::V0;

use Regexp::Pattern;

my $e = dies { re("License::foo") };
like $e,
	qr/No regexp pattern named 'foo' in package 'Regexp::Pattern::License'/,
	"get unknown -> dies";

subtest "get" => sub {
	my $re = re("License::fsful");
	ok $re;
	like(
		'This configure script is free software; the Free Software Foundation gives unlimited permission to copy, distribute and modify it.',
		$re
	);
	unlike( 'foo', $re );
};

# TODO
#subtest "get dynamic" => sub {
#	my $re3a = re( "License::re3", variant => 'A' );
#	ok $re3a;
#	ok( '123-456' =~ $re3a );
#	ok( !( 'foo' =~ $re3a ) );
#	my $re3b = re( "License::re3", variant => 'B' );
#	ok $re3b;
#	ok( '123-45-67890' =~ $re3b );
#	ok( !( '123-456' =~ $re3b ) );
#};

done_testing;
