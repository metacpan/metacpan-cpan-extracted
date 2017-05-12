use Data::Dumper;

use strict;
use Test::More 'no_plan';

BEGIN {
    use_ok( 'RDF::SKOS::STW' );
}

use constant DONE => 1;

if (DONE) {
    my $skos = new RDF::SKOS::STW;

    my @css = $skos->schemes;
    is (scalar @css, 1, 'only one scheme');
    map { isa_ok ($_, 'RDF::SKOS::Scheme') } @css;

    my $sch = $skos->scheme ($css[0]->{id});
    isa_ok ($sch, 'RDF::SKOS::Scheme');
    is ($sch->{id}, $css[0]->{id}, 'the one and only scheme');

    ok (eq_set ([ map { $_->{id} } $css[0]->topConcepts ],
		[ map { "http://zbw.eu/stw/thsys/$_" } qw(a b g n p v w) ]), 'top level for stw');


    my $a = $skos->concept ("http://zbw.eu/stw/thsys/a");
    isa_ok ($a, 'RDF::SKOS::Concept');
    is ($a->{id}, 'http://zbw.eu/stw/thsys/a', 'identity of concept');
#    warn Dumper $a;

    ok (eq_set ([ map { $_->[1] } $a->prefLabels ],
		[ 'en', 'de' ]), 'prefLabel language for /a');
    map { ok ($_->[1], 'label exists') } $a->prefLabels ;

    foreach my $ll (qw(altLabels hiddenLabels notes scopeNotes examples historyNotes editorialNotes changeNotes)) {
	ok (eq_array ([$a->$ll], []), "no $ll");
    }


    my @ns = $a->narrower;
    ok (eq_array([ map { $_->{id} } $a->narrower ], [ 'http://zbw.eu/stw/thsys/70582' ]), 'one narrower for /a');
    ok (eq_array([ map { $_->{id} } 
		   map { $_->broader } 
		       $a->narrower ], [ 'http://zbw.eu/stw/thsys/a' ]), 'one narrower/broader for /a');

    my ($x70582) = $skos->concept ("http://zbw.eu/stw/thsys/a")->narrower; # there is only one
    ok (scalar $skos->concepts > 20, 'many concepts');

    @ns = $x70582->narrower;
    is (scalar @ns, 28, 'many narrowers for 70582');

    foreach my $n (@ns) {
	my ($y) = $n->broader;
	is ($y->{id}, $x70582->{id}, 'broader of narrower of 70582');
    }
#    warn Dumper \@ns;

    my ($x18970) = $skos->concept ('http://zbw.eu/stw/descriptor/18970-2');
    @ns = $x18970->related;
#    warn Dumper \@ns;
    ok (
	eq_set ([ map { $_->{id} } @ns ],
		[
		 map { "http://zbw.eu/stw/descriptor/$_"}
		 qw( 16146-6 19788-0 19762-4 18911-4 18968-3 )
		]), 'related of 18970');


    @ns = $x18970->relatedTransitive;
#    warn Dumper \@ns;
    ok (
	eq_set ([ map { $_->{id} } @ns ],
		[
		 map { "http://zbw.eu/stw/descriptor/$_"}
		 qw( 16146-6 19788-0 19762-4 18911-4 18968-3 18970-2)
		]), 'relatedTransitive of 18970');


    my ($x15690) = $skos->concept ('http://zbw.eu/stw/descriptor/15690-2');
    is (scalar $x15690->altLabels, 5, 'altLabels for 15690');
}

__END__

