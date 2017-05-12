#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Test::JSON;

foreach my $filename (glob('rdf_linkeddata*json')) {
	ok(open(CONFIG, '<' . $filename), "Test config file $filename opened OK");
	my $json = join("\n", <CONFIG>);
	close CONFIG;
	is_valid_json ($json, "File $filename contains valid JSON");
}

done_testing();
