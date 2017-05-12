package Test::Net::SAJAX::UserAgent;

use strict;
use warnings 'all';


use HTTP::Response;
use Test::MockObject;
use URI;
use URI::Escape (); # No imports
use URI::QueryParam;

sub new {
	my ($class) = @_;

	# Create a fake UA using a mock object
	my $fake_ua = Test::MockObject->new;

	# Set the fake methods
	$fake_ua->mock(get     => \&get);
	$fake_ua->mock(post    => \&post);
	$fake_ua->mock(request => \&request);

	# Set the fake inheritance for the UA
	$fake_ua->set_isa('LWP::UserAgent');

	return $fake_ua;
}

sub get {
	my ($self, $url) = @_;

	# Get the called function name
	my $function  = $url->query_param('rs');
	my @arguments = $url->query_param('rsargs[]');
	my $target_id = $url->query_param('rst');
	my $rand_key  = $url->query_param('rsrnd');

	# Change URL into a URI object
	$url = URI->new($url);

	return _process_request(
		function  => $function,
		arguments => \@arguments,
		target_id => $target_id,
		rand_key  => $rand_key,
		url       => $url,
		method    => 'GET',
	);
}

sub post {
	my ($self, $url, $post_data) = @_;

	# Get the called function name
	my $function  = $post_data->{rs};
	my $arguments = $post_data->{'rsargs[]'};

	return _process_request(
		function  => $function,
		arguments => $arguments,
		url       => $url,
		method    => 'POST',
	);
}

sub request {
	my ($self, $request) = @_;

	# The function to redirect to
	my $handle_request = sub {
		die sprintf 'Cannot handle %s request', $request->method;
	};

	if ($request->method eq 'GET') {
		# Forward to GET mocker
		$handle_request = sub { return $self->get($request->uri); };
	}
	elsif ($request->method eq 'POST') {
		# Forward to POST mocket
		$handle_request = sub {
			# Get the key pairs from the content
			my %content = map {
				URI::Escape::uri_unescape($_)
			} map {
				split m{=}msx
			} split m{&}msx, $request->decoded_content;

			return $self->post($request->uri, \%content);
		};
	}

	# Forward the request
	return $handle_request->();
}

sub _process_request {
	my %args = @_;

	my ($function, $method) = @args{qw(function method)};

	my $call = __PACKAGE__->can("_any_$function");

	if (!defined $call) {
		if ($method eq 'POST') {
			$call = __PACKAGE__->can("_post_$function");
		}
		else {
			$call = __PACKAGE__->can("_get_$function");
		}
	}

	if (!defined $call) {
		return HTTP::Response->new(200, 'OK', undef, "-:$function not callable");
	}

	my $data = eval { $call->(%args) };

	if ($@) {
		return HTTP::Response->new(200, 'OK', undef, "-:Perl error occurred: $@");
	}

	if (ref $data ne 'HASH') {
		return HTTP::Response->new(200, 'OK', undef, sprintf '+:%s', $data);
	}
	elsif (!exists $data->{response}) {
		return HTTP::Response->new(200, 'OK', undef, sprintf '+:%s', $data->{data});
	}

	return $data->{response};
}


sub _any_Echo {
	my %args = @_;

	my @arguments = @{$args{arguments}};

	if (!@arguments) {
		die 'Nothing supplied to Echo';
	}

	return {
		response => HTTP::Response->new(200, 'OK', undef, $arguments[0]),
	};
}
sub _any_EchoRandKey {
	my %args = @_;

	# Get the target id of the request
	my $rand_key = $args{rand_key};

	return {
		response => HTTP::Response->new(200, 'OK', undef, "+:var res = '$rand_key'; res;"),
	};
}
sub _any_EchoStatus {
	my %args = @_;

	my @arguments = @{$args{arguments}};

	my $status = 200;

	if (@arguments) {
		$status = $arguments[0];
	}

	return {
		response => HTTP::Response->new($status, '?????', undef, "+:var res = $status; res;"),
	};
}
sub _any_EchoTargetId {
	my %args = @_;

	# Get the target id of the request
	my $target_id = $args{target_id};

	return {
		response => HTTP::Response->new(200, 'OK', undef, "+:var res = '$target_id'; res;"),
	};
}
sub _any_EchoUrl {
	my %args = @_;

	my $url = $args{url};

	return {
		response => HTTP::Response->new(200, 'OK', undef, "+:var url = '$url'; url;"),
	};
}
sub _any_GetNumber {
	my %args = @_;

	my @arguments = @{$args{arguments}};

	my $number = int(rand(100));

	if (@arguments) {
		$number = $arguments[0];
	}

	return $number;
}

1;
