package Rose::HTML::Link;

use strict;

use base 'Rose::HTML::Object';

our $VERSION = '0.606';

__PACKAGE__->add_valid_html_attrs
(
  'charset',  # %Charset;      #IMPLIED  -- char encoding of linked resource
  'href',     # %URI;          #IMPLIED  -- URI for linked resource
  'hreflang', # %LanguageCode; #IMPLIED  -- language code
  'type',     # %ContentType;  #IMPLIED  -- advisory content type
  'rel',      # %LinkTypes;    #IMPLIED  -- forward link types
  'rev',      # %LinkTypes;    #IMPLIED  -- reverse link types
  'media',    # %MediaDesc;    #IMPLIED  -- for rendering on these media
);

sub rel  { shift->html_attr('rel', @_) }
sub href { shift->html_attr('href', @_) }

sub element       { 'link' }
sub html_element  { 'link' }
sub xhtml_element { 'link' }

sub is_self_closing { 1 }

1;

__END__

=head1 NAME

Rose::HTML::Link - Object representation of the "link" HTML tag.

=head1 SYNOPSIS

    $link = 
      Rose::HTML::Link->new(
        rel  => 'stylesheet', 
        href => '/style/main.css');

    print $link->html;
    print $link->xhtml;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Link> is an object representation of a "link" HTML tag used to reference another document (e.g., a CSS stylesheet).

This class inherits from, and follows the conventions of, L<Rose::HTML::Object>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Object> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    charset
    class
    dir
    href
    hreflang
    id
    lang
    media
    onclick
    ondblclick
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
    style
    title
    type
    xml:lang

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
