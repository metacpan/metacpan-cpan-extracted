package MongoDBxTestSchema::Review;

use MongoDBx::Class::Moose;
use namespace::autoclean;

with 'MongoDBx::Class::Document';

belongs_to 'novel' => (is => 'ro', isa => 'Novel', required => 1);

has 'reviewer' => (is => 'ro', isa => 'Str', required => 1);

has 'text' => (is => 'ro', isa => 'Str', required => 1);

has 'score' => (is => 'ro', isa => 'Int', predicate => 'has_score');

__PACKAGE__->meta->make_immutable;
