package Rose::HTML::Form::Field::Hidden;

use strict;

use base 'Rose::HTML::Form::Field::Input';

our $VERSION = '0.616';

__PACKAGE__->delete_valid_html_attrs(qw(disabled ismap usemap alt src tabindex
checked maxlength onblur onchange onclick ondblclick onfocus onkeydown
onkeypress onkeyup onmousedown onmousemove onmouseout onmouseover onmouseup
onselect readonly size title accesskey));

__PACKAGE__->add_required_html_attrs('value');
__PACKAGE__->required_html_attr_value(type => 'hidden');

sub hidden_fields       { (wantarray) ? shift : [ shift ] }
sub html_hidden_fields  { (wantarray) ? shift->html_field : [ shift->html_field ] }
sub xhtml_hidden_fields { (wantarray) ? shift->xhtml_field : [ shift->xhtml_field ] }

sub error      {   }
sub errors     {   }
sub has_error  { 0 }
sub has_errors { 0 }
sub validate   { 1 }

sub html_field
{
  my($self) = shift;
  $self->html_attr(value => $self->output_value);
  return $self->SUPER::html_field(@_);
}

sub xhtml_field
{
  my($self) = shift;
  $self->html_attr(value => $self->output_value);
  return $self->SUPER::xhtml_field(@_);
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::Hidden - Object representation of a hidden field in an HTML form.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Hidden->new(
        name    => 'code',  
        default => '1234');

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Hidden> is an object representation of a hidden field in an HTML form.

This class inherits from, and follows the conventions of, L<Rose::HTML::Form::Field>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form::Field> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    accept
    class
    dir
    id
    lang
    name
    style
    type
    value
    xml:lang

Required attributes (default values in parentheses):

    type (hidden)
    value

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::Hidden> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<error>

This method is a no-op.

=item B<has_error>

Returns false.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
