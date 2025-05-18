package PDF::API2::Resource::XObject::Image::Imager;

# $Id: Imager.pm 2707 2025-05-17 17:03:41Z fil $

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01';

use PDF::API2::Util;
use PDF::API2::Basic::PDF::Utils;
use Scalar::Util qw(weaken);

use base 'PDF::API2::Resource::XObject::Image';

sub DEBUG () { 0 }

sub new
{
    my( $package, $pdf, $img, $name, %opts ) = @_;
    
    $package = ref $package if ref $package;
    
    $pdf = $pdf->{'pdf'} if $pdf->isa( 'PDF::API2' );

    my $self = $package->SUPER::new( $pdf, $name||'Im'.pdfkey() );
    $pdf->new_obj( $self ) unless $self->is_obj( $pdf );

    $self->{' apipdf'}=$pdf;
    weaken $self->{' apipdf'};

    $self->read_imager( $img, %opts );

    return  $self;
}


sub read_imager
{
    my( $self, $img, %opts ) = @_;

    my $pdf = $self->{' apipdf'};

    my $w = $img->getwidth;
    my $h = $img->getheight;
    my $bpc = $img->bits;
    my $type = $img->type;

    DEBUG and warn "# Type: $type";
    DEBUG and warn "# Bits per pixel: $bpc";
    
    if( $type eq 'paletted' ) {
        # 1-bit image w/o alpha is probably better handled by
        # PDF::API2::Resource::XObject::Image::PNG
        DEBUG and warn "# Convert to rgb8";
        $img = $img->to_rgb8;
        $bpc = $img->bits;
        $type = $img->type;
        DEBUG and warn "# Bits per pixel: $bpc";
    }

    DEBUG and warn "# Width: $w";
    DEBUG and warn "# Height: $h";

    die "Unable to process $bpc bit image" if $bpc != 8;

    $self->width( $w );
    $self->height( $h );
    $self->bpc( $bpc );

    my $ch = $img->getchannels;

    if( $ch == 2 || $ch == 4 ) {        # grey+alpha or RGBA
        DEBUG and warn "# Alpha channel";
        my $alpha = $img->convert( preset=>'alpha' );   # save alpha channels
        $img = $img->convert( preset=>'noalpha' );      # save RGB channels
        $ch--;

        # Add an SMask
        my $mask = PDFDict();
        $pdf->new_obj( $mask );
        $mask->{'Type'}             = PDFName('XObject');
        $mask->{'Subtype'}          = PDFName('Image');
        $mask->{'Width'}            = PDFNum($w);
        $mask->{'Height'}           = PDFNum($h);
        $mask->{'ColorSpace'}       = PDFName('DeviceGray');
        # $mask->{'Filter'}           = PDFArray(PDFName('FlateDecode'));
        $mask->{'BitsPerComponent'} = PDFNum($bpc);
        $self->{'SMask'}            = $mask;

        $self->_read_to( $mask, $alpha );
    }

    my $decode = PDFDict();
    $self->{'DecodeParms'} = PDFArray($decode);
    $decode->{'BitsPerComponent'} = PDFNum($bpc);
    $decode->{'Colors'} = PDFNum( $ch );
    $decode->{'Columns'} = PDFNum( $w );

    # $self->filters('FlateDecode');
    if( $ch == 1 ) {                    # grey
        DEBUG and warn "# Device: Gray";
        $self->colorspace('DeviceGray');
    }
    elsif( $ch == 3 ) {                 # RGB
        DEBUG and warn "# Device: RGB";
        $self->colorspace('DeviceRGB');
    }
    else {
        die "How do I deal with $ch channels?";
    }

    $self->_read_to( $self, $img );

    return $self;
}

