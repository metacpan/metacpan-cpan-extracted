package REST::Consumer::HandlerInvocation;

use strict;
use warnings;

use REST::Consumer::ResponseException;

# This is an object which is passed to a coderef in the handlers => {}
# hash. It represents an invocation of a particular response-code handler.
#
# Your code should never need to instantiate this class itself.
sub new {
	my ($class, %args) = @_;
	my $self = (bless {%args} => $class);
	$self->{debugger} ||= sub {};
	return $self;
}

# Here are elments of the public API:
# Magic values your code can return to change the execution flow:
sub default {
	my ($self) = @_;
	return REST::Consumer::HandlerFlow::Default->new;
}
sub retry {
	my ($self) = @_;
	return REST::Consumer::HandlerFlow::Retry->new(
		request => $self->request,
		response => $self->response,
		attempt => $self->attempt,
	);
}
sub fail {
	my ($self) = @_;
	return REST::Consumer::HandlerFlow::Fail->new(
		request => $self->request,
		response => $self->response,
		attempt => $self->attempt,
	);
}


# Accessors that can provide information to your handler:
sub request { shift->{request} }
sub response { shift->{response} }
sub attempt { shift->{attempt} } # e.g. attempt #2

# ->parsed_response throws an exception if the response is not parseable.
# You might want to ask whether ->response_parseable.
sub parsed_response {
	my ($self) = @_;
	$self->attempt_content_deserialization;
	unless ($self->{response_parseable}) {
		REST::Consumer::ResponseException->throw(
			request  => $self->{request},
			response => $self->{response},
			attempts => $self->{attempt},
		 );
	}
	return $self->{parsed_response};
}

# True iff the response was parseable.
sub response_parseable {
	my ($self) = @_;
	$self->attempt_content_deserialization;
	return $self->{response_parseable};
}

# This is never parsed, but it is decoded.
sub response_body {
	my ($self) = @_;
	$self->attempt_content_deserialization;
	return $self->{response_body};
}


# This is a private API. Do not invoke.
sub attempt_content_deserialization {
	my ($self) = @_;
	return if exists $self->{response_body};
	$self->{response_body} = $self->response->decoded_content();

	# parse response content, if present
	my $response_content;
	my $content_type = $self->response->header('Content-Type');
	if ($content_type && $content_type =~ m|.+/json|) {
		eval {
			$self->{parsed_response} = JSON::XS::decode_json($self->response->decoded_content() );
			$self->{response_parseable} = 1;
			1;
		} or do {
			# might or might not be an error.  e.g. if content is empty or is just a string
			$self->debug(sprintf("failed to parse json response: %s\n%s\n",
				$self->{response_body},
				$@,
			));
			$self->{response_parseable} = 0;
		};
	};
}

sub debug {
	shift->{debugger}->(@_);
}

# These are part of a private API. You should not instantiate them.
# Instead access them in the scope of a handler like so:
# 4xx => sub {
#   my ($h) = @_;
#   return $h->default; # or
#   return $h->retry;   # or
#   return $h->fail;
# }
package REST::Consumer::HandlerFlow::Base;
sub new {
	my ($self, %args) = @_;
	return bless {%args} => $self;
}

sub throw {
	my ($self) = @_;
	REST::Consumer::RequestException->throw(
		request  => $self->{request},
		response => $self->{response},
		attempts => $self->{attempt},
	 );
}


package REST::Consumer::HandlerFlow::Default;
use base qw(REST::Consumer::HandlerFlow::Base);
sub rest_consumer_should_default { 1 }

package REST::Consumer::HandlerFlow::Retry;
use base qw(REST::Consumer::HandlerFlow::Base);
sub rest_consumer_should_retry { 1 }

package REST::Consumer::HandlerFlow::Fail;
use base qw(REST::Consumer::HandlerFlow::Base);
sub rest_consumer_should_fail { 1 }

1;
