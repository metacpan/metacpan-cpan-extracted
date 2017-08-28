package Plack::Middleware::BasicStyle;

use 5.014000;
use strict;
use warnings;

use parent qw/Plack::Middleware/;

use HTML::Parser;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw/style any_content_type even_if_styled use_link_header/;

our $VERSION = '0.001001';
our $DEFAULT_STYLE = <<'EOF' =~ y/\n\t //rd;
<style>
  body {
    margin:40px auto;
    max-width: 650px;
    line-height: 1.6;
    font-size:18px;
    color:#444;
    padding:0 10px
  }

  h1,h2,h3 {
    line-height:1.2
  }
</style>
EOF

sub prepare_app {
	my ($self) = @_;
	$self->{link_header} =
	  sprintf '<%s>; rel=stylesheet', $self->use_link_header
	  if $self->use_link_header;
	$self->style($self->style // $DEFAULT_STYLE);
}

sub _content_type_ok {
	my ($self, $hdrs) = @_;
	return 1 if $self->any_content_type;
	my $content_type =
	  Plack::Util::header_get($hdrs, 'Content-Type');
	return '' unless $content_type;
	$content_type =~ m,text/html,is;
}

sub call { ## no critic (Complexity)
	my ($self, $env) = @_;
	if ($self->use_link_header) {
		my $req = Plack::Request->new($env);
		if (lc $req->path eq lc $self->use_link_header) {
			my $days30 = 30 * 86_400;
			my @hdrs = (
				'Content-Length' => length $self->style,
				'Content-Type'   => 'text/css',
				'Cache-Control'  => "max-age=$days30",
			);
			return [200, \@hdrs, [$self->style]]
		}
	}

	my $res = $self->app->($env);
	if (ref $res ne 'ARRAY'
		  || @$res < 3
		  || ref $res->[2] ne 'ARRAY' ) {
		$res
	} elsif (!$self->_content_type_ok($res->[1])) {
		$res
	} else {
		my ($styled, $html_end, $head_end, $doctype_end);
		my $parser_callback = sub {
			my ($tagname, $offset_end, $attr) = @_;
			$html_end //= $offset_end if $tagname eq 'html';
			$head_end //= $offset_end if $tagname eq 'head';
			$doctype_end //= $offset_end if $tagname eq 'doctype';
			$styled = 1 if $tagname eq 'style';
			$styled = 1 if $tagname eq 'link'
			  && ($attr->{rel} // '') =~ /stylesheet/is;
		};

		my $p = HTML::Parser->new(api_version => 3);
		$p->report_tags(qw/style link html head/);
		$p->handler(start => $parser_callback, 'tagname,offset_end,attr');
		$p->handler(declaration => $parser_callback, 'tagname,offset_end,attr');
		$p->parse($_) for @{$res->[2]};
		$p->eof;

		return $res if $styled && !$self->even_if_styled;

		if ($self->use_link_header) {
			push @{$res->[1]}, 'Link', $self->{link_header};
		} else {
			# If there's a <head>, put the style right after it
			# Otherwise, if there's a <html>, put the style right after it
			# Otherwise, if there's a <!DOCTYPE ...>, put the style right after it
			# Otherwise, put the style at the very beginning of the body
			if ($head_end || $html_end || $doctype_end) {
				my $body = join '', @{$res->[2]};
				my $pos = $head_end // $html_end // $doctype_end;
				substr $body, $pos, 0, $self->style;
				$res->[2] = [$body]
			} else {
				unshift @{$res->[2]}, $self->style
			}
		}

		$res
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::BasicStyle - Add a basic <style> element to pages that don't have one

=head1 SYNOPSIS

  # Basic usage (all default options)
  use Plack::Builder;
  builder {
    enable 'BasicStyle';
    ...
  }

  # Default options set explicitly
  use Plack::Builder;
  builder {
    enable 'BasicStyle',
      style => $Plack::Middleware::BasicStyle::DEFAULT_STYLE,
      any_content_type => '',
      even_if_styled   => '',
      use_link_header  => '';
    ...
  }

  # Custom options
  use Plack::Builder;
  builder {
    enable 'BasicStyle',
      style => '<style>body { background-color: #ddd }</style>',
      any_content_type => 1,
      even_if_styled   => 1,
      use_link_header  => '/basic-style.css';
    ...
  }

=head1 DESCRIPTION

Plack::Middleware::BasicStyle is a Plack middleware that adds a basic
<style> element to HTML pages that do not have a stylesheet.

The default style, taken from
L<http://bettermotherfuckingwebsite.com>, is (before minification):

  <style>
    body {
      margin:40px auto;
      max-width: 650px;
      line-height: 1.6;
      font-size:18px;
      color:#444;
      padding:0 10px
    }

    h1,h2,h3 {
      line-height:1.2
    }
  </style>

The middleware takes the following arguments:

=over

=item B<style>

This is the HTML fragment that will be added to unstyled pages.

It defaults to the value of
C<< $Plack::Middleware::BasicStyle::DEFAULT_STYLE >>.

=item B<any_content_type>

If true, don't check whether Content-Type contains C<text/html>.

If false (default), passes the response through unchanged if the
Content-Type header is unset or does not contain the case-insensitive
substring C<text/html>.

=item B<even_if_styled>

If true, don't check whether the response already includes a <style>
or <link ... rel="stylesheet"> element.

If false (default), passes the response through unchanged if the
response includes a <style> or <link ... rel="stylesheet"> element.

=item B<use_link_header>

If false or unset (default), the given HTML fragment will be added
right after the <head> start tag (if this exists), right after the
<html> start tag (if this exists but <head> doesn't), or at the
beginning of the document (if neither <html> nor <head> exists).

If set, its value is interpreted as an URL path. The body of the
response will not be modified, instead a C<Link:> HTTP header will be
added to unstyled pages. Additionally, the middleware will intercept
requests to that exact URL path and return the style (with status 200,
a Content-Type of C<text/css>, a correct Content-Length header, and a
Cache-Control header instructing the browser to cache the style for 30
days).

Setting this makes the module more resilient to bugs and more
efficient at the cost of asking the client to make an extra request.
Therefore setting this argument is B<recommended>.

=back

=head1 CAVEATS

This middleware only works with simple (non-streaming) responses,
where the body is an arrayref.

In other words, responses where the body is an IO::Handle, or
streaming/delayed responses are NOT supported and will be passed
through unchanged by this middleware.

=head1 SEE ALSO

L<http://bettermotherfuckingwebsite.com>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
