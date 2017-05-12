package Plack::Middleware::JSON::ForBrowsers;
{
  $Plack::Middleware::JSON::ForBrowsers::VERSION = '0.002000';
}
use parent qw(Plack::Middleware);

# ABSTRACT: Plack middleware which turns application/json responses into HTML

use strict;
use warnings;
use Carp;
use JSON;
use MRO::Compat;
use Plack::Util::Accessor qw(json html_head html_foot);
use List::MoreUtils qw(any);
use Encode;
use HTML::Entities qw(encode_entities_numeric);


chomp(my $html_head = <<'EOHTML');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>JSON::ForBrowsers</title>
		<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
		<style type="text/css">
			html, body {
				padding: 0px;
				margin: 0px;
			}
			pre {
				background-color: #FAFAFA;
				border: 1px solid #E9E9E9;
				padding: 4px;
				margin: 12px;
			}
		</style>
	</head>
	<body>
		<pre><code>
EOHTML

(my $html_foot = <<'EOHTML') =~ s/^\s+//x;
		</code></pre>
	</body>
</html>
EOHTML

my @json_types = qw(application/json);
my @html_types = qw(text/html application/xhtml+xml);



sub new {
	my ($class, $arg_ref) = @_;

	my $self = $class->next::method($arg_ref);
	$self->json(JSON->new()->utf8()->pretty());

	unless (defined $self->html_head()) {
		$self->html_head($html_head);
	}
	unless (defined $self->html_foot()) {
		$self->html_foot($html_foot);
	}

	return $self;
}



sub call {
	my($self, $env) = @_;

	my $res = $self->app->($env);

	unless ($self->looks_like_browser_request($env)) {
		return $res;
	}

	return $self->response_cb($res, sub {
		my ($cb_res) = @_;

		my $h = Plack::Util::headers($cb_res->[1]);
		# Ignore stuff like '; charset=utf-8' for now, just assume UTF-8 input
		if (any { index($h->get('Content-Type'), $_) >= 0 } @json_types) {
			$h->set('Content-Type' => 'text/html; charset=utf-8');

			my $json = '';
			my $seen_last = 0;
			return sub {
				if (defined $_[0]) {
					$json .= $_[0];
					return '';
				}
				else {
					if ($seen_last) {
						return;
					}
					else {
						$seen_last = 1;
						return $self->json_to_html($json);
					}
				}
			};
		}
		return;
	});
}



sub looks_like_browser_request {
	my ($self, $env) = @_;

	if (defined $env->{HTTP_X_REQUESTED_WITH}
			&& $env->{HTTP_X_REQUESTED_WITH} eq 'XMLHttpRequest') {
		return 0;
	}

	if (defined $env->{HTTP_ACCEPT}
			&& any { index($env->{HTTP_ACCEPT}, $_) >= 0 } @html_types) {
		return 1;
	}

	return 0;
}



sub json_to_html {
	my ($self, $json) = @_;

	my $pretty_json_string = decode(
		'UTF-8',
		$self->json()->encode(
			$self->json()->decode($json)
		)
	);
	chomp $pretty_json_string;
	return encode(
		'UTF-8',
		$self->html_head()
			. encode_entities_numeric($pretty_json_string) .
		$self->html_foot()
	);
}


1;


__END__
=pod

=head1 NAME

Plack::Middleware::JSON::ForBrowsers - Plack middleware which turns application/json responses into HTML

=head1 VERSION

version 0.002000

=head1 SYNOPSIS

Basic Usage:

	use Plack::Builder;

	builder {
		enable 'JSON::ForBrowsers';
		$app;
	};

Combined with L<Plack::Middleware::Debug|Plack::Middleware::Debug>:

	use Plack::Builder;

	builder {
		enable 'Debug';
		enable 'JSON::ForBrowsers';
		$app;
	};

Custom HTML head and foot:

	use Plack::Builder;

	builder {
		enable 'JSON::ForBrowsers' => (
			html_head => '<pre><code>',
			html_foot => '</code></pre>',
		);
		mount '/'  => $json_app;
	};

=head1 DESCRIPTION

Plack::Middleware::JSON::ForBrowsers turns C<application/json> responses
into HTML that can be displayed in the web browser. This is primarily intended
as a development tool, especially for use with
L<Plack::Middleware::Debug|Plack::Middleware::Debug>.

The middleware checks the request for the C<X-Requested-With> header - if it
does not exist or its value is not C<XMLHttpRequest> and the C<Accept> header
indicates that HTML is acceptable, it will wrap the JSON from an C<application/json>
response with HTML and adapt the content type accordingly.

This behaviour should not break clients which expect JSON, as they still I<do>
get JSON. But when the same URI is requested with a web browser, HTML-wrapped
and pretty-printed JSON will be returned, which can be displayed without external
programs or special extensions.

=head1 METHODS

=head2 new

Constructor, creates a new instance of the middleware.

=head3 Parameters

This method expects its parameters as a hash or hash reference.

=over

=item html_head

String that will be prefixed to the prettified JSON instead of the default HTML
head. If passed, it must be a UTF-8-encoded character string.

=item html_foot

String that will be appended to the prettified JSON instead of the default HTML
foot. If passed, it must be a UTF-8-encoded character string.

=back

=head2 call

Specialized C<call> method. Expects the response body to contain a UTF-8 encoded
byte string.

=head2 looks_like_browser_request

Tries to decide if a request is coming from a web browser. Uses the C<Accept>
and C<X-Requested-With> headers for this decision.

=head3 Parameters

This method expects positional parameters.

=over

=item env

The L<PSGI|PSGI> environment.

=back

=head3 Result

C<1> if it looks like the request came from a browser, C<0> otherwise.

=head2 json_to_html

Takes a UTF-8 encoded JSON byte string as input and turns it into a UTF-8
encoded HTML byte string, with HTML entity encoded characters to avoid XSS.

=head3 Parameters

This method expects positional parameters.

=over

=item json

The JSON byte string.

=back

=head3 Result

The JSON wrapped in HTML.

=head1 SEE ALSO

=over

=item *

L<Plack::Middleware|Plack::Middleware>

=item *

L<Plack::Middleware::Debug|Plack::Middleware::Debug>

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

