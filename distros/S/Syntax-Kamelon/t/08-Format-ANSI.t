use strict;
use warnings;
use lib 't/testlib';

use Test::More tests => 3;
BEGIN { use_ok('Syntax::Kamelon::Format::ANSI') };

use Syntax::Kamelon;
use KamTest qw(InitWorkFolder PreText TestParse WriteCleanUp);

my @kams = (
	Syntax::Kamelon->new(
		syntax => 'Perl',
		formatter => ['ANSI',
		],
	),
	Syntax::Kamelon->new(
		syntax => 'Perl',
		formatter => ['ANSI',
			lineoffset => 1,
		],
	),
);

InitWorkFolder('t/Format-ANSI');

my @messages = (
	'with',
	'without'
);

my $num = 1;
for (@kams) {
	ok((TestParse($_, 'codefolding.pm', "format-ansi-$num.ansi") eq 1), $messages[$num - 1] . ' line numbers');
	$num ++;
}

WriteCleanUp;
