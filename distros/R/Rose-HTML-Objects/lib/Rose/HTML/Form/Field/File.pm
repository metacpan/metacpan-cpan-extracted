package Rose::HTML::Form::Field::File;

use strict;

use base 'Rose::HTML::Form::Field::Text';

our $VERSION = '0.606';

__PACKAGE__->required_html_attr_value(type => 'file');
__PACKAGE__->delete_valid_html_attrs(qw(ismap usemap alt src));

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::File - Object representation of a file upload field in an HTML form.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::File->new(
        label => 'File', 
        name  => 'file',
        size  => 32);

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::File> is an object representation of a file upload field in an HTML form.

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
    size
    type (file)
    value

Boolean attributes:

    checked
    disabled
    readonly
    required

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::File> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
