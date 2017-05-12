use strict;
use warnings;

use Test::More;
use RDF::Flow;
use RDF::Flow::Dummy;
use RDF::Flow::Union;
use RDF::Trine::Model;
use RDF::Trine qw(iri statement);

my $f = rdflow( from => 't/data/example.ttl' );
my $rdf = $f->retrieve('http://example.org/foo');
is ( $rdf->size, 1, 'from file' );

my $example_model = RDF::Trine::Model->new;
$example_model->add_statement(statement(
    map { iri("http://example.com/$_") } qw(subject predicate object) ));

#  use Log::Contextual::SimpleLogger;
#  use Log::Contextual qw( :log ),
#     -logger => Log::Contextual::SimpleLogger->new({ levels => [qw(trace)]});
#use Carp;

# '/subject', [ 'Accept' => 'text/turtle' ] ],
#        content => qr{subject>.+predicate>.+object>},

# '/adverb', [ 'Accept' => 'text/turtle' ] ],
#  content => 'Not found',

my $source = RDF::Flow::Union->new( $example_model, RDF::Flow::Dummy->new );

# request => '/subject'
# content => qr{subject>.+predicate>.+object>},
#
ok( $source->retrieve('http://example.com/subject') );

# request => '/adverb'
# content => qr{adverb> a.+Resource>},

$source = sub { die "boo!"; };

# name => 'Failing source',
# request => '/foo'
# content => 'boo!'

#  name => 'Empty source',
#  source => sub { } ),
#  request => '/foo'


## directory as source

$f = rdflow( from => 't/data' );
$rdf = $f->retrieve('http://example.org/foo');
is ( $rdf->size, 3, 'from directory' );

done_testing;
