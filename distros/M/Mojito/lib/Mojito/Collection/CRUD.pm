use strictures 1;
package Mojito::Collection::CRUD;
$Mojito::Collection::CRUD::VERSION = '0.25';
use Mojito::Collection::CRUD::Mongo;
use Mojito::Collection::CRUD::Deep;
use Mojito::Collection::CRUD::Elasticsearch;
use Moo;

has 'editer' => (
    is => 'ro',
    lazy => 1,
    writer => '_set_editer',
    handles =>  [ qw( create read update delete db ) ],
);

sub BUILD {
    my ($self, $constructor_args_href) = @_;
    
    # Determine the document store backend from the configuration
    my $doc_storage = ucfirst lc $constructor_args_href->{config}->{document_storage};
    my $delegatee = __PACKAGE__ . '::' . $doc_storage;
    $self->_set_editer($delegatee->new($constructor_args_href));
}

1;
