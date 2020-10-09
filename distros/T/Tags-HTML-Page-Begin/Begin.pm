package Tags::HTML::Page::Begin;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Readonly;

# Constants.
Readonly::Hash my %LANG => (
	'title' => 'Page title',
);

our $VERSION = 0.10;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Application name.
	$self->{'application-name'} = undef;

	# Author.
	$self->{'author'} = undef;

	# Base element.
	$self->{'base_href'} = undef;
	$self->{'base_target'} = undef;

	# 'CSS::Struct' object.
	$self->{'css'} = undef;

	# CSS links.
	$self->{'css_src'} = [];

	# Charset.
	$self->{'charset'} = 'UTF-8';

	# Description.
	$self->{'description'} = undef;

	# Doctype.
	$self->{'doctype'} = '<!DOCTYPE html>';

	# Favicon.
	$self->{'favicon'} = undef;

	# Generator.
	$self->{'generator'} = 'Perl module: '.__PACKAGE__.', Version: '.$VERSION;

	# HTML element lang attribute.
	$self->{'html_lang'} = 'en';

	# http-equiv content-type.
	$self->{'http_equiv_content_type'} = 'text/html';

	# Keywords.
	$self->{'keywords'} = undef;

	# Languages.
	$self->{'lang'} = \%LANG;

	# Refresh.
	$self->{'refresh'} = undef;

	# Robots.
	$self->{'robots'} = undef;

	# RSS
	$self->{'rss'} = undef;

	# Script js code.
	$self->{'script_js'} = [];

	# Script js sources.
	$self->{'script_js_src'} = [];

	# 'Tags' object.
	$self->{'tags'} = undef;

	# Viewport.
	$self->{'viewport'} = undef;

	# Process params.
	set_params($self, @params);

	# Check to 'Tags' object.
	if (! $self->{'tags'} || ! $self->{'tags'}->isa('Tags::Output')) {
		err "Parameter 'tags' must be a 'Tags::Output::*' class.";
	}

	# Check to 'CSS::Struct' object.
	if ($self->{'css'} && ! $self->{'css'}->isa('CSS::Struct::Output')) {
		err "Parameter 'css' must be a 'CSS::Struct::Output::*' class.";
	}

	# Check for 'css_src' array.
	if (ref $self->{'css_src'} ne 'ARRAY') {
		err "Parameter 'css_src' must be a array.";
	}
	foreach my $css_src_hr (@{$self->{'css_src'}}) {
		if (ref $css_src_hr ne 'HASH') {
			err "Parameter 'css_src' must be a array of hash structures.";
		}
		foreach my $key (keys %{$css_src_hr}) {
			if (none { $key eq $_ } qw(link media)) {
				err "Parameter 'css_src' must be a array of hash ".
					"structures with 'media' and 'link' keys."
			}
		}
	}

	# Check charset.
	if (! defined $self->{'charset'}) {
		err "Parameter 'charset' is required.";
	}

	# Check for 'script_js' array.
	if (ref $self->{'script_js'} ne 'ARRAY') {
		err "Parameter 'script_js' must be a array.";
	}

	# Check for 'script_js_src' array.
	if (ref $self->{'script_js_src'} ne 'ARRAY') {
		err "Parameter 'script_js_src' must be a array.";
	}

	# Check for favicon.
	if (defined $self->{'favicon'} && $self->{'favicon'} !~ m/\.(ico|png|jpg|gif|svg)$/ms) {
		err "Parameter 'favicon' contain bad image type.";
	}

	# Object.
	return $self;
}

