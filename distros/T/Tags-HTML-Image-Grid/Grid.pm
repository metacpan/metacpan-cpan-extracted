package Tags::HTML::Image::Grid;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Scalar::Util qw(blessed);
use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_image_grid', 'img_link_cb', 'img_select_cb', 'img_src_cb',
		'img_width', 'title'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Form CSS style.
	$self->{'css_image_grid'} = 'image-grid';

	# Image link callback.
	$self->{'img_link_cb'} = undef;

	# Image select callback.
	$self->{'img_select_cb'} = undef;

	# Image src callback across data object.
	$self->{'img_src_cb'} = undef;

	# Image width in pixels.
	$self->{'img_width'} = 340;

	# Image grid title.
	$self->{'title'} = undef;

	# Process params.
	set_params($self, @{$object_params_ar});

	# Check callback codes.
	$self->_check_callback('img_link_cb');
	$self->_check_callback('img_select_cb');
	$self->_check_callback('img_src_cb');

	# Object.
	return $self;
}

sub _check_callback {
	my ($self, $callback_key) = @_;

	if (defined $self->{$callback_key}
		&& ref $self->{$callback_key} ne 'CODE') {

		err "Parameter '$callback_key' must be a code.";
	}

	return;
}

sub _check_images {
	my ($self, $images_ar) = @_;

	foreach my $image (@{$images_ar}) {
		if (! blessed($image) && ! $image->isa('Data::Image')) {

			err 'Bad data image object.';
		}
	}

	return;
}

