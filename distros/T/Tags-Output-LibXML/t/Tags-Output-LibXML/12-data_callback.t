# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::LibXML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $sub = sub {
	my $data_arr_ref = shift;
	foreach my $data (@{$data_arr_ref}) {
		$data =~ s/a/\./g;
	}
	return;
};
my $obj = Tags::Output::LibXML->new(
	'cdata_callback' => $sub,
	'data_callback' => $sub,
);
$obj->put(
	['b', 'tag'],
	['d', 'nan', 'ana'],
	['cd', 'nan'],
	['e', 'tag'],

	# Ignore for this module.
	['r', 'ananas'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag>n.n.n.<![CDATA[n.n]]></tag>
END
is($ret, $right_ret);
