# $Id: Magick.pm,v 1.6 2012/01/03 16:47:16 dk Exp $
package Prima::Image::Magick;

use strict;
use warnings;
require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw( prima_to_magick magick_to_prima );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
our $VERSION     = '0.07';

require XSLoader;
XSLoader::load('Prima::Image::Magick', $VERSION);

use Prima;
use Image::Magick;

# proxy Image::Magick methods into Prima::Image
{
	no strict 'refs';
	my $v = join('|', @Image::Magick::EXPORT);
	my $package = 'Image::Magick';
	if (my @isa = grep { /Image::Magick/ } @Image::Magick::ISA) {
		$package = $isa[0];
	}
	my %d = map { $_ => 1 } grep { !/^([a-z_].*|[A-Z_]+|$v|Prima)$/ } keys %{$package . '::'};
	# delete aliases
	for my $meth ( keys %d) {
		if ( exists $d{"${meth}Image"}) {
			delete $d{"${meth}Image"};
			next;
		}
	}
	for my $meth ( keys %d) {
		next if exists $Prima::Image::{$meth};
		my $sub = sub {
			my $self = shift;
			my $mag  = $self-> BeginMagick;
			my @res;
			if ( wantarray) {
				@res = $mag-> $meth( @_ );
			} else {
				$res[0] = $mag-> $meth( @_ );
			}
			$self-> EndMagick;
			return wantarray ? @res : $res[0];
		};
		*{"Prima::Image::$meth"} = $sub;
	}
}

sub Prima::Image::BeginMagick
{
	my $self = $_[0];
	if ( exists $self-> {__ImageMagickStorage} ) {
		$self-> {__ImageMagickStorage}-> [0]++;
	} else {
		$self-> {__ImageMagickStorage} = [ 0, prima_to_magick( $self ) ];
	}
	$self-> {__ImageMagickStorage}-> [1];
}

sub Prima::Image::EndMagick
{
	my $self = $_[0];
	return unless 
		exists $self-> {__ImageMagickStorage} and 
		0 == $self-> {__ImageMagickStorage}->[0]--;
	convert_to_prima( $self-> {__ImageMagickStorage}->[1], $self);
	delete $self-> {__ImageMagickStorage};
}

sub prima_to_magick
{
	my ( $p) = @_;
	die "Not a Prima::Image object" unless $p and $p->isa('Prima::Image');
	my $m = Image::Magick-> new();
	convert_to_magick( $p, $m);
	$m;
}

sub magick_to_prima
{
	my ( $m, %h) = @_;
	die "Not an Image::Magick object" unless $m and $m->isa('Image::Magick');
	my $p = Prima::Image-> new;
	convert_to_prima( $m, $p);
	$p;
}

*Prima::Image::Magick = \&prima_to_magick;
*Image::Magick::Prima = \&magick_to_prima;

1;
__END__

=head1 NAME

Prima::Image::Magick - Juggle images between Prima and Image::Magick

=head1 SYNOPSIS

  use Prima::Image::Magick;

  my $i = Prima::Image-> new( ... );  # native prima images
  $i-> MedianFilter( radius => 5);    # can call Image::Magick methods

=head1 DESCRIPTION

Allows transformations between L<Prima> images and L<Image::Magick> images.
Exports all methods found on C<Image::Magick> into C<Prima::Image> space, thus
opening the possibilities of ImageMagick for Prima images.

=head1 Prima::Image API

The mutator methods found on C<Image::Magick> namespace are wrapped and
imported into C<Prima::Image> space, so that an image is implictly converted
to C<Image::Magick> and back, so that for example

    $prima_image-> Edge( radius => 5);

is actually the same as

    my $m = prima_to_magick( $prima_image);
    $m-> Edge( radius => 5);
    $prima_image = magick_to_prima( $m);

except that C<$prima_image> internally remains the same perl object. 

This approach is obviusly ineffective when more than one call to ImageMagick
code is required. To avoid the ineffeciency, wrappers C<BeginMagick> and C<EndMagick>
are declared, so 

    $prima_image-> BeginMagick;
    $prima_image-> Edge( radius => 5);
    $prima_image-> Enhance;
    $prima_image-> EndMagick;

is same as
    
    my $m = prima_to_magick( $prima_image);
    $m-> Edge( radius => 5);
    $m-> Enhance;
    $prima_image = magick_to_prima( $m);


=head1 Prima::Image::Magick API

=over

=item prima_to_magick $magick_image

Returns a deep copy of C<$magick_image> stored in a new instance of C<Prima::Image>
object. C<$magick_image> must contain exactly one ImageMagick bitmap. This means that
empty objects and objects f.ex. after C< Read('file1', 'file2') > cannot be used here.
Use C<Image::Magick::Deconstruct> to break image sequence into constituent parts.

Exported either by explicit request or as a part of C<use Prima::Image::Magick ':all'> call.

=item prima_to_magick $prima_image

Returns a deep copy of C<$prima_image> stored in a new instance of C<Image::Magick>
object.

Exported either by explicit request or as a part of C<use Prima::Image::Magick ':all'> call.

=item convert_to_magick $prima_image, $magick_image

Copies content of C<$prima_image> to C<$magick_image>. Not to be called directy
unless really necessary; the method is not exported, and its syntax may change
in future. 

=item convert_to_prima $magick_image, $prima_image

Copies content of C<$magick_image> to C<$prima_image>. Not to be called directy
unless really necessary; the method is not exported, and its syntax may change
in future.

=back

=head1 SEE ALSO

L<Prima>, L<Image::Magick>, L<examples/example.pl>.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Dmitry Karasik

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
