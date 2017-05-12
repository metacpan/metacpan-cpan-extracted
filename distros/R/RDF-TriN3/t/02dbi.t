use Test::More tests => 7;
BEGIN { use_ok('RDF::TriN3') };

my $store = RDF::Trine::Store::DBI->temporary_store;
$store->clear_restrictions;
my $model = RDF::Trine::Model->new($store);
ok($model, "RDF::Trine autoloaded");

my $n3 = <<NOTATION3;
\@prefix foaf: <http://xmlns.com/foaf/0.1/> .

#comment

{
	?person a foaf:Person .
} =>
	{
		?person a foaf:Agent .
	} .

NOTATION3

my $parser = RDF::Trine::Parser::Notation3->new();
ok($parser, "Created parser");

$parser->parse_into_model('http://example.com/', $n3, $model);

is($model->count_statements, 1, "Got exactly one statement.");

my $iter = $model->get_statements(undef, undef, undef, undef);
my $f;
while (my $st = $iter->next)
{
	ok($st, "Retrieved the statement");

	is($st->subject->as_ntriples,
		'"?person <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .\n"^^<http://open.vocab.org/terms/Formula>',
		'Statement looks good.');

	$f = $st->subject;
}

ok($f->pattern->[0]->isa('RDF::Trine::Statement'), 'Formulae can be introspected.');
