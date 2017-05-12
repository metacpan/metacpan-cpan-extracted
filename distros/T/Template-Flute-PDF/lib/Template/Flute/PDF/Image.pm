package Template::Flute::PDF::Image;

use strict;
use warnings;

use File::Temp qw(tempfile);
use Image::Size;

# map of supported image types
my %types = (JPG => 'jpeg',
			 TIF => 'tiff',
#			'pnm',
			 PNG => 'png',
			 GIF => 'gif',
			);

=head1 NAME

Template::Flute::PDF::Image - PDF image class

=head1 SYNOPSIS

  new Template::Flute::PDF::Image(file => $file,
                                 pdf => $self->{pdf});

=head1 CONSTRUCTOR

=head2 new

Create Template::Flute::PDF::Image object with the following parameters:

=over 4

=item file

Image file (required).

=item pdf

Template::Flute::PDF object (required).

=back

=cut

sub new {
	my ($proto, @args) = @_;
	my ($class, $self, @ret, $img_dir, $template_file, $template_dir);

	$class = ref($proto) || $proto;
	$self = {@args};

	unless ($self->{file}) {
		die "Missing file name for image object.\n";
	}

    unless (-f $self->{file}) {
        die "File for image object not found: $self->{file}.\n";
    }

	bless ($self, $class);
	
	# determine width, height, file type
	@ret = imgsize($self->{file});

	if (exists $types{$ret[2]}) {
		$self->{width} = $ret[0];
		$self->{height} = $ret[1];
		$self->{type} = $types{$ret[2]};
	}
	else {
		$self->convert();
	}
	
	return $self;
}

=head1 FUNCTIONS

=head2 info

Returns image information, see L<Image::Size>.

=cut

sub info {
	my ($filename) = @_;
	my (@ret);

	@ret = imgsize($filename);

	unless (defined $ret[0]) {
		# error reading the image
		return;
	}

	return @ret;
}

=head2 width

Get image width:

    $image->width;

Set image width:

    $image->width(200);

Returns image width in both cases.

=cut

sub width {
    my $self = shift;

    if (@_ > 0 && defined $_[0]) {
	$self->{width} = shift;
    }
    
    return $self->{width};
}

=head2 height

Get image height:

    $image->height;

Set image height:

    $image->height(100);

=cut

sub height {
    my $self = shift;
 
    if (@_ > 0 && defined $_[0]) {
	$self->{height} = shift;
    }

    return $self->{height};
}

=head2 convert FORMAT

Converts image to FORMAT. This is necessary as PDF::API2 does support
only a limited range of formats.

=cut	
	
sub convert {
	my ($self, $format) = @_;
	my ($magick, $msg, $tmph, $tmpfile);

	$format ||= 'png';

    eval "require Image::Magick";
    die "Can't load Image::Magick for format $format: $@" if $@;
    
	$self->{original_file} = $self->{file};

	# create and register temporary file
	($tmph, $tmpfile) = tempfile('temzooXXXXXX', SUFFIX => ".$format");
	
	$self->{tmpfile} = $tmpfile;

	$magick = Image::Magick->new;

	if ($msg = $magick->Read($self->{file})) {
		die "Failed to read picture from $self->{file}: $msg\n";
	}

	if ($msg = $magick->Write(file => $tmph, magick => $format)) {
		die "Failed to write picture to $tmpfile: $msg\n";
	}
	
	$self->{file} = $tmpfile;
	$self->{type} = $format;

	($self->{width}, $self->{height}) = $magick->Get('width', 'height');
	
	return 1;
}

sub DESTROY {
    my $self = shift;

    if (exists $self->{tmpfile}) {
	# clean up temporary file generated within convert method
	unlink $self->{tmpfile};
    }
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
