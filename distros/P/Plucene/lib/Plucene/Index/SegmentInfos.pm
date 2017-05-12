package Plucene::Index::SegmentInfos;

=head1 NAME

Plucene::Index::SegmentInfos - A collection of SegmentInfo objects

=head1 SYNOPSIS

	my $segmentinfos = Plucene::Index::SegmentInfos->new;

	$segmentinfos->read($dir);
	$segmentinfos->write($dir);

	$segmentinfos->add_element(Plucene::Index::SegmentInfo $segment_info);

	my Plucene::Index::SegmentInfo @segment_info 
		= $segmentinfos->segments; 

=head1 DESCRIPTION

This is a collection of Plucene::Index::SegmentInfo objects

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;

use Plucene::Index::SegmentInfo;
use Plucene::Store::InputStream;
use Plucene::Store::OutputStream;
use File::Slurp;

=head2 new

	my $segmentinfos = Plucene::Index::SegmentInfos->new;

This will create a new (empty) Plucene::Index::SegmentInfos object.

=cut

sub new { bless { segments => [] }, shift }

=head2 read

	$segmentinfos->read($dir);

This will read the segments file from the passed directory.

=cut

sub read {
	my ($self, $directory) = @_;
	my ($count, @unpack) = unpack "NN/(w/aN)", read_file("$directory/segments");
	my @segs;
	while (my ($name, $count) = splice @unpack, 0, 2) {
		push @segs,
			bless {
			name      => $name,
			doc_count => $count,
			dir       => $directory,
			} => 'Plucene::Index::SegmentInfo';
	}
	$self->{segments} = \@segs;
	$self->{counter}  = $count;
}

=head2 write

	$segmentinfos->write($dir);

This will write the segments info file out.

=cut

sub write {
	my ($self, $directory) = @_;
	my $segfile  = "$directory/segments";
	my $tempfile = "${segfile}.new";
	my @segs     = $self->segments;
	my $template = "NN" . ("w/a*N" x @segs);
	my $packed   = pack $template, $self->{counter} || 0, scalar @segs,
		map { $_->name => $_->doc_count } @segs;
	write_file($tempfile => $packed);
	rename($tempfile => $segfile);
}

=head2 add_element

	$segmentinfos->add_element(Plucene::Index::SegmentInfo $segment_info);

This will add the passed Plucene::Index::SegmentInfo object..

=cut

sub add_element { push @{ $_[0]->{segments} }, $_[1] }

=head2 info

	my Plucene::Index::SegmentInfo $info 
		= $segmentinfos->info($segment_no);

This will return the Plucene::Index::SegmentInfo object at the passed 
segment number.

=cut

sub info { $_[0]->{segments}->[ $_[1] ] }

=head2 segments

	my Plucene::Index::SegmentInfo @segment_info 
		= $segmentinfos->segments; 

This returns all the Plucene::Index::SegmentInfo onjects in this segment.

=cut

sub segments { @{ $_[0]->{segments} } }

1;
