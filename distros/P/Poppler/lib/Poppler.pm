package Poppler;

our $VERSION = "1.0101";
$VERSION = eval $VERSION;

=encoding utf8

=head1 NAME

Poppler - Bindings to the poppler PDF rendering library

=head1 SYNOPSIS

  use Poppler;

  # initialize using filename 
  my $pdf = Poppler::Document->new_from_file( 'file.pdf' );

  # or, initialize using scalar data
  open my $fh, '<:raw', 'file.pdf';
  read ($fh, my $data, -s 'file.pdf')
  close $fh;
  my $pdf = Poppler::Document->new_from_data( $data );

  # get some general info
  my $n_pages = $pdf->get_n_pages;
  my $title   = $pdf->get_title; 
  # etc ...

  # get the first page
  my $page = $pdf->get_page( 0 );

  # get page size
  my ($w, $h)  = $page->get_size;

  # or, for backward compatibility
  my $dims = $page->get_size; # a Poppler::Dimension object
  my $w = $dims->get_width;
  my $h = $dims->get_height;

  # do other fancy things (get page links, annotations, movies, etc)
  # (see poppler-glib documentation for details)

  # render to a Cairo surface
  use Cairo;
  my $surface = Cairo::ImageSurface->create( 'argb32', 100, 100 );
  my $cr = Cairo::Context->create( $surface );
  $page->render_to_cairo( $cr );
  $cr->show_page;

=head1 ABSTRACT

Bindings to the poppler PDF library via the Glib interface. Allows
querying of a PDF file structure and rendering to various output targets.

=head1 DESCRIPTION

The C<Poppler> module provides complete bindings to the poppler PDF library
through the Glib interface. Find out more about poppler at
L<http://poppler.freedesktop.org>.

As of version 1.01, no XS is used directly but bindings are provided using
GObject introspection and the L<Glib::Object::Introspection> module. See the
L<Poppler/SYNOPSIS> for a brief example of how the module can be used. For
detailed documentation on the available classes and methods, see the poppler
glib documentation for the C libraries and the L<Glib::Object::Introspection>
documentation for a description of how methods are mapped between the C
libraries and the Perl namespace.

=head1 CONSTRUCTORS

=over

=item new_from_file ($filename)

Takes a system path or URI to a PDF file as an argument and returns a
Poppler::Document object. The C<poppler-glib> library itself requires a full
URI (e.g. "file:///home/user/file.pdf") but this module attempts to convert
regular system paths if provided via the L<URI> module.

=item new_from_data ($data)

Takes a PDF data chunk as an argument and returns a Poppler::Document object.

=back

=head1 METHODS

For details on the classes and methods available beyond the constructors
listed above, please refer to the canonical documentation for the C library
listed under L<Poppler/SEE ALSO>. A general discussion of how these classes
and methods map to the Perl equivalents can be found in the
L<Glib::Object::Introspection> documentation. Generally speaking, a C function
such as 'poppler_document_get_title' would map to
'Poppler::Document->get_title'.

=cut

use strict;
use warnings;
use Carp qw/croak/;
use Cwd qw/abs_path/;
use Exporter;
use File::ShareDir;
use Glib::Object::Introspection;
use URI::file;
use FindBin;
use Poppler::Page::Dimension;

our @ISA = qw(Exporter);

my $_POPPLER_BASENAME = 'Poppler';
my $_POPPLER_VERSION  = '0.18';
my $_POPPLER_PACKAGE  = 'Poppler';

=head2 Customizations and overrides

In order to make things more Perlish, C<Poppler> customizes the API generated
by L<Glib::Object::Introspection> in a few spots:

=over

=cut

# - Customizations ---------------------------------------------------------- #

=item * The array ref normally returned by the following functions is flattened
into a list:

=over

=item Poppler::Document::get_attachments

=item Poppler::Page::get_link_mapping

=item Poppler::Page::find_text

=item Poppler::Page::find_text_with_options

=item Poppler::Page::get_annot_mapping

=item Poppler::Page::get_form_field_mapping

=item Poppler::Page::get_image_mapping

=item Poppler::Page::get_link_mapping

=item Poppler::Page::get_selection_region

=item Poppler::Page::get_text_attributes

=item Poppler::Page::get_text_attributes_for_area

=back

=cut

