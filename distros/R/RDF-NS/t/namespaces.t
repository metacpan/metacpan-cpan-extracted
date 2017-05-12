use strict;
use warnings;
use Test::More;

use RDF::NS;

# this should never change
my $rdf  = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';

my $cur = RDF::NS->new;
is $cur->rdf, $rdf, 'rdf: namespace not changed';

$cur = RDF::NS->new('any');
is $cur->rdfs, $rdfs, 'rdfs: namespace not changed';

# get some prefixed URIs
my $ns = RDF::NS->new('20111028');

is $ns->rdf, $rdf, '$ns->rdf';
is $ns->rdf_, $rdf, '$ns->rdf_';
is $ns->rdf_type, $rdf.'type', '$ns->rdf_type';
is $ns->rdf_type('x'), $rdf.'type', '$ns->rdf_type';
is $ns->rdf('f-o'), $rdf."f-o", '$ns->rdf("f-o")';
is $ns->rdf(0), $rdf."0", '$ns->rdf("0")';

is $ns->URI("rdf:type"), $rdf.'type', '$ns->URI("rdf:type")';
is $ns->URI("rdf_type"), $rdf.'type', '$ns->URI("rdf_type")';
is $ns->URI("<rdf:type>"), "rdf:type", '$ns->URI("<rdf:type>")';

# scalar context
is $ns->SPARQL('rdf'), "PREFIX rdf: <$rdf>", 'SPARQL("rdf")';
is $ns->TTL('rdfs'), "\@prefix rdfs: <$rdfs> .", 'TTL("rdfs")';

# order is relevant
is $ns->XMLNS('rdfs,rdf'), "xmlns:rdfs=\"$rdfs\"", 'order ok';
is $ns->XMLNS('rdf,rdfs'), "xmlns:rdf=\"$rdf\"", 'order ok';

my %formats = (
    SPARQL => ["PREFIX rdf: <$rdf>","PREFIX rdfs: <$rdfs>"],
    TTL    => ["\@prefix rdf: <$rdf> .","\@prefix rdfs: <$rdfs> ."],
    XMLNS  => ["xmlns:rdf=\"$rdf\"","xmlns:rdfs=\"$rdfs\""],
    TXT    => ["rdf\t$rdf","rdfs\t$rdfs"],
    BEACON => ["#PREFIX: $rdf","#PREFIX: $rdfs"],
    ""     => [$rdf,$rdfs],
);

# list context
my @args = (['rdfs','rdf'],['rdf|rdfs'],['rdf,xxxxxx','rdfs'],['rdfs  rdf']);
foreach my $format (keys %formats) {
    foreach (@args) {
        my @list = $format ? $ns->$format(@$_) : $ns->FORMAT( $format, @$_ );
        is_deeply \@list, $formats{$format}, "$format(...)";
    }
}

my %s = $ns->SELECT('rdfs,xx','rdf');
is_deeply \%s, { rdfs => $rdfs, rdf => $rdf }, 'SELECT (list)';

my $first = $ns->SELECT('xxxxx,,rdf');
is $first, $rdf, 'SELECT (scalar)';

# edge case
$ns->{''} = "http://example.org/";
is $ns->URI(":foo"), "http://example.org/foo", "empty prefix allowed";

$ns = bless( { 'x' => 'http://example.org/' }, 'RDF::NS');
is $ns->x_alice, "http://example.org/alice", "blessed alone, one-letter prefix";

# blanks
is $ns->_abc, undef;
is $ns->_, undef;
is $ns->URI('_:xy'), undef;
is $ns->URI('_:'), undef;
is $ns->URI('_'), undef;

# constructor
$ns = RDF::NS->new({ 
    x => 'http://example.org/', 
    _ => 'http://exampel.com/'
});
is_deeply $ns, { x => 'http://example.org/' }, 'hash constructor';

done_testing;
