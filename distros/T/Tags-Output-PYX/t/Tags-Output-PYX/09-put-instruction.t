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
	['i', 'perl'],
	['i', 'perl', 'print "1";'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
?perl
?perl print "1";
END
chomp $right_ret;
is($ret, $right_ret, 'Simple instruction test.');
