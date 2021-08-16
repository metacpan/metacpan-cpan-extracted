use Test2::V0;

use re qw(is_regexp);
use Regexp::Pattern;

my $e = dies { re("License::foo") };
like $e,
	qr/No regexp pattern named 'foo' in package 'Regexp::Pattern::License'/,
	"get unknown -> dies";

subtest "get" => sub {
	my $re = re("License::fsful");
	ok $re;
	isa_ok( $re, 'Regexp' );
	my $e = dies { $re->possible_match_range };
	like $e,
		qr/Can\'t locate object method "possible_match_range" via package "Regexp"/,
		"call RE2 option -> dies";
	like(
		'This configure script is free software; the Free Software Foundation gives unlimited permission to copy, distribute and modify it.',
		$re
	);
	unlike( 'foo', $re );
};

subtest "get RE2 engine" => sub {
	my $re = re( "License::fsful", engine => 'RE2' );
	ok $re;
	isa_ok( $re, 'Regexp' );
	isa_ok( $re, 're::engine::RE2' );
	like(
		'This configure script is free software; the Free Software Foundation gives unlimited permission to copy, distribute and modify it.',
		$re
	);
	unlike( 'foo', $re );
};

subtest "get no engine" => sub {
	my $re = re( "License::fsful", engine => 'none' );
	ok $re;
	ref_ok( \$re, 'SCALAR' );
	like $re, qr/\Q(?:[Tt]he )?Free Software Foundation)/;
};

subtest "get bogus engine" => sub {
	my $e = dies { my $re = re( "License::fsful", engine => 'bogus' ) };
	like $e,
		qr/Unsupported regexp engine "bogus"/,
		"call bogus option -> dies";
};

done_testing;
