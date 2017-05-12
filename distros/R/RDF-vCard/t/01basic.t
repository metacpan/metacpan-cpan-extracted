use Test::More tests => 6;
BEGIN { use_ok('RDF::vCard') };

ok(
	RDF::vCard::Importer->can('new'),
	"RDF::vCard::Importer can be instantiated.",
	);

ok(
	RDF::vCard::Exporter->can('new'),
	"RDF::vCard::Exporter can be instantiated.",
	);
ok(
	RDF::vCard::Line->can("new"),
	"RDF::vCard::Line can be instantiated.",
	);

my $line = RDF::vCard::Line->new(
	property        => "email",
	value           => "joe\@example.net",
	type_parameters => { type=>[qw(PREF INTERNET)] },
	);

is(
	"$line",
	"EMAIL;TYPE=PREF,INTERNET:joe\@example.net",
	"Lines seem formatted correctly.",
	);

my $card = RDF::vCard::Entity->new;
$card->add($line);

ok(
	"$card" =~ /example.net/,
	"Cards seem to work.",
	);

