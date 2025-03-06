use Test::More;
use strict;
use warnings;
use POD::Generate;

use lib ".";

my $pg = POD::Generate->new();

my $data = $pg->start("Test::Memory")
	->synopsis(qq|This is a code snippet.\n\n\tuse Test::Memory;\n\n\tmy \$memory = Test::Memory->new();|)
	->description(q|A test of ones memory.|)
	->methods
	->h2("Mind", "The element of a person that enables them to be aware of the world and their experiences, to think, and to feel; the faculty of consciousness and thought.")
	->v(q|	$memory->Mind();|)
	->h3("Intelligence", "A person or being with the ability to acquire and apply knowledge and skills.")
	->v(q|	$memory->Mind->Intelligence();|)
	->h4("Factual", "Concerned with what is actually the case.")
	->v(q|	$memory->Mind->Intelligence->Factual(%params);|)
	->item("one", "Oxford, Ticehurst and Potters Bar.")
	->item("two", "Koh Chang, Zakynthos and Barbados.")
	->item("three", "An event or occurrence which leaves an impression on someone.")
	->footer(
		name => "LNATION",
		email => 'email@lnation.org'
	)
->end("string");

open my $oh, '>', 't/new.pod';
print $oh $data;
close $oh;

open my $fh, "<", "t/test.pod";
my $expected = do { local $/; <$fh> };
close $fh;

is($data, $expected);

done_testing();
