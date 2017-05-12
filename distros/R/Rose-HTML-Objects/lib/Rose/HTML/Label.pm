package Rose::HTML::Label;

use strict;

use Rose::HTML::Text;

use base 'Rose::HTML::Object';

our $VERSION = '0.606';

__PACKAGE__->add_valid_html_attrs
(
  'for',         # IDREF          #IMPLIED  -- matches field ID value --
  'accesskey',   # %Character;    #IMPLIED  -- accessibility key character --
  'onfocus',     # %Script;       #IMPLIED  -- the element got the focus --
  'onblur',      # %Script;       #IMPLIED  -- the element lost the focus --
);

sub element       { 'label' }
sub html_element  { 'label' }
sub xhtml_element { 'label' }

sub contents
{
  my($self) = shift; 
  $self->children(map { UNIVERSAL::isa($_, 'Rose::HTML::Object') ? $_ : 
                        Rose::HTML::Text->new(html => $_) } @_)  if(@_);
  return join('', map { $_->html } $self->children)
}

1;

__END__

=head1 NAME

Rose::HTML::Label - Object representation of the "label" HTML tag.

=head1 SYNOPSIS

    my $label = Rose::HTML::Label->new(for      => 'name',
                                       contents => 'Name');

    # <label for="name">Name</label>
    print $i->html;

    $i->accesskey('n');

    # <label accesskey="n" for="name">Name</label>
    print $i->xhtml;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Label> is an object representation of the E<lt>labelE<gt> HTML tag.  Yes, there really is a E<lt>labelE<gt> tag in both HTML 4.01 and XHTML 1.0.  Look it up.

This class inherits from, and follows the conventions of, L<Rose::HTML::Object>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Object> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    accesskey
    class
    dir
    for
    id
    lang
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
    style
    title
    xml:lang

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
