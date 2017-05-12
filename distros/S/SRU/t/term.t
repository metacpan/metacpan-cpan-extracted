use strict;
use warnings;
use Test::More qw( no_plan );
use SRU::Utils::XMLTest qw( wellFormedXML );

use_ok( 'SRU::Response::Term' );

MISSING_TERM: {
    ok( ! $SRU::Error, 'error undefined' );
    my $t = SRU::Response::Term->new();
    ok( !$t, 'constructor returned undef when missing value attribute' );
    is( $SRU::Error,'must supply value parameter in call to new()','error msg');
}

OK: {
    my $t = SRU::Response::Term->new(
        value               => 'Foo Fighter', 
        numberOfRecords     => 42,
        displayTerm         => 'Le Fighters de Foo', 
        whereInList         => 'inner',
        extraTermData       => '<fighter>foo</fighter>'
    );
    isa_ok( $t, 'SRU::Response::Term' );
    is( $t->value(), 'Foo Fighter', 'value()' );
    is( $t->numberOfRecords(), 42, 'numberOfRecords()' );
    is( $t->displayTerm(), 'Le Fighters de Foo', 'displayTerm()' );
    is( $t->whereInList(), 'inner', 'whereInList()' );
    is( $t->extraTermData(), '<fighter>foo</fighter>', 'extraTermData()' );

    my $xml = $t->asXML();
    ok( wellFormedXML($xml), 'asXML() well formed XML' );
}
        

