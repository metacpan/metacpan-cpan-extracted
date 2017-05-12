package Plucene::Index::TermInfosReader;

=head1 NAME 

Plucene::Index::TermInfosReader - read the term infos file

=head1 SYNOPSIS

	my $reader = Plucene::Index::TermInfosReader->new(
			$dir_name, $segment, $fis);

	my Plucene::Index::TermInfo $term_info = 
		$reader->get(Plucene::Index::Term $term);
		
	my Plucene::Index::SegmentTermEnum $enum = 
		$reader->terms(Plucene::Index::Term $term);
	
=head1 DESCRIPTION

This reads a term infos file.

=head1 METHODS

=cut

use strict;
use warnings;

use Memoize;

use Carp qw/confess/;

use Plucene::Index::SegmentTermEnum;
use Plucene::Index::TermInfosWriter;
use Plucene::Store::InputStream;

=head2 new

	my $reader = Plucene::Index::TermInfosReader->new(
			$dir_name, $segment, $fis);

This will create a new Plucene::Index::TermInfosReader object with
the passed directory name, segment name and field infos.
			
=cut

sub new {
	my ($class, $dir, $seg, $fis) = @_;
	my $file = "$dir/$seg.tis";
	confess("$file is already open!") unless -s $file;

	my $self = bless {
		directory   => $dir,
		segment     => $seg,
		field_infos => $fis,
		enum        => Plucene::Index::SegmentTermEnum->new(
			Plucene::Store::InputStream->new($file),
			$fis, 0
		),
	}, $class;
	$self->{size} = $self->{enum}->size;
	$self->_read_index;
	return $self;
}

sub _read_index {
	my $self       = shift;
	my $index_enum = Plucene::Index::SegmentTermEnum->new(
		Plucene::Store::InputStream->new(
			"$self->{directory}/$self->{segment}.tii"),
		$self->{field_infos},
		1
	);
	my $size = $index_enum->size;
	$self->{index_terms}    = [];
	$self->{index_infos}    = [];
	$self->{index_pointers} = [];
	for (my $i = 0 ; $index_enum->next ; $i++) {
		$self->{index_terms}->[$i] = $index_enum->term;

		# Need to clone here.
		$self->{index_infos}->[$i] =
			Plucene::Index::TermInfo->new({ %{ $index_enum->term_info } });
		$self->{index_pointers}->[$i] = $index_enum->index_pointer;
	}
}

memoize('_get_index_offset');

sub _get_index_offset {
	my ($self, $term) = @_;
	my $lo = 0;
	my $hi = $#{ $self->{index_terms} };

	while ($hi >= $lo) {
		my $mid = ($lo + $hi) >> 1;

		# Terms are comparable, hooray
		my $delta = $term->_cmp($self->{index_terms}->[$mid]);
		if    ($delta < 0) { $hi = $mid - 1; }
		elsif ($delta > 0) { $lo = $mid + 1; }
		else { return $mid }
	}
	return $hi;
}

=head2 get

	my Plucene::Index::TermInfo $term_info = 
		$reader->get(Plucene::Index::Term $term);

=cut

sub get {
	my ($self, $term) = @_;
	return unless $self->{size};
	$self->_seek_enum($self->_get_index_offset($term));
	return $self->_scan_enum($term);
}

sub _seek_enum {
	my ($self, $offset) = @_;
	$self->{enum}->seek(
		$self->{index_pointers}->[$offset],
		$offset * Plucene::Index::TermInfosWriter::INDEX_INTERVAL() - 1,
		$self->{index_terms}->[$offset],
		$self->{index_infos}->[$offset]);
}

sub _scan_enum {
	my ($self, $term) = @_;
	1 while $term->gt($self->{enum}->term) && $self->{enum}->next;
	return $self->{enum}->term_info
		if $self->{enum}->term
		and $self->{enum}->term->eq($term);
	return;
}

=head2 get_int / get_position

These are never called.

=cut

sub get_int      { }
sub get_position { }

=head2 terms

	my Plucene::Index::SegmentTermEnum $enum = 
		$reader->terms(Plucene::Index::Term $term);

This will return the Plucene::Index::SegmentTermEnum for the passed-in
Plucene::Index::Term.
		
=cut

sub terms {
	my ($self, $term) = @_;
	$term ? $self->get($term) : $self->_seek_enum(0);
	$self->{enum}->clone;
}

1;
