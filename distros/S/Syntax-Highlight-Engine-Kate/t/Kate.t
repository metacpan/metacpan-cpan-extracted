use strict;

use Term::ANSIColor;

use Test::More;

my %reg = ();
open RG, "<REGISTERED" or  die "cannot open REGISTERED";
while (my $t = <RG>) {
	chomp($t);
	my ($lang, $testfile) = split /\t/, $t;
	unless (defined($testfile)) { $testfile = "" }
	#diag "#language $lang, samplefile, ;$testfile; quovadis";
	$reg{$lang} = $testfile;
}
close RG;

my %filetypes = (
	'../some/path/index.html' => 'HTML',
	'Module.pm' => 'Perl',
	'c:\\Documents and Settings\\My Documents\\settings.xml' => 'XML',
);

my %options = (
	substitutions => {
		"\n" => color('reset') . "\n",
	},
	format_table => {
		Alert => [color('white bold on_green'), color('reset')],
		BaseN => [color('green'), color('reset')],
		BString => [color('red bold'), color('reset')],
		Char => [color('magenta'), color('reset')],
		Comment => [color('white bold on_blue'), color('reset')],
		DataType => [color('blue'), color('reset')],
		DecVal => [color('blue bold'), color('reset')],
		Error => [color('yellow bold on_red'), color('reset')],
		Float => [color('blue bold'), color('reset')],
		Function => [color('yellow bold on_blue'), color('reset')],
		IString => [color('red'), color('reset')],
		Keyword => [color('bold'), color('reset')],
		Normal => [color('reset'), color('reset')],
		Operator => [color('green'), color('reset')],
		Others => [color('yellow bold on_green'), color('reset')],
		RegionMarker => [color('black on_yellow bold'), color('reset')],
		Reserved => [color('magenta on_blue'), color('reset')],
		String => [color('red'), color('reset')],
		Variable => [color('blue on_red bold'), color('reset')],
		Warning => [color('green bold on_red'), color('reset')],
	},
);

my @langl = sort keys %reg;
my @ftl = sort keys %filetypes;
my $numtest = (@langl * 4) + 2 + (@ftl * 2);

plan tests => $numtest;
use Syntax::Highlight::Engine::Kate;
ok(1, "cannot find Kate");

my $k = new Syntax::Highlight::Engine::Kate(%options);
ok(defined($k), "cannot create Kate");

for (@ftl) {
	my $t = $_;
	my $l = $k->languagePropose($t);
	is($l, $filetypes{$t}, "Cannot select correct filetype for $t");
	$k->languageAutoSet($t);
	is($k->language, $filetypes{$t}, "Cannot select correct filetype for $t");
}

for (@langl) {
	my $ln = $_;
	#diag "testing $ln";
	my $md = $k->syntaxes->{$ln};
	my $mod = "Syntax::Highlight::Engine::Kate::$md";
	eval "use $mod";
	is($@, "", "cannot find $mod");
	my $m = new $mod(%options);
	ok(defined($m), "cannot create $mod");
	my $fl = $reg{$ln};
	if ($fl ne "") {
		my $txt = "";
		open(TST, "<$fl") or die "cannot open $fl";
		while (<TST>) { 
			$txt = $txt . $_; 
		};
		close TST;
		my $res = "";
		#diag "testing as kate plugin";
		$k->language($ln);
		$k->reset;
		eval "\$res = \$k->highlightText(\$txt)";
		is($@, "", "errors when highlighting");
#		diag $res;
		#diag "testing standalone";
		eval "\$res = \$m->highlightText(\$txt)";
		is($@, "", "errors when highlighting");
#		diag $res;
	} else {
		diag "Should be SKIP-ed! '$ln'";
		ok(1); ok(1);
		#skip(1, "no test file");
		#skip(1, "no test file");
	}
}

