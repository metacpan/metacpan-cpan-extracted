# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::PYX->new;
$obj->put(
	['r', '<?xml version="1.1"?>'."\n"],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
-<?xml version="1.1"?>\n
END
chomp $right_ret;
is($ret, $right_ret, 'Simple raw data test.');
