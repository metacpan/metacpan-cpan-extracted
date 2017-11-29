use strict;
use warnings;
use lib 't/testlib';

use Test::More tests => 10;
BEGIN { use_ok('Syntax::Kamelon::Format::HTML4') };

use Syntax::Kamelon;
use KamTest qw(InitWorkFolder TestParse WriteCleanUp);

my @messages = (
	'Plain', 
	'Line Numbers/Theme DarkGray',
	'Sections',
	'Theme Gray',
	'Theme LightGray',
	'Theme Black',
	'Theme White',
	'Scrolled',
	'Fold markers',
);

my @kams = (
	Syntax::Kamelon->new( #Plain
		syntax => 'Perl',
		formatter => ['HTML4',
			title => $messages[0],
		],
	),

	Syntax::Kamelon->new( #Line Numbers
		syntax => 'Perl',
		formatter => ['HTML4',
			lineoffset => 1,
			title => $messages[1],
		],
	),
	Syntax::Kamelon->new( #Sections
		syntax => 'Perl',
		formatter => ['HTML4',
			sections => 1,
			title => $messages[2],
		],
	),
	Syntax::Kamelon->new( #Theme Gray
		syntax => 'Perl',
		formatter => ['HTML4',
			lineoffset => 1,
			theme => 'Gray',
			title => $messages[3],
		],
	),
	Syntax::Kamelon->new( #Theme LightGray
		syntax => 'Perl',
		formatter => ['HTML4',
			lineoffset => 1,
			theme => 'LightGray',
			title => $messages[4],
		],
	),
	Syntax::Kamelon->new( #Theme Black
		syntax => 'Perl',
		formatter => ['HTML4',
			lineoffset => 1,
			theme => 'Black',
			title => $messages[5],
		],
	),
	Syntax::Kamelon->new( #Theme White
		syntax => 'Perl',
		formatter => ['HTML4',
			lineoffset => 1,
			theme => 'White',
			title => $messages[6],
		],
	),
	Syntax::Kamelon->new( #Scrolled
		syntax => 'Perl',
		formatter => ['HTML4',
			scrolled => 1,
			title => $messages[7],
		],
	),
	Syntax::Kamelon->new( #Fold markers
		syntax => 'Perl',
		formatter => ['HTML4',
			foldmarkers => 1,
			title => $messages[8],
		],
	),
);

InitWorkFolder('t/Format-HTML4');


my $num = 1;
for (@kams) {
	my $message = $messages[$num - 1];
	ok((TestParse($_, 'codefolding.pm', "format-html4-$num.html") eq 1), $message);
	$num ++;
}

WriteCleanUp;
