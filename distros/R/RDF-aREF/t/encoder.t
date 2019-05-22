use strict;
use warnings;
use Test::More;
use RDF::aREF::Encoder;

sub test_encoder(@) {
    my ($encoder, $method, @tests) = @_;
    note "RDF::aREF::Encoder::$method";
    while (@tests) {
        my $input  = shift @tests;
        my $expect = shift @tests;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        if ( ref $expect ) {
            is_deeply $encoder->$method($input), $expect, $expect;
        } else {
            is $encoder->$method($input), $expect, $expect;
        }
    }
}

my $encoder = RDF::aREF::Encoder->new( ns => '20140910' );

test_encoder $encoder => 'subject',
    # RDF/JSON
    {
        type => 'uri',
        value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    } => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
    {
        type => 'bnode',
        value => '_:foo'
    } => '_:foo',
    # RDF::Trine
    ['URI','http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] 
      => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
    ['BLANK', 0 ] => '_:0',
    # else
    'http://example.org/' => undef,
;

test_encoder $encoder => 'predicate',
    # RDF/JSON
    {
        type => 'uri',
        value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    } => 'a',
    {
        type => 'uri',
        value => 'http://purl.org/dc/terms/title'
    } => 'dct_title',
    # RDF::Trine
    ['URI','http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] => 'a',
    ['URI','http://undefinednamespace.foo'] => 'http://undefinednamespace.foo',
    ['BLANK', 0 ] => undef,
    # else
    'http://example.org/' => undef,
;

test_encoder $encoder => 'object',
    # RDF/JSON
    {
        type => 'uri',
        value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    } => 'rdf_type',
    {
        type => 'uri',
        value => 'http://www.w3.org/2006/vcard/ns#street-address',
    } => 'vcard_street-address',
    {
        type => 'uri',
        value => 'http://undefinednamespace.foo/thing'
    } => '<http://undefinednamespace.foo/thing>',
    {
        type  => 'literal',
        value => 'hello, world!',
        lang  => 'en'
    } => 'hello, world!@en',
    {
        type  => 'literal',
        value => '12',
        datatype => 'http://www.w3.org/2001/XMLSchema#integer'
    } => '12^xs_integer',
    {
        type  => 'bnode',
        value => '_:12',
    } => '_:12',
    # RDF::Trine
    ['URI','http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] => 'rdf_type',
    ['URI','http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] => 'rdf_type',
    ['BLANK', 0 ] => '_:0',
    ['hello, world!', 'en', undef ] => 'hello, world!@en',
    ['hello, world!' ] => 'hello, world!@',
    [42, undef, 'http://www.w3.org/2001/XMLSchema#integer'] => '42^xs_integer',
    # else
    'http://example.org/' => undef,
;

# RDF::aREF::Encoder::uri( ... )
test_encoder $encoder => 'uri',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => 'rdf_type',
    'http://undefinednamespace.foo' => '<http://undefinednamespace.foo>'
;

# RDF::aREF::Encoder::literal( ... )
test_encoder $encoder => 'literal',
    '' => '@'
;

# RDF::aREF::Encoder::bnode( ... )
test_encoder $encoder => 'bnode',
    abc   => '_:abc',
    0     => '_:0',
    '_:0' => undef,
;

# RDF::aREF::Encoder::qname( ... )
test_encoder $encoder => 'qname',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => 'rdf_type',
    'http://schema.org/Review' => 'schema_Review',
    'http://www.w3.org/2006/vcard/ns#street-address' => 'vcard_street-address',
    'http://undefinednamespace.foo/thing' => undef
;

# encoder methods with ns => 0
$encoder = RDF::aREF::Encoder->new( ns => 0 );
is $encoder->literal( 42, undef, 'http://www.w3.org/2001/XMLSchema#integer'), 
    '42^xsd_integer', 'literal (ns=0)';
is $encoder->qname('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
    'rdf_type', 'qname (ns=0)';
is $encoder->predicate('http://purl.org/dc/terms/title'), 
    undef, 'predicate (ns=0)';

done_testing;
