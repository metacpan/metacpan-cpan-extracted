package REST::Consumer::RequestException;

use strict;
use warnings;
use base qw(REST::Consumer::Exception);

sub as_string {
	my $self = shift;
	my $attempts = (($self->{attempts} || 0) >= 2) ? " after $self->{attempts} attempts" : '';
	return sprintf("Request Failed$attempts: %s %s -- %s at %s\n",
		$self->{request}->method,
		$self->{request}->uri->as_string,
		$self->{response}->status_line,
		$self->{_immediate_caller},
	);
}

1;
