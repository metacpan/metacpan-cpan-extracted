package Tags::HTML::Stars;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use List::Util qw(max);
use MIME::Base64;
use Readonly;

# Constants.
Readonly::Scalar our $STAR_FULL_FILENAME => 'Star*.svg';
Readonly::Scalar our $STAR_HALF_FILENAME => 'Star-.svg';
Readonly::Scalar our $STAR_NOTHING_FILENAME => 'Star½.svg';
Readonly::Scalar our $IMG_STAR_FULL => encode_base64(<<'END', '');
<svg width="300px" height="275px" viewBox="0 0 300 275" xmlns="http://www.w3.org/2000/svg" version="1.1">
  <polygon fill="#fdff00" stroke="#605a00" stroke-width="15" points="150,25 179,111 269,111 197,165 223,251 150,200 77,251 103,165 31,111 121,111" />
</svg>
END
Readonly::Scalar our $IMG_STAR_HALF => encode_base64(<<'END', '');
<svg width="300px" height="275px" viewBox="0 0 300 275" xmlns="http://www.w3.org/2000/svg" version="1.1">
  <clipPath id="empty"><rect x="150" y="0" width="150" height="275" /></clipPath>
  <clipPath id="filled"><rect x="0" y="0" width="150" height="275" /></clipPath>
  <polygon fill="none" stroke="#808080" stroke-width="15" stroke-opacity="0.37647060" points="150,25 179,111 269,111 197,165 223,251 150,200 77,251 103,165 31,111 121,111" clip-path="url(#empty)" />
  <polygon fill="#fdff00" stroke="#605a00" stroke-width="15" points="150,25 179,111 269,111 197,165 223,251 150,200 77,251 103,165 31,111 121,111" clip-path="url(#filled)" />
</svg>
END
Readonly::Scalar our $IMG_STAR_NOTHING => encode_base64(<<'END', '');
<svg width="300px" height="275px" viewBox="0 0 300 275" xmlns="http://www.w3.org/2000/svg" version="1.1">
  <polygon fill="none" stroke="#808080" stroke-width="15" stroke-opacity="0.37647060" points="150,25 179,111 269,111 197,165 223,251 150,200 77,251 103,165 31,111 121,111" />
</svg>
END

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# No CSS support.
	push @params, 'no_css', 1;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['public_image_dir', 'star_width'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Public image directory.
	$self->{'public_image_dir'} = undef;

	# Star width (300px).
	$self->{'star_width'} = undef;

	# Process params.
	set_params($self, @{$object_params_ar});

	# Object.
	return $self;
}

# Process 'Tags'.
sub _process {
	my ($self, $stars_hr) = @_;

	# Main stars.
	$self->{'tags'}->put(
		['b', 'div'],
	);

	my $max_num = max(keys %{$stars_hr});
	foreach my $num (1 .. $max_num) {
		my $image_src = $self->_star_src($stars_hr->{$num});

		$self->{'tags'}->put(
			['b', 'img'],
			(
				$self->{'star_width'}
				? (
				['a', 'style', 'width: '.$self->{'star_width'}.';'],
				) : (),
			),
			['a', 'src', $image_src],
			['e', 'img'],
		);
	}

	$self->{'tags'}->put(
		['e', 'div'],
	);

	return;
}

