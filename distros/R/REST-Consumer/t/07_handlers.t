#! /usr/bin/env perl

use strict;
use warnings;

use REST::Consumer;
use HTTP::Response;
use LWP::UserAgent;
use Test::More tests => 13;
use Test::Resub qw(resub);
use JSON::XS;

my $flake_counter = 0;
my $rs = resub 'LWP::UserAgent::request' => sub {
	my $self = shift;
	my $http_request = shift;
	my %handlers = (
		'/conflict' => sub {
			my $response = HTTP::Response->new(409);
			my $content = JSON::XS::encode_json({
				code => 409,
				error => 'conflict and violence',
			});
			$response->content($content);
			$response->request($http_request);
			$response->content_type('application/json');
			return $response;
		},
		'/fail' => sub {
			my $response = HTTP::Response->new(500);
			$response->content( JSON::XS::encode_json({
				url => $http_request->uri->as_string
			}));
			$response->request($http_request);
			$response->content_type('application/json');
			return $response;
		},
		'/flake' => sub {
			$flake_counter = ($flake_counter + 1) % 4;
			if ($flake_counter) {
				# invocation 1,2,3,5,6,7...
				my $response = HTTP::Response->new(500);
				$response->request($http_request);
				$response->content_type('application/json');
				$response->content( JSON::XS::encode_json({status => 'failfailfail'}) );
				return $response;
			} else {
				my $response = HTTP::Response->new(200);
				$response->request($http_request);
				$response->content_type('application/json');
				$response->content( JSON::XS::encode_json({status => 'success'}) );
				return $response;
			}
		},
		'/404' => sub {
			my $response = HTTP::Response->new(404);
			$response->request($http_request);
			$response->content_type('application/json');
			return $response;
		},
		'/not_parseable' => sub {
			my $response = HTTP::Response->new(200);
			$response->request($http_request);
			$response->content_type('text/plain');
			$response->content('the json parser is a fink!');
			return $response;
		},
	);
		
	my $uri = $http_request->uri->as_string;
	$uri =~ s{^http://localhost}{};
	return ($handlers{$uri} || $handlers{'/404'})->();
};

REST::Consumer->configure({
	foo => {
		host    => 'localhost',
		retries => 0,
	},
});

{
	my $response;
	my %handlers = (
		409 => sub {
			my ($h) = @_;
			return "error: " . $h->parsed_response->{error};
		},
		'4xx' => sub {
		 	return "fallback bad-request error";
		},
	);
	my $service = REST::Consumer->service('foo');


	eval {
		$response = $service->post(
			path => '/conflict',
			handlers => \%handlers,
		);
	};
	my $exception = $@;
	is $exception, '', "there was no exception even though there was a 409";
	is $response, "error: conflict and violence",
		"the value returned from the handler is what you get from the POST";

	
	eval {
		$service->post(path => '/fail', handlers => \%handlers);
	};
	$exception = $@;
	ok $exception =~ m/500 Internal Server/,
		'handler for code 409 was bypassed on code 500';

	eval {
		$response = $service->post(path => '/404', handlers => \%handlers);
	};
	$exception = $@;
	is $exception, '', 'fallback to 4xx happened';
	is $response, 'fallback bad-request error', 'fallback to 4xx returned stuff';	
}


{
	my $response;
	eval {
		$response = REST::Consumer->service('foo')->post(
			path => '/fail',
			body => {
				foo => 'bar',
			},
			timeout => 5,
			handlers => {
				500 => sub {
					my ($handler_self) = @_;
					return $handler_self->default;
				},
			}
		);
	};
	my $exception = $@;
	isa_ok $exception, "REST::Consumer::RequestException",
		'resumes normal processing flow when you return $handler_self->default';
}


{
	# Retrying via automatic, then going to a handler
	my $response;
	my $flaky_post = sub {
		my (%args) = @_;
		REST::Consumer->service('foo')->post(
			path => '/flake', # succeeds every 4th request
			%args,
			
			handlers => {
				200 => sub {
					my ($h) = @_;
					return $h->parsed_response->{status};
				},
			}
		);
	};
	eval { $response = $flaky_post->(retry => 3) };
	my $exception = $@;
	is $exception, '', 'no exception because we retried!';
	is $response, 'success', 'we extracted the right status';

	eval { $response = $flaky_post->(retry => 2) };
	$exception = $@;
	isa_ok $exception, 'REST::Consumer::RequestException',
		'exception if we retried too many times';
}

{
	# Retrying via ->retry
	my $response;
	$rs->reset;
	eval {
		$response = REST::Consumer->service('foo')->post(
			path => '/404',

			retry => 10,
			handlers => {
				404 => sub { shift->retry }
			}
		);
	};
	my $exception = $@;
	isa_ok $exception, "REST::Consumer::RequestException",
		'->retry is not permission to loop forever';
	is $rs->called, 11, '->retry is limited by retry count'
}

# ->parsed_response
#   If you're a handler asking for a parsed response,
#   chances are you are in fact expecting a parsed response.
#   If you got back an unparsed response, your code would
#    not be happy.
#
#   So if your code's not happy, we should raise an exception,
#    saying that we couldn't get a parsed response. We shouldn't
#    wait until you try to access $actually_not_parsed->{field}
#    and blow up; that's lame and makes errors hard to track down.
{
	my $response;
	$rs->reset;
	eval {
		$response = REST::Consumer->service('foo')->post(
			path => '/not_parseable',

			retry => 1,
			handlers => {
				200 => sub {
					my ($h) = @_;
					return $h->parsed_response->{field_xyz};
					# if parsed_response returns a string,
					#  this code would raise "can't use string as a hash-ref".
					# Let's not raise that. Let's complain about the parseability
					# of the response.
				},
			}
		);
	};
	my $exception = $@;
	isa_ok $exception, "REST::Consumer::ResponseException",
		'We asked for a parsed response, but the response was unpareseable';
	
	is $rs->called, 1, 'do not retry on unparseable 200 codes';
}

# Future extensions:
# A handler named 'default'.
# Handlers named 'before' and 'after'.
#   (This might be tricky if things start getting thrown.)
# A strategy for code reuse in handlers.
#  (Perhaps handlers => 'Some::Snazzy::Class' or handlers => (object)?)
