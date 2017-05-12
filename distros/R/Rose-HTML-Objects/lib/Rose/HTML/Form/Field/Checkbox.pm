package Rose::HTML::Form::Field::Checkbox;

use strict;

use base 'Rose::HTML::Form::Field::OnOff::Checkable';

our $VERSION = '0.617';

__PACKAGE__->delete_valid_html_attrs(qw(ismap usemap alt src));
__PACKAGE__->required_html_attr_value(type => 'checkbox');

sub html_checkbox
{
  my($self) = shift;
  $self->html_attr(checked => $self->checked);
  return $self->SUPER::html_field(@_);
}

sub xhtml_checkbox
{
  my($self) = shift;
  $self->html_attr(checked => $self->checked);
  return $self->SUPER::xhtml_field(@_);
}

sub html_field
{
  my($self) = shift;

  return ($self->html_prefix || '') .
         $self->html_checkbox . ' ' . $self->html_label .
         ($self->html_suffix || '');
}

sub xhtml_field
{
  my($self) = shift;  
  return ($self->html_prefix || '') .
         $self->xhtml_checkbox . ' ' . $self->html_label .
         ($self->html_suffix || '');
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::Checkbox - Object representation of a single checkbox field in an HTML form.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Checkbox->new(
        label => 'Run tests', 
        name  => 'tests',  
        value => 'yes');

    $checked = $field->is_checked; # false

    $field->checked(1);

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Checkbox> is an object representation of a single checkbox field in an HTML form.

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

    type (checkbox)
    value

Boolean attributes:

    checked
    disabled
    readonly

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::Checkbox> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<checked [BOOL]>

Check or uncheck the checkbox by passing a boolean value.  If BOOL is true, the checkbox will be checked. If it is false, it will be unchecked. Returns true if the checkbox is checked, false otherwise.

=item B<hidden [BOOL]>

Get or set a boolean value that indicates whether or not this checkbox will be shown in its parent L<checkbox group|Rose::HTML::Form::Field::CheckboxGroup>.  Setting it to true also sets L<checked|/checked> to false.

=item B<hide>

Calls L<hidden|/hidden>, passing a true value.

=item B<html_checkbox>

Returns the HTML serialization of the checkbox field only (i.e., without any label or error message)

=item B<is_checked>

Returns true if the checkbox is checked, false otherwise.

=item B<is_on>

Simply calls L<is_checked|/is_checked>.  This method exists for API uniformity between radio buttons and checkboxes.

=item B<show>

Calls L<hidden|/hidden>, passing a false value.

=item B<value [VALUE]>

Gets or sets the value of the "value" HTML attribute.

=item B<xhtml_checkbox>

Returns the XHTML serialization of the checkbox field only (i.e., without any label or error message)

=item B<label_object>

Returns the object representing the L<label|Rose::HTML::Label> for the checkbox.

Example:

  $field =
    Rose::HTML::Form::Field::Checkbox->new(
      label => 'Run tests',
      name  => 'tests',
      value => 'yes');

  $field->label_object->add_class('checkbox_label');

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
