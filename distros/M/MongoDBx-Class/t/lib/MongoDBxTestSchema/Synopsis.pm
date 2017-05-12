package MongoDBxTestSchema::Synopsis;

use MongoDBx::Class::Moose;
use namespace::autoclean;

with 'MongoDBx::Class::Document';

belongs_to 'novel' => (is => 'ro', isa => 'Novel', required => 1);

has 'text' => (is => 'ro', isa => 'Str', writer => 'set_text', required => 1);

__PACKAGE__->meta->make_immutable;
