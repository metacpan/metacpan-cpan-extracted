use 5.010;
use warnings;

use Perl6::Form;

my @amounts = (0, 1, 1.2345, 1234.56, -1234.56, 1234567.89);
# my @amounts = qw(0 1,0 1,2345 1234,56 -1234,56 1234567,89);

my %format = (
	"Canadian (English)"	=> q/   {-$],]]],]]].0}/,
	"Canadian (French)"		=> q/    {-] ]]] ]]],0 $}/,
	"Dutch"					=> q/     {],]]],]]].0-EUR}/,
	"Swiss"					=> q/{Sfr -]']]]']]].0}/,
	"German (pre-euro)"		=> q/    {-].]]].]]],[DM}/,
	"Norwegian"				=> q/ {kr -].]]].]]],0}/,
	"Indian"				=> q/    {-]],]],]]].0Rs}/,
	"Portuguese (pre-euro)"	=> q/    {-].]]].]]]$0 Esc}/,
);

while (my($style, $format) = each %format) {
	print form
		"$style:\n\n",
		"    $format",
		\@amounts,
		"\n";
}
