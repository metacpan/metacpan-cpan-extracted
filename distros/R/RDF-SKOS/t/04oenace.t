use Data::Dumper;

use strict;
use Test::More 'no_plan';

BEGIN {
	use_ok( 'RDF::SKOS::OeNACE' );
}

use constant DONE => 1;

if (DONE) {
    my $oe = new RDF::SKOS::OeNACE;
    my @cs = $oe->concepts;
    ok (@cs, 'at least some concepts');

    my @tops = $oe->topConcepts;
    ok ((! grep { $_->{id} !~ /^[A-Z]$/} @tops), 'top: only those we want A-Z');
    is (scalar @tops, 21, 'top: all we want');

    foreach my $c (@cs) {
	foreach my $l ($c->prefLabels) {
	    if      ($l->[1] eq 'de') {
		is ($l->[0]   ,  $RDF::SKOS::OeNACE::SKOS{$c->{id}}->[1], 'label');
	    } elsif ($l->[1] eq 'en') {
		is ($l->[0]   ,  $RDF::SKOS::OeNACE::SKOS{$c->{id}}->[2], 'label');
	    } else {
		ok (0);
	    }
	}
	is_deeply ( [$c->altLabels ], [], 'no altLabels');

	my ($x) = $c->hiddenLabels;
	is ($x->[0], $c->{id}, 'hiddenLabels')
    }


}

if (DONE) {
    my $oe = new RDF::SKOS::OeNACE;
    is_deeply ([ $oe->schemes] , [], 'no schemes');
    eval {
	$oe->scheme ('xxx');
    }; like ($@, qr/schemeing/, 'no particular');
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

#	ok (eq_array ([ $c->exactMatch ],   []), 'no exactMatch');
#	ok (eq_array ([ $c->closeMatch ],   []), 'no closeMatch');
#	ok (eq_array ([ $c->broadMatch ],   []), 'no broadMatch');
#	ok (eq_array ([ $c->narrowMatch ],  []), 'no narrowMatch');
#	ok (eq_array ([ $c->relatedMatch ], []), 'no relatedMatch');

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
