package MongoDBxTestSchema::Tag;

use MongoDBx::Class::Moose;
use namespace::autoclean;

with 'MongoDBx::Class::EmbeddedDocument';

has 'category' => (is => 'ro', isa => 'Str', required => 1);

has 'subcategory' => (is => 'ro', isa => 'Str', required => 1);

__PACKAGE__->meta->make_immutable;
