use strict;
use Test::More;

use RDF::Flow qw(:all);
use RDF::Flow::Cached;

eval "use GraphViz";
my $skip = $@;

SKIP: {
    skip('GraphViz required to run tests',1) if $skip;

    {package Cache; sub get {} sub set {} sub new {}}

    my $sa = rdflow( sub { }, name => "Foo" );
    my $sb = rdflow( sub { }, name => "Bar" );
    my $s1 = cascade( $sa, $sb );
    my $s2 = rdflow( sub { }, name => "S2" );
    my $s3 = union( rdflow( sub { }, name => "S3" ), rdflow ( sub{}, name => "S4") );

    my $c1 = RDF::Flow::Cached->new( $s1, Cache->new );
    my $s = pipeline ( $c1, $s2, $s3 );
    my $g = $s->graphviz;

    $g->as_png('flow.png');
    # TODO: check image

    ok(1);
}

done_testing;
