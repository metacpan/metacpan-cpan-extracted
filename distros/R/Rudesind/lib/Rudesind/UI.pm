package Rudesind::UI;

use strict;

use Text::WikiFormat ();

use Rudesind::Config;
use Rudesind::Gallery;
use Rudesind::Image;


sub text_to_html
{
    return Text::WikiFormat::format( $_[0],
                                     {},
                                     { implicit_links => 0,
                                       absolute_links => 1,
                                       extended => 1,
                                     },
                                   );
}

sub new_from_path
{
    my $path = shift;
    my $config = shift;

    my $re = Rudesind::Image->image_extension_re;

    if ( $path =~ s/\.html$// || $path =~ /$re/ )
    {
        my ( $dir_path, $file ) = $path =~ m{(.+?)/([^/]+$)};

        $dir_path ||= '/';
        $file ||= $path;

        my $dir = Rudesind::Gallery->new( path => $dir_path, config => $config );

        return unless $dir;

        return ( $dir, $dir->image($file) );
    }
    else
    {
        return ( Rudesind::Gallery->new( path => $path, config => $config ) );
    }
}


1;

__END__

=pod

=head1 NAME

Rudesind::UI - Functions used by the Rudesind UI

=head1 SYNOPSIS

  my ( $gallery, $image ) = Rudesind::UI::new_from_path( $path );

  my $html = Rudesind::UI::text_to_html( $image->caption );

=head1 DESCRIPTION

This module contains a few functions needed for Rudesind's Mason UI.

=head1 FUNCTIONS

Currently, this module provides two functions:

=over 4

=item * new_from_path($path)

Given a path based on the current URI, this function determines
whether this path is for an image or gallery.

If it is for a gallery, it returns a list consisting of a single
C<Rudesind::Gallery> object.  If it is for an image, it returns a list
consisting of a C<Rudesind::Gallery> and C<Rudesind::Image> object.

=item * text_to_html($text)

Given a piece of text (a gallery or image caption), this method
formats that text as HTML using C<Text::WikiFormat>, and returns the
HTML.

=back

=cut
