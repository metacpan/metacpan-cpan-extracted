use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new;
$obj->put(
	['b', 'element'],
	['d', 'a<a', 'a>a', 'a&a'],
	['e', 'element'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<element>a&lt;aa>aa&amp;a</element>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
my $sub = sub {
	my $data_arr_ref = shift;
	foreach my $data (@{$data_arr_ref}) {
		$data =~ s/a/\./g;
	}
	return;
};
$obj = Tags::Output::Raw->new(
	'cdata_callback' => $sub,
	'data_callback' => $sub,
	'raw_callback' => $sub,
);
$obj->put(
	['b', 'element'],
	['d', 'nan', 'ana'],
	['cd', 'nan'],
	['e', 'element'],
	['r', 'ananas'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<element>n.n.n.<![CDATA[n.n]]></element>.n.n.s
END
chomp $right_ret;
is($ret, $right_ret);
