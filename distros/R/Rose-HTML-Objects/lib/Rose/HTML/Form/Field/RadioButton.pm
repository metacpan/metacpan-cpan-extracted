package Rose::HTML::Form::Field::RadioButton;

use strict;

use base 'Rose::HTML::Form::Field::OnOff::Checkable';

our $VERSION = '0.606';

__PACKAGE__->delete_valid_html_attrs(qw(ismap usemap alt src));
__PACKAGE__->required_html_attr_value(type => 'radio');

sub html_radio_button
{
  my($self) = shift;
  $self->html_attr(checked => $self->checked);
  return $self->SUPER::html_field(@_);
}

sub xhtml_radio_button
{
  my($self) = shift;
  $self->html_attr(checked => $self->checked);
  return $self->SUPER::xhtml_field(@_);
}

sub html_field
{
  my($self) = shift;

  return ($self->html_prefix || '') .
         $self->html_radio_button . ' ' . $self->html_label .
         ($self->html_suffix || '');
}

sub xhtml_field
{
  my($self) = shift;  
  return ($self->html_prefix || '') .
         $self->xhtml_radio_button . ' ' . $self->html_label .
         ($self->html_suffix || '');
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::RadioButton - Object representation of a single radio button field in an HTML form.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::RadioButton->new(
        label => 'Run tests', 
        name  => 'tests',  
        value => 'yes');

    $checked = $field->is_checked; # false

    $field->checked(1);

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::RadioButton> is an object representation of a single radio button field in an HTML form.

This class inherits from, and follows the conventions of, L<Rose::HTML::Form::Field>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form::Field> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    accept
    accesskey
    checked
    class
    dir
    disabled
    id
    lang
    maxlength
    name
    onblur
    onchange
    onclick
    ondblclick
    onfocus
    onkeydown
    onkeypress
    onkeyup
    onmousedown
    onmousemove
    onmouseout
    onmouseover
    onmouseup
    onselect
    readonly
    size
    style
    tabindex
    title
    type
    value
    xml:lang

Required attributes (default values in parentheses):

    type (radio)
    value

Boolean attributes:

    checked
    disabled
    readonly

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::RadioButton> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<checked [BOOL]>

Check or uncheck the radio button by passing a boolean value.  If BOOL is true, the radio button will be checked. If it is false, it will be unchecked. Returns true if the radio button is checked, false otherwise.

=item B<hidden [BOOL]>

Get or set a boolean value that indicates whether or not this radio button will be shown in its parent L<radio button group|Rose::HTML::Form::Field::RadioButtonGroup>.  Setting it to true also sets L<checked|/checked> to false.

=item B<hide>

Calls L<hidden|/hidden>, passing a true value.

=item B<html_radio_button>

Returns the HTML serialization of the radio button field only (i.e., without any label or error message)

=item B<is_checked>

Returns true if the radio button is checked, false otherwise.

=item B<is_on>

Simply calls L<is_checked()|/is_checked>.  This method exists for API uniformity between radio buttons and checkboxes.

=item B<show>

Calls L<hidden|/hidden>, passing a false value.

=item B<value [VALUE]>

Gets or sets the value of the "value" HTML attribute.

=item B<xhtml_radio_button>

Returns the XHTML serialization of the radio button field only (i.e., without any label or error message)

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
