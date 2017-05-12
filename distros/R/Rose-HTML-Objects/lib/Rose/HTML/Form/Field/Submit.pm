package Rose::HTML::Form::Field::Submit;

use strict;

use Carp();

use base 'Rose::HTML::Form::Field::Input';

use Rose::Object::MakeMethods::Generic
(
  'boolean' => 'was_submitted',
);

use Rose::HTML::Object::MakeMethods::Localization
(
  localized_message =>
  [
    qw(_value)
  ],
);

__PACKAGE__->add_required_html_attrs(
{
  type  => 'submit',
  name  => '',
});

our $VERSION = '0.616';

sub is_button { 1 }
sub is_empty { 1 }

sub hidden_fields      { (wantarray) ? () : [] }
sub html_hidden_fields { (wantarray) ? () : [] }

*xhtml_hidden_fields = \&html_hidden_fields;

sub clear { shift->was_submitted(0) }
sub reset { shift->was_submitted(0) }

sub image_html  { shift->__image_html(0, @_) }
sub image_xhtml { shift->__image_html(1, @_) }

sub __image_html
{
  my($self, $xhtml, %args) = @_;

  $args{'type'} = 'image';

  my %old;

  while(my($k, $v) = each(%args))
  {
    if($self->html_attr_exists($k))
    {
      $old{$k} = $self->html_attr($k);
    }

    $self->html_attr($k => $v);
  }

  Carp::croak("Missing src attribute")  unless(length $self->html_attr('src'));

  my $ret = $xhtml ? $self->xhtml : $self->html;

  # Back out changes
  foreach my $attr (keys %args)
  {
    if(exists $old{$attr})
    {
      $self->html_attr($attr => $old{$attr});
    }
    else
    {
      $self->delete_html_attr($attr);
    }
  }

  return $ret;
}

sub value_message_id
{
  my($self) = shift;

  if(@_)
  {
    $self->_value_message_id(@_);
    return $self->html_attr(value => $self->_value);
  }

  return $self->_value_message_id;
}

*value_id = \&value_message_id;

sub value
{
  my($self) = shift;

  if(@_)
  {
    my $value = $self->_value(@_);
    return $self->SUPER::value($value);
  }

  my $value = $self->html_attr('value');

  unless(defined $value)
  {
    return $self->html_attr(value => $self->_value);
  }

  return $value;
}

sub input_value
{
  my ($self, $value) = @_;
  no warnings 'uninitialized';
  $self->was_submitted($value eq $self->value);
}

sub internal_value
{
  my ($self) = shift;
  return $self->value  if($self->was_submitted);
  return undef;
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::Submit - Object representation of a submit button in an HTML form.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Submit->new(name  => 'run',
                                           value => 'Do it!');

    print $field->html;

    # or...

    print $field->image_html(src => 'images/run_button.gif');

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Submit> is an object representation of a submit button in an HTML form.

This class inherits from, and follows the conventions of, L<Rose::HTML::Form::Field>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form::Field> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    accept
    accesskey
    alt
    checked
    class
    dir
    disabled
    id
    ismap
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
    src
    style
    tabindex
    title
    type
    usemap
    value
    xml:lang

Required attributes (default values in parentheses):

    name
    type (submit)

Boolean attributes:

    checked
    disabled
    ismap
    readonly

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::Submit> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<image_html [ARGS]>

Returns the HTML serialization of the submit button using an image instead of a standard button widget (in other words, type="image").   ARGS is a list of HTML attribute name/value pairs which are temporarily set, then backed out before the method returns.  (The type="image" change is also backed out.)

The "src" HTML attribute must be set (either in ARGS or from an existing value for that attribute) or a fatal error will occur.

=item B<image_xhtml [ARGS]>

Like L<image_html()|/image_html>, but serialized to XHTML instead.

=item B<is_empty>

Returns true.

=item B<value [VALUE]>

Gets or sets the value of the "value" HTML attribute.

=item B<was_submitted>

Returns true if this submit button was pressed, false otherwise.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
