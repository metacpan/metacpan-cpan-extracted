package REST::Consumer::Dispatch;

use strict;
use warnings;

use REST::Consumer::HandlerInvocation;

# While the code functions as a dispatcher,
#   I'd like the object to represent an individual dispatch,
#   and have notions about its retry count which can safely change.

sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	$self->initialize(%args);
	return $self;
}

sub initialize {
	my ($self, %args) = @_;
	$self->{$_} = $args{$_} for qw(handlers default_is_raw debugger);
	$self->{debugger} ||= sub {};
}

sub handlers_for_code {
	my ($self, $code) = @_;
	my $metacode = substr($code, 0, 1) . 'xx'; # e.g. 4xx
	
	return grep { defined }  (
		$self->user_handler($code),
		$self->user_handler($metacode),
		$self->fallback_handler($code),
	);
}

sub user_handler {
	my ($self, $code) = @_;
	return $self->{handlers}{$code};
}

sub handle_response {
	my ($self, %args) = @_;
	my $response = $args{response};
	my $request = $args{request};
	my $attempt_no = $args{attempt};

	my @args = (REST::Consumer::HandlerInvocation->new(
		request => $request,
		response => $response,
		attempt => $attempt_no,
		debugger => $self->{debugger},
	));
	my $code = $response->code;
	my @handlers = $self->handlers_for_code($code);
	while (my $attempt = shift @handlers) {
		my @results = $attempt->(@args);
		if ($self->is_magic_operation($results[0], 'default')) {
			next;
		} elsif ($self->is_magic_operation($results[0], 'retry')) {
			return ('retry', $results[0]);
		} elsif ($self->is_magic_operation($results[0], 'fail')) {
			return ('fail', $results[0]);
		} else {
			return ('succeed', \@results);
		}
	}
	die "the fallback handler didn't catch us. who broke it?";
}

sub is_magic_operation {
	# Herein we solve the semi-predicate problem
	# by coming up with a predicate that is implausible
	my ($self, $candidate_magic, $operation) = @_;
	return ref $candidate_magic && UNIVERSAL::can($candidate_magic, "rest_consumer_should_${operation}");
}
	
sub fallback_handler {
	my ($self, $code) = @_;
	
	return sub {
		my ($h) = @_;
		if ($h->response->is_success) {
			if ($self->{default_is_raw}) {
				return $h->response;
			} elsif ($h->response_parseable) {
				return $h->parsed_response;
			} else {
				return $h->response_body;
			}
		}
		my $ought_retry = !(scalar grep {$h->response->code() == $_} qw(403 404 405 413));
		if ($ought_retry) {
			return $h->retry;
		} else {
			return $h->fail;
		}
	}
}

sub debug {
	shift->{debugger}->(@_);
}

1;
