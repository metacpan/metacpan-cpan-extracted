use Data::Dumper;

use strict;
use Test::More 'no_plan';

BEGIN {
	use_ok( 'RDF::SKOS' );
}

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

use constant DONE => 1;

if (DONE) {

    my $skos = new RDF::SKOS;
    isa_ok ($skos, 'RDF::SKOS');
    eval {
	$skos->concept ('aaa', 'bbb');
    }; if ($@) {
	like ($@, qr/concept/, _chomp $@);
    }
    my $c = $skos->concept ('aaa' => { prefLabels => [ [ 'xxx', 'de' ] ] });
    isa_ok ($c, 'RDF::SKOS::Concept');
    is_deeply ([ $c->prefLabels ], [ ['xxx', 'de'] ], 'prefLabels');

    is_deeply ([ $c->altLabels    ],    [],           'altLabels');
    is_deeply ([ $c->hiddenLabels ],    [],           'hiddenLabels');
    is_deeply ([ $c->notes        ],    [],           'notes');
    is_deeply ([ $c->scopeNotes   ],    [],           'scopeNotes');
    is_deeply ([ $c->definitions  ],    [],           'definitions');
    is_deeply ([ $c->examples     ],    [],           'examples');
    is_deeply ([ $c->historyNotes ],    [],           'historyNotes');
    is_deeply ([ $c->editorialNotes ],  [],           'editorialNotes');
    is_deeply ([ $c->changeNotes  ],    [],           'changeNotes');

    $skos->concept ('bbb' => { prefLabels => [ [ 'yyy', 'de' ] ] });
    my $d = $skos->concept ('bbb');
    isa_ok ($d, 'RDF::SKOS::Concept');
    is_deeply ([ $d->prefLabels ], [ ['yyy', 'de'] ], 'prefLabels');

    my $e = $skos->concept ('aaa');
    is ($e, $c, 'same concept');
}

__END__

if (1) {
    my $skos = new RDF::SKOS;

    my $aaa = $skos->concept ('aaa' => { prefLabels => [ [ 'aaa', 'de' ] ] });
    my $bbb = $skos->concept ('bbb' => { prefLabels => [ [ 'bbb', 'de' ] ] });
    my $ccc = $skos->concept ('ccc' => { prefLabels => [ [ 'ccc', 'de' ] ] });

    $skos->is_narrower_than ('aaa', 'ccc');
}

__END__

if (DONE) {
    use RDF::Redland;
    my $storage = new RDF::Redland::Storage ("hashes", "test", "hash-type='memory'");
    my $model   = new RDF::Redland::Model ($storage, "");

    my $parser = new RDF::Redland::Parser (undef, "application/rdf+xml")
	or die "Failed to find parser\n";
    my $uri = new RDF::Redland::URI ("file:data/stw.rdf");
    $parser->parse_into_model ($uri, $uri, $model);

    my $skos = new RDF::SKOS::Redland ($model);

    my @css = $skos->schemes;
    is (scalar @css, 1, 'only one scheme');
    map { isa_ok ($_, 'RDF::SKOS::Scheme') } @css;

    ok (eq_set ([ map { $_->{id} } $css[0]->topConcepts ],
		[ map { "http://zbw.eu/stw/thsys/$_" } qw(a b g n p v w) ]), 'top level for stw');


    my $a = $skos->concept ("http://zbw.eu/stw/thsys/a");
    isa_ok ($a, 'RDF::SKOS::Concept');
    is ($a->{id}, 'http://zbw.eu/stw/thsys/a', 'identity of concept');
#    warn Dumper $a;

    ok (eq_set ([ map { $_->[1] } $a->prefLabels ],
		[ 'en', 'de' ]), 'prefLabel language for /a');
    map { ok ($_->[1], 'label exists') } $a->prefLabels ;
    ok (eq_array ([$a->altLabels], []), 'no altLabels');
#    warn Dumper [ $a->altLabels  ];

    my @ns = $a->narrower;
    ok (eq_array([ map { $_->{id} } $a->narrower ], [ 'http://zbw.eu/stw/thsys/70582' ]), 'one narrower for /a');
    ok (eq_array([ map { $_->{id} } 
		   map { $_->broader } 
		       $a->narrower ], [ 'http://zbw.eu/stw/thsys/a' ]), 'one narrower/broader for /a');

    my ($x70582) = $skos->concept ("http://zbw.eu/stw/thsys/a")->narrower; # there is only one

    my @ns = $x70582->narrower;
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

    my ($x15690) = $skos->concept ('http://zbw.eu/stw/descriptor/15690-2');
    is (scalar $x15690->altLabels, 5, 'altLabels for 15690');

    ok (scalar $skos->concepts > 20, 'many concepts');
}

