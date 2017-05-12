package MongoDBx::Class::Moose;

# ABSTRACT: Extends Moose with common relationships for MongoDBx::Class documents

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose ();
use Moose::Exporter;

=head1 NAME

MongoDBx::Class::Moose - Extends Moose with common relationships for MongoDBx::Class documents

=head1 VERSION

version 1.030002

=head1 PROVIDES

L<Moose>

=head1 SYNOPSIS

	# create a document class
	package MyApp::Schema::Novel;

	use MongoDBx::Class::Moose; # use this instead of Moose;
	use namespace::autoclean;

	with 'MongoDBx::Class::Document';

	has 'title' => (is => 'ro', isa => 'Str', required => 1, writer => 'set_title');

	holds_one 'author' => (is => 'ro', isa => 'MyApp::Schema::PersonName', required => 1, writer => 'set_author');

	has 'year' => (is => 'ro', isa => 'Int', predicate => 'has_year', writer => 'set_year');

	has 'added' => (is => 'ro', isa => 'DateTime', traits => ['Parsed'], required => 1);
	
	holds_many 'tags' => (is => 'ro', isa => 'MyApp::Schema::Tag', predicate => 'has_tags');

	joins_one 'synopsis' => (is => 'ro', isa => 'Synopsis', coll => 'synopsis', ref => 'novel');

	has_many 'related_novels' => (is => 'ro', isa => 'Novel', predicate => 'has_related_novels', writer => 'set_related_novels', clearer => 'clear_related_novels');

	joins_many 'reviews' => (is => 'ro', isa => 'Review', coll => 'reviews', ref => 'novel');

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

=head1 DESCRIPTION

This module provides some relationship types (i.e. database references)
for L<MongoDB documents|MongoDBx::Class::Document> and L<embedded documents|MongoDBx::Class::EmbeddedDocument>,
in the form of L<Moose> attributes. It also provides everything Moose
provides, and so is to replace C<use Moose> when creating document classes.

=cut

Moose::Exporter->setup_import_methods(
	with_meta => [ 'belongs_to', 'has_one', 'has_many', 'holds_one', 'holds_many', 'defines_many', 'joins_one', 'joins_many' ],
	also      => 'Moose',
);

=head1 RELATIONSHIP TYPES

This module provides the following relationship types. The differences
between different relationships stem from the different ways in which
references can be represented in the database.

=head2 belongs_to

Specifies that the document has an attribute which references another,
supposedly parent, document. The reference is in the form documented by
L<MongoDBx::Class::Reference>.

	belongs_to 'parent' => (is => 'ro', isa => 'Article', required => 1)

In the database, this relationship is represented in the referencing
document like this:

	{ ... parent => { '$ref' => 'coll_name', '$id' => $mongo_oid } ... }

Calling C<parent()> on the referencing document returns the parent
document after expansion:

	$doc->parent->title;

=cut

sub belongs_to {
	my ($meta, $name, %opts) = @_;

	$opts{isa} = 'MongoDBx::Class::CoercedReference';
	$opts{coerce} = 1;

	$meta->add_attribute('_'.$name => %opts);
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;
		return unless $self->$attr;
		return $self->$attr->load;
	});
}

=head2 has_one

Specifies that the document has an attribute which references another
document. The reference is in the form documented by L<MongoDBx::Class::Reference>.
This is entirely equivalent to L</belongs_to>, the two are provided merely
for convenience, the difference is purely semantic.

=cut

sub has_one {
	belongs_to(@_);
}

=head2 has_many

Specifies that the document has an attribute which holds a list (array)
of references to other documents. These references are in the form
documented by L<MongoDBx::Class::Reference>.

	has_many 'related_articles' => (is => 'ro', isa => 'Article', predicate => 'has_related_articles')

In the database, this relationship is represented in the referencing
document like this:

	{ ... related_articles => [{ '$ref' => 'coll_name', '$id' => $mongo_oid_1 }, { '$ref' => 'other_coll_name', '$id' => $mongo_oid_2 }] ... }

Calling C<related_articles()> on the referencing document returns an array
of all referenced documents, after expansion:

	foreach ($doc->related_articles) {
		print $_->title, "\n";
	}

=cut

sub has_many {
	my ($meta, $name, %opts) = @_;

	$opts{isa} = "ArrayOfMongoDBx::Class::CoercedReference";
	$opts{coerce} = 1;

	$meta->add_attribute('_'.$name => %opts);
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;

		my @docs;
		foreach (@{$self->$attr || []}) {
			push(@docs, $_->load);
		}
		return @docs;
	});
}

=head2 holds_one

Specifies that the document has an attribute which holds an embedded
document (a.k.a sub-document) in its entirety. The embedded document
is represented by a class that C<does> L<MongoDBx::Class::EmbeddedDocument>.

	holds_one 'author' => (is => 'ro', isa => 'MyApp::Schema::PersonName', required => 1)

Note that the C<holds_one> relationship has the unfortunate constraint of
having to pass the full package name of the foreign document (e.g. MyApp::Schema::PersonName
above), whereas other relationship types (except C<holds_many> which has
the same constraint) require the class name only (e.g. Novel).

In the database, this relationship is represented in the referencing (i.e.
holding) document like this:

	{ ... author => { first_name => 'Arthur', middle_name => 'Conan', last_name => 'Doyle' } ... }

Calling C<author()> on the referencing document returns the embedded
document, after expansion:

	$doc->author->first_name; # returns 'Arthur'

=cut

sub holds_one {
	my ($meta, $name, %opts) = @_;

	$opts{documentation} = 'MongoDBx::Class::EmbeddedDocument';

	$meta->add_attribute($name => %opts);
}

=head2 holds_many