# Process 'Tags'.
sub process {
	my $self = shift;

	my $css;
	if ($self->{'css'}) {
		$css = $self->{'css'}->flush(1)."\n";
	}

	# Begin of page.
	$self->{'tags'}->put(
		['r', $self->{'doctype'}],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', $self->{'html_lang'}],
		['b', 'head'],
	);

	if (defined $self->{'http_equiv_content_type'}) {
		$self->{'tags'}->put(
			['b', 'meta'],
			['a', 'http-equiv', 'Content-Type'],
			['a', 'content', $self->{'http_equiv_content_type'}.
				'; charset='.$self->{'charset'}],
			['e', 'meta'],
		);
	}
	if (defined $self->{'base_href'}) {
		$self->{'tags'}->put(
			['b', 'base'],
			['a', 'href', $self->{'base_href'}],
			defined $self->{'base_target'} ? (
				['a', 'target', $self->{'base_target'}],
			) : (),
			['e', 'base'],
		);
	}
	if (! defined $self->{'http_equiv_content_type'}) {
		$self->{'tags'}->put(
			['b', 'meta'],
			['a', 'charset', $self->{'charset'}],
			['e', 'meta'],
		);
	}
	$self->_meta('application-name');
	$self->_meta('author');
	$self->_meta('description');
	$self->_meta('generator');
	$self->_meta('keywords');
	$self->_meta('robots');
	$self->_meta('viewport');
	if (defined $self->{'refresh'}) {
		$self->{'tags'}->put(
			['b', 'meta'],
			['a', 'http-equiv', 'refresh'],
			['a', 'content', $self->{'refresh'}],
			['e', 'meta'],
		);
	}

	$self->_favicon;

	if (@{$self->{'script_js'}}) {
		foreach my $script_js (@{$self->{'script_js'}}) {
			$self->{'tags'}->put(
				['b', 'script'],
				['a', 'type', 'text/javascript'],
				['d', $script_js],
				['e', 'script'],
			);
		}
	}
	if (@{$self->{'script_js_src'}}) {
		foreach my $script_js_src (@{$self->{'script_js_src'}}) {
			$self->{'tags'}->put(
				['b', 'script'],
				['a', 'type', 'text/javascript'],
				['a', 'src', $script_js_src],
				['e', 'script'],
			);
		}
	}

	$self->{'tags'}->put(
		['b', 'title'],
		['d', $self->{'lang'}->{'title'}],
		['e', 'title'],

		(
			$css ? (
				['b', 'style'],
				['a', 'type', 'text/css'],
				['d', $css],
				['e', 'style'],
			) : (),
		),
	);
	if (@{$self->{'css_src'}}) {
		foreach my $css_src_hr (@{$self->{'css_src'}}) {
			$self->{'tags'}->put(
				['b', 'link'],
				['a', 'rel', 'stylesheet'],
				['a', 'href', $css_src_hr->{'link'}],
				$css_src_hr->{'media'} ? (
					['a', 'media', $css_src_hr->{'media'}],
				) : (),
				['a', 'type', 'text/css'],
				['e', 'link'],
			);
		}
	}

	if (defined $self->{'rss'}) {
		$self->{'tags'}->put(
			['b', 'link'],
			['a', 'rel', 'alternate'],
			['a', 'type', 'application/rss+xml'],
			['a', 'title', 'RSS'],
			['a', 'href', $self->{'rss'}],
			['e', 'link'],
		);
	}

	$self->{'tags'}->put(
		['e', 'head'],
		['b', 'body'],
	);

	return;
}

sub _favicon {
	my $self = shift;

	if (! defined $self->{'favicon'}) {
		return;
	}

	my ($suffix) = $self->{'favicon'} =~ m/\.(ico|png|jpg|gif|svg)$/ms;
	my $image_type;
	if ($suffix eq 'ico') {
		$image_type = 'image/vnd.microsoft.icon';
	} elsif ($suffix eq 'png') {
		$image_type = 'image/png';
	} elsif ($suffix eq 'svg') {
		$image_type = 'image/svg+xml';
	} elsif ($suffix eq 'gif') {
		$image_type = 'image/gif';
	} else {
		$image_type = 'image/jpeg';
	}

	$self->{'tags'}->put(
		['b', 'link'],
		['a', 'rel', 'icon'],
		['a', 'href', $self->{'favicon'}],
		['a', 'type', $image_type],
		['e', 'link'],
	);

	return;
}