__END__

if (DONE) {
    my $oe = new RDF::SKOS::OeNACE;
    my @cs = $oe->concepts;
    ok (@cs, 'at least some concepts');

    foreach my $c (@cs) {
	foreach my $l ($c->prefLabels) {
	    if      ($l->[1] eq '@de') {
		is ($l->[0]   ,  $RDF::SKOS::OeNACE::SKOS{$c->{id}}->[1], 'label');
	    } elsif ($l->[1] eq '@en') {
		is ($l->[0]   ,  $RDF::SKOS::OeNACE::SKOS{$c->{id}}->[2], 'label');
	    } else {
		ok (0);
	    }
	}
	ok (scalar $c->altLabels == 0, 'no altLabels');

	my ($x) = $c->hiddenLabels;
	is ($x, $c->{id}, 'hiddenLabels')
    }


}

if (DONE) {
    my $oe = new RDF::SKOS::OeNACE;
    my $J = $oe->concept ('J');
#    warn Dumper $J;

    ok (eq_array ([ sort map { $_->{id} } $J->narrower ],
		  [ qw(J58 J59 J60 J61 J62 J63) ]),
	'narrower of J');

    ok (eq_array ([ sort map { $_->{id} } $oe->concept ('J58')->narrower ],
		  [ qw(J581 J582) ]),
	'narrower of J58');

    ok (eq_array ([ sort map { $_->{id} } $oe->concept ('J581')->narrower ],
		  [ qw(J5811 J5812 J5813 J5814 J5819 ) ]),
	'narrower of J581');

    ok (eq_array ([ sort map { $_->{id} } $oe->concept ('J5811')->narrower ],
		  [ qw(J58110 ) ]),
	'narrower of J5811');

    ok (eq_array ([ sort map { $_->{id} }    $oe->concept ('J581')->narrower ],
		  [ sort map { $_->{id} }    $oe->concept ('J581')->narrowerTransitive ]),
	'narrower is not transitive');


    ok (eq_array ([ sort map { $_->{id} } $oe->concept ('J58110')->broader ],
		  [ 'J5811' ]), 'broader of J58110');
    ok (eq_array ([ sort map { $_->{id} } $oe->concept ('J5811')->broader ],
		  [ 'J581' ]), 'broader of J5811');
    ok (eq_array ([ sort map { $_->{id} } $oe->concept ('J581')->broader ],
		  [ 'J58' ]), 'broader of J581');
    ok (eq_array ([ sort map { $_->{id} } $oe->concept ('J58')->broader ],
		  [ 'J' ]), 'broader of J58');
    ok (eq_array ([ sort map { $_->{id} } $oe->concept ('J')->broader ],
		  [  ]), 'broader of J');
    ok (eq_array ([ sort map { $_->{id} }    $oe->concept ('J581')->broader ],
		  [ sort map { $_->{id} }    $oe->concept ('J581')->broaderTransitive ]),
	'broader is not transitive');

#    warn Dumper [ map { $_->{id} } @ns ];

}

if (DONE) {
    my $oe = new RDF::SKOS::OeNACE;
    ok (eq_array ([ $oe->schemes], []), 'no schemes');
}

if (DONE) {
    my $oe = new RDF::SKOS::OeNACE;
    foreach my $c ($oe->concepts) {
	ok (eq_array ([ $c->related ],      []), 'no related');

	ok (eq_array ([ $c->exactMatch ],   []), 'no exactMatch');
	ok (eq_array ([ $c->closeMatch ],   []), 'no closeMatch');
	ok (eq_array ([ $c->broadMatch ],   []), 'no broadMatch');
	ok (eq_array ([ $c->narrowMatch ],  []), 'no narrowMatch');
	ok (eq_array ([ $c->relatedMatch ], []), 'no relatedMatch');

    }
    
}

__END__

1;"J";"J";"INFORMATION UND KOMMUNIKATION"
2;"J58";"J 58";"Verlagswesen"
3;"J581";"J 58.1";"Verlegen von Büchern und Zeitschriften; sonstiges Verlagswesen (ohne Software)"
4;"J5811";"J 58.11";"Verlegen von Büchern"
5;"J58110";"J 58.11-0";"Verlegen von Büchern"
4;"J5812";"J 58.12";"Verlegen von Adressbüchern und Verzeichnissen"
5;"J58120";"J 58.12-0";"Verlegen von Adressbüchern und Verzeichnissen"
4;"J5813";"J 58.13";"Verlegen von Zeitungen"
5;"J58130";"J 58.13-0";"Verlegen von Zeitungen"
4;"J5814";"J 58.14";"Verlegen von Zeitschriften"