sub _read_to
{
    my( $self, $obj, $img ) =  @_;
    # It would be nice to LZW this data 
    # https://www.verypdf.com/document/pdf-format-reference/pg_0072.htm
    my $data;
    $img->write( type=>'raw', data=>\$data ) or die "Unable to create raw: ".$img->errstr;
    if( 0 ) {
        use Compress::LZW::Compressor;
        my $c = Compress::LZW::Compressor->new;
        $obj->{'Filter'} = PDFArray(PDFName('LZWDecode'));
        $obj->{' stream'} = $c->compress( $data );
        # use Data::Dump qw( pp );
        warn pp $c->compress( join '', 0x45, 0x45, 0x45, 0x45, 0x45, 0x65, 0x45, 0x45, 0x45, 0x66 );
    }
    else {
        $obj->{'Filter'} = PDFArray(PDFName('FlateDecode'));
        $obj->{' stream'} = $data;
    }
}

*PDF::API2::imager = sub {
    my( $self, $img, %opts ) = @_;
    my $obj = PDF::API2::Resource::XObject::Image::Imager->new( $self->{'pdf'}, $img, undef, %opts );
    $self->{'pdf'}->out_obj( $self->{'pages'} );
    return $obj;
};


1;
__END__

=head1 NAME

PDF::API2::Resource::XObject::Image::Imager - Import Imager images into PDF

=head1 SYNOPSIS

    use PDF::API2;
    use PDF::API2::Resource::XObject::Image::Imager;
    use Imager;

    # read the image
    my $img = Imager->new;
    $img->read( file=>$file ) or die $img->errstr;

    my $pdf = PDF::API2->new;

    # import the image
    my $xo = $pdf->imager( $img );

    my $page = $pdf->page;
    my $gfx = $page->gfx;

    # place the image on a page
    $gfx->image( $xo, $x, $y, $scale );
    
=head1 DESCRIPTION

This module makes it trivial to import images into your PDF.  It leverages
all the hard image file handling work done by L<Imager>.

L<PDF::API2> is a fine module, if a bit baroque.  One gap is that its
handling of images: PNG import is in pure-Perl and very slow and GD imports
ignore alpha channels.

That said, given that TIFFs and PNGs may be included as-is in PDFs,
PDF::API2's is probably doing things in a better way.

=head2 Optimization

C<PDF::API2::Resource::XObject::Image::Imager> currently only outputs
C<FlatDecode>.  If the size of your PDF is important, you should pass it
through L<GhostScript|https://ghostscript.com/>'s
L<ps2pdf|https://linux.die.net/man/1/ps2pdf>.  

    $pdf->save( "$file.tmp.pdf" );
    system( "ps2pdf $file.tmp.pdf $file" );
    unlink "$file.tmp.pdf";

=head1 METHODS

=head2 imager

    my $xo = $pdf->imager( $img, %opts );

Imports an L<Imager> object into your PDF.  Returns an XObject that may be
place on pages of your PDF.   

Currently no options are defined.  If you want to reproduce
L<PDF::API2/image_png>'s -notrans option, you must strip out the alpha
channel before calling L</imager>.

    my $noalpha = $img->convert( preset=>'noalpha' );
    my $xo = $pdf->imager( $noalpha );

Paletted images are converted to RGB before importing.

Greyscale images are left as-is.

16 bit or double images are not currently supported and will throw an error.  If you want to import
a 16 bit or double image, convert it to rgb8 beforehand.

    my $rgb8 = $img->to_rgb8;
    my $xo = $pdf->imager( $rgb8 );

This method is created in the L<PDF::API2> package.  While this is
bad behaviour, it beats typing out C<PDF::API2::Resource::XObject::Image::Imager>.


=head1 INTERNAL METHODS

You should not be calling these methods. Call C</imager> instead.

=head2 new

    my $xo = PDF::API2::Resource::XObject::Image::Imager->new( $pdf, $img, $name, %opts );

Creates a new image xobject from an Imager object.  

A C<$name> is assigned if none is given.  

Currently no options are defined.

=head2 read_imager

    $xo->read_imager( $img, %opts );

Adds C<$img> to the XObject.

Currently no options are defined.


=head1 SEE ALSO

L<Imager>, L<PDF::API2>

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
