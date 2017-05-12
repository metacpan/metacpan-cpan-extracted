use strict;
use warnings;
use Test::More;

use RDF::NS;

my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
my $dc   = 'http://purl.org/dc/elements/1.1/';

my $ns = RDF::NS->new('20111028');

is $ns->PREFIX('http://www.w3.org/1999/02/22-rdf-syntax-ns#'), 'rdf', 'PREFIX';
is $ns->PREFIX('http://127.0.0.1/dev/null'), undef, 'not existing prefix';

is $ns->PREFIX($dc), 'dc', 'PREFIX dc';
is_deeply [ $ns->PREFIXES($dc) ], [qw(dc dc11)], 'PREFIXES has dc, dc11';

my $rev = $ns->REVERSE;

is $rev->{$rdfs}, 'rdfs', 'reverse';
is $rev->{$dc}, 'dc', 'reverse';
is $rev->{'http://www.w3.org/2003/01/geo/wgs84_pos#'}, 'geo', 'reverse';

is $rev->qname($ns->rdfs_type), 'rdfs:type', 'qname (scalar context)';
is $rev->qname($ns->rdfs), 'rdfs:', 'qname (scalar context)';

$rev = RDF::SN->new('20140908');
is $rev->qname($ns->dc11), 'dc:', 'qname';
is $rev->qname_($ns->dc11), 'dc_', 'qname_';

is_deeply [ $rev->qname($ns->rdfs_type) ], [ 'rdfs','type' ], 'qname (scalar context)';
is_deeply [ $rev->qname($ns->dc) ], [ 'dc', '' ], 'qname (list context)';
is_deeply [ $rev->qname_($ns->dc) ], [ 'dc', '' ], 'qname_ (list context)';

# check deterministic reverse lookup
is($ns->REVERSE->qname('http://www.w3.org/2001/XMLSchema#'), 'xs:', 'xs:') for 1..10;

done_testing;
