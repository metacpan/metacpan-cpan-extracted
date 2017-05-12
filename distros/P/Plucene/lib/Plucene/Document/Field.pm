package Plucene::Document::Field;

=head1 NAME 

Plucene::Document::Field - A field in a Plucene::Document

=head1 SYNOPSIS

	my $field = Plucene::Document::Field->Keyword($name, $string);
	my $field = Plucene::Document::Field->Text($name, $string);

	my $field = Plucene::Document::Field->UnIndexded($name, $string);
	my $field = Plucene::Document::Field->UnStored($name, $string);

=head1 DESCRIPTION

Each Plucene::Document is made up of Plucene::Document::Field
objects. Each of these fields can be stored, indexed or tokenised.

=head1 FIELDS

=cut

use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(name string is_stored is_indexed is_tokenized reader));

=head2 name

Returns the name of the field.

=head2 string

Returns the value of the field.

=head2 is_stored

Returns true if the field is or will be stored, or false if it was
created with C<UnStored>.

=head2 is_indexed

Returns true if the field is or will be indexed, or false if it was
created with C<UnIndexed>.

=head2 is_tokenized

Returns true if the field is or will be tokenized, or false if it was
created with C<UnIndexed> or C<Keyword>.

=cut

use Carp qw(confess);

=head1 METHODS

=head2 Keyword

	my $field = Plucene::Document::Field->Keyword($name, $string);

This will make a new Plucene::Document::Field object that is stored 
and indexed, but not tokenised.
	
=cut

sub Keyword {
	my ($self, $name, $string) = @_;
	return $self->new({
			name         => $name,
			string       => $string,
			is_stored    => 1,
			is_indexed   => 1,
			is_tokenized => 0
		});
}

=head2 UnIndexed

	my $field = Plucene::Document::Field->UnIndexded($name, $string);

This will make a new Plucene::Document::Field object that is stored, but 
not indexed or tokenised.
	
=cut

sub UnIndexed {
	my ($self, $name, $string) = @_;
	return $self->new({
			name         => $name,
			string       => $string,
			is_stored    => 1,
			is_indexed   => 0,
			is_tokenized => 0
		});
}

=head2 Text

	my $field = Plucene::Document::Field->Text($name, $string);

This will make a new Plucene::Document::Field object that is stored,
indexed and tokenised.
	
=cut

sub Text {
	my ($self, $name, $string) = @_;
	return $self->new({
			name         => $name,
			string       => $string,
			is_stored    => 1,
			is_indexed   => 1,
			is_tokenized => 1
		});
}

=head2 UnStored

	my $field = Plucene::Document::Field->UnStored($name, $string);

This will make a new Plucene::Document::Field object that isn't stored,
but is indexed and tokenised.

=cut

sub UnStored {
	my ($self, $name, $string) = @_;
	return $self->new({
			name         => $name,
			string       => $string,
			is_stored    => 0,
			is_indexed   => 1,
			is_tokenized => 1
		});
}

1;
