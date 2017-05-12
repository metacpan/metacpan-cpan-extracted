package MongoDBxTestSchema::Novel;

use MongoDBx::Class::Moose;
use namespace::autoclean;

with 'MongoDBx::Class::Document';

has 'title' => (is => 'ro', isa => 'Str', required => 1, writer => 'set_title');

holds_one 'author' => (is => 'ro', isa => 'MongoDBxTestSchema::PersonName', required => 1, writer => 'set_author');

has 'year' => (is => 'ro', isa => 'Int', predicate => 'has_year', writer => 'set_year');

has 'added' => (is => 'ro', isa => 'DateTime', traits => ['Parsed'], required => 1);

has 'review_count' => (is => 'rw', isa => 'Int', traits => ['Transient'], lazy => 1, builder => '_build_review_count');

holds_many 'tags' => (is => 'ro', isa => 'MongoDBxTestSchema::Tag', predicate => 'has_tags');

joins_one 'synopsis' => (is => 'ro', isa => 'Synopsis', coll => 'synopsis', ref => 'novel');

has_many 'related_novels' => (is => 'ro', isa => 'Novel', predicate => 'has_related_novels', writer => 'set_related_novels', clearer => 'clear_related_novels');

joins_many 'reviews' => (is => 'ro', isa => 'Review', coll => 'reviews', ref => 'novel');

sub _build_review_count { shift->reviews->count }

sub print_related_novels {
	my $self = shift;

	foreach my $other_novel ($self->related_novels) {
		print $other_novel->title, ', ',
		      $other_novel->year, ', ',
		      $other_novel->author->name, "\n";
	}
}

around 'reviews' => sub {
	my ($orig, $self) = (shift, shift);

	my $cursor = $self->$orig;
	
	return $cursor->sort([ year => -1, title => 1, 'author.last_name' => 1 ]);
};

__PACKAGE__->meta->make_immutable;
