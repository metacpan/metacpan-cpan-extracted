
package MyConText::URL;
use MyConText::String;
use strict;
use vars qw! @ISA !;
@ISA = qw! MyConText::String !;

use LWP::UserAgent;

sub index_document {
	my ($self, $uri) = @_;
	my $ua = ( defined $self->{'user_agent'}
		? $self->{'user_agent'}
		: $self->{'user_agent'} = new LWP::UserAgent );

	my $request = new HTTP::Request('GET', $uri);
	my $response = $ua->simple_request($request);
	if ($response->is_success) {
		return $self->SUPER::index_document($uri, $response->content);
		}
	else {
		$self->{'errstr'} = $response->message;
		}
	return;
	}

1;

