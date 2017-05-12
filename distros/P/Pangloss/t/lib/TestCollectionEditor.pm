package TestCollectionEditor;

use Error;
use Pangloss::StoredObject::Error;
use base qw( Pangloss::Application::CollectionEditor );

use constant object_name      => 'object';
use constant objects_name     => 'objects';
use constant collection_name  => 'test_objects';
use constant collection_class => 'TestCollection';

sub error_key_exists {
    my $self = shift;
    my $key  = shift;
    throw Pangloss::StoredObject::Error(flag => eExists, key => $key);
}

1;
