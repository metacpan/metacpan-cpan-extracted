package Plucene::Index::Reader;

use strict;
use warnings;

use Carp;
use Fcntl qw(O_EXCL O_CREAT O_WRONLY);

use Plucene::Index::SegmentReader;
use Plucene::Index::SegmentInfos;
use Plucene::Index::SegmentsReader;

=head1 NAME

Plucene::Index::Reader - Abstract class for accessing an index

=head1 DESCRIPTION

IndexReader is an abstract class, providing an interface for accessing an
index.  Search of an index is done entirely through this abstract interface, so
that any subclass which implements it is searchable.

Concrete subclasses of IndexReader are usually constructed with a call to the
static method L</open>.

For efficiency, in this API documents are often referred to via document
numbers, non-negative integers which each name a unique document in the index.
These document numbers are ephemeral--they may change as documents are added to
and deleted from an index.  Clients should thus not rely on a given document
having the same number between sessions.

=head1 METHODS

=head2 new

	my $reader = Plucene::Index::Reader->new($dir_name);

This will create a new Plucene::Index::Reader with the passed in directory.

=cut

sub new {
	my ($class, $directory) = @_;
	bless { directory => $directory, writelock => undef }, $class;
}

=head2 open

	# If there is only one segment
	my Plucene::Index::SegmentReader $seg_read = $reader->open;

	# If there are many segments
	my Plucene::Index::SegmentsReader $seg_read = $reader->open;
	
Returns an IndexReader reading the index in the given Directory.

=cut

sub open {
	my ($self, $directory) = @_;
	my $reader = Plucene::Index::SegmentInfos->new;
	$reader->read($directory);
	my @segments = $reader->segments;

	return Plucene::Index::SegmentReader->new($reader->info(0), 1)
		if @segments == 1;
	return Plucene::Index::SegmentsReader->new(
		$directory,
		map Plucene::Index::SegmentReader->new($reader->info($_),
			$_ == $#segments),
		0 .. $#segments
	);

}

=head2 last_modified

	my $last_modified = Plucene::Index::Reader->last_modified($directory);

=cut

sub last_modified { (stat "$_[1]/segments")[9] }

=head2 index_exists

	if (Plucene::Index::Reader->index_exists($directory)){ ... }

=cut

sub index_exists { -e "$_[1]/segments" }

=head2 is_locked

	if (Plucene::Index::Reader->is_locked($directory)){ ... }

=cut

sub is_locked { -e "$_[1]/write.lock" }

=head2 delete

	$reader->delete($doc);

=cut

sub delete {
	my ($self, $doc) = @_;
	local *FH;
	if (!$self->{writelock}) {
		$self->{writelock} = "$self->{directory}/write.lock";
		sysopen FH, $self->{writelock}, O_EXCL | O_CREAT | O_WRONLY
			or croak "Couldn't get lock";
		close *FH;
	}
	$self->_do_delete($doc);
	unlink "$self->{directory}/write.lock";
}

=head2 delete_term

	$reader->delete_term($term);

This will delete all the documents which contain the passed term.
	
=cut

sub delete_term {
	my ($self, $term) = @_;
	my $enum = $self->term_docs($term);
	$self->delete($enum->doc) while $enum->next;
}

=head2 close

	$reader->close;

=cut

sub close {
	my $self = shift;
	$self->_do_close;
	$self->unlock($self->{directory});
}

=head2 unlock

	$reader->unlock($directory);

=cut

sub unlock {
	unlink "$_[1]/write.lock";
	unlink "$_[1]/commit.lock";
}

=head2 num_docs / max_doc / document / is_deleted / norms / terms / 
doc_freq / term_docs / term_positions / _do_delete / _do_close

These must be defined in a subclass

=cut

sub num_docs       { die "Please define num_docs in subclass" }
sub max_doc        { die "Please define max_doc in subclass" }
sub document       { die "Please define document in subclass" }
sub is_deleted     { die "Please define is_deleted in subclass" }
sub norms          { die "Please define norms in subclass" }
sub terms          { die "Please define terms in subclass" }
sub doc_freq       { die "Please define doc_freq in subclass" }
sub term_docs      { die "Please define term_docs in subclass" }
sub term_positions { die "Please define term_positions in subclass" }
sub _do_delete     { die "Please define _do_delete in subclass" }
sub _do_close      { die "Please define _do_close in subclass" }

1;
