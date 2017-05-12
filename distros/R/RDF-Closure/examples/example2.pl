use 5.010;
use lib "lib";
use Data::Dumper;
use Error qw':try';
use RDF::Trine;
# use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use RDF::Closure::DatatypeHandling qw[
	literal_valid
	literal_canonical
	literals_identical
	literal_tuple
	$RDF $RDFS $OWL $XSD
	];
use RDF::Closure::Engine::OWL2Plus;

my $lit1 = RDF::Trine::Node::Literal->new('TrUe', undef, $XSD->boolean->uri);
my $lit2 = RDF::Trine::Node::Literal->new('Tre', undef, $XSD->boolean->uri);
my $lit3 = RDF::Trine::Node::Literal->new('1', undef, $XSD->boolean->uri);

{
	say RDF::Closure::DatatypeHandling->literal_valid($lit1) ? 'lit1 valid' : 'lit1 invalid';
	say literal_valid($lit2)  ? 'lit2 valid' : 'lit2 invalid';
}

{
	say literals_identical($lit1, $lit2) ? 'lit1 == lit2' : 'lit1 != lit2';
	say literals_identical($lit1, $lit3) ? 'lit1 == lit3' : 'lit1 != lit3';
}

{
	my $plain1 = RDF::Trine::Node::Literal->new('Hello@en-GB', undef, $RDF->PlainLiteral->uri);
	my $plain2 = RDF::Trine::Node::Literal->new('Hello', 'en-GB', undef);
	say Dumper( literal_tuple($plain1), literal_tuple($plain2) );
	say RDF::Closure::DatatypeHandling->literals_identical($plain1, $plain2)
		? 'rdf:PlainLiteral and RDF plain literals are equivalent'
		: 'Bad fooey';
}

{
	my $dth = RDF::Closure::Engine::OWL2Plus::create_dt_handling();
	my $twentynine1 = RDF::Trine::Node::Literal->new('29', undef, $XSD->integer->uri);
	my $twentynine2 = RDF::Trine::Node::Literal->new('29.000', undef, $XSD->decimal->uri);
	my $twentynine3 = RDF::Trine::Node::Literal->new('29/1', undef, $OWL->rational->uri);
	say Dumper( $dth->literal_tuple($twentynine1), $dth->literal_tuple($twentynine2), $dth->literal_tuple($twentynine3) );
	say $dth->literals_identical($twentynine1, $twentynine2)
		? 'numbers equivalent'
		: 'Bad fooey times twentynine';
	say $dth->literals_identical($twentynine2, $twentynine3)
		? 'numbers equivalent'
		: 'Bad fooey times twentynine';
	say $dth->literals_identical($twentynine1, $twentynine3)
		? 'numbers equivalent'
		: 'Bad fooey times twentynine';
}

{
	my $dth = RDF::Closure::Engine::OWL2Plus::create_dt_handling();
	my $n1 = RDF::Trine::Node::Literal->new('0.75', undef, $XSD->decimal->uri);
	my $n2 = RDF::Trine::Node::Literal->new('3/4', undef, $OWL->rational->uri);
	say Dumper( $dth->literal_tuple($n1), $dth->literal_tuple($n2) );
	say $dth->literals_identical($n1, $n2)
		? 'rationals equivalent'
		: 'Bad fooey with rationals';
}

{
	my $dth = RDF::Closure::DatatypeHandling->new;
	my $n1 = RDF::Trine::Node::Literal->new('0.75', undef, $XSD->decimal->uri);
	my $n2 = RDF::Trine::Node::Literal->new('3/4', undef, $OWL->rational->uri);
	say Dumper( $dth->literal_tuple($n1), $dth->literal_tuple($n2) );
	say $dth->literals_identical($n1, $n2)
		? 'bad fooey - owl:rational should not be supported by default'
		: 'usually owl:rational is not supported';
}

{
	my $plain1 = RDF::Trine::Node::Literal->new('Hello@', undef, $RDF->PlainLiteral->uri);
	my $plain2 = RDF::Trine::Node::Literal->new('Hello', undef, undef);
	my $plain3 = RDF::Trine::Node::Literal->new('Hello', 'en', undef);
	my $string = RDF::Trine::Node::Literal->new('Hello', undef, $XSD->string);
	say RDF::Closure::DatatypeHandling->literals_identical($plain1, $string)
		? 'rdf:PlainLiteral and strings can be equivalent'
		: 'Bad fooey';
	say RDF::Closure::DatatypeHandling->literals_identical($plain2, $string)
		? 'RDF plain literals and strings can be equivalent'
		: 'Bad fooey';
	say !RDF::Closure::DatatypeHandling->literals_identical($plain3, $string)
		? '... but not if they have a language tag set!'
		: 'Bad fooey';
}

{
	my $xml1 = RDF::Trine::Node::Literal->new("<foo xmlns=\"about:blank\" bar='1'></foo>", undef, $RDF->XMLLiteral->uri);
	my $xml2 = RDF::Trine::Node::Literal->new("<foo bar=\"1\"   xmlns=\"about:blank\" />", undef, $RDF->XMLLiteral->uri);
	say Dumper( literal_canonical($xml1), literal_canonical($xml2) );
	say RDF::Closure::DatatypeHandling->literals_identical($xml1, $xml2)
		? 'Canonical XML works'
		: 'Bad fooey';
}

{
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('Hello','en-GB') ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('Hello world',undef, $XSD->token->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('+002001.1230', undef, $XSD->decimal->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('+002001.1230', undef, $XSD->float->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('2001-01-02T15:00:00.000100+01:00', undef, $XSD->dateTimeStamp->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('2001-01-02T15:00:00.000100', undef, $XSD->dateTime->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('ZXhhbXBsZQ   ', undef, $XSD->base64Binary->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('2001-01-02', undef, $XSD->date->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('2001-01-02+07:00', undef, $XSD->date->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('2001-01', undef, $XSD->gYearMonth->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('2001', undef, $XSD->gYear->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('--01-02', undef, $XSD->gMonthDay->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('--02-29', undef, $XSD->gMonthDay->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('---02Z', undef, $XSD->gDay->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('00:15:00.123456789', undef, $XSD->time->uri) ) );
	say Dumper( literal_canonical( RDF::Trine::Node::Literal->new('00:15:00.123456789-02:00', undef, $XSD->time->uri) ) );
}



  my $lit     = RDF::Trine::Node::Literal->new(
    "2010-01-01T11:00:00-01:00", undef, $XSD->dateTime);
  my $handler = RDF::Closure::DatatypeHandling->new(force_utc => 1);
  print $handler->literal_canonical($lit)->as_ntriples;
