use strict;
use warnings;

use Tags::Output::LibXML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'tag'],

	# Ignore for this module.
	['r', 'Raw'],

	['e', 'tag'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag/>
END
is($ret, $right_ret);
