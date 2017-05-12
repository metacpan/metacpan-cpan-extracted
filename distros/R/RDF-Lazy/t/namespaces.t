use strict;
use warnings;

use Test::More;
use RDF::Lazy;

my $g = RDF::Lazy->new;

is $g->ns('dc'), 'http://purl.org/dc/elements/1.1/', 'ns namespace lookup';
is $g->ns('http://purl.org/dc/elements/1.1/'), 'dc', 'ns prefix lookup';
ok !$g->ns('rdfs:seeAlso'), 'qname lookup';

$g->ns( dc => 'http://example.org/' );
is $g->ns('dc'), 'http://example.org/', 'ns namespace lookup after modify';
is $g->ns('http://example.org/'), 'dc', 'ns prefix lookup';

done_testing;
