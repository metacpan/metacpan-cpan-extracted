package REST::Consumer::ResponseException;
use strict;
use warnings;

use base qw(REST::Consumer::Exception);
	
sub as_string {
	my $self = shift;
	return sprintf("Response not in expected format: %s %s -- %s at %s\n",
		$self->{request}->method,
		$self->{request}->uri->as_string,
		$self->{response}->status_line,
		$self->{_immediate_caller},
	);
}

1;
