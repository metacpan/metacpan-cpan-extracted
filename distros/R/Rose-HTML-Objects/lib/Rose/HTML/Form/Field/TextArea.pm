package Rose::HTML::Form::Field::TextArea;

use strict;

use Carp();

use Rose::HTML::Object::Errors qw(:string);

use base 'Rose::HTML::Form::Field';

our $VERSION = '0.606';

use Rose::Object::MakeMethods::Generic
(
  scalar => 'maxlength',
);

__PACKAGE__->add_valid_html_attrs
(
  'rows',        # NUMBER         #REQUIRED
  'cols',        # NUMBER         #REQUIRED
  'disabled',    # (disabled)     #IMPLIED  -- unavailable in this context --
  'readonly',    # (readonly)     #IMPLIED
  'onselect',    # %Script;       #IMPLIED  -- some text was selected --
  'onchange',    # %Script;       #IMPLIED  -- the element value was changed --
);

__PACKAGE__->add_required_html_attrs(
{
  rows  => 6,
  cols  => 50,
});

__PACKAGE__->add_boolean_html_attrs
(
  'disabled',
  'readonly',
);

sub element       { 'textarea' }
sub html_element  { 'textarea' }
sub xhtml_element { 'textarea' }

sub value { shift->input_value(@_) }

sub contents
{
  my($self) = shift;
  return $self->input_value(@_)  if(@_);
  return $self->output_value;
}

sub input_value
{
  my($self) = shift;

  if(@_)
  {
    $self->SUPER::input_value(@_);
    $self->children(defined $_[0] ? $self->output_value : '');
  }

  # XXX: Intentional double set in order to maintain error()
  # XXX: produced by a possible call to inflate_value()
  return $self->SUPER::input_value(@_);
}

sub clear
{
  my($self) = shift;
  $self->delete_children;
  return $self->SUPER::clear(@_);
}

sub reset
{
  my($self) = shift;
  $self->SUPER::reset(@_);
  $self->children($self->output_value);
}

sub size
{
  my($self) = shift;

  if(@_)
  {
    local $_ = shift;

    if(my($cols, $rows) = /^(\d+)x(\d+)$/)
    {
      $self->cols($cols);
      $self->rows($rows);
      return $cols . 'x' . $rows;
    }
    else
    {
      Carp::croak "Invalid size argument '$_' is not in the form COLSxROWS";
    }
  }

  return $self->cols . 'x' . $self->rows;
}

sub validate
{
  my($self) = shift;

  my $ok = $self->SUPER::validate(@_);
  return $ok  unless($ok);

  my $value = $self->input_value;
  return 1  unless(defined $value && length $value);

  my $maxlength = $self->maxlength;

  my $name = sub { $self->label || $self->name };

  if(defined $maxlength && length($value) > $maxlength)
  {
    $self->add_error_id(STRING_OVERFLOW, { label => $name, maxlength => $maxlength });
    return 0;
  }

  return 1;
}
1;

__END__

=head1 NAME

Rose::HTML::Form::Field::TextArea - Object representation of a multi-line text field in an HTML form.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::TextArea->new(
        label => 'Comments', 
        name  => 'comments',
        rows  => 2,
        cols  => 50);

    $comments = $field->internal_value;

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::TextArea> is an object representation of a multi-line text field in an HTML form.

This class inherits from, and follows the conventions of, L<Rose::HTML::Form::Field>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form::Field> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    accesskey
    class
    cols
    dir
    disabled
    id
    lang
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
    rows
    style
    tabindex
    title
    value
    xml:lang

Required attributes (default values in parentheses):

    cols (50)
    rows (6)

Boolean attributes:

    checked
    disabled
    readonly

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::TextArea> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<contents [TEXT]>

Get or set the contents of the text area.  If a TEXT argument is present, it is passed to L<input_value()|Rose::HTML::Form::Field/input_value> and the return value of that method call is then returned.  Otherwise, L<output_value()|Rose::HTML::Form::Field/output_value> is called with no arguments.

=item B<maxlength [INT]>

Get or set the maximum length of the input value.  Note that this is not an HTML attribute; this limit is enforced by the L<validate|Rose::HTML::Form::Field/validate> method, not by the web browser.

=item B<size [COLSxROWS]>

Get or set the number of columns and rows (C<cols> and C<rows>) in the text area in the form of a string "COLSxROWS".  For example, "40x3" means 40 columns and 3 rows.  If the size argument is not in the correct format, a fatal error will occur.

=item B<value [TEXT]>

Simply calls L<input_value|Rose::HTML::Form::Field/input_value>, passing all arguments.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