sub _star_src {
	my ($self, $id) = @_;

	# Link to file.
	my $src;
	if (defined $self->{'public_image_dir'}) {
		$src = $self->{'public_image_dir'};
		if ($src ne '') {
			$src .= '/';
		}
		if ($id eq 'full') {
			$src .= $STAR_FULL_FILENAME;
		} elsif ($id eq 'half') {
			$src .= $STAR_HALF_FILENAME;
		} elsif ($id eq 'nothing') {
			$src .= $STAR_NOTHING_FILENAME
		}
	} else {
		$src = 'data:image/svg+xml;base64,';
		if ($id eq 'full') {
			$src .= $IMG_STAR_FULL;
		} elsif ($id eq 'half') {
			$src .= $IMG_STAR_HALF;
		} elsif ($id eq 'nothing') {
			$src .= $IMG_STAR_NOTHING;
		}
	}

	return $src;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Stars - Tags helper for stars evaluation.

=head1 SYNOPSIS

 use Tags::HTML::Stars;

 my $obj = Tags::HTML::Stars->new(%params);
 $obj->process($stars_hr);

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Stars->new(%params);

Constructor.

=over 8

=item * C<public_image_dir>

Public image directory.

Default value is undef.

=item * C<star_width>

Width of star.

Default value is undef (original with of image, in case of inline image is 300px).

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<process>

 $obj->process($stars_hr);

Process Tags structure for output with stars.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Tags::HTML::Stars;
 use Tags::Output::Indent;

 # Object.
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Stars->new(
         'tags' => $tags,
 );

 # Process stars.
 $obj->process({
         1 => 'full',
         2 => 'half',
         3 => 'nothing',
 });

 # Print out.
 print $tags->flush;

 # Output:
 # <div>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0iI2ZkZmYwMCIgc3Ryb2tlPSIjNjA1YTAwIiBzdHJva2Utd2lkdGg9IjE1IiBwb2ludHM9IjE1MCwyNSAxNzksMTExIDI2OSwxMTEgMTk3LDE2NSAyMjMsMjUxIDE1MCwyMDAgNzcsMjUxIDEwMywxNjUgMzEsMTExIDEyMSwxMTEiIC8+Cjwvc3ZnPgo="
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPGNsaXBQYXRoIGlkPSJlbXB0eSI+PHJlY3QgeD0iMTUwIiB5PSIwIiB3aWR0aD0iMTUwIiBoZWlnaHQ9IjI3NSIgLz48L2NsaXBQYXRoPgogIDxjbGlwUGF0aCBpZD0iZmlsbGVkIj48cmVjdCB4PSIwIiB5PSIwIiB3aWR0aD0iMTUwIiBoZWlnaHQ9IjI3NSIgLz48L2NsaXBQYXRoPgogIDxwb2x5Z29uIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzgwODA4MCIgc3Ryb2tlLXdpZHRoPSIxNSIgc3Ryb2tlLW9wYWNpdHk9IjAuMzc2NDcwNjAiIHBvaW50cz0iMTUwLDI1IDE3OSwxMTEgMjY5LDExMSAxOTcsMTY1IDIyMywyNTEgMTUwLDIwMCA3NywyNTEgMTAzLDE2NSAzMSwxMTEgMTIxLDExMSIgY2xpcC1wYXRoPSJ1cmwoI2VtcHR5KSIgLz4KICA8cG9seWdvbiBmaWxsPSIjZmRmZjAwIiBzdHJva2U9IiM2MDVhMDAiIHN0cm9rZS13aWR0aD0iMTUiIHBvaW50cz0iMTUwLDI1IDE3OSwxMTEgMjY5LDExMSAxOTcsMTY1IDIyMywyNTEgMTUwLDIwMCA3NywyNTEgMTAzLDE2NSAzMSwxMTEgMTIxLDExMSIgY2xpcC1wYXRoPSJ1cmwoI2ZpbGxlZCkiIC8+Cjwvc3ZnPgo="
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0ibm9uZSIgc3Ryb2tlPSIjODA4MDgwIiBzdHJva2Utd2lkdGg9IjE1IiBzdHJva2Utb3BhY2l0eT0iMC4zNzY0NzA2MCIgcG9pbnRzPSIxNTAsMjUgMTc5LDExMSAyNjksMTExIDE5NywxNjUgMjIzLDI1MSAxNTAsMjAwIDc3LDI1MSAxMDMsMTY1IDMxLDExMSAxMjEsMTExIiAvPgo8L3N2Zz4K"
 #     >
 #   </img>
 # </div>

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Number::Stars;
 use Tags::HTML::Stars;
 use Tags::Output::Indent;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 percent\n";
         exit 1;
 }
 my $percent = $ARGV[0];

 # Object.
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Stars->new(
         'tags' => $tags,
 );

 my $stars_hr = Number::Stars->new->percent_stars($percent);

 # Process stars.
 $obj->process($stars_hr);

 # Print out.
 print $tags->flush;

 # Output:
 # <div>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0iI2ZkZmYwMCIgc3Ryb2tlPSIjNjA1YTAwIiBzdHJva2Utd2lkdGg9IjE1IiBwb2ludHM9IjE1MCwyNSAxNzksMTExIDI2OSwxMTEgMTk3LDE2NSAyMjMsMjUxIDE1MCwyMDAgNzcsMjUxIDEwMywxNjUgMzEsMTExIDEyMSwxMTEiIC8+Cjwvc3ZnPgo="
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0iI2ZkZmYwMCIgc3Ryb2tlPSIjNjA1YTAwIiBzdHJva2Utd2lkdGg9IjE1IiBwb2ludHM9IjE1MCwyNSAxNzksMTExIDI2OSwxMTEgMTk3LDE2NSAyMjMsMjUxIDE1MCwyMDAgNzcsMjUxIDEwMywxNjUgMzEsMTExIDEyMSwxMTEiIC8+Cjwvc3ZnPgo="
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0iI2ZkZmYwMCIgc3Ryb2tlPSIjNjA1YTAwIiBzdHJva2Utd2lkdGg9IjE1IiBwb2ludHM9IjE1MCwyNSAxNzksMTExIDI2OSwxMTEgMTk3LDE2NSAyMjMsMjUxIDE1MCwyMDAgNzcsMjUxIDEwMywxNjUgMzEsMTExIDEyMSwxMTEiIC8+Cjwvc3ZnPgo="
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0iI2ZkZmYwMCIgc3Ryb2tlPSIjNjA1YTAwIiBzdHJva2Utd2lkdGg9IjE1IiBwb2ludHM9IjE1MCwyNSAxNzksMTExIDI2OSwxMTEgMTk3LDE2NSAyMjMsMjUxIDE1MCwyMDAgNzcsMjUxIDEwMywxNjUgMzEsMTExIDEyMSwxMTEiIC8+Cjwvc3ZnPgo="
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0iI2ZkZmYwMCIgc3Ryb2tlPSIjNjA1YTAwIiBzdHJva2Utd2lkdGg9IjE1IiBwb2ludHM9IjE1MCwyNSAxNzksMTExIDI2OSwxMTEgMTk3LDE2NSAyMjMsMjUxIDE1MCwyMDAgNzcsMjUxIDEwMywxNjUgMzEsMTExIDEyMSwxMTEiIC8+Cjwvc3ZnPgo="
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPGNsaXBQYXRoIGlkPSJlbXB0eSI+PHJlY3QgeD0iMTUwIiB5PSIwIiB3aWR0aD0iMTUwIiBoZWlnaHQ9IjI3NSIgLz48L2NsaXBQYXRoPgogIDxjbGlwUGF0aCBpZD0iZmlsbGVkIj48cmVjdCB4PSIwIiB5PSIwIiB3aWR0aD0iMTUwIiBoZWlnaHQ9IjI3NSIgLz48L2NsaXBQYXRoPgogIDxwb2x5Z29uIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzgwODA4MCIgc3Ryb2tlLXdpZHRoPSIxNSIgc3Ryb2tlLW9wYWNpdHk9IjAuMzc2NDcwNjAiIHBvaW50cz0iMTUwLDI1IDE3OSwxMTEgMjY5LDExMSAxOTcsMTY1IDIyMywyNTEgMTUwLDIwMCA3NywyNTEgMTAzLDE2NSAzMSwxMTEgMTIxLDExMSIgY2xpcC1wYXRoPSJ1cmwoI2VtcHR5KSIgLz4KICA8cG9seWdvbiBmaWxsPSIjZmRmZjAwIiBzdHJva2U9IiM2MDVhMDAiIHN0cm9rZS13aWR0aD0iMTUiIHBvaW50cz0iMTUwLDI1IDE3OSwxMTEgMjY5LDExMSAxOTcsMTY1IDIyMywyNTEgMTUwLDIwMCA3NywyNTEgMTAzLDE2NSAzMSwxMTEgMTIxLDExMSIgY2xpcC1wYXRoPSJ1cmwoI2ZpbGxlZCkiIC8+Cjwvc3ZnPgo="
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0ibm9uZSIgc3Ryb2tlPSIjODA4MDgwIiBzdHJva2Utd2lkdGg9IjE1IiBzdHJva2Utb3BhY2l0eT0iMC4zNzY0NzA2MCIgcG9pbnRzPSIxNTAsMjUgMTc5LDExMSAyNjksMTExIDE5NywxNjUgMjIzLDI1MSAxNTAsMjAwIDc3LDI1MSAxMDMsMTY1IDMxLDExMSAxMjEsMTExIiAvPgo8L3N2Zz4K"
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0ibm9uZSIgc3Ryb2tlPSIjODA4MDgwIiBzdHJva2Utd2lkdGg9IjE1IiBzdHJva2Utb3BhY2l0eT0iMC4zNzY0NzA2MCIgcG9pbnRzPSIxNTAsMjUgMTc5LDExMSAyNjksMTExIDE5NywxNjUgMjIzLDI1MSAxNTAsMjAwIDc3LDI1MSAxMDMsMTY1IDMxLDExMSAxMjEsMTExIiAvPgo8L3N2Zz4K"
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0ibm9uZSIgc3Ryb2tlPSIjODA4MDgwIiBzdHJva2Utd2lkdGg9IjE1IiBzdHJva2Utb3BhY2l0eT0iMC4zNzY0NzA2MCIgcG9pbnRzPSIxNTAsMjUgMTc5LDExMSAyNjksMTExIDE5NywxNjUgMjIzLDI1MSAxNTAsMjAwIDc3LDI1MSAxMDMsMTY1IDMxLDExMSAxMjEsMTExIiAvPgo8L3N2Zz4K"
 #     >
 #   </img>
 #   <img src=
 #     "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwcHgiIGhlaWdodD0iMjc1cHgiIHZpZXdCb3g9IjAgMCAzMDAgMjc1IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMSI+CiAgPHBvbHlnb24gZmlsbD0ibm9uZSIgc3Ryb2tlPSIjODA4MDgwIiBzdHJva2Utd2lkdGg9IjE1IiBzdHJva2Utb3BhY2l0eT0iMC4zNzY0NzA2MCIgcG9pbnRzPSIxNTAsMjUgMTc5LDExMSAyNjksMTExIDE5NywxNjUgMjIzLDI1MSAxNTAsMjAwIDc3LDI1MSAxMDMsMTY1IDMxLDExMSAxMjEsMTExIiAvPgo8L3N2Zz4K"
 #     >
 #   </img>
 # </div>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Utils>,
L<MIME::Base64>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Number::Stars>

Class for conversion between percent number to star visualization

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Stars>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.03

=cut
