package Plack::Middleware::AccessLog::Structured;
$Plack::Middleware::AccessLog::Structured::VERSION = '0.002000';
use parent qw(Plack::Middleware);

# ABSTRACT: Access log middleware which creates structured log messages

use strict;
use warnings;

use Carp;
use MRO::Compat;
use Time::Moment;
use Plack::Util::Accessor qw(logger callback extra_field);
use Net::Domain qw(hostname hostfqdn);
use JSON;


sub new {
	my ($class, $arg_ref) = @_;

	my $self = $class->next::method($arg_ref);
	if (defined $self->callback() && ref $self->callback() ne 'CODE') {
		croak("Passed 'callback' parameter must be a code reference");
	}
	if (defined $self->extra_field() && ref $self->extra_field() ne 'HASH') {
		croak("Passed 'extra_field' parameter must be a hash reference");
	}

	return $self;
}



sub call {
	my ($self, $env) = @_;

	my $t_before = Time::Moment->now_utc();
	my $res = $self->app->($env);

	return $self->response_cb($res, sub {
		my ($cb_res) = @_;

		my $t_after = Time::Moment->now_utc();
		my $h = Plack::Util::headers($cb_res->[1]);
		my $content_type = $h->get('Content-Type');
		my $log_entry = {
			class            => ref($self),
			# Request data
			remote_addr      => $env->{REMOTE_ADDR},
			request_method   => _safe($env->{REQUEST_METHOD}),
			request_uri      => _safe($env->{REQUEST_URI}),
			server_protocol  => $env->{SERVER_PROTOCOL},
			http_user_agent  => _safe($env->{HTTP_USER_AGENT}),
			http_host        => $env->{HTTP_HOST} || $env->{SERVER_NAME},
			http_referer     => $env->{HTTP_REFERER},
			remote_user      => $env->{REMOTE_USER},
			# Server information
			pid              => $$,
			hostfqdn         => hostfqdn(),
			hostname         => hostname(),
			# Response data
			response_status  => $cb_res->[0],
			content_length   => Plack::Util::content_length($cb_res->[2]) || $h->get('Content-Length'),
			content_type     => defined $content_type ? "$content_type" : undef,
			# Timing
			request_duration => ( $t_before->delta_microseconds($t_after) / 1000 ),
			date             => $t_before->strftime('%FT%T%3fZ'),
			epochtime        => $t_before->strftime('%s.%3N'),
		};

		if ($self->extra_field()) {
			for my $env_field (keys %{$self->extra_field}) {
				$log_entry->{$self->extra_field()->{$env_field}}
					= $env->{$env_field};
			}
		}

		if ($self->callback()) {
			$log_entry = $self->callback()->($env, $log_entry);
		}

		my $logger = $self->logger() || sub { $env->{'psgi.errors'}->print($_[0] . "\n") };
		$logger->(encode_json($log_entry));

		return;
	});
}


# Taken from Plack::Middleware::AccessLog
sub _safe {
	my ($string) = @_;
	$string =~ s/([^[:print:]])/"\\x" . unpack("H*", $1)/xeg
		if defined $string;
	return $string;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::AccessLog::Structured - Access log middleware which creates structured log messages

=head1 VERSION

version 0.002000

=head1 SYNOPSIS

	use Plack::Middleware::AccessLog::Structured;

	Plack::Middleware::AccessLog::Structured->wrap($app,
		callback    => sub {
			my ($env, $message) = @_;
			$message->{foo} = 'bar';
			return $message;
		},
		extra_field => {
			'some.application.field' => 'log_field',
			'some.psgi-env.field'    => 'another_log_field',
		},
	);

=head1 DESCRIPTION

Plack::Middleware::AccessLog::Structured is a L<Plack::Middleware|Plack::Middleware>
which creates and logs structured messages.

If the above example is used with a basic L<PSGI|PSGI> application that simply
returns C<ok>, the following, JSON-encoded message would be logged (on one log
line):

	{
		"remote_addr": "127.0.0.1",
		"request_method": "GET",
		"request_uri": "/",
		"server_protocol": "HTTP/1.1",
		"remote_user": null,
		"http_referer": null,
		"http_user_agent": "Mozilla/5.0 [...]",
		"request_duration": 0.0679492950439453,
		"epochtime": 1348687439.49608,
		"date": "2012-09-26T19:23:59.496Z",
		"hostfqdn": "some.hostname.tld",
		"hostname": "some",
		"http_host": "localhost:5000",
		"pid": 4777,
		"log_field": null,
		"another_log_field": null,
		"foo": "bar",
		"response_status": 200,
		"content_length": 2,
		"content_type": "text/plain",
		"class": "Plack::Middleware::AccessLog::Structured"
	}

=head1 METHODS

=head2 new

Constructor, creates new instance.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item callback

Optional callback that can be used to modify the log message before it is
encoded and logged. Gets the L<PSGI|PSGI> environment and the message as
parameters and must return the possibly modified message.

=item extra_field

Optional hash reference with a mapping from L<PSGI|PSGI> environment keys to
keys in the log message. If passed, values from the L<PSGI|PSGI> environment will
be copied to the corresponding fields in the log message, using this mapping.

=item logger

A callback to pass the JSON-encoded log messages to. By default, log messages
are printed to the C<psgi.errors> output stream.

=back

=head3 Result

A fresh instance of the middleware.

=head2 call

Specialized C<call> method.

=head1 SEE ALSO

=over

=item *

L<Plack::Middleware|Plack::Middleware>

=item *

L<Log::Message::Structured|Log::Message::Structured> which inspired some of the
fields in the log message.

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
