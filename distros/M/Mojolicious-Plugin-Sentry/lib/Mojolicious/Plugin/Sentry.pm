package Mojolicious::Plugin::Sentry;

use Mojo::Base 'Mojolicious::Plugin';
use Sentry::Raven;

our $VERSION = 0.11;

has qw/sentry/;

sub register {
	my ($plugin, $app, $conf)  = @_;

	$plugin->sentry( Sentry::Raven->new(%$conf) );

	$app->helper(sentry => sub {
		$plugin->sentry;
	});

	$app->helper(sentryCaptureMessage => sub {
		my $self = shift;
		my $data = shift;
		my %p    = @_;

		if (ref $data eq 'Mojo::Exception') {
			my $req = $self->req;
			my ($filename, $lineno) = $data->message =~ /at\s+(.+?)\s+line\s+(\d+)/g;

			$plugin->sentry->capture_message(
				$data->message,
				$plugin->sentry->request_context(
					$req->url->to_string,
					method => $req->method,
					data   => $req->params->to_hash,
					headers => { map {$_ => ~~$req->headers->header($_)} @{$req->headers->names} },
				),
				$self->sentry->stacktrace_context([
					{
						filename     => $filename,
						lineno       => $data->line->[0],
						context_line => $data->line->[1],
						pre_context  => [
							map {$_->[1]}
							@{$data->lines_before}
						],
						post_context  => [
							map {$_->[1]}
							@{$data->lines_after}
						],
					}
				]),
				%p,
			);
		} else {
			$plugin->sentry->capture_message(
				$data,
				%p,
			);
		}
	});
}

1;

=pod
 
=head1 NAME

Mojolicious::Plugin::Sentry - A perl sentry client for Mojolicious

=head1 VERSION

version 0.1

=head1 SYNOPSIS

	# Mojolicious::Lite
	plugin 'sentry' => {
		sentry_dsn  => 'DSN',
		server_name => 'HOSTNAME',
		logger      => 'root',
		platform    => 'perl',
	};

	# Mojolicious with config
	$self->plugin('sentry' => {
		sentry_dsn  => 'DSN',
		server_name => 'HOSTNAME',
		logger      => 'root',
		platform    => 'perl',
	});

	# template: tmpl/exception.html.ep
	% sentryCaptureMessage $exception;

=head1 DESCRIPTION

Mojolicious::Plugin::Sentry is a plugin for the Mojolicious web framework which allow you use Sentry L<https://getsentry.com>.

See also L<Sentry::Raven|https://metacpan.org/pod/Sentry::Raven> for configuration parameters on init plugin and for use sentryCaptureMessage.

=head1 SEE ALSO

L<Sentry::Raven|https://metacpan.org/pod/Sentry::Raven>

=head1 SOURCE REPOSITORY

L<https://github.com/likhatskiy/Mojolicious-Plugin-Sentry>

=head1 AUTHOR

Alexey Likhatskiy, <likhatskiy@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 "Alexey Likhatskiy"

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