# Process 'Tags'.
sub _process {
	my ($self, $images_ar) = @_;

	$self->_check_images($images_ar);

	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'class', $self->{'css_image_grid'}],

		['b', 'div'],
		['a', 'class', $self->{'css_image_grid'}.'-inner'],
	);
	if (defined $self->{'title'}) {
		$self->{'tags'}->put(
			['b', 'fieldset'],
			['b', 'legend'],
			['d', $self->{'title'}],
			['e', 'legend'],
		);
	}
	foreach my $image (@{$images_ar}) {
		if (defined $self->{'img_link_cb'}) {
			$self->{'tags'}->put(
				['b', 'a'],
				['a', 'href', $self->{'img_link_cb'}->($image)],
			);
		}
		$self->{'tags'}->put(
			['b', 'figure'],
		);
		my $image_url;
		if (defined $image->url) {
			$image_url = $image->url;
		} elsif (defined $image->url_cb) {
			$image_url = $image->url_cb->($image);
		} elsif (defined $self->{'img_src_cb'}) {
			$image_url = $self->{'img_src_cb'}->($image);
		} else {
			err 'No image URL.';
		}

		if (defined $self->{'img_select_cb'}) {
			my $select_hr = $self->{'img_select_cb'}->($self, $image);
			if (ref $select_hr eq 'HASH' && $select_hr->{'value'}) {
				$select_hr->{'css_background_color'} ||= 'lightgreen';
				$self->{'tags'}->put(
					['b', 'i'],
					['a', 'class', 'selected'],
					['a', 'style', 'background-color: '.$select_hr->{'css_background_color'}.';'],
					exists $select_hr->{'value'} ? (
						['d', $select_hr->{'value'}],
					) : (),
					['e', 'i'],
				);
			}
		}

		$self->{'tags'}->put(
			['b', 'img'],
			['a', 'src', $image_url],
			['e', 'img'],
		);
		if ($image->comment) {
			$self->{'tags'}->put(
				['b', 'figcaption'],
				['d', $image->comment],
				['e', 'figcaption'],
			);
		}
		$self->{'tags'}->put(
			['e', 'figure'],
		);
		if (defined $self->{'img_link_cb'}) {
			$self->{'tags'}->put(
				['e', 'a'],
			);
		}
	}
	if (defined $self->{'title'}) {
		$self->{'tags'}->put(
			['e', 'fieldset'],
		);
	}
	$self->{'tags'}->put(
		['e', 'div'],
		['e', 'div'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	$self->{'css'}->put(

		# Grid center on page.
		['s', '.'.$self->{'css_image_grid'}],
		['d', 'display', 'flex'],
		['d', 'align-items', 'center'],
		['d', 'justify-content', 'center'],
		['e'],

		# 4 columns in grid.
		['s', '.'.$self->{'css_image_grid'}.'-inner'],
		['d', 'display', 'grid'],
		['d', 'grid-gap', '1px'],
		['d', 'grid-template-columns', 'repeat(4, '.$self->{'img_width'}.'px)'],
		['e'],

		# Create rectangle.
		['s', '.'.$self->{'css_image_grid'}.' figure'],
		['d', 'object-fit', 'cover'],
		['d', 'width', $self->{'img_width'}.'px'],
		['d', 'height', $self->{'img_width'}.'px'],
		['d', 'position', 'relative'],
		['d', 'overflow', 'hidden'],
		['d', 'border', '1px solid white'],
		['d', 'margin', 0],
		['d', 'padding', 0],
		['e'],

		['s', '.'.$self->{'css_image_grid'}.' img'],
		['d', 'object-fit', 'cover'],
		['d', 'width', '100%'],
		['d', 'height', '100%'],
		['d', 'vertical-align', 'middle'],
		['e'],

		['s', '.'.$self->{'css_image_grid'}.' figcaption'],
		['d', 'margin', 0],
		['d', 'padding', '1em'],
		['d', 'position', 'absolute'],
		['d', 'z-index', 1],
		['d', 'bottom', 0],
		['d', 'left', 0],
		['d', 'width', '100%'],
		['d', 'max-height', '100%'],
		['d', 'overflow', 'auto'],
		['d', 'box-sizing', 'border-box'],
		['d', 'transition', 'transform 0.5s'],
		['d', 'transform', 'translateY(100%)'],
		['d', 'background', 'rgba(0, 0, 0, 0.7)'],
		['d', 'color', 'rgb(255, 255, 255)'],
		['e'],

		['s', '.'.$self->{'css_image_grid'}.' figure:hover figcaption'],
		['d', 'transform', 'translateY(0%)'],
		['e'],

		['s', '.'.$self->{'css_image_grid'}.' .selected'],
		['d', 'border', '1px solid black'],
		['d', 'border-radius', '0.5em'],
		['d', 'color', 'black'],
		['d', 'padding', '0.5em'],
		['d', 'position', 'absolute'],
		['d', 'right', '10px'],
		['d', 'top', '10px'],
		['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Image::Grid - Tags helper for image grid.

=head1 SYNOPSIS

 use Tags::HTML::Image::Grid;

 my $obj = Tags::HTML::Image::Grid->new(%params);
 $obj->process($images_ar);
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Image::Grid->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_image_grid>

Form CSS style.

Default value is 'image-grid'.

=item * C<img_link_cb>

Image link callback.

Default value is undef.

=item * C<img_select_cb>

Image select callback.

Default value is undef.

=item * C<img_src_cb>

Image src callback across data object.

Default value is undef.

=item * C<img_width>

Image width in pixels.

Default value is 340.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=item * C<title>

Image grid title.

Default value is undef.

=back

=head2 C<process>

 $obj->process($images_ar);

Process Tags structure for images in C<$images_ar> to output.

Accepted items in C<$images_ar> reference to array are L<Data::Image> objects.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process CSS::Struct structure for output.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.
         Parameter 'img_link_cb' must be a code.
         Parameter 'img_select_cb' must be a code.
         Parameter 'img_src_cb' must be a code.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         Bad data image object.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE

=for comment filename=default_grid.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::Image;
 use Tags::HTML::Image::Grid;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Image::Grid->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Images.
 my $image1 = Data::Image->new(
         'comment' => 'Michal from Czechia',
         'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
 );
 my $image2 = Data::Image->new(
         'comment' => 'Self photo',
         'url' => 'https://upload.wikimedia.org/wikipedia/commons/7/76/Michal_Josef_%C5%A0pa%C4%8Dek_-_self_photo_3.jpg',
 );

 # Process image grid.
 $obj->process([$image1, $image2]);
 $obj->process_css;

 # Print out.
 print $tags->flush;
 print "\n\n";
 print $css->flush;

 # Output:
 # <div class="image-grid">
 #   <div class="image-grid-inner">
 #     <figure>
 #       <img src=
 #         "https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg"
 #         >
 #       </img>
 #       <figcaption>
 #         Michal from Czechia
 #       </figcaption>
 #     </figure>
 #     <figure>
 #       <img src=
 #         "https://upload.wikimedia.org/wikipedia/commons/7/76/Michal_Josef_%C5%A0pa%C4%8Dek_-_self_photo_3.jpg"
 #         >
 #       </img>
 #       <figcaption>
 #         Self photo
 #       </figcaption>
 #     </figure>
 #   </div>
 # </div>
 # 
 # .image-grid {
 # 	display: flex;
 # 	align-items: center;
 # 	justify-content: center;
 # }
 # .image-grid-inner {
 # 	display: grid;
 # 	grid-gap: 1px;
 # 	grid-template-columns: repeat(4, 340px);
 # }
 # .image-grid figure {
 # 	object-fit: cover;
 # 	width: 340px;
 # 	height: 340px;
 # 	position: relative;
 # 	overflow: hidden;
 # 	border: 1px solid white;
 # 	margin: 0;
 # 	padding: 0;
 # }
 # .image-grid img {
 # 	object-fit: cover;
 # 	width: 100%;
 # 	height: 100%;
 # 	vertical-align: middle;
 # }
 # .image-grid figcaption {
 # 	margin: 0;
 # 	padding: 1em;
 # 	position: absolute;
 # 	z-index: 1;
 # 	bottom: 0;
 # 	left: 0;
 # 	width: 100%;
 # 	max-height: 100%;
 # 	overflow: auto;
 # 	box-sizing: border-box;
 # 	transition: transform 0.5s;
 # 	transform: translateY(100%);
 # 	background: rgba(0, 0, 0, 0.7);
 # 	color: rgb(255, 255, 255);
 # }
 # .image-grid figure:hover figcaption {
 # 	transform: translateY(0%);
 # }
 # .image-grid .selected {
 # 	border: 1px solid black;
 # 	border-radius: 0.5em;
 # 	color: black;
 # 	padding: 0.5em;
 # 	position: absolute;
 # 	right: 10px;
 # 	top: 10px;
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::MoreUtils>,
L<Scalar::Util>,
L<Tags::HTML>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Image-Grid>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
