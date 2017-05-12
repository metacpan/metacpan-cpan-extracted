use strict;
use warnings;
use Test::More;
use RDF::aREF::Decoder;

my $_rdf  = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
my $_foaf = "http://xmlns.com/foaf/0.1/";
my $_xsd  = 'http://www.w3.org/2001/XMLSchema#';
my $_ex   = "http://example.org/";
my $alice = "http://example.org/alice";

sub decode {
    my @triples;
    my ($aref, %options) = ref $_[0] eq 'HASH' ? ($_[0]) : (@{$_[0]});
    RDF::aREF::Decoder->new(
        callback => sub {
            push @triples, join " ", map { 
                (ref $_ ? '?'.$$_ : $_) // '' 
            } @_;
        }, %options
    )->decode( $aref );
    join "\n", sort @triples;
}

sub test_decode(@) { ## no critic
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is decode($_[0]), $_[1];
}

# many ways to encode the same simple triple
test_decode $_, "$alice ${_rdf}type ${_foaf}Person" for
  # predicate map
    { _id => $alice, a => "foaf_Person" },
    { _id => $alice, a => "${_foaf}Person" },
    { _id => $alice, a => "<${_foaf}Person>" },
    { _id => $alice, rdf_type => "foaf_Person" },
    { _id => $alice, "${_rdf}type" => "foaf_Person" },
    { _id => $alice, "<${_rdf}type>" => "foaf_Person" },
  # subject map
    { $alice => { a => "foaf_Person" } },
    { $alice => { a => "${_foaf}Person" } },
    { $alice => { a => "<${_foaf}Person>" } },
    { $alice => { rdf_type => "foaf_Person" } },
    { $alice => { "${_rdf}type" => "foaf_Person" } },
    { $alice => { "<${_rdf}type>" => "foaf_Person" } },
    { _ns => { x => $_ex }, x_alice => { a => "foaf_Person" } },
;

# simple literals
test_decode $_, "$alice ${_foaf}name Alice " for
    { $alice => { foaf_name => "Alice" } },
    { $alice => { foaf_name => "Alice@" } },
    { $alice => { foaf_name => "Alice^<${_xsd}string>" } },
    { $alice => { foaf_name => "Alice^xsd_string" } },
;

# datatypes
test_decode $_, "$alice ${_foaf}age 42  ${_xsd}integer" for
    { $alice => { foaf_age => "42^xsd_integer" } },
    { $alice => { foaf_age => "42^<${_xsd}integer>" } },
;

# language tags
test_decode { $alice => { foaf_name => "Alice\@$_" } }, 
    "$alice ${_foaf}name Alice ".lc($_) for qw(en en-US abcdefgh-x-12345678);

# blank nodes
test_decode $_, "$alice ${_foaf}knows _:b1" for
    { $alice => { foaf_knows => { } } },
    { $alice => { foaf_knows => { _id => '_:b1' } } },
;

test_decode [ $_, bnode_prefix => 'x' ], "$alice ${_foaf}knows _:x1" for
    { $alice => { foaf_knows => { } } },
    { $alice => { foaf_knows => { _id => '_:b1' } } },
;

test_decode $_, "_:b1 ${_rdf}type ${_foaf}Person\n$alice ${_foaf}knows _:b1" for
#    { $alice => { foaf_knows => { a => 'foaf_Person' } } },
#    { $alice => { foaf_knows => { _id => '_:b1', a => 'foaf_Person' } } },
    { $alice => { foaf_knows => '_:b1' }, '_:b1' => { a => 'foaf_Person' } },
;

# TODO: more blank nodes

=cut
# valid
decode_aref { '<x:subj>' => { a => undef } }, complain => 2;
decode_aref { '' => { a => 'foaf_Person' } }, complain => 2, null => '';
ok !$error, 'not strict by default';

my $rdf = decode_aref { '<x:subj>' => { a => '' } }, complain => 2, null => '';
ok !$rdf, 'empty string as null';

decode_aref { '<x:subj>' => { a => '' } }, %handler, strict => 1;
ok !$error && $rdf, 'empty string not null by default';
=cut

=cut
my @looks_like_error = (
    { '0' => { a => 'foaf_Person' }, _ns => 'x:' },
    { _id => '0', a => 'foaf_Person', _ns => 'x:' },
);
my $rdf;
my $decoder = RDF::aREF::Decoder->new( callback => sub { $rdf++ } );
foreach (@looks_like_error) {
    $decoder->decode($_);
    ok $rdf, 'triple';
    $rdf = 0;
}
=cut

note '->plain_literal';

my %tests = (
    "a@" => "a",
    "0^<xs:integer>" => "0",
    "http://example.org/" => undef,
    "http://example.org/@" => 'http://example.org/',
    "<http://example.org/@>" => undef,
    "<>" => "<>", # (sic!)
);

use RDF::aREF::Decoder;
my $decoder = RDF::aREF::Decoder->new;

while (my ($aref, $literal) = each %tests) {
    my $got = $decoder->plain_literal($aref);
    is $got, $literal, $aref;
}

done_testing;
