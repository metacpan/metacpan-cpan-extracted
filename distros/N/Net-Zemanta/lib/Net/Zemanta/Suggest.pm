package Net::Zemanta::Suggest;

=head1 NAME

Net::Zemanta::Suggest - Perl interface to Zemanta Suggest service

=cut

use warnings;
use strict;

use Net::Zemanta::Method;
our @ISA = qw(Net::Zemanta::Method);

=head1 SYNOPSIS

	use Net::Zemanta::Suggest;

	my $zemanta = Net::Zemanta::Suggest->new(
			APIKEY => 'your-API-key' 
		);

	my $suggestions = $zemanta->suggest(
			"Cozy lummox gives smart squid who asks for job pen."
		);

	# Suggested images
	for $image (@{$suggestions->{images}}) {
		$image->{url_m};
		$image->{description};
	}

	# Related articles
	for $article (@{$suggestions->{articles}}) {
		$article->{url};
		$article->{title};
	}

	# In-text links
	for $link (@{$suggestions->{markup}->{links}}) {
		for $target (@{$link->{target}}) {
			$link->{anchor}, " -> ", $target->{url};
		}
	}

	# Keywords
	for $keyword (@{$suggestions->{keywords}}) {
		$keyword->{name};
	}

=head1 METHODS

=over 8

=item B<new()>

	Net::Zemanta::Suggest->new(PARAM => ...);

Acceptable parameters:

=over 4

=item  APIKEY

The API key used for authentication with the service.

=item  MARKUP_ONLY

If set to true, a faster variant of the API call is made that only returns
the markup element. Default is to provide everything (images, related articles,
markup and tags).

=item  USER_AGENT

If supplied the value is prepended to this module's identification string 
to become something like:

	your-killer-app/0.042 Perl-Net-Zemanta/0.1 libwww-perl/5.8

Otherwise just Net::Zemanta's user agent string will be sent.

=back

C<new()> returns C<undef> on error.

=cut

sub new {
	my $class 	= shift;
	my %params	= @_;

	if( $params{MARKUP_ONLY} ) {
		$params{METHOD} = "zemanta.suggest_markup";
	} else {
		$params{METHOD} = "zemanta.suggest";
	}

	my $self = $class->SUPER::new(%params);

	return unless $self;

	bless ($self, $class);
	return $self;
}

=item B<suggest()>

	$suggestions = $zemanta->suggest( text, PARAM => ... )

Requests suggestions for the given text. Suggestions are returned as a tree
of hash and list references that correspond to the returned JSON data
structure. The most important parameters and result elements are described bellow.
For the full reference see L<http://developer.zemanta.com>.

Optional parameters:

=over 4

=item  MARKUP_LIMIT

Number of in-text links to return (default is 10).

=item  IMAGES_LIMIT

Number of images to return (default is 24).

=item  ARTICLES_LIMIT

Number of related articles to return (default is 10).

=item  IMAGE_MAX_W, IMAGE_MAX_H

Maximum width and height of returned images respectively (default is 300 by 300).

=back

C<suggest()> returns C<undef> on error.

=over 8

=item B<articles>

Related articles. Contains a list of article objects, each having the following
elements:

=over 4

=item B<url>

URL of the article.

=item B<title>

Title of the article.

=item B<published_datetime>

Date when article was published in ISO 8601 format.

=back

=item B<keywords>

Suggested keywords. Contains a list of keyword objects, each having the
following elements:

=over 4

=item B<name>

Keyword name (may contain spaces)

=back

=item B<images>

Related images. Contains a list of image objects, each having the following
elements:

=over 4

=item B<url_l>, B<url_m>, B<url_s>

URLs of a large, medium and small version of the picture respectively.

=item B<url_l_w>, B<url_l_h>, B<url_m_w>, B<url_m_h>, B<url_s_w>, B<url_s_h>

Width and height of large, medium and small version of the picture respectively.

=item B<license>

String containing license terms.

=item B<description>

String containing description

=item B<attribution>

Attribution that must be posted together with the image.

=item B<source_url>

URL of a web page where more information about the image can be found.

=back

=item B<markup>

An object containing the following elements:

=over 4

=item B<text>

HTML formatted input text with added in-text hyperlinks.

=item B<links>

Suggested in-text hyperlinks. A list of link objects, each having 
the following elements:

=over 4

=item B<anchor>

Word or phrase in the original text that should be used as the anchor for the
link.

=item B<target>

List of possible targets for this link. Each target has the following elements:

=over 4

=item B<url>

Destination URL.

=item B<type>

Type of the resource URL is pointing to.

=item B<title>

Title of the resource.

=back

=back

=back

=item B<rid>

Request ID.

=item B<signature>

HTML signature that should be appended to the text.

=back

=item B<error()>

If the last call to C<suggest()> returned an error, this function returns a
string containing a short description of the error. Otherwise it returns
C<undef>.

=back

=cut

sub suggest {
	my $self = shift;

	my ($text, %options) = @_;

	my %lc_options;
	while(my ($key, $value) = each %options) {
		$lc_options{lc $key} = $value 
	}

	my $text_utf8 = Encode::encode("utf8", $text);

	return $self->execute(	text     => $text_utf8,
				%lc_options );
}

=head1 SEE ALSO

=over 4

=item * L<http://zemanta.com>

=item * L<http://developer.zemanta.com>

=back

=head1 AUTHOR

Tomaz Solc E<lt>tomaz@zemanta.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Zemanta ltd.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.7 or, at your option,
any later version of Perl 5 you may have available.

=cut
