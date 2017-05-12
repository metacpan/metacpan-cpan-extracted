package Plucene::Index::SegmentInfo;

=head1 NAME 

Plucene::Index::SegmentInfo - Information on a Segment

=head1 SYNOPSIS

	my $segment_info = Plucene::Index::SegmentInfo->new;

	# get
	my $name = $segment_info->name;
	my $doc_count = $segment_info->doc_count;
	my $dir = $segment_info->dir;

	# set
	$segment_info->name($new_name);
	$segment_info->doc_count($new_doc_count);
	$segment_info->dir($new_dir);
	
=head1 DESCRIPTION

This class holds information on a segment.

The index database is composed of 'segments' each stored in a separate file. 
When you add documents to the index, new segments may be created. You can 
compact the database and reduce the number of segments by optimizing it.

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

=head2 name / doc_count / dir

Get / set these attributes.

=cut

__PACKAGE__->mk_accessors(qw/name doc_count dir/);

1;
