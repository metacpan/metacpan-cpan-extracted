package Plucene::Index::FieldsReader;

=head1 NAME 

Plucene::Index::FieldsReader - read Fields in a Document

=head1 SYNOPSIS

	my $reader = Plucene::Index::FieldsReader->new(
		$dir_name, $segment, $field_infos);

	my Plucene::Document $doc = $reader->doc($offset);

	my $size = $reader->size;

=head1 DESCRIPTION

This class gives access to documents within the index.

=head1 METHODS

=cut

use strict;
use warnings;

use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Store::InputStream;

=head2 new

	my $reader = Plucene::Index::FieldsReader->new(
		$dir_name, $segment, $field_infos);

This will create a new Plucene::Index::FieldsReader with the passed in 
directory name, segment and field infos.
		
=cut

sub new {
	my ($class, $dir, $seg, $fn) = @_;
	bless {
		field_infos => $fn,
		fields      => Plucene::Store::InputStream->new("$dir/$seg.fdt"),
		index       => Plucene::Store::InputStream->new("$dir/$seg.fdx"),
		size        => ((-s "$dir/$seg.fdx") / 8) }, $class;
}

=head2 size

	my $size = $reader->size;

This returns the size.

=cut

sub size { $_[0]->{size} }

=head2 doc

	my Plucene::Document $doc = $reader->doc($offset);

This will return the Plucene::Document object found at the passed in
position.

=cut

sub doc {
	my ($self, $n) = @_;
	$self->{index}->seek($n * 8, 0);
	my $pos = $self->{index}->read_long;
	$self->{fields}->seek($pos, 0);
	my $doc = Plucene::Document->new();
	for (1 .. $self->{fields}->read_vint) {
		my $fi = $self->{field_infos}->{bynumber}->[ $self->{fields}->read_vint ];
		my $bits = $self->{fields}->read_byte;
		$doc->add(
			bless {
				name         => $fi->name,
				string       => $self->{fields}->read_string,
				is_stored    => 1,
				is_indexed   => $fi->is_indexed,
				is_tokenized => (($bits & 1) != 0)              # No, really
				} => 'Plucene::Document::Field'
		);
	}
	return $doc;
}

1;
