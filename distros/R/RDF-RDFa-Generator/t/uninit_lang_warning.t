use strict;
use warnings;

use Test::More;
use Test::Output;

use RDF::Trine qw(blank iri literal);
use RDF::RDFa::Generator;

my $t = RDF::Trine::Statement::Quad->new(
	blank('x'),
	iri('http://example.org/p'),
	literal(3),
	iri('http://example.org/graph1'),
);

my $model = RDF::Trine::Model->new(); 
$model->add_statement($t);

my $pretty = RDF::RDFa::Generator::HTML::Pretty->new();

stderr_unlike sub {
	print $pretty->create_document($model);
}, qr/Use of uninitialized value in subroutine entry/, 'pretty - no uninitalized value warning ok';

my $head = RDF::RDFa::Generator::HTML::Head->new();

stderr_unlike sub {
	print $head->create_document($model);
}, qr/Use of uninitialized value in subroutine entry/, 'head - no uninitalized value warning ok';

done_testing();
