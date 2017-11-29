use strict;
use warnings;
use lib 't/testlib';

use Test::More tests => 10;
BEGIN { use_ok('Syntax::Kamelon::Format::Base') };

use Syntax::Kamelon;
use KamTest qw(InitWorkFolder PreText PostText TestParse WriteCleanUp);

my %formtab = ();
for (Syntax::Kamelon->AvailableAttributes) {
	$formtab{$_} = "<font class=\"$_\">"
}


my $base = Syntax::Kamelon::Format::Base->new(1,
	format_table => \%formtab,
);
ok(defined $base, 'Creation');
ok(($base->{ENGINE} eq 1), 'Engine');

my $textfilter = "[%~ text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]";

my $title = '';

my $pretext = <<__EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile $title</title>
</head>
<body>
__EOF


my $posttext = "</body>\n</html>\n";

my $normal_template = <<__EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile scalar template without additional options</title>
</head>
<body>
[% FOREACH line = content ~%]
	[% FOREACH snippet = line ~%]
		<font class="[% snippet.tag %]">
		[%~ snippet.text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]
		</font>
	[%~ END %]</br>
[% END ~%]
</body>
</html>
__EOF


my $linenumber_template = <<__EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile scalar template with line numbers</title>
</head>
<body>
[% linenum = lineoffset ~%]
[% FOREACH line = content ~%]
	[% linenum  FILTER format('%03d ') ~%]
	[% FOREACH snippet = line ~%]
		<font class="[% snippet.tag %]">
		[%~ snippet.text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]
		</font>
	[%~ END %]</br>
	[%~ linenum = linenum + 1 %]
[% END ~%]
</body>
</html>
__EOF


my @kams = (
	new Syntax::Kamelon(
		syntax => 'Perl',
		formatter => ['Base',
			textfilter => \$textfilter,
			format_table => \%formtab,
			newline => "</br>\n",
			tagend => '</font>',
		],
	),
	new Syntax::Kamelon(
		syntax => 'Perl',
		formatter => ['Base',
			lineoffset => 1,
			textfilter => \$textfilter,
			format_table => \%formtab,
			newline => "</br>\n",
			tagend => '</font>',
		],
	),
	new Syntax::Kamelon(
		syntax => 'Perl',
		formatter => ['Base',
			template => \$normal_template,
		],
	),
	new Syntax::Kamelon(
		syntax => 'Perl',
		formatter => ['Base',
			lineoffset => 1,
			template => \$linenumber_template,
		],
	),
	new Syntax::Kamelon(
		syntax => 'Perl',
		formatter => ['Base',
			template => 't/Format-Base/normal_template.tpl',
		],
	),
	new Syntax::Kamelon(
		syntax => 'Perl',
		formatter => ['Base',
			lineoffset => 1,
			template => 't/Format-Base/linenumber_template.tpl',
		],
	),
	new Syntax::Kamelon(
		syntax => 'Perl',
		formatter => ['Base',
			foldingdepth => 99,
			template => 't/Format-Base/folding_template.tpl',
		],
	),
);


InitWorkFolder('t/Format-Base');

my @messages = (
	'textfilter option',
	'textfilter option with linenumbers',
	'scalar template without additional options',
	'scalar template with line numbers',
	'template file without additional options',
	'template file with line numbers',
	'template file with code folding',
);

my $num = 1;
for (@kams) {
	my $title = $messages[$num - 1];
	if ($num < 3) {
		PreText( <<__EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile $title</title>
</head>
<body>
__EOF
		);
		PostText("</body>\n</html>\n");
	} else {
		PreText("");
		PostText("");
	}
	ok((TestParse($_, 'codefolding.pm', "format-base-$num.html") eq 1), $title);
	$num ++;
}

WriteCleanUp;
