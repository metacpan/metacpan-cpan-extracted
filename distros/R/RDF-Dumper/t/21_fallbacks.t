use strict;

use Test::More;
use RDF::Trine qw(statement iri);
use RDF::Dumper qw(Dumper);

$Data::Dumper::Indent = 0;

my $model = RDF::Trine::Model->temporary_model;
my $stm = statement( iri('my:a'), iri('my:b'), iri('my:c') );
$model->add_statement( $stm );

is(
    Dumper(undef),
    qq(undef),
);

is(
    Dumper([qw<1 2 3>]),
    qq(['1','2','3']),
);

is(
    Dumper($model),
    qq(<my:a> <my:b> <my:c> .\n),
);

done_testing;