my @_POPPLER_FLATTEN_ARRAY_REF_RETURN_FOR = qw/
  Poppler::Document::get_attachments
  Poppler::Page::get_link_mapping
  Poppler::Page::find_text
  Poppler::Page::find_text_with_options
  Poppler::Page::get_annot_mapping
  Poppler::Page::get_form_field_mapping
  Poppler::Page::get_image_mapping
  Poppler::Page::get_link_mapping
  Poppler::Page::get_selection_region
  Poppler::Page::get_text_attributes
  Poppler::Page::get_text_attributes_for_area
/;

=item * The following functions normally return a boolean and additional out
arguments, where the boolean indicates whether the out arguments are valid.
They are altered such that when the boolean is true, only the additional out
arguments are returned, and when the boolean is false, an empty list is
returned.

=over

=item Poppler::Document::get_id

=item Poppler::Page::get_text_layout

=item Poppler::Page::get_text_layout_for_area

=item Poppler::Page::get_thumbnail_size

=back

=cut

my @_POPPLER_HANDLE_SENTINEL_BOOLEAN_FOR = qw/
  Poppler::Document::get_id
  Poppler::Page::get_text_layout
  Poppler::Page::get_text_layout_for_area
  Poppler::Page::get_thumbnail_size
/;


# - Wiring ------------------------------------------------------------------ #

sub import {

  Glib::Object::Introspection->setup (
    search_path => File::ShareDir::dist_dir('Poppler'),
    basename    => $_POPPLER_BASENAME,
    version     => $_POPPLER_VERSION,
    package     => $_POPPLER_PACKAGE,
    flatten_array_ref_return_for => \@_POPPLER_FLATTEN_ARRAY_REF_RETURN_FOR,
    handle_sentinel_boolean_for => \@_POPPLER_HANDLE_SENTINEL_BOOLEAN_FOR,
  );

  # call into Exporter for the unrecognized arguments; handles exporting and
  # version checking
  Poppler->export_to_level (1, @_);

}

# - Overrides --------------------------------------------------------------- #

=item * Perl reimplementations of C<Poppler::Document::new_from_file>,
C<Poppler::Document::save>, and C<Poppler::Document::save_a_copy>
are provided which remove the need to provide filenames as URIs (e.g.
"file:///absolute/path"). The module accepts either real URIs or regular
system paths and will convert as necessary using the C<URI> module. Any of
these formats should work:

    $p = Poppler::Document->new_from_file( 'file:///home/user/file.pdf' );
    $p = Poppler::Document->new_from_file( '/home/user/file.pdf' );
    $p = Poppler::Document->new_from_file( 'file.pdf' );

    # likewise for save()
    # likewise for save_a_copy()

=cut

sub Poppler::Document::new_from_file {

    my ($class, $fn, $pwd) = @_;

    $fn = URI::file->new_abs($fn) 
        if (! URI->new($fn)->has_recognized_scheme);
    my $doc = Glib::Object::Introspection->invoke(
        'Poppler', 'Document', 'new_from_file', $class, $fn, $pwd);

    return $doc;

}

sub Poppler::Document::save {

    my ($class, $fn) = @_;

    $fn = URI::file->new_abs($fn) 
        if (! URI->new($fn)->has_recognized_scheme);
    my $bool = Glib::Object::Introspection->invoke(
        'Poppler', 'Document', 'save', $class, $fn);

    return $bool;

}

sub Poppler::Document::save_a_copy {

    my ($class, $fn) = @_;

    $fn = URI::file->new_abs($fn) 
        if (! URI->new($fn)->has_recognized_scheme);
    my $bool = Glib::Object::Introspection->invoke(
        'Poppler', 'Document', 'save_a_copy', $class, $fn);

    return $bool;

}

sub Poppler::Page::get_size {

    my ($class) = @_;

    my ($w,$h) = Glib::Object::Introspection->invoke(
        'Poppler', 'Page', 'get_size', $class);
    return Poppler::Page::Dimension->new($w, $h)
        if (! wantarray);
    return($w, $h);

}

=back

=cut

1;

__END__


=head1 SEE ALSO

=over

=item * C library documentation for poppler-glib at
L<http://people.freedesktop.org/~ajohnson/docs/poppler-glib/>.

=item * L<Glib>

=item * L<Glib::Object::Introspection>

=back

=head1 AUTHORS

=over

=item 2009-2016 Cornelius , < cornelius.howl _at_ gmail.com >

=item 2016-present Jeremy Volkening <jdv@base2bio.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2016 by c9s (Cornelius)
Copyright (C) 2016 by Jeremy Volkening

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
