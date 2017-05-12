package Rose::HTML::Anchor;

use strict;

use base 'Rose::HTML::Object';

our $VERSION = '0.606';

__PACKAGE__->add_valid_html_attrs
(
  'charset',   # %Charset;      #IMPLIED  -- char encoding of linked resource
  'type',      # %ContentType;  #IMPLIED  -- advisory content type
  'name',      # CDATA          #IMPLIED  -- named link end
  'href',      # %URI;          #IMPLIED  -- URI for linked resource
  'hreflang',  # %LanguageCode; #IMPLIED  -- language code
  'rel',       # %LinkTypes;    #IMPLIED  -- forward link types
  'rev',       # %LinkTypes;    #IMPLIED  -- reverse link types
  'accesskey', # %Character;    #IMPLIED  -- accessibility key character
  'shape',     # %Shape;        rect      -- for use with client-side image maps
  'coords',    # %Coords;       #IMPLIED  -- for use with client-side image maps
  'tabindex',  # NUMBER         #IMPLIED  -- position in tabbing order
  'onfocus',   # %Script;       #IMPLIED  -- the element got the focus
  'onblur',    # %Script;       #IMPLIED  -- the element lost the focus
);

sub href  { shift->html_attr('href', @_) }
sub name  { shift->html_attr('name', @_) }
sub title { shift->html_attr('title', @_) }

sub element       { 'a' }
sub html_element  { 'a' }
sub xhtml_element { 'a' }

sub link     { shift->children(@_) }
sub contents { shift->children(@_) }

1;

__END__

=head1 NAME

Rose::HTML::Anchor - Object representation of an HTML anchor.

=head1 SYNOPSIS

    $a = Rose::HTML::Anchor->new(href => 'apple.html', link => 'Apple');

    print $a->html;

    $a->link(Rose::HTML::Image->new(src => 'a.gif'));

    print $a->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Anchor> is an object representation of an HTML anchor, or "a" tag.

This class inherits from, and follows the conventions of, L<Rose::HTML::Object>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Object> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    accesskey
    charset
    class
    coords
    dir
    href
    hreflang
    id
    lang
    name
    onblur
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
    rel
    rev
    shape
    style
    tabindex
    title
    type
    xml:lang

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Anchor> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<link [ARGS]>

This is an alias for the L<children|Rose::HTML::Object/children> method.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
