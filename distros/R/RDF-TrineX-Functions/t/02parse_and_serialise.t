use Test::More tests => 10;

use RDF::Trine;
use RDF::TrineX::Functions
	iri       => {},
	parse     => {},
	serialize => { -type => RDF::Trine::Serializer::NTriples::Canonical->new };

my %in;
($in{filename} = __FILE__) =~ s/t$/nt/;
open $in{filehandle}, '<', $in{filename} or die "Could not open $in{filename}: $!";
$in{data} = do { local (@ARGV, $/) = $in{filename}; <> };
open $in{datahandle}, '<', \($in{data});

foreach my $source (qw(data datahandle filename filehandle))
{
	my $model = parse(
		$in{$source},
		as   => 'NTriples',
		base => 'http://example.net/',
	);

	is($model->count_statements, 1, "parse(<$source>) OK");
	
	if ($source eq 'filehandle')
	{
		my $out      = serialize($model);
		my $expected = $in{data};
		for ($out, $expected) { s/[\r\n]//g };
		is($out, $expected, "serialize OK");
	}
}

my $model = parse();
isa_ok $model => 'RDF::Trine::Model';

parse(
	$in{data},
	as    => 'NTriples',
	into  => $model,
	graph => 'http://example.net/g1',
	base  => 'http://example.net/',
);

parse(
	$in{data},
	as    => 'NTriples',
	into  => $model,
	graph => iri('http://example.net/g1'),
	base  => 'http://example.net/',
);

parse(
	$in{data},
	as    => 'NTriples',
	into  => $model,
	graph => 'http://example.net/g2',
	base  => 'http://example.net/',
);

is $model->count_statements((undef)x4), 2, "model is correct size"
	or note serialize($model, as => 'NQuads');

my %expected = (
	1 => 1,
	2 => 1,
	3 => 0,
);
for (qw(1 2 3))
{
	is(
		$model->count_statements((undef)x3, iri("http://example.net/g$_")),
		$expected{$_},
		"graph http://example.net/g$_",
	);
}

