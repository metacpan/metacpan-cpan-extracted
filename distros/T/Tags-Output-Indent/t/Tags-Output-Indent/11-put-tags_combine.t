use strict;
use warnings;

use Tags::Output::Indent;
use Test::More 'tests' => 1;

# Test.
my $obj = Tags::Output::Indent->new;
$obj->put(
	['b', 'MAIN'],
	['c', ' COMMENT '],
	['e', 'MAIN'],
	['b', 'MAIN'],
	['d', 'DATA'],
	['e', 'MAIN'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<MAIN>
  <!-- COMMENT -->
</MAIN>
<MAIN>
  DATA
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret);
