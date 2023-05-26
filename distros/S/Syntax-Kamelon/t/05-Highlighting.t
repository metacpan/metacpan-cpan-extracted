use strict;
use warnings;
use lib 't/testlib';

use Test::More tests => 18;

use Syntax::Kamelon;
use KamTest qw(InitWorkFolder PostText PreText TestParse WriteCleanUp);

InitWorkFolder('t/Highlighting');

my $xmldir = './t/Highlighting/XML';

my %formtab = ();
for (Syntax::Kamelon->AvailableAttributes) {
	$formtab{$_} = "<font class=\"$_\">"
}

my $textfilter = "[%~ text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]";
my $hl = new Syntax::Kamelon(
	xmlfolder => $xmldir,
	formatter => ['Base',
		textfilter => \$textfilter,
		format_table => \%formtab,
		newline => "</br>\n",
		tagend => '</font>',
	],
);
ok(defined $hl, 'Creation');

my @l = $hl->AvailableSyntaxes;
my @li = ();
for (@l) {
	if ($hl->{INDEXER}->InfoSection($_) eq 'Test') {
		push @li, $_
	}
}

PostText("</body>\n</html>\n");


for (@li) {
	PreText( <<__EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile $_</title>
</head>
<body>
__EOF
);

	my $sample = "highlight.$_";
	$hl->Reset;
	$hl->Syntax($_);
	ok((TestParse($hl, "highlight.$_", "$_.html") eq 1), $_);
}

WriteCleanUp;
