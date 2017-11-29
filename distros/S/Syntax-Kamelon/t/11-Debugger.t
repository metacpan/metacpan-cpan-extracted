use strict;
use warnings;
use lib 't/testlib';

use Test::More tests => 3;
BEGIN { use_ok('Syntax::Kamelon::Debugger') };
use KamTest qw(InitWorkFolder TestParse WriteCleanUp);

InitWorkFolder('t/Debugger');

my $k = new Syntax::Kamelon::Debugger(
	syntax => 'Perl',
	formatter => ['HTML4',
		title => 'Debugger test',
	],
);
ok(defined $k, 'Creation');

ok((TestParse($k, "codefolding.pm", "debuggertest.html") eq 1), "Parsing and formatting");

WriteCleanUp;
