use Test2::V0;

use Regexp::Pattern;

plan 4;

my $e = dies { re("License::foo") };
like $e,
	qr/No regexp pattern named 'foo' in package 'Regexp::Pattern::License'/,
	"get unknown -> dies";

subtest "get" => sub {
	my $re = re("License::fsful");
	isa_ok $re, ['Regexp'], 're object is a Regexp';
	like(
		'This configure script is free software; the Free Software Foundation gives unlimited permission to copy, distribute and modify it.',
		$re
	);
	unlike( 'foo', $re );
};

subtest "get no engine" => sub {
	my $re = re( "License::fsful", engine => 'none' );
	ok $re;
	ref_ok \$re, 'SCALAR', 're output is a scalar';
	like $re, qr/\Q(?:[Tt]he )?Free Software Foundation)/;
};

subtest "get bogus engine" => sub {
	my $e = dies { my $re = re( "License::fsful", engine => 'bogus' ) };
	like $e,
		qr/Unsupported regexp engine "bogus"/,
		'call with bogus engine -> dies';
};

done_testing;
