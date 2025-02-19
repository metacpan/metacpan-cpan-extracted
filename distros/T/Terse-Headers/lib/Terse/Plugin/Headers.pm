package Terse::Plugin::Headers;

use base 'Terse::Plugin';

sub build_plugin {
	my ($self) = @_;
	$self->default_headers = {
		'Strict-Transport-Sercurity' => 'max-age=3600',
		'X-Content-Security-Policy' => "default-src 'self'",
		'X-Content-Type-Options' => 'nosniff',
		'X-Download-Options' => 'noopen',
		'X-XSS-Protection' => 1,
		'Server' => 'guess',
		'Cache-Control' => 'no-cache, no-store',
		'Pragma' => 'no-cache'
	};
	return $self;
}

sub set {
	my ($self, $t, %headers) = @_;
	$t->headers({
		%{ $self->default_headers },
		%headers
	});
	return $self;
}

1;

=head1 NAME

Terse::Plugin::Headers - Terse headers

=cut

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	package MyApp::Plugin::Headers;

	use base 'Terse::Plugin::Headers';

	1;

	package MyApp;

	use base 'Terse::App';

	sub auth {
		my ($self, $context) = @_;
		if ($context->req) { # second run through of the auth sub routine
			$context->plugin('headers')->set($context, %headers);
		}
	}

	1;

=cut

=head1 LICENSE AND COPYRIGHT
 
L<Terse::Static>.
 
=cut
