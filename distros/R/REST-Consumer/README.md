# REST::Consumer

A general-purpose client for interacting with RESTful HTTP services

### Synopsis

This module provides an interface that encapsulates building an http request, sending, and parsing responses.  It also retries on failed requests and has configurable timeouts.

### Usage

First configure the REST::Consumer class. This only needs to be done once per process and the results will be cached in a file. You can then refer to the service by name.

	REST::Consumer->configure('http://somewhere.com/consumer/config');

And / or:

	REST::Consumer->configure({
		'google-calendar' => {
			url => 'https://apps-apis.google.com',
		},
		'google-accounts' => {
			url => 'https://accounts.google.com',
		},
	});

Then later:

	my $media = REST::Consumer->service('google-calendar')->get(
		path => '/users/me/calendarList',
		timeout => 5,
		retry => 5,
	);

	use Data::Dumper;
	print Dumper($media);


Example Using Authentication:

	my $client = REST::Consumer->new(
		host => 'service.shuttercorp.net',
		auth => {
			type => 'basic',
			username => 'mrbigglesworth',
			password => 'cupcake',
		}
	)
	
	
	$client->get(
		path => ....
		params => {...}
	)	


Example Using Handlers:

	my $result = $client->post(
		path => '/foo',
	  ...
		handlers => {
			409 => sub {
				my ($h) = @_;
				if ($h->response_parseable) {
					my $conflicting_user = $h->parsed_response->{user};
					# ->parsed_response will raise an error if the response
					#   is not in fact the sort of thing that could be parsed
					#   (e.g. a flat string)
					return "conflict with $conflicting_user";
				}
				return $h->default;
				# resume normal flow (retries, etc)
			},
			420 => sub {
				# Twitter's custom 'enhance your calm' rate limit
				my ($h) = @_;
				# (assuming your code has a $self->logger capability)
				$self->logger->warn("service is rate-limiting us with drug references");
				return $h->retry; # explicit retry is also available (respects retry limit)
			},
			4xx => sub {
				my ($h) = @_;
				# (assuming your code has a $self->logger capability)
				$self->logger->critical("Bad request! Response body: %s", $h->response_body);
				die "IncompetentProgrammerException";
			},
		}
	);

	# $result contains the parsed response, or the string "conflict with <user>",
	# or it dies with an IncompetentProgrammerException.
