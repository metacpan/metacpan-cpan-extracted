package Plucene::Index::Writer;

=head1 NAME 

Plucene::Index::Writer - write an index.

=head1 SYNOPSIS

	my $writer = Plucene::Index::Writer->new($path, $analyser, $create);

	$writer->add_document($doc);
	$writer->add_indexes(@dirs);

	$writer->optimize; # called before close
	
	my $doc_count = $writer->doc_count;

	my $mergefactor = $writer->mergefactor;

	$writer->set_mergefactor($value);

=head1 DESCRIPTION

This is the writer class.

If an index will not have more documents added for a while and optimal search
performance is desired, then the C<optimize> method should be called before the
index is closed.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp qw/cluck croak/;
use Fcntl qw(O_EXCL O_CREAT O_WRONLY);
use File::Path qw(mkpath);
use List::Util qw(sum);
use File::Temp qw(tempdir);

use Plucene::Index::DocumentWriter;
use Plucene::Index::SegmentInfos;
use Plucene::Index::SegmentInfo;
use Plucene::Index::SegmentReader;
use Plucene::Index::SegmentMerger;
use Plucene::Utils;

use constant MAX_FIELD_LENGTH => 10_000;

our $max_merge_docs = ~0;

=head2 new

	my $writer = Plucene::Index::Writer->new($path, $analyser, $create);

This will create a new Plucene::Index::Writer object.
	
The third argument to the constructor determines whether a new index is
created, or whether an existing index is opened for the addition of new
documents.

=cut

sub new {
	my ($class, $path, $analyzer, $create) = @_;
	$create = 0 unless defined $create;
	if (!-d $path) {
		croak "Couldn't write into $path - it doesn't exist" unless $create;
		mkpath($path) or croak "Couldn't create $path - $!";
	}

	my $lock = "$path/write.lock";

	my $self = bless {
		directory => $path,
		analyzer  => $analyzer,
		lock      => $lock,       # There are many like it, but this one is mine
		segmentinfos  => new Plucene::Index::SegmentInfos(),
		tmp_directory => tempdir(CLEANUP => 1),
		mergefactor   => 10,
	}, $class;

	local *FH;
	sysopen FH, $lock, O_EXCL | O_CREAT | O_WRONLY
		or croak "Couldn't get lock";
	close *FH;

	do_locked {
		$create
			? $self->{segmentinfos}->write($path)
			: $self->{segmentinfos}->read($path);
		}
		"$path/commit.lock";

	return $self;
}

=head2 mergefactor / set_mergefactor

	my $mergefactor = $writer->mergefactor;

	$writer->set_mergefactor($value);

Get / set the mergefactor. It defaults to 5.

=cut

sub mergefactor { $_[0]->{mergefactor} }

sub set_mergefactor {
	$_[0]->{mergefactor} = $_[1] || $_[0]->mergefactor || 10;
}

sub DESTROY {
	my $self = shift;
	unlink $self->{lock} if $self->{lock};
	$self->_flush;
}

=head2 doc_count

	my $doc_count = $writer->doc_count;

=cut

sub doc_count { sum map $_->doc_count(), $_[0]->{segmentinfos}->segments }

=head2 add_document

	$writer->add_document($doc);

Adds a document to the index. After the document has been added, a merge takes
place if there are more than C<$Plucene::Index::Writer::mergefactor> segments
in the index. This defaults to 10, but can be set to whatever value is optimal 
for your application.   
	
=cut

sub add_document {
	my ($self, $doc) = @_;

	my $dw = Plucene::Index::DocumentWriter->new($self->{tmp_directory},
		$self->{analyzer}, MAX_FIELD_LENGTH);
	my $segname = $self->_new_segname;
	$dw->add_document($segname, $doc);

	#lock $self;
	$self->{segmentinfos}->add_element(
		Plucene::Index::SegmentInfo->new({
				name      => $segname,
				doc_count => 1,
				dir       => $self->{tmp_directory} }));
	$self->_maybe_merge_segments;
}

sub _new_segname {
	"_" . $_[0]->{segmentinfos}->{counter}++    # Urgh
}

sub _flush {
	my $self        = shift;
	my @segs        = $self->{segmentinfos}->segments;
	my $min_segment = $#segs;
	my $doc_count   = 0;
	while ($min_segment >= 0
		and $segs[$min_segment]->dir eq $self->{tmp_directory}) {
		$doc_count += $segs[$min_segment]->doc_count;
		$min_segment--;
	}
	if ( $min_segment < 0
		or ($doc_count + $segs[$min_segment]->doc_count > $self->mergefactor)
		or !($segs[-1]->dir eq $self->{tmp_directory})) {
		$min_segment++;
	}
	return if $min_segment > @segs;
	$self->_merge_segments($min_segment);
}

