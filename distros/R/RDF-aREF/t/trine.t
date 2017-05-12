use strict;
use Test::More;
use RDF::aREF;
use RDF::aREF::Encoder;

BEGIN {
    eval { 
        require RDF::Trine;
        RDF::Trine->import(qw(statement iri literal));
        1; 
    } or do {
        plan skip_all => "RDF::Trine required";
    };
}

my $model = RDF::Trine::Model->new;

decode_aref( {
        _id => 'http://example.org/alice',
        a => 'foaf_Person',
        foaf_knows => 'http://example.org/bob'
    }, 
    callback => $model,
);
is $model->size, 2, 'added two statements';

my $aref = encode_aref $model, ns => '20150725';
is_deeply $aref,  {
        _id => 'http://example.org/alice',
        a => 'foaf_Person',
        foaf_knows => '<http://example.org/bob>'
    }, 'encode_aref from RDF::Trine::Model';

decode_aref({ _id => 'http://example.org/alice', a => 'foaf_Person' }, callback => $model);
decode_aref({ _id => 'http://example.org/bob', a => 'foaf_Person' }, callback => $model);
is $model->size, 3, 'added another statement';

is_deeply( encode_aref($model, ns => '20150725'), {
   'http://example.org/alice' => {
     'a' => 'foaf_Person',
     'foaf_knows' => '<http://example.org/bob>'
   },
   'http://example.org/bob' => {
     'a' => 'foaf_Person'
   }
 }, 'converted predicate map to subject map');


# bnodes
$model = RDF::Trine::Model->new;
my $decoder = RDF::aREF::Decoder->new( callback => $model );
my $aref = { _id => '<x:subject>', foaf_knows => { foaf_name => 'alice' } }; 
$decoder->decode( $aref );
$decoder->decode( $aref );
is $model->size, 4, 'no bnode collision';
is $decoder->bnode_count, 2;
$decoder->bnode_count(1);
$decoder->decode( $aref );
is $model->size, 4, 'bnode collision';

# errors
my $warning;
local $SIG{__WARN__} = sub { $warning = shift };
decode_aref( {
        _id => 'isbn:123', 
        rdfs_seeAlso => [
            'isbn:456 x',  # looks like an IRI to aREF but rejected by Trine
            'isbn:789'
        ]
    }, 
    callback => $model,
);
ok $warning, "bad IRI";
is $model->size, 5, 'ignored illformed URI';

my $encoder = RDF::aREF::Encoder->new(ns => '20140910');

is_deeply $encoder->triple( 
    iri('http://example.org/'),
    iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
    iri('http://xmlns.com/foaf/0.1/Agent'),
), { _id => 'http://example.org/', a => 'foaf_Agent' }, 'triple';

is_deeply $encoder->triple( 
    iri('http://example.org/'),
    iri('http://xmlns.com/foaf/0.1/name'),
    literal('Anne','de'),
), { _id => 'http://example.org/', foaf_name => 'Anne@de' }, 'triple';

# TODO encode_aref $model / $iterator

done_testing;
