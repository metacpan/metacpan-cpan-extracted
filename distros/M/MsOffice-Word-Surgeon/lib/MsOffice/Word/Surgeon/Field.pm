package MsOffice::Word::Surgeon::Field;
use 5.24.0;
use Moose;
use Moose::Util::TypeConstraints   qw(enum);
use MooseX::StrictConstructor;

use namespace::clean -except => 'meta';

#======================================================================
# ATTRIBUTES
#======================================================================

has 'xml_before'  => (is => 'ro', isa => 'Str', required => 1);
has 'code'        => (is => 'rw', isa => 'Str', required => 1);
has 'result'      => (is => 'rw', isa => 'Str', required => 1);
has 'status'      => (is => 'rw', isa => enum([qw/begin separate end/]), default => "end");
has 'type'        => (is => 'ro', isa => 'Str', builder => '_type', lazy => 1);

#======================================================================
# METHODS
#======================================================================

sub _type {
  my ($self) = @_;

  my ($type) = $self->code =~ /^\s*(\w+)/; 
  $type    //= "";
  return uc($type);
}


sub append_to_code {
  my ($self, $more_code) = @_;
  $self->{code} .= $more_code;
}

sub append_to_result {
  my ($self, $more_result) = @_;
  $self->{result} .= $more_result;
}

1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon::Field - internal representation for a MsWord field

=head1 DESCRIPTION

This is used internally by L<MsOffice::Word::Surgeon> for storing
a MsWord field.


=head1 METHODS

=head2 new

  my $field = MsOffice::Word::Surgeon::Field(
    xml_before  => $xml_string,
    code        => $code_instruction_string,
    result      => $xml_fragment,
    status      => 'begin',
  );

Constructor for a new field object. Arguments are :

=over

=item xml_before

A string containing arbitrary XML preceding that field in the complete document.
The string may be empty but must be present.

=item code

A code containing the instruction string for that field.
If the instruction string contains embedded fields, these are represented through
the L<MsOffice::Word::Surgeon/show_embedded_field> syntax -- by default, just a pair of curly braces.

=item result

An XML fragment corresponding to the last update of that field in MsWord.

=item status

One of C<begin>, C<separate>, or C<end>.

Status C<begin> or C<separate> are intermediate, used internally during the parsing process. Normally all
fields are in C<end> status.

=back


=head2 add_to_code

While parsing fields, additional field instruction fragments are added through this method

=head2 add_to_result

While parsing fields, additional XML fragments belonging to the field result are added through this method

=head2 type

The first instruction in the C<code> part, eg C<REF>, C<QUOTE>, C<ASK>, C<DOCPROPERTY>, etc.
Note : in the Microsoft Word Object Model, the L<https://learn.microsoft.com/en-us/office/vba/api/word.field.type|Field.Type> attribute
is an integer value in an enumerated type. Here the attribute is just an uppercase string. Lists of valild field types
can be found in the Word documentation.



=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 by Laurent Dami.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