=head2 optimize

	$writer->optimize;

Merges all segments together into a single segment, optimizing an index
for search. This should be the last method called on an indexer, as it 
invalidates the writer object.

=cut

sub optimize {
	my $self = shift;
	my $segments;
	while (
		($segments = scalar $self->{segmentinfos}->segments) > 1
		or

		# If it's fragmented
		(
			$segments == 1 and    # or it's not fragmented
			(
				Plucene::Index::SegmentReader->has_deletions(    # but has deletions
					$self->{segmentinfos}->info(0))))
		) {
		my $minseg = $segments - $self->mergefactor;
		$self->_merge_segments($minseg < 0 ? 0 : $minseg);
	}
}

=head2 add_indexes

	$writer->add_indexes(@dirs);

Merges all segments from an array of indexes into this index.

This may be used to parallelize batch indexing.  A large document
collection can be broken into sub-collections.  Each sub-collection can be
indexed in parallel, on a different thread, process or machine.  The
complete index can then be created by merging sub-collection indexes
with this method.

After this completes, the index is optimized.

=cut

sub add_indexes {
	my ($self, @dirs) = @_;
	$self->optimize;
	for my $dir (@dirs) {
		my $sis = new Plucene::Index::SegmentInfos;
		$sis->read($dir);
		$self->{segmentinfos}->add_element($_) for $sis->segments;
	}
	$self->optimize;
}

# Incremental segment merger.
# Or even this code - SC
sub _maybe_merge_segments {
	my $self              = shift;
	my $target_merge_docs = $self->mergefactor;
	while ($target_merge_docs <= $max_merge_docs) {
		cluck("No segments defined!") unless $self->{segmentinfos};
		my $min_seg    = scalar $self->{segmentinfos}->segments;
		my $merge_docs = 0;
		while (--$min_seg >= 0) {
			my $si = $self->{segmentinfos}->info($min_seg);
			last if $si->doc_count >= $target_merge_docs;
			$merge_docs += $si->doc_count;
		}
		last unless $merge_docs >= $target_merge_docs;
		$self->_merge_segments($min_seg + 1);
		$target_merge_docs *= $self->mergefactor;
	}
}

# Pops segments off of segmentInfos stack down to minSegment, merges
# them, and pushes the merged index onto the top of the segmentInfos stack.
sub _merge_segments {
	my $self        = shift;
	my $min_segment = shift;
	my $mergedname  = $self->_new_segname;
	my $mergedcount = 0;
	my $merger      = Plucene::Index::SegmentMerger->new({
			dir     => $self->{directory},
			segment => $mergedname
		});
	my @to_delete;
	my @segments = $self->{segmentinfos}->segments;
	return if $#segments < $min_segment;

	for my $si (@segments[ $min_segment .. $#segments ]) {
		my $reader = Plucene::Index::SegmentReader->new($si);
		$merger->add($reader);
		push @to_delete, $reader
			if $reader->directory eq $self->{directory}
			or $reader->directory eq $self->{tmp_directory};
		$mergedcount += $si->doc_count;
	}
	$merger->merge;

	$self->{segmentinfos}->{segments} =    # This is a bit naughty
		[
		($self->{segmentinfos}->segments)[ 0 .. $min_segment - 1 ],
		Plucene::Index::SegmentInfo->new({
				name      => $mergedname,
				dir       => $self->{directory},
				doc_count => $mergedcount
			}) ];
	do_locked {
		$self->{segmentinfos}->write($self->{directory});
		$self->_delete_segments(@to_delete);
		}
		"$self->{directory}/commit.lock";

}

sub _delete_segments {
	my ($self, @to_delete) = @_;
	my @try_later = $self->_delete($self->_read_deletable_files);
	for my $reader (@to_delete) {
		for my $file ($reader->files) {
			push @try_later, $self->_delete("$reader->{directory}/$file");
		}
	}
	$self->_write_deletable_files(@try_later);
}

sub _delete {
	my ($self, @files) = @_;
	my @failed;
	for (@files) { unlink $_ or push @failed, $_ }
	return @failed;
}

sub _read_deletable_files {
	my $self = shift;
	return unless -e (my $dfile = "$self->{directory}/deletable");
	open my $fh, $dfile or die $!;
	chomp(my @files = <$fh>);
	return @files;
}

sub _write_deletable_files {
	my ($self, @files) = @_;
	my $dfile = "$self->{directory}/deletable";
	open my $fh, ">" . $dfile . ".new" or die $!;
	print $fh "$_\n" for @files;
	close($fh);
	rename $dfile . ".new", $dfile;
}

1;
