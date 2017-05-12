package Plucene::Document;

=head1 NAME 

Plucene::Document - The unit of indexing and searching

=head1 SYNOPSIS

	my $document = Plucene::Document->new;

	$document->add( Plucene::Document::Field $field);
	my Plucene::Document::Field $field = $document->get($field_name);
	
	my Plucene::Document::Fields @fields = $document->fields;
	
=head1 DESCRIPTION

Documents are the unit of indexing and search, and each document is a set 
of fields.  Each field has a name and a textual value. 

A field may be stored with the document, in which case it is returned with 
search hits on the document.  Thus each document should typically contain 
stored fields which uniquely identify it.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors();    # For new

=head2 get

	my Plucene::Document::Field $field = $document->get($field_name);

This returns the Plucene::Document::Field object of the field with the 
given name if any exist in this document, or null.

=cut

sub get {
	my ($obj, $field) = @_;
	return ($obj->{$field} || [])->[-1];
}

=head2 add

	$document->add( Plucene::Document::Field $field);
	
This will add a field to the document.

=cut

sub add {
	my ($obj, $field) = @_;
	push @{ $obj->{ $field->name } }, $field;
}

=head2 fields

	my Plucene::Document::Field @fields = $document->fields;

This returns an list of all the fields in a document.

=cut

sub fields { map @$_, values %{ +shift } }

1;
