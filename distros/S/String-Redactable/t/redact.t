use v5.20;
use utf8;
use open qw(:std :utf8);

use Test::More;
use Data::Dumper;

my $class = require './Makefile.PL';

my $warnings;
$SIG{__WARN__} = sub { $warnings = $_[0] };
my $warning_regex = qr/Possible unintended interpolation of a redactable string/;

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, qw(new placeholder);
	isa_ok my $obj = $class->new('1234'), $class;

	ok defined $obj->placeholder, 'placeholder is defined';
	ok length $obj->placeholder, 'placeholder has a non-zero length';
	};

my @strings = (
	[ 'ASCII',    'abcdef' ],
	[ 'Wide',     "Bjork Guðmundsdóttir" ],
	[ 'Emoji',    "🍰🐪🦙🦆" ],
	[ 'Numeric',  12345 ],
	);

foreach my $tuple ( @strings ) {
	my $secret = $tuple->[1];
	my $secret_regex = qr/\Q$secret/;

	subtest $tuple->[0] => sub {
		isa_ok my $s = $class->new($secret), $class;

		subtest 'basic' => sub {
			is length $s->to_str_unsafe, length $secret, "strings are the same length";
			is $s->to_str_unsafe, $secret, 'to_str_unsafe returns the original';
			};

		subtest 'concatenation' => sub {
			use warnings; undef $warnings;
			is '' . $s, $s->placeholder, "substr gets just the placeholder";
			like $warnings, $warning_regex, 'saw warning about interpolation';
			};

		subtest 'dumper' => sub {
			unlike Dumper($s), $secret_regex, "Dumper gets just the placeholder";
			};

		subtest 'interpolate' => sub {
			use warnings; undef $warnings;
			is "$s", $s->placeholder, "interpolation with quotes gets just the placeholder";
			like $warnings, $warning_regex, 'saw warning about interpolation';

			undef $warnings;
			is qq($s), $s->placeholder, "interpolation with qq() gets just the placeholder";
			like $warnings, $warning_regex, 'saw warning about interpolation';

			undef $warnings;
			my $regex = qr/\Q$s/;
			like $warnings, $warning_regex, 'saw warning about interpolation';

			unlike "$regex", $secret_regex, "interpolation in qr// does not expose secret";
			};

		subtest 'sprintf' => sub {
			is sprintf( '%s', $s), $s->placeholder, "sprintf gets just the placeholder";
			};

		subtest 'substr' => sub {
			is substr($s, 0), $s->placeholder, "substr gets just the placeholder";
			};

		subtest 'JSON' => sub {
			require JSON;
			my $data = { string => $s };
			my $json = 'ab'; #JSON::encode_json($data);
			unlike $json, $secret_regex, 'secret does not show up in JSON';
			};

		subtest 'YAML' => sub {
			require YAML::XS;
			my $data = { string => $s };
			my $yaml = YAML::XS::Dump($data);
			unlike $yaml, $secret_regex, 'secret does not show up in YAML';
			};
		};
	}

done_testing();
