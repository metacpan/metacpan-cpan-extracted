package Mxpress::PDF::Mechanize;
our $VERSION = '0.02';	
use Zydeco prefix => 'Mxpress::PDF';
use Cwd qw/getcwd/;
use Log::Log4perl qw(:easy);
class Mxpress::PDF::Mechanize {
	class Plugin::Mechanize::Screenshot extends Plugin::Image {
		has mech_class (type => Str);
		has mech_open_args (type => HashRef);
		has selector (type => Str);
		has js (type => Str);
		has screenshot_w_scale (type => Num);
		has screenshot_h_scale (type => Num);
		has screenshot_left_offset (type => Num);
		has screenshot_top_offset (type => Num);
		has sleep (type => Num);
		factory screenshot (Object $file, Map %args) {
			$class->new(
				mech_open_args => {
					incognito => 0,
					autodie => 0,
					autoclose => 0,
					headless => 1
				},
				file => $file,
				mech_class => 'WWW::Mechanize::Chrome',
				padding => 0,
				screenshot_h_scale => 1,
				screenshot_w_scale => 1,
				screenshot_left_offset => 0,
				screenshot_top_offset => 0,
				align => 'fill',
				%args
			);
		}
		method take (Str $url, Map %args) { # around add 
			$self->set_attrs(%args);
			$self->add($self->_mechanized_screenshot($url));
		}
		method _mechanized_screenshot (Str $url) {
			$self->mech->get($url);
			$self->mech->eval_in_page($self->js) if $self->js;
			$self->mech->sleep($self->sleep) if $self->sleep;
			my $img = $self->selector ? do {
				my $shiny = $self->mech->selector($self->selector, single => 1);
				my ($pos) = $self->mech->element_coordinates($shiny);
				$pos->{width} = $pos->{width} * $self->screenshot_w_scale;
				$pos->{height} = $pos->{height} * $self->screenshot_h_scale;
				$pos->{left} += $self->screenshot_left_offset;
				$pos->{top} += $self->screenshot_top_offset;
				$self->mech->content_as_png($pos);
			} : $self->mech->content_as_png();
			open my $fh, "<", \$img;
			return ($fh, 'png');
		}
		has _mech (type => Object); # builder
		method mech {
			require $self->mech_class;
			return $self->_mech || $self->_mech($self->mech_class->new(%{$self->mech_open_args}));
		}
	}
}

1;

__END__

=head1 NAME

Mxpress::PDF::Mechanize - Take a screenshot and add it to the pdf

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

This is a quick example of how to expand Mxpress::PDF...

	use Mxpress::PDF;
	use Mxpress::PDF::Mechanize;

	my $file = Mxpress::PDF->new_file($file_name, 
		plugins => [qw/screenshot/]
	);

	my $url = 'https://www.gohawaii.com/trip-planning';
	$file->screenshot->add($url, %screenshot_args);

	$file->save;

=head1 Description

This extends Mxpress::PDF currently with a single plugin 'screenshot'. tbc

=head1 Factory

=head2 screenshot

Returns a new Mxpress::PDF::Plugin::Mechanize::Screenshot Object. This object is for assisting with mechanizing browser screenshots..

	my $page = Mxpress::PDF->page(%page_args);

=head1 Screenshot

Mxpress::PDF::Plugin::Mechanize::Screenshot extends Mxpress::PDF::Plugin::Image and is for taking screenshots and adding them to a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		screenshot => { %screenshot_attrs },
	);

or when calling the objects add method.

	$file->screenshot->add(
		%screenshot_attrs
	);

	my $screenshot = $file->screenshot;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Screenshot object, they are all optional.

	$screenshot->$attrs();

=head3 mech_class (type => Str);

Mechanize class - WWW::Mechanize::Chrome

	$screenshot->mech_class

=head3  mech_open_args (type => HashRef)

Args that are passed to $mech_class->new;

	$screenshot->mech_open_args
	
=head3 mech 

The Instantiated mech_class

	$screenshot->mech->$methods

=head3 selector (type => Str);

Select the node wrapper.

	$screenshot->selector('#my-id');

=head3 js (type => Str);

Execute some JS.

	$screenshot->js($js_string);

=head2 sleep (type => Str);

Sleep while the JS does it's thing.

	$screenshot->sleep;

=head3 screenshot_scale (type => Num);

Scaling the screenshot

	$screenshot->screenshot_scale;	

=head3 screenshot_left_offset (type => Num);

Set a left offset before taking the screenshot.

	$screenshot->screenshot_left_offset

=head3 screenshot_top_offset (type => Num);

Set a top offset before taking the screenshot.

	$screenshot->screenshot->top_offset;

=head3 width (type => Num);

The width of the image added to the pdf.

	$img->width($pt);

=head3 height (type => Num);

The height of the image added to the pdf.

	$img->height($pt);

=head3 align (type => Str);

Align the image - fill|left|center|right

	$img->align('right');

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mxpress-pdf-mechanize at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mxpress-PDF-Mechanize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mxpress::PDF::Mechanize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Mxpress-PDF-Mechanize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mxpress-PDF-Mechanize>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Mxpress-PDF-Mechanize>

=item * Search CPAN

L<https://metacpan.org/release/Mxpress-PDF-Mechanize>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Mxpress::PDF::Mechanize
