package Tags::HTML::Image;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Mo::utils 0.12 qw(check_code);
use Mo::utils::CSS 0.02 qw(check_css_class);
use Scalar::Util qw(blessed);

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_class', 'css_comment_height', 'fit_minus',
		'img_comment_cb', 'img_select_cb', 'img_src_cb', 'img_width', 'title'],
		@params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Image CSS class.
	$self->{'css_class'} = 'image';

	# Image comment height (in pixels).
	$self->{'css_comment_height'} = '50';

	# Length to minus of image fit.
	$self->{'fit_minus'} = undef;

	# Image comment callback.
	$self->{'img_comment_cb'} = undef;

	# Image select callback.
	$self->{'img_select_cb'} = undef;

	# Image src callback across data object.
	$self->{'img_src_cb'} = undef;

	# Image width in pixels.
	$self->{'img_width'} = undef;

	# Image title.
	$self->{'title'} = undef;

	# Process params.
	set_params($self, @{$object_params_ar});

	check_css_class($self, 'css_class');

	# Check callback codes.
	check_code($self, 'img_comment_cb');
	check_code($self, 'img_select_cb');
	check_code($self, 'img_src_cb');

	$self->_cleanup;

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_image'};
	$self->{'_image_comment_tags'} = [];
	$self->{'_image_comment_css'} = [];
	$self->{'_image_select_tags'} = [];
	$self->{'_image_select_css'} = [];
	delete $self->{'_image_url'};

	return;
}

