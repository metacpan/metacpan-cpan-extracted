package Rose::HTML::Image;

use strict;

use Image::Size;

use base 'Rose::HTML::Object';

our $DOC_ROOT;

our $VERSION = '0.606';

__PACKAGE__->add_required_html_attrs(
{
  'alt',  => '',
  'src',  => '',
});


__PACKAGE__->add_valid_html_attrs
(
  'src',      # %URI;      #REQUIRED -- URI of image to embed --
  'alt',      # %Text;     #REQUIRED -- short description --
  'longdesc', # %URI;      #IMPLIED  -- link to long description --
  'name',     # CDATA      #IMPLIED  -- name of image for scripting --
  'height',   # %Length;   #IMPLIED  -- override height --
  'width',    # %Length;   #IMPLIED  -- override width --
  'usemap',   # %URI;      #IMPLIED  -- use client-side image map --
  'ismap',    # (ismap)    #IMPLIED  -- use server-side image map --
);

__PACKAGE__->add_boolean_html_attrs
(
  'ismap',
);

sub is_self_closing { 1 }

sub element       { 'img' }
sub html_element  { 'img' }
sub xhtml_element { 'img' }

QUIET:
{
  no warnings 'uninitialized';
  use constant MOD_PERL_1 => ($ENV{'MOD_PERL'} && !$ENV{'MOD_PERL_API_VERSION'})     ? 1 : 0;
  use constant MOD_PERL_2 => ($ENV{'MOD_PERL'} && $ENV{'MOD_PERL_API_VERSION'} == 2) ? 1 : 0;

  use constant TRY_MOD_PERL_2 => eval { require Apache2::RequestUtil } && !$@ ? 1 : 0;
}

sub init_document_root 
{
  if(MOD_PERL_1)
  {
    return Apache->request->document_root;
  }

  if(TRY_MOD_PERL_2)
  {
    my $r;

    TRY:
    {
      local $@;
      eval { $r = Apache2::RequestUtil->request };
    }

    if($r)
    {
      return $r->document_root;
    }
  }

  return $DOC_ROOT || '';
}

sub src
{
  my($self) = shift;
  my $src = $self->html_attr('src', @_);
  $self->_new_src_or_document_root($src)  if(@_);
  return $src;
}

sub path
{
  my($self) = shift;
  return $self->{'path'}  unless(@_);
  $self->_new_path($self->{'path'} = shift);
  return $self->{'path'};
}

sub document_root
{
  my($self) = shift;

  if(@_)
  {
    $self->{'document_root'} = shift;
    $self->_new_src_or_document_root($self->src);
    return $self->{'document_root'};
  }

  $self->{'document_root'} = $self->init_document_root
    unless(defined  $self->{'document_root'});

  return $self->{'document_root'};
}

sub _new_src_or_document_root
{
  my($self, $src) = @_;

  if(-e $src)
  {
    $self->{'path'} = $src;
  }
  else
  {
    $self->{'path'} = $self->document_root . $src;
  }

  $self->init_size($self->{'path'});
}

sub _new_path
{
  my($self, $path) = @_;

  unless($self->{'document_root'})
  {
    $self->init_size;
    return;
  }

  my $src = $path;

  $src =~ s/^$self->{'document_root'}//;

  $self->html_attr('src' => $src);

  $self->init_size;
}

sub init_size
{
  my($self, $path) = @_;

  $path ||= $self->{'path'} || return;

  my($w, $h) = Image::Size::imgsize($path);

  $self->html_attr(width  => $w);
  $self->html_attr(height => $h);
}

1;

__END__

=head1 NAME

Rose::HTML::Image - Object representation of the "img" HTML tag.

=head1 SYNOPSIS

    $img = Rose::HTML::Image->new(src => '/logo.png',
                                  alt => 'Logo');

    $img->document_root('/var/web/htdocs');

    # <img alt="Logo" height="48" src="/logo.png" width="72">
    print $img->html;

    $img->alt(undef);

    # <img alt="" height="48" src="/logo.png" width="72" />
    print $img->xhtml;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Image> is an object representation of the E<lt>imgE<gt> HTML tag. It includes the ability to automatically fill in the "width" and "height" HTML attributes with the correct values, provided it is given enough information to find the actual image file on disk.  The L<Image::Size> module is used to read the file and determine the correct dimensions.

This class inherits from, and follows the conventions of, L<Rose::HTML::Object>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Object> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    alt
    class
    dir
    height
    id
    ismap
    lang
    longdesc
    name
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
    src
    style
    title
    usemap
    width
    xml:lang

Required attributes:

    alt
    src

Boolean attributes:

    ismap

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Image> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<document_root [PATH]>

Get or set the web site document root.  This is combined with the value of the "src" HTML attribute to build the path to the actual image file on disk.

If running in a mod_perl 1.x environment, the document root defaults to the value returned by:

    Apache->request->document_root

If running in a mod_perl 2.x environment, the document root defaults to the value returned by:

    Apache2::RequestUtil->request->document_root

Note that you must have the C<GlobalRequest> option set for this to work.  If you do not, the document root defaults to undef.

These calls are made once for each L<Rose::HTML::Image> object that needs to use the document root.

=item B<init_size [PATH]>

Try to set the "width" and "height" HTML attributes but using L<Image::Size> to read the image file on disk.  If a PATH argument is passed, the image file is read at that location.  Otherwise, if the L<path()|/path> attribute is set, that path is used.  Failing that, the width and height HTML attributes are simply not modified.

=item B<path [PATH]>

Get or set the path to the image file on disk.

If a PATH argument is passed and L<document_root()|/document_root> is defined, then PATH has L<document_root()|/document_root> removed from the front of it (substitution anchored at the start of PATH) and the resulting string is set as the value of the "src" HTML attribute.  Regardless of the value of L<document_root()|/document_root>, L<init_size()|/init_size> is called in an attempt to set the "height" and "width" HTML attributes.

The current value of the C<path> object attribute is returned.

=item B<src [SRC]>

Get or set the value of the "src" HTML attribute.

If a SRC argument is passed and a file is found at the path specified by SRC, then L<path()|/path> is set to SRC.  Otherwise, L<path()|/path> is set to the concatenation of L<document_root()|/document_root> and SRC.  In either case, L<init_size()|/init_size> is called in an attempt to set the "height" and "width" HTML attributes.

The current value of the "src" HTML attribute is returned.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
