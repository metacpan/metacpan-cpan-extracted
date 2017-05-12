# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::LibXML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::LibXML->new;
$obj->put(
	['i', 'perl', 'print "1\n";'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<?perl print "1\n";?>
END
is($ret, $right_ret);
