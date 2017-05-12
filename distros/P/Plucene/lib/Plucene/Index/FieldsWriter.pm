package Plucene::Index::FieldsWriter;

=head1 NAME 

Plucene::Index::FieldsWriter - writes Fields to a Document

=head1 SYNOPSIS

	my $writer = Plucene::Index::FieldsWriter->new(
		$dir_name, $segment, $field_infos);

	$writer->add_document(Plucene::Document $doc);

=head1 DESCRIPTION

This class add documents to the appropriate files.

=head1 METHODS

=cut

use strict;
use warnings;

use Plucene::Store::OutputStream;
use Plucene::Index::FieldInfos;

=head2 new

	my $writer = Plucene::Index::FieldsWriter->new(
		$dir_name, $segment, $field_infos);

This will create a new Plucene::Index::FieldsWriter object with the passed
directory name, segment and field infos.
		
=cut

# private FieldInfos fieldInfos;
# private OutputStream fieldsStream;
# private OutputStream indexStream;

# FieldsWriter(Directory d, String segment, FieldInfos fn)
#      throws IOException {
#   fieldInfos = fn;
#   fieldsStream = d.createFile(segment + ".fdt");
#   indexStream = d.createFile(segment + ".fdx");
# }

sub new {
	my ($self, $d, $segment, $fn) = @_;
	bless {
		field_infos   => $fn,
		segment       => $segment,
		fields_stream => Plucene::Store::OutputStream->new("$d/$segment.fdt"),
		index_stream  => Plucene::Store::OutputStream->new("$d/$segment.fdx"),
	}, $self;
}

=head2 close

	$writer->close;

=cut

# final void close() throws IOException {
#   fieldsStream.close();
#   indexStream.close();
# }

sub close {
	my $self = shift;
	$self->{fields_stream}->close;
	$self->{index_stream}->close;
}

=head2 add_document

	$writer->add_document(Plucene::Document $doc);

This will add the passed Plucene::Document.

=cut

# final void addDocument(Document doc) throws IOException {
#   indexStream.writeLong(fieldsStream.getFilePointer());
#
#   int storedCount = 0;
#   Enumeration fields  = doc.fields();
#   while (fields.hasMoreElements()) {
#     Field field = (Field)fields.nextElement();
#     if (field.isStored())
#       storedCount++;
#   }
#   fieldsStream.writeVInt(storedCount);
#
#   fields  = doc.fields();
#   while (fields.hasMoreElements()) {
#     Field field = (Field)fields.nextElement();
#     if (field.isStored()) {
#       fieldsStream.writeVInt(fieldInfos.fieldNumber(field.name()));
#
#       byte bits = 0;
#       if (field.isTokenized())
#         bits |= 1;
#       fieldsStream.writeByte(bits);
#
#       fieldsStream.writeString(field.stringValue());
#     }
#   }
# }

sub add_document {
	my ($self, $doc) = @_;
	$self->{index_stream}->write_long($self->{fields_stream}->tell);
	my @stored = grep $_->is_stored, $doc->fields;
	$self->{fields_stream}->write_vint(scalar @stored);
	for my $field (@stored) {
		$self->{fields_stream}
			->write_vint($self->{field_infos}->field_number($field->name));
		$self->{fields_stream}->print(chr($field->is_tokenized));
		$self->{fields_stream}->write_string($field->string);
	}
}

1;
