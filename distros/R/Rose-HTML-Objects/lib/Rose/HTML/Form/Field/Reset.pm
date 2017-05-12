package Rose::HTML::Form::Field::Reset;

use strict;

use base 'Rose::HTML::Form::Field::Submit';

__PACKAGE__->required_html_attr_value(type => 'reset');

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::Reset - Object representation of a reset button in an HTML form.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Reset->new(name  => 'reset',
                                          value => 'Reset');

    print $field->html;

    # or...

    print $field->image_html(src => 'images/reset_button.gif');

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Reset> is an object representation of a reset button in an HTML form.

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
    type (reset)

Boolean attributes:

    checked
    disabled
    ismap
    readonly

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::Reset> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<image_html [ARGS]>

Returns the HTML serialization of the reset button using an image instead of a standard button widget (in other words, type="image").   ARGS is a list of HTML attribute name/value pairs which are temporarily set, then backed out before the method returns.  (The type="image" change is also backed out.)

The "src" HTML attribute must be set (either in ARGS or from an existing value for that attribute) or a fatal error will occur.

=item B<image_xhtml [ARGS]>

Like L<image_html()|/image_html>, but serialized to XHTML instead.

=item B<value [VALUE]>

Gets or sets the value of the "value" HTML attribute.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