sub _init {
	my ($self, $image, @params) = @_;

	if (! defined $image) {
		err 'Image object is required.';
	}
	if (! blessed($image) || ! $image->isa('Data::Image')) {
		err "Image object must be a instance of 'Data::Image'.";
	}

	$self->{'_image'} = $image;

	# Process image URL.
	if (defined $self->{'_image'}->url) {
		$self->{'_image_url'} = $self->{'_image'}->url;
	} elsif (defined $self->{'_image'}->url_cb) {
		$self->{'_image_url'} = $self->{'_image'}->url_cb->($self->{'_image'});
	} elsif (defined $self->{'img_src_cb'}) {
		$self->{'_image_url'} = $self->{'img_src_cb'}->($self->{'_image'});
	} else {
		err 'No image URL.';
	}

	# Process comment.
	if (defined $self->{'img_comment_cb'}) {
		($self->{'_image_comment_tags'}, $self->{'_image_comment_css'})
			= $self->{'img_comment_cb'}->($self, $image, @params);
	} else {
		if (defined $image->comment) {
			$self->{'_image_comment_tags'} = [
				['d', $image->comment],
			];
		}
	}
	if (@{$self->{'_image_comment_tags'}}) {
		my $comment_font_size = $self->{'css_comment_height'} / 2;
		my $comment_vertical_padding = $self->{'css_comment_height'} / 4;
		push @{$self->{'_image_comment_css'}}, (
			['s', '.'.$self->{'css_class'}.' figcaption'],
			['d', 'position', 'absolute'],
			['d', 'bottom', 0],
			['d', 'background', 'rgb(0, 0, 0)'],
			['d', 'background', 'rgba(0, 0, 0, 0.5)'],
			['d', 'color', '#f1f1f1'],
			['d', 'width', '100%'],
			['d', 'transition', '.5s ease'],
			['d', 'opacity', 0],
			['d', 'font-size', $comment_font_size.'px'],
			['d', 'padding', $comment_vertical_padding.'px 5px'],
			['d', 'text-align', 'center'],
			['e'],

			['s', 'figure.'.$self->{'css_class'}.':hover figcaption'],
			['d', 'opacity', 1],
			['e'],
		);
	}

	if (defined $self->{'img_select_cb'}) {
		my $select_hr = $self->{'img_select_cb'}->($self, $image, @params);
		if (ref $select_hr eq 'HASH' && exists $select_hr->{'value'}) {
			$select_hr->{'css_background_color'} ||= 'lightgreen';
			$self->{'_image_select_tags'} = [
				['b', 'i'],
				['a', 'class', 'selected'],
				['a', 'style', 'background-color: '.$select_hr->{'css_background_color'}.';'],
				exists $select_hr->{'value'} ? (
					['d', $select_hr->{'value'}],
				) : (),
				['e', 'i'],
			];
		}

		push @{$self->{'_image_select_css'}}, (
			['s', '.'.$self->{'css_class'}.' .selected'],
			['d', 'border', '1px solid black'],
			['d', 'border-radius', '0.5em'],
			['d', 'color', 'black'],
			['d', 'padding', '0.5em'],
			['d', 'position', 'absolute'],
			['d', 'right', '10px'],
			['d', 'top', '10px'],
			['e'],
		);
	}

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	# Begin of figure.
	$self->{'tags'}->put(
		['b', 'figure'],
		['a', 'class', $self->{'css_class'}],
	);

	# Begin of image title.
	if (defined $self->{'title'}) {
		$self->{'tags'}->put(
			['b', 'fieldset'],
			['b', 'legend'],
			['d', $self->{'title'}],
			['e', 'legend'],
		);
	}

	# Select information.
	if (@{$self->{'_image_select_tags'}}) {
		$self->{'tags'}->put(
			@{$self->{'_image_select_tags'}},
		);
	}

	my @alt;
	if ($self->{'_image'}->comment) {
		push @alt, ['a', 'alt', $self->{'_image'}->comment];
	}

	# Image.
	$self->{'tags'}->put(
		['b', 'img'],
		@alt,
		['a', 'src', $self->{'_image_url'}],
		['e', 'img'],
	);

	# Image comment.
	if (@{$self->{'_image_comment_tags'}}) {
		$self->{'tags'}->put(
			['b', 'figcaption'],
			@{$self->{'_image_comment_tags'}},
			['e', 'figcaption'],
		);
	}

	# End of image title.
	if (defined $self->{'title'}) {
		$self->{'tags'}->put(
			['e', 'fieldset'],
		);
	}

	# End of figure.
	$self->{'tags'}->put(
		['e', 'figure'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	my $calc;
	if (! defined $self->{'img_width'}) {
		$calc .= 'calc(100vh';
		if (defined $self->{'fit_minus'}) {
			$calc .= ' - '.$self->{'fit_minus'};
		}
		$calc .= ')';
	}

	$self->{'css'}->put(
		['s', '.'.$self->{'css_class'}.' img'],
		['d', 'display', 'block'],
		['d', 'height', '100%'],
		['d', 'width', '100%'],
		['d', 'object-fit', 'contain'],
		['e'],

		['s', '.'.$self->{'css_class'}],
		defined $self->{'img_width'} ? (
			['d', 'width', $self->{'img_width'}],
		) : (
			['d', 'height', $calc],
		),
		['e'],

		@{$self->{'_image_comment_css'}},

		@{$self->{'_image_select_css'}},
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Image - Tags helper class for image presentation.

=head1 SYNOPSIS

 use Tags::HTML::Image;

 my $obj = Tags::HTML::Image->new(%params);
 $obj->cleanup;
 $obj->init($image);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Image->new(%params);

Constructor.

=over 8

=item * C<css_class>

Image CSS class.

Default value is 'image'.

=item * C<css_comment_height>

Image comment height (in pixels).

Default value is 50.

=item * C<fit_minus>

Length to minus of image fit.

Default value is undef.

=item * C<img_comment_cb>

Image comment callback.

Default value is undef.

=item * C<img_select_cb>

Image select callback.

Default value is undef.

=item * C<img_src_cb>

Image src callback across data object.

Default value is undef.

=item * C<img_width>

Image width in pixels.

Default value is undef.

=item * C<tags>

'L<Tags::Output>' object.

Default value is undef.

=item * C<title>

Image title.

Default value is undef.

=back

Returns instance of object.

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

Returns undef.

=head2 C<init>

 $obj->init($image);

Process initialization in page run.

Take L<Data::Image> object as C<$image>,

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Process initialization before page run.

It is not used in this module.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for output with hello world message.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Mo::utils::check_code():
                 Parameter 'img_comment_cb' must be a code.
                 Parameter 'img_select_cb' must be a code.
                 Parameter 'img_src_cb' must be a code.
         From Mo::utils::CSS::check_css_class():
                 Parameter 'css_class' has bad CSS class name.
                         Value: %s
                 Parameter 'css_class' has bad CSS class name (number on begin).
                         Value: %s
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 init():
         Image object is required.
         Image object must be a instance of 'Data::Image'.
         No image URL.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE1

=for comment filename=create_image_and_print_html.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::Image;
 use DateTime;
 use Tags::HTML::Image;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Image->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Definition of image.
 my $image = Data::Image->new(
         'author' => 'Zuzana Zonova',
         'comment' => 'Michal from Czechia',
         'dt_created' => DateTime->new(
                 'day' => 1,
                 'month' => 1,
                 'year' => 2022,
         ),
         'height' => 2730,
         'size' => 1040304,
         'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
         'width' => 4096,
 );

 # Init.
 $obj->init($image);

 # Process HTML and CSS.
 $obj->process;
 $obj->process_css;

 # Print out.
 print "HTML:\n";
 print $tags->flush;
 print "\n\n";
 print "CSS:\n";
 print $css->flush;

 # Output:
 # HTML:
 # <figure class="image">
 #   <img alt="Michal from Czechia" src=
 #     "https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg"
 #     >
 #   </img>
 #   <figcaption>
 #     Michal from Czechia
 #   </figcaption>
 # </figure>
 # 
 # CSS:
 # .image img {
 #         display: block;
 #         height: 100%;
 #         width: 100%;
 #         object-fit: contain;
 # }
 # .image {
 #         height: calc(100vh);
 # }
 # .image figcaption {
 #         position: absolute;
 #         bottom: 0;
 #         background: rgb(0, 0, 0);
 #         background: rgba(0, 0, 0, 0.5);
 #         color: #f1f1f1;
 #         width: 100%;
 #         transition: .5s ease;
 #         opacity: 0;
 #         font-size: 25px;
 #         padding: 12.5px 5px;
 #         text-align: center;
 # }
 # figure.image:hover figcaption {
 #         opacity: 1;
 # }

=head1 EXAMPLE2

=for comment filename=plack_app_image.pl

 use strict;
 use warnings;
 
 use CSS::Struct::Output::Indent;
 use Data::Image;
 use DateTime;
 use Plack::App::Tags::HTML;
 use Plack::Runner;
 use Tags::Output::Indent;
 
 my $image = Data::Image->new(
 	'author' => 'Zuzana Zonova',
 	'comment' => 'Michal from Czechia',
 	'dt_created' => DateTime->new(
 		'day' => 1,
 		'month' => 1,
 		'year' => 2022,
 	),
 	'height' => 2730,
 	'size' => 1040304,
 	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
 	'width' => 4096,
 );
 
 my $app = Plack::App::Tags::HTML->new(
 	'component' => 'Tags::HTML::Image',
 	'css' => CSS::Struct::Output::Indent->new,
 	'data_init' => [$image],
 	'tags' => Tags::Output::Indent->new(
 		'xml' => 1,
 		'preserved' => ['style'],
 	),
 	'title' => 'Image',
 )->to_app;
 Plack::Runner->new->run($app);

 # Output (GET /):
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Image
 #     </title>
 #     <style type="text/css">
 # * {
 #         box-sizing: border-box;
 #         margin: 0;
 #         padding: 0;
 # }
 # .image img {
 #         display: block;
 #         height: 100%;
 #         width: 100%;
 #         object-fit: contain;
 # }
 # .image {
 #         height: calc(100vh);
 # }
 # .image figcaption {
 #         position: absolute;
 #         bottom: 0;
 #         background: rgb(0, 0, 0);
 #         background: rgba(0, 0, 0, 0.5);
 #         color: #f1f1f1;
 #         width: 100%;
 #         transition: .5s ease;
 #         opacity: 0;
 #         font-size: 25px;
 #         padding: 12.5px 5px;
 #         text-align: center;
 # }
 # figure.image:hover figcaption {
 #         opacity: 1;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <figure class="image">
 #       <img alt="Michal from Czechia" src=
 #         "https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg"
 #         />
 #       <figcaption>
 #         Michal from Czechia
 #       </figcaption>
 #     </figure>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Mo::utils>,
L<Mo::utils::CSS>,
L<Scalar::Util>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Image>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