sub _meta {
	my ($self, $key) = @_;

	if (! defined $self->{$key}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'meta'],
		['a', 'name', $key],
		['a', 'content', $self->{$key}],
		['e', 'meta'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Page::Begin - Tags helper for HTML page begin.

=head1 SYNOPSIS

 use Tags::HTML::Page::Begin;

 my $obj = Tags::HTML::Page::Begin->new(%params);
 $obj->process;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Page::Begin->new(%params);

Constructor.

=over 8

=item * C<application-name>

Application name.

Default name is undef.

=item * C<author>

Author name.

Default value is undef.

=item * C<base_href>

Base link (<base href="https://skim.cz" />.

Default value is undef.

=item * C<base_target>

Base target.
It's used in if 'base_href' parameter exists.

Default value is undef.

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_src>

List of CSS link structures.

 Structure is something like:
 {
   'link' => '/foo.css',
   'media' => 'screen',
 }

Default value is [].

=item * C<charset>

Document character set.

Parameter is required.

Default value is 'UTF-8'.

=item * C<description>

Document description.

Default value is undef.

=item * C<doctype>

Document doctype string.

Default value is '<!DOCTYPE html>'.

=item * C<favicon>

Favorite icon image link.
Supported images are 'ICO', 'PNG', 'GIF', 'SVG' and 'JPG' files.

Default value is undef.

=item * C<generator>

Generator value.

Default value is 'Perl module: Tags::HTML::Page::Begin, Version: __MODULE_VERSION__'.

=item * C<html_lang>

HTML element lang attribute.
Creates html element in form: <html lang="en">

Default value is 'en'.

=item * C<http_equiv_content_type>

http-equiv content-type meta element.
If defined creates meta in form: <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
Unless defined creates meta in form: <meta charset="UTF-8" />

Defaut value is 'text/html'.

=item * C<keywords>

Document keywords.

Default value is undef.

=item * C<lang>

Hash with language information for output.
Keys are: 'title'.

Default value is reference to hash with these value:
 'title' => 'Page title'

=item * C<refresh>

Page refresh time in seconds.

Default value is undef.

=item * C<robots>

Robots meta.

Default value is undef.

=item * C<rss>

RSS link.

Default value is undef.

=item * C<script_js>

List of JavaScript scripts.

Default value is reference to blank array.

=item * C<script_js_src>

List of JavaScript links.

Default value is reference to blank array.

=item * C<tags>

'Tags::Output' object.

It's required.

Default value is undef.

=item * C<viewport>

Document viewport.

Default value is undef.

=back

=head2 C<process>

 $obj->process;

Process Tags structure for output.

Returns undef.

=head1 ERRORS

 new():
         Parameter 'css' must be a 'CSS::Struct::Output::*' class.
         Parameter 'css_src' must be a array.
         Parameter 'css_src' must be a array of hash structures.
         Parameter 'css_src' must be a array of hash structures with 'media' and 'link' keys.
         Parameter 'charset' is required.
         Parameter 'script_js' must be a array.
         Parameter 'script_js_src' must be a array.
         Parameter 'tags' must be a 'Tags::Output::*' class.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::Output::Indent;

 # Object.
 my $tags = Tags::Output::Indent->new(
         'preserved' => ['style'],
         'xml' => 1,
 );
 my $css = CSS::Struct::Output::Indent->new;
 my $begin = Tags::HTML::Page::Begin->new(
         'css' => $css,
         'tags' => $tags,
 );
 my $end = Tags::HTML::Page::End->new(
         'tags' => $tags,
 );

 # Process page
 $css->put(
        ['s', 'div'],
        ['d', 'color', 'red'],
        ['d', 'background-color', 'black'],
        ['e'],
 );
 $begin->process;
 $tags->put(
        ['b', 'div'],
        ['d', 'Hello world!'],
        ['e', 'div'],
 );
 $end->process;

 # Print out.
 print $tags->flush;

 # Output:
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
 #     <meta name="generator" content=
 #       "Perl module: Tags::HTML::Page::Begin, Version: 0.06" />
 #     <title>
 #       Page title
 #     </title>
 #     <style type="text/css">
 # div {
 # 	color: red;
 # 	background-color: black;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div>
 #       Hello world!
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::MoreUtils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Tags::HTML::Page::End>

Tags helper for HTML page end.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Page-Begin>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.10

=cut
