use Test::More;

use RDF::Helper;
use Data::Dumper;

my $xml_string = undef;
{
    local $/= undef;
    $xml_string = <DATA>;
}

my @models;

#----------------------------------------------------------------------
# RDF::Redland
#----------------------------------------------------------------------
SKIP: {
	eval { require RDF::Redland };
	skip "RDF::Redland not installed", 11 if $@;
	
	my $rdf = RDF::Helper->new(
		BaseInterface => 'RDF::Redland',
		BaseURI => 'http://example.com/'
	);
	
	ok($rdf->include_rdfxml(xml => $xml_string), 'include_rdfxml');
	ok($rdf->exists('http://example.com/first', 'http://example.com/value', '1'), 'test t:testa (1)');
	
	my $first	= $rdf->property_hash( 'http://example.com/first' );
	is_deeply( $first, {
		'next'		=> 'http://example.com/next',
		'value'		=> '1',
		'rdf:type'	=> 'http://example.com/item'
	}, 'first non-recursive' );
	
	my $second	= $rdf->property_hash( 'http://example.com/second' );
	is_deeply( $second, {
		'next'		=> 'http://example.com/third',
		'value'		=> '2',
		'rdf:type'	=> 'http://example.com/item'
	}, 'second non-recursive' );
	

	my $second_deep	= $rdf->deep_prophash( 'http://example.com/second' );
	is_deeply( $second_deep, {
		'next'		=> {
						'next'		=> 'http://example.com/next',
						'value'		=> '3',
						'rdf:type'	=> 'http://example.com/item',
					},
		'value'		=> '2',
		'rdf:type'	=> 'http://example.com/item'
	}, 'second non-recursive' );
	
	my %expect;
	%expect	= (
		'next'		=> \%expect,
		'value'		=> '9',
		'rdf:type'	=> 'http://example.com/item'
	);
	my $deep	= $rdf->deep_prophash( 'http://example.com/recurse' );
	is_deeply( $deep, \%expect, 'deeply recursive' );
}

#----------------------------------------------------------------------
# RDF::Trine
#----------------------------------------------------------------------
SKIP: {
	eval { require RDF::Trine };
	skip "RDF::Trine not installed", 11 if $@;
	
	my $rdf = RDF::Helper->new(
		BaseInterface => 'RDF::Trine',
		BaseURI => 'http://example.com/'
	);

	ok($rdf->include_rdfxml(xml => $xml_string), 'include_rdfxml');

    ok($rdf->exists('http://example.com/first', 'http://example.com/value', '1'), 'test t:testa (1)');

	my $first	= $rdf->property_hash( 'http://example.com/first' );

    is_deeply( $first, {
		'next'		=> 'http://example.com/next',
		'value'		=> '1',
		'rdf:type'	=> 'http://example.com/item'
	}, 'first non-recursive' );

	my $second	= $rdf->property_hash( 'http://example.com/second' );
	is_deeply( $second, {
		'next'		=> 'http://example.com/third',
		'value'		=> '2',
		'rdf:type'	=> 'http://example.com/item'
	}, 'second non-recursive' );
	

	my $second_deep	= $rdf->deep_prophash( 'http://example.com/second' );
	is_deeply( $second_deep, {
		'next'		=> {
						'next'		=> 'http://example.com/next',
						'value'		=> '3',
						'rdf:type'	=> 'http://example.com/item',
					},
		'value'		=> '2',
		'rdf:type'	=> 'http://example.com/item'
	}, 'second non-recursive' );
	
	my %expect;
	%expect	= (
		'next'		=> \%expect,
		'value'		=> '9',
		'rdf:type'	=> 'http://example.com/item'
	);
	my $deep	= $rdf->deep_prophash( 'http://example.com/recurse' );
	is_deeply( $deep, \%expect, 'deeply recursive' );
	
}

done_testing();

__DATA__
<?xml version="1.0"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		xmlns="http://example.com/">
	<item rdf:about="http://example.com/first">
		<value>1</value>
		<next rdf:resource="http://example.com/next" />
	</item>

	<item rdf:about="http://example.com/second">
		<value>2</value>
		<next rdf:resource="http://example.com/third" />
	</item>
	<item rdf:about="http://example.com/third">
		<value>3</value>
		<next rdf:resource="http://example.com/next" />
	</item>
	
	<item rdf:about="http://example.com/recurse">
		<value>9</value>
		<next rdf:resource="http://example.com/recurse" />
	</item>
</rdf:RDF>