Specifies that the document has an attribute which holds a list (array)
of embedded documents (a.k.a sub-documents) in their entirety. These
embedded documents are represented by a class that C<does>
L<MongoDBx::Class::EmbeddedDocument>.

	holds_many 'tags' => (is => 'ro', isa => 'MyApp::Schema::Tag', predicate => 'has_tags')

Note that the C<holds_many> relationship has the unfortunate constraint of
having to pass the full package name of the foreign document (e.g. MyApp::Schema::Tag
above), whereas other relationship types (except C<holds_one> which has
the same constraint) require the class name only (e.g. Novel).

In the database, this relationship is represented in the referencing (i.e.
holding) document like this:

	{ ... tags => [ { category => 'mystery', subcategory => 'thriller' }, { category => 'mystery', subcategory => 'detective' } ] ... }

=cut

sub holds_many {
	my ($meta, $name, %opts) = @_;

	$opts{isa} = "ArrayRef[$opts{isa}]";
	$opts{documentation} = 'MongoDBx::Class::EmbeddedDocument';

	$meta->add_attribute('_'.$name => %opts);
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;

		return @{$self->$attr || []};
	});
}

=head2 defines_many

Specifies that the document has an attribute which holds a hash (a.k.a
associative array or dictionary) of embedded documents in their entirety.
These embedded documents are represented by a class that C<does>
L<MongoDBx::Class::EmbeddedDocument>.

	defines_many 'things' => (is => 'ro', isa => 'MyApp::Schema::Thing', predicate => 'has_things');

When calling C<things()> on a document, a hash-ref is returned (not a hash!).

Like C<holds_many> and C<holds_one>, this relationship has the unfortunate
constraint of having to pass the full package name of the foreign document
(e.g. MyApp::Schema::Thing above), whereas other relationship types
require the class name only (e.g. Novel).

In the database, this relationship is represented in the referencing (i.e.
holding) document like this:

	{ ...
	  things => {
		"mine" => { _class => 'MyApp::Schema::Thing', ... },
		"his" => { _class => 'MyApp::Schema::Thing', ... },
		"hers" => { _class => 'MyApp::Schema::Thing', ... },
	  }
	  ...
	}

=cut

sub defines_many {
	my ($meta, $name, %opts) = @_;

	$opts{isa} = "HashRef[$opts{isa}]";
	$opts{documentation} = 'MongoDBx::Class::EmbeddedDocument';

	$meta->add_attribute('_'.$name => %opts);
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;

		return $self->$attr || {};
	});
}

=head2 joins_one

Specifies that the document is referenced by one other document. The reference
in the other document to this document is in the form documented by
L<MongoDBx::Class::Reference>. This "pseudo-attribute" requires
two new options: 'coll', with the name of the collection in which the
referencing document is located, and 'ref', with the name of the attribute
which is referencing the document. If 'coll' isn't provided, the referencing
document is searched in the same collection.

	joins_one 'synopsis' => (is => 'ro', isa => 'Synopsis', coll => 'synopsis', ref => 'novel')

In the database, this relationship is represented in the referencing
document (located in the 'synopsis' collection) like this:

	{ ... novel => { '$ref' => 'novels', '$id' => $mongo_oid } ... }

When calling C<synopsis()> on a Novel document, a C<find_one()> query is
performed like so:

	$db->get_collection('synopsis')->find_one({ 'novel.$id' => $doc->_id })

Note that passing a 'required' option to C<joins_one> has no effect at all,
the existence of the referencing document is never enforced, so C<undef>
can be returned.

=cut

sub joins_one {
	my ($meta, $name, %opts) = @_;

	$opts{coll} ||= '<same>';
	$opts{isa} = 'MongoDBx::Class::Reference';

	my $ref = delete $opts{ref};
	my $coll = delete $opts{coll};

	$meta->add_method($name => sub {
		my $self = shift;

		my $coll_name = $coll eq '<same>' ? $self->_collection->name : $coll;

		return $self->_collection->_database->get_collection($coll_name)->find_one({ $ref.'.$id' => $self->_id });
	});
}

=head2 joins_many

Specifies that the document is referenced by other documents. The references
in the other document to this document are in the form documented by
L<MongoDBx::Class::Reference>. This "pseudo-attribute" requires two new
options: 'coll', with the name of the collection in which the referencing
documents are located, and 'ref', with the name of the attribute which
is referncing the document. If 'coll' isn't provided, the referencing
documents are searched in the same collection.

	joins_many 'reviews' => (is => 'ro', isa => 'Review', coll => 'reviews', ref => 'novel')

In the database, this relationship is represented in the referencing
documents (located in the 'reviews' collection) like this:

	{ ... novel => { '$ref' => 'novels', '$id' => $mongo_oid } ... }

When calling C<reviews()> on a Novel document, a C<find()> query is
performed like so:

	$db->get_collection('reviews')->find({ 'novel.$id' => $doc->_id })

And thus a L<MongoDBx::Class::Cursor> is returned.

Note that passing the 'required' option to C<joins_many> has no effect
at all, and the existance of referncing documents is never enforced, so
the cursor can have a count of zero.

=cut

sub joins_many {
	my ($meta, $name, %opts) = @_;

	$opts{coll} ||= '<same>';
	$opts{isa} = 'MongoDBx::Class::Reference';

	my $ref = delete $opts{ref};
	my $coll = delete $opts{coll};

	$meta->add_method($name => sub {
		my $self = shift;

		my $coll_name = $coll eq '<same>' ? $self->_collection->name : $coll;

		return $self->_collection->_database->get_collection($coll_name)->find({ $ref.'.$id' => $self->_id });
	});
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Moose

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 SEE ALSO

L<MongoDBx::Class::Document>, L<MongoDBx::Class::EmbeddedDocument>, L<Moose>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
