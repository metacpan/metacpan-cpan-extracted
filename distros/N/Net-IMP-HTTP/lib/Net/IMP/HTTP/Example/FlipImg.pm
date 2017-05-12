use strict;
use warnings;

package Net::IMP::HTTP::Example::FlipImg;
use base 'Net::IMP::HTTP::Request';
use fields (
    'ignore',  # irrelevant content
    'image',   # collected octets for image
);

use Net::IMP;  # import IMP_ constants
use Net::IMP::Debug;
use Image::Magick;
use constant MAX_SIZE => 2**16;

sub RTYPES { ( IMP_PASS, IMP_REPLACE ) }
sub new_analyzer {
    my ($factory,%args) = @_;
    my $self = $factory->SUPER::new_analyzer(%args);
    # request data do not matter
    $self->run_callback([ IMP_PASS,0,IMP_MAXOFFSET ]);
    return $self;
}

sub request_hdr {}
sub request_body {}
sub any_data {}

sub response_hdr {
    my ($self,$hdr) = @_;
    my $ignore;
    # we only want selected image/ content types and not too big
    debug("header=$hdr");
    my ($ct) = $hdr =~m{\nContent-type:[ \t]*([^\s;]+)}i;
    my ($clen) = $hdr =~m{\nContent-length:[ \t]*(\d+)}i;
    my ($code) = $hdr =~m{\AHTTP/1\.[01][ \t]+(\d+)};
    if ( $code != 200 ) {
	debug("will not rotate code=$code");
	$ignore++;
    } elsif ( ! $ct or $ct !~m{^image/(png|gif|jpeg)$} ) {
	debug("will not rotate content type $ct");
	$ignore++;
    } elsif ( $clen and $clen > MAX_SIZE ) {
	debug("image is too big: $clen" );
	$ignore++;
    }
    
    if ( $ignore ) {
	$self->run_callback([ IMP_PASS,1,IMP_MAXOFFSET ]);
	$self->{ignore} = 1;
	return;
    }

    # pass header
    $self->run_callback([ IMP_PASS,1,$self->offset(1) ]);
}

sub response_body {
    my ($self,$data) = @_;
    $self->{ignore} and return;
    my $off = $self->offset(1);

    if ( $data ne '' ) {
	$self->{image} .= $data;  # append to image
	# replace with '' in caller to save memory there
	# at the end we will replace eof with the flipped image
	$self->run_callback([ IMP_REPLACE,1,$off,'' ]);

	# with chunked encoding we don't get a length up front, so check now
	if ( length($self->{image}) > MAX_SIZE ) {
	    debug("image too big");
	    $self->run_callback(
		[ IMP_REPLACE,1,$off,$self->{image} ], # unchanged image
		[ IMP_PASS,1,IMP_MAXOFFSET ]
	    );
	    $self->{ignore} = 1;
	}

	return;
    }

    # end of image reached, flip with Image::Magick
    debug("flip image size=%d",length($self->{image}));
    my $img = Image::Magick->new;
    debug("failed to flip img: $@") if ! eval {
	$img->BlobToImage($self->{image});
	$img->Flip;
	($self->{image}) = $img->ImageToBlob;
	debug("replace with ".length($self->{image})." bytes");
	1;
    };

    $self->run_callback(
	[ IMP_REPLACE,1,$self->offset(1),$self->{image} ],
	[ IMP_PASS,1,IMP_MAXOFFSET ],
    );
}

1;
__END__

=head1 NAME

Net::IMP::HTTP::Example::FlipImg - sample IMP plugin to flip images

=head1 SYNOPSIS

    # use proxy from App::HTTP_Proxy_IMP to flip images
    http_proxy_imp --filter Example::FlipImg listen_ip:port

=head1 DESCRIPTION

This is a sample plugin to flip PNG, GIF and JPEG with a size less than 32k.
