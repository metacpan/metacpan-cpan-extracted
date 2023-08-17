package Rose::HTML::Form::Field::Password;

use strict;

use base 'Rose::HTML::Form::Field::Text';

our $VERSION = '0.606';

__PACKAGE__->add_required_html_attrs(
{
  type  => 'password',
  name  => '',
  size  => 15,
  value => '',
});

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::Password - Object representation of a password field in an HTML form.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Password->new(
        label     => 'Your Password', 
        name      => 'password',
        size      => 16,
        maxlength => 64);

    $pw = $field->internal_value;

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Password> is an object representation of a password field in an HTML form.

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

    name
    size  (15)
    type  (password)
    value

Boolean attributes:

    checked
    disabled
    readonly
    required

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::Password> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
