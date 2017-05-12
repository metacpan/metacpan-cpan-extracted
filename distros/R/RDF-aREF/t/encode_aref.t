use strict;
use warnings;
use Test::More;
use RDF::aREF;
use RDF::aREF::Encoder;

my $example = { # RDF/JSON
    "http://example.org/about" => {
        "http://purl.org/dc/terms/title" => [ 
            { value => "Anna's Homepage", 
               type => "literal", 
               lang => "en" } ]
    } 
};

my $aref = encode_aref($example, ns => '20140910');
is_deeply $aref, {
    _id => "http://example.org/about",
    dct_title => "Anna's Homepage\@en" 
}, 'add_hashref';

encode_aref( {
    "http://example.org/about" => { 
        "x:y" => [{ "type" => "uri", value => "x:z" }]
    } }, 
    subject_map => 1,
    to => $aref
);
is_deeply $aref, {
    'http://example.org/about' => {
        dct_title => "Anna's Homepage\@en",
        "x:y" => "<x:z>",
    } }, 'encode_aref( $rdfjson, subject_map => 1, to => $aref )';

# TODO: normalize/avoid duplicate triples

is_deeply encode_aref($example, ns => 0), {
    _id => "http://example.org/about",
    "http://purl.org/dc/terms/title" => "Anna's Homepage\@en" 
}, 'encode_aref( $rdfjson, ns => 0)';
is_deeply encode_aref($example, ns => 0, subject_map => 1), {
    "http://example.org/about" => {
        "http://purl.org/dc/terms/title" => "Anna's Homepage\@en"
    }
}, 'encode_aref( $rdfjson, ns => 0, subject_map => 1)';

{
    my $encoder = RDF::aREF::Encoder->new( ns => '20140910' );
    is $encoder->literal('x', '',  'http://www.w3.org/2001/XMLSchema#string'),
        'x@', 'omit xsd_string';
}

done_testing;
