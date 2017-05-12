use Test::More tests => 11;
BEGIN { use_ok('RDF::TriN3') };

my $model = RDF::Trine::Model->temporary_model;

my $n3 = <<'NOTATION3';
@keywords is, of, a.
@namepattern "\d{1,2}[A-Z][a-z]{2}\d{4}" <http://example.com/days/> .
@dtpattern   "\d{1,2}[a-z]{3}\d{4}"      <http://example.com/day> .
@term        lit                         :as_literal .

1Apr2003 lit 1apr2003 .

NOTATION3

my $parser = RDF::Trine::Parser::ShorthandRDF->new();
ok($parser, "Created parser");

$parser->parse_into_model('http://example.org/', $n3, $model);

is($model->count_statements, 1, "Got exactly one statement.");

my $iter = $model->get_statements;
my $f;
while (my $st = $iter->next)
{
	ok($st, "Retrieved the statement.");
	
	ok($st->subject->is_resource,
		'Subject is resource.');

	is($st->subject->uri,
		'http://example.com/days/1Apr2003',
		'Subject URI is correct.');

	ok($st->predicate->is_resource,
		'Predicate is resource.');

	is($st->predicate->uri,
		'http://example.org/#as_literal',
		'Predicate URI is correct.');

	ok($st->object->is_literal && $st->object->has_datatype,
		'Object is typed literal.');

	is($st->object->literal_value,
		'1apr2003',
		'Object literal value is correct.');

	is($st->object->literal_datatype,
		'http://example.com/day',
		'Object literal datatype is correct.');
}

