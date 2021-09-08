#! /usr/bin/env perl
use Test2::V0;
use Mock::Data::Regex;
use Mock::Data;
use Data::Dumper;
sub explain { local $Data::Dumper::Useqq=1; Data::Dumper::Dumper(shift) }

# The following are checks to varify the type and content of Regex::ParseNodes
sub is_seq {
	my ($pattern, $rep)= @_;
	return object {
		call pattern => $pattern;
		call repetition => $rep if $rep;
		etc;
	}
}
sub is_charset {
	my ($notation, $rep)= @_;
	return object {
		call pattern => object { call notation => $notation; };
		call repetition => $rep if $rep;
		etc;
	}
}
sub is_or {
	my ($pattern, $rep)= @_;
	return object {
		call pattern => $pattern;
		call repetition => $rep if $rep;
		etc;
	};
}
sub is_assert {
	my %flags= @_;
	return object {
		field $_ => $flags{$_}
			for keys %flags;
		etc;
	};
}

*escape_str= *Mock::Data::Charset::_escape_str;

subtest parse_regex => sub {
	my @tests= (
		[ qr/abc/,           is_seq(['abc']) ],
		[ qr/\0/,            is_seq(["\0"]) ],
		[ qr/\x20/,          is_seq([' ']) ],
		[ qr/\\/,            is_seq(["\\"]) ],
		[ qr/\012/,          is_seq(["\n"]) ],
		[ qr/a*/,            is_seq(['a'],[0,]) ],
		[ qr/a+b/,           is_seq([ is_seq(['a'],[1,]), 'b' ]) ],
		[ qr/a(ab)*b/,       is_seq([ 'a', is_seq(['ab'],[0,]), 'b' ]) ],
		[ qr/a[abc]d/,       is_seq([ 'a', is_charset('abc'), 'd' ]) ],
		[ qr/^a/,            is_seq([ is_assert(start => 1),'a' ]) ],
		[ qr/^a/m,           is_seq([ is_assert(start => 'LF'), 'a' ]) ],
		[ qr/a$/,            is_seq([ 'a', is_assert(end => 'FinalLF') ]) ],
		[ qr/a$/m,           is_seq([ 'a', is_assert(end => 'LF'     ) ]) ],
		[ qr/a(b$)/m,        is_seq([ 'a', is_seq([ 'b', is_assert(end => 'LF') ]) ]) ],
		[ qr/a\Z/m,          is_seq([ 'a', is_assert(end => 1        ) ]) ],
		[ qr/\w/m,           is_charset('\w') ],
		[ qr/\w+\d+/,        is_seq([ is_charset('\w', [1,]), is_charset('\d', [1,]) ]) ],
		[ qr/(abc\w+)?/,     is_seq([ 'abc', is_charset('\w', [1,]) ],[0,1]) ],
	);
	for (@tests) {
		my ($regex, $expected)= @$_;
		my $parse= Mock::Data::Regex->parse($regex);
		is( $parse, $expected, "regex $regex" )
			or diag explain $parse;
	}
};

subtest regex_generator => sub {
	my @tests= (
		[ qr/abc/, 1, 1 ],
		[ qr/a+b/, 1, 1 ],
		[ qr/a*b/, 1, 1 ],
		[ qr/a(ab)*b/, 1, 1 ],
		[ qr/a[abc]d/, 1, 1 ],
		[ qr/^abc$/, 0, 0 ],
		[ qr/^abc$/m, 1, 1 ],
		[ qr/\n^a/m, 1, 1 ],
		[ qr/\n(^a|c)+/m, 1, 1 ],
		[ qr/a(ab$)+/, 1, 0 ],
		[ qr/a(ab$)+/m, 1, 1 ],
		[ qr/(ab|cd|ef)+/, 1, 1 ],
		[ qr/(ab|cd*|ef+){1,3}/, 1, 1 ],
		[ qr/(ab){0,3}/, 1, 1 ],
		[ qr/(ab){3,}/, 1, 1 ],
		[ qr/a/i, 1, 1 ],
		[ qr/ab/i, 1, 1 ],
		($] >= 5.014? eval <<'END'
			[ qr/[[:alpha:]\P{digit}]+/, 1, 1 ],
			[ qr/[[:alpha:]\P{digit}]+/a, 1, 1 ],
			[ qr/[\w\d]+/a, 1, 1 ],
END
		:()),
	);
	my $mock= Mock::Data->new();
	for (@tests) {
		my ($regex, $can_prefix, $can_suffix)= @$_;
		subtest "regex $regex" => sub {
			my $generator= Mock::Data::Regex->new($regex);
			my $str= $generator->generate($mock);
			like( $str, $regex, "Str=".escape_str($str) )
				or diag explain $generator->regex_parse_tree;
			my $gen= $generator->compile;
			for (1..8) {
				my $str= $gen->($mock);
				like( $str, qr/^$regex$/, "Str=".escape_str($str) );
			}
			# Test prefix/suffix feature
			if ($can_prefix || $can_suffix) {
				my $match= $can_prefix && $can_suffix? qr/^_\n?$regex\n?_\Z/
					: $can_prefix? qr/^_\n?$regex$/
					: qr/^$regex\n?_\Z/;
				my $str= $generator->generate($mock, { prefix => '_', suffix => '_' });
				like( $str, $match, "with prefix/suffix (str=".escape_str($str).")" );
			}
		};
	}
};

subtest codepoint_constraints => sub {
	my @tests= (
		[ qr/.{50}/ ],
		($] >= 5.014? eval <<'END'
		[ qr/.{50}/a ],
END
		:()),
	);
	my $mock= Mock::Data->new();
	for (@tests) {
		my ($regex)= @$_;
		subtest "regex $regex" => sub {
			my $generator= Mock::Data::Regex->new(
				regex => $regex,
				min_codepoint => 1,
				max_codepoint => 0x7F,
			);
			my $str= $generator->generate($mock);
			like( $str, qr/^[\x01-\x7F]+$/, 'codepoints within 1-0x7F' );
			$str= $generator->generate($mock, { min_codepoint => 0x70 });
			like( $str, qr/^[\x70-\x7F]+$/, 'codepoints within 0x70-0x7f' );
			$str= $generator->generate($mock, { max_codepoint => 0x10 });
			like( $str, qr/^[\x01-\x10]+$/, 'codepoints within 0x01-0x10' );
		};
	}
};

done_testing;
