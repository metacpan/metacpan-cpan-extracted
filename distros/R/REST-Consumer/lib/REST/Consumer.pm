package REST::Consumer;
# a generic client for talking to restful web services

use strict;
use warnings;

use Carp qw(cluck);
use LWP::UserAgent::Paranoid;
use URI;
use JSON::XS;
use HTTP::Request;
use HTTP::Headers;
use File::Path qw( mkpath );
use REST::Consumer::Dispatch;
use REST::Consumer::RequestException;
use REST::Consumer::PermissiveResolver;
use Time::HiRes qw(usleep);

our $VERSION = '1.02';

my $global_configuration = {};
my %service_clients;
my $data_path = $ENV{DATA_PATH} || $ENV{TMPDIR} || '/tmp';
my $throw_exceptions = 1;

# make sure config gets loaded from url every 5 minutes
my $config_reload_interval = 60 * 5;

sub throw_exceptions {
	my ($class, $value) = @_;
	$throw_exceptions = $value if defined $value;
	return $throw_exceptions;
}

sub configure {
	my ($class, $config, @args) = @_;
	if (!ref $config) {
		if ($config =~ /^https?:/) {
			# if the config is a scalar that starts with http:, assume it's a url to fetch configuration from
			my $uri = URI->new($config);
			my ($dir, $filename) = _config_file_path($uri);

			my @stat = stat("$dir/$filename");
			my $age_in_seconds = time - $stat[9];

			$config = load_config_from_file("$dir/$filename", \@stat);

			# reload config from url if it's older than 10 minutes
			if (!$config || ($age_in_seconds && $age_in_seconds > $config_reload_interval)) {
				my $client = $class->new( host => $uri->host, port => $uri->port );
				$config = $client->get( path => $uri->path );

				# try to cache config loaded from a url to a file for fault tolerance
				write_config_to_file($uri, $config);
			}
		} else {
			# otherwise it's a filename
			my $path = $config;
			$config = load_config_from_file($path);
		}
	}

	if (ref $config ne 'HASH') {
		die "Invalid configuration. It should either be a hashref or a url or filename to get config data from";
	}

	for my $key (keys %$config) {
		$global_configuration->{$key} = _validate_client_config($config->{$key});
	}

	return 1;
}

sub _config_file_path {
	my ($uri) = @_;
	my $cache_filename = $uri->host . '-' . $uri->port . $uri->path . '.json';
#	$cache_filename =~ s/\//-/g;
	my ($dir, $filename) = $cache_filename =~ /(.*)\/([^\/]*)/i;
	return ("$data_path/rest-consumer/config/$dir", $filename);
}

sub load_config_from_file {
	my ($path, $stat) = @_;
	my @stat = $stat || stat($path);
	return if !-e _ || !-r _;

	undef $/;
	open my $config_fh, $path or die "Couldn't open config file '$path': $!";

	my $data = <$config_fh>;
	my $decoded_data = JSON::XS::decode_json($data);
	close $config_fh;
	return $decoded_data;
}

sub write_config_to_file {
	my ($url, $config) = @_;
	my ($dir, $filename) = _config_file_path($url);

	eval { mkpath($dir) };
	if ($@) {
		warn "Couldn’t create make directory for rest consumer config $dir: $@";
		return;
	}

#	if (!-w "$dir/$filename") {
#		warn "Can't write config data to: $dir/$filename - not caching rest consumer config data";
#		return;
#	}

	open my $cache_file, '>', "$dir/$filename"
		or die "Couldn't open config file for write '$dir/$filename': $!";

	print $cache_file JSON::XS::encode_json($config);
	close $cache_file;
}

sub service {
	my ($class, $name) = @_;
	return $service_clients{$name} if defined $service_clients{$name};

	die "No service configured with name: $name"
		if !exists $global_configuration->{$name};

	$service_clients{$name} = $class->new(%{$global_configuration->{$name}});
	return $service_clients{$name};
}

sub _validate_client_config {
	my ($config) = @_;
	my $valid = {
		host       => $config->{host},
		url        => $config->{url},
		port       => $config->{port},
		(defined $config->{ua} ? (ua => $config->{ua}) : ()),

		# timeout on requests to the service
		timeout => $config->{timeout} || 10,

		# retry this many times if we don't get a 200 response from the service
		retry   => exists $config->{retry} ? $config->{retry} : exists $config->{retries} ? $config->{retries} : 0,

		# delay by this many ms before every retry 
		retry_delay   => $config->{retry_delay} || 0, 

		# print some extra debugging messages
		verbose => $config->{verbose} || 0,

		# enable persistent connection
		keep_alive => $config->{keep_alive} || 1,

		agent => $config->{user_agent} || "REST-Consumer/$VERSION",

		auth => $config->{auth} || {},
	};

	if (!$valid->{host} and !$valid->{url}) {
		die "Either host or url is required";
	}

	return $valid;
}

sub new {
	my ($class, @args) = @_;
	my $args = {};
	if (scalar @args == 1 && !ref $args[0]) {
		$args->{url} = $args[0];
	} else {
		$args = { @args };
	}
	my $self = _validate_client_config($args);
	bless $self, $class;
	return $self;
}

sub host {
	my ($self, $host) = @_;
	$self->{host} = $host if defined $host;
	return $self->{host};
}

sub port {
	my ($self, $port) = @_;
	$self->{port} = $port if defined $port;
	return $self->{port};
}

sub timeout {
	my ($self, $timeout) = @_;
	if (defined $timeout) {
		$self->{timeout} = $timeout;
		$self->apply_timeout($self->{_user_agent}) if $self->{_user_agent};
	}
	return $self->{timeout};
}

sub retry {
	my ($self, $retry) = @_;
	$self->{retry} = $retry if defined $retry;
	return $self->{retry};
}

sub retry_delay {
	my ($self, $retry_delay) = @_;
	$self->{retry_delay} = $retry_delay if defined $retry_delay;
	return $self->{retry_delay};
}

sub keep_alive {
	my ($self, $keep_alive) = @_;
	if (defined $keep_alive) {
		$self->{keep_alive} = $keep_alive;
		$self->apply_keep_alive($self->{_user_agent}) if $self->{_user_agent};
	}
	return $self->{keep_alive};
}

sub agent {
	my ($self, $agent) = @_;
	if (defined $agent) {
		$self->{agent} = $agent;
		$self->apply_agent($self->{_user_agent}) if $self->{_user_agent};
	}
	return $self->{agent};
}

sub last_request {
	my ($self) = @_;
	return $self->{_last_request};
}

sub last_response {
	my ($self) = @_;
	return $self->{_last_response};
}

sub get_user_agent { user_agent(@_) }

sub apply_timeout {
	my ($self, $ua) = @_;
	if ($ua->can('request_timeout')) {
		# $ua is a LWP::UserAgent::Paranoid or some other thing that honors request_timeout
		$ua->request_timeout($self->timeout);
	} else {
		# $ua is vanilla LWP or a subclass, use the inferior timeout method
		$ua->timeout($self->timeout);
	}
}

sub apply_agent {
	my ($self, $ua) = @_;
	$ua->agent($self->agent);
}

sub apply_keep_alive {
	my ($self, $ua) = @_;
	if ($ua->can('keep_alive')) {
		# $ua is some well-behaved user-provided object
		$ua->keep_alive($self->keep_alive);
	} elsif ($ua->can('conn_cache')) {
		# $ua is an LWP::UserAgent - unfortunately there's no ->keep_alive method exposed by LWP::UserAgent,
		# so we just do what its constructor does to set up keep-alive.
		if ($self->keep_alive) {
			$ua->conn_cache({total_capacity => $self->keep_alive});
		} else {
			$ua->conn_cache(undef);
		}
	} else {
		# no clue how to handle things; sorry charlie.
		cluck "Don't know how to make a user-specified user agent object of type ${\ref($ua)} honor your keep_alive request.\n";
	}
}


sub user_agent {
	my $self = shift;
	return $self->{_user_agent} if defined $self->{_user_agent};

	my $user_agent = delete $self->{ua};
	unless ($user_agent) {
		# Paranoid's default resolver blocks access to private IP addresses.
		# We don't want to do any such thing by default, so provide a more permissive one.
		$user_agent = LWP::UserAgent::Paranoid->new(
			resolver => REST::Consumer::PermissiveResolver->new
		);
	}

	# bubble our ->timeout, ->agent, and ->keep_alive args into this $user_agent object.
	# if keep alive is enabled, we create a connection that persists globally
	$self->apply_timeout($user_agent);
	$self->apply_agent($user_agent);
	$self->apply_keep_alive($user_agent);

	# handle auth headers
	my $default_headers = $user_agent->default_headers;
	$default_headers->header( 'accept' => 'application/json' );

	if (exists $self->{auth} && $self->{auth}{type} && $self->{auth}{type} eq 'basic') {
		$default_headers->authorization_basic($self->{auth}{username}, $self->{auth}{password});
	}

	$self->{_user_agent} = $user_agent;
	return $user_agent;
}


# create the base url for the request composed of the host and port
# add http if it hasn't already been prepended
sub get_service_base_url {
	my $self = shift;
	return $self->{url} if $self->{url};

	my $host = $self->{host};
	my $port = $self->{port};
	$host =~ s|/$||;

	return ( ($host =~ m|^https?://| ? '' : 'http://' ) . $host . ($port ? ":$port" : '') );
}

# return a URI object containing the url and any query parameters
# path: the url
# params: an array ref or hash ref containing key/value pairs to add to the URI
sub get_uri {
	my $self = shift;
	my %args = @_;
	my $path = $args{path};
	my $params = $args{params};
	$path =~ s|^/||;

	# replace any sinatra-like url tokens with their param value
	if (ref $params eq 'HASH') {
		$path =~ s/\:(\w+)/exists $params->{$1} ? URI::Escape::uri_escape(delete $params->{$1}) : $1/eg;
	}

	my $uri = URI->new( $self->get_service_base_url() . "/$path" );
	# accept key / values in hash or array format
	my @params = ref($params) eq 'HASH' ? %$params : ref($params) eq 'ARRAY' ? @$params : ();
	$uri->query_form( @params );
	return $uri;
}

# get an http request object for the given input
sub get_http_request {
	my $self     = shift;
	my %args     = @_;
	my $path     = $args{path} or die 'path is a required argument.  e.g. "/" ';
	my $content     = $args{content};
	my $headers  = $args{headers};
	my $params   = $args{params};
	my $method   = $args{method} or die 'method is a required argument';
	my $content_type = $args{content_type};

	# build the uri from path and params
	my $uri = $self->get_uri(path => $path, params => $params);

	$self->debug( sprintf('Creating request: %s %s', $method, $uri->as_string() ));

	# add headers if present
	my $full_headers = $self->user_agent->default_headers || HTTP::Headers->new;
	if ($headers) {
		my @header_params = ref($headers) eq 'HASH' ? %$headers : ref($headers) eq 'ARRAY' ? @$headers : ();
		$full_headers->header(@header_params);
	}

	# assemble request
	my $req = HTTP::Request->new($method => $uri, $full_headers);

	$self->add_content_to_request(
		request      => $req,
		content_type => $content_type,
		content      => $content,
	);


	return $req;
}


# add content to the request
# by default, serialize to json
# otherwise use content type to determine any action if needed
# content type defaults to application/json
sub add_content_to_request {
	my $self = shift;
	my %args = @_;
	my $request = $args{request} or die 'request is required';
	my $content_type = $args{content_type} || 'application/x-www-form-urlencoded';
	my $content = $args{content};

	return unless defined($content) && length($content);

	$request->content_type($content_type);
	if ($content_type eq 'application/x-www-form-urlencoded') {
		# We use a temporary URI object to format
		# the application/x-www-form-urlencoded content.
		my $url = URI->new('http:');
		if (ref $content eq 'HASH') {
			$url->query_form(%$content);
		} elsif (ref $content eq 'ARRAY') {
			$url->query_form(@$content);
		} else {
			$url->query($content);
		}
		$content = $url->query;

		# HTML/4.01 says that line breaks are represented as "CR LF" pairs (i.e., `%0D%0A')
		$content =~ s/(?<!%0D)%0A/%0D%0A/g;
		$request->content($content);
	} elsif ($content_type eq 'application/json') {
		my $json = ref($content) ? JSON::XS::encode_json($content) : $content;
		$request->content($json);
	} elsif ($content_type eq 'multipart/form-data') {
		$request->content($content);
	} else {
		# if content type is something else, just include the raw data here
		# modify this code if we need to process other content types differently
		$request->content($content);
	}
}

# send a request to the given path with the given method, params, and content body
# and get back a response object
#
# path: the location of the resource on the given hostname.  e.g. '/path/to/resource'
# content: optional content body to send in a post.  e.g. a json document
# params: an arrayref or hashref of key/value pairs to include in the request
# headers: a list of key value pairs to add to the header
# method: get,post,delete,put,head
#
# depending on the value of $self->retry this function will retry a request if it receives an error.
# In the future we may want to consider managing this based on the specific error code received.
sub get_response {
	my $self     = shift;
	my %args     = @_;
	my $path     = $args{path} or die 'path is a required argument.  e.g. "/" ';
	my $content  = $args{content} || $args{body};
	my $headers  = $args{headers};
	my $params   = $args{params};
	my $method   = $args{method} or die 'method is a required argument';
	my $content_type = $args{content_type};
	my $retry_count = defined $args{retry} ? $args{retry} : $self->{retry};
	my $process_response = $args{process_response} || 0;
	
	my $req = $self->get_http_request(
		path     => $path,
		content  => $content,
		headers  => $headers,
		params   => $params,
		method   => $method,
		content_type => $content_type,
	);

	my ($result, $flow_control);
	# run the request
	my $try = 0;
	while ($try <= $retry_count) {
		$try++;
		my $response = $self->get_response_for_request(http_request => $req);

		# Okay, now do processing like retries, handlers, and whatnot.
		my $dispatch = REST::Consumer::Dispatch->new(
			handlers => $args{handlers},
			default_is_raw => ($process_response ? 0 : 1),
			debugger => $self->debugger,
		);

		($flow_control, $result) = $dispatch->handle_response(
			request => $req,
			response => $response,
			attempt => $try,
		);
		
		last unless $flow_control eq 'retry';
		if ($self->retry_delay) {
			$self->debug(sprintf ("Sleeping %d ms before retrying...", $self->retry_delay));
			usleep (1000 * $self->retry_delay);
		}
	}

	if ($flow_control eq 'succeed') {
		# $result is an arrayref of the value(s) returned
		#  by a handler (possibly the default handler).
		if (scalar @$result == 1) {
			return $result->[0];
		} else {
			return @$result;
		}
	} else {
		# $flow_control could be 'succeed' or 'retry'
		#   (but we ran out of retries)
		# $result = a failure object
		if ($self->throw_exceptions) {
			$result->throw;
		} else {
			return $result;
		}
	}
}

# do everything that get_response does, but return the deserialized content in the response instead of the response object
sub get_processed_response {
	my $self = shift;
	my $response = $self->get_response(
		process_response => 1,
		@_,
	);
	return $response;
}


#
# http_request => an HTTP Request object
# _retries => how many times we've already tried to get a valid response for this request
sub get_response_for_request {
	my ($self, %args) = @_;
	my $http_request = $args{http_request};
	$self->{_last_request} = $http_request;
	$self->{_last_response} = undef;

	my $user_agent = $self->user_agent;
	my $response = $user_agent->request($http_request);

	$self->{_last_response} = $response;
	$self->debug( sprintf('Got response: %s', $response->code()));

	return $response;
}

sub head {
	my $self = shift;
	return $self->get_response(@_, method => 'HEAD');
}

sub get {
	my $self = shift;
	return $self->get_processed_response(@_, method => 'GET');
}

sub post {
	my $self = shift;
	return $self->get_processed_response(@_, method => 'POST');
}

sub delete {
	my $self = shift;
	return $self->get_processed_response(@_, method => 'DELETE');
}

sub put {
	my $self = shift;
	return $self->get_processed_response(@_, method => 'PUT');
}


sub debugger {
	my $self = shift;
	return sub {} unless $self->{verbose};
	return sub {
		local $\ = "\n";
		print STDERR @_;
	}
}

# print status messages to stderr if running in verbose mode
sub debug {
	shift->debugger->(@_);
}


1;
__END__

=head1 Name

REST::Consumer - General client for interacting with json data in HTTP Restful services

=head1 Synopsis

This module provides an interface that encapsulates building an http request, sending the request, and parsing a json response.  It also retries on failed requests and has configurable timeouts.

=head1 Usage

To make a request, create an instance of the client and then call the get(), post(), put(), or delete() methods.
(Alternatively, call ->get_processed_response() and supply your own method name.)

	# Required parameters:
	my $client = REST::Consumer->new(
		host => 'service.somewhere.com',
		port => 80,
	);


	# Optional parameters:
	my $client = REST::Consumer->new(
		host        => 'service.somewhere.com',
		port        => 80,
		timeout     => 60, (default 10)
		retry       => 10, (default 3)
		retry_delay => 100, (ms, default 0)
		verbose     => 1, (default 0)
		keep_alive  => 1, (default 0)
		agent       => 'Service Monkey', (default REST-Consumer/$VERSION)
		ua          => My::UserAgent->new,
		auth => {
			type => 'basic',
			username => 'yep',
			password => 'nope',
		},
	);


=head1 Methods

=over

=item B<get> ( path => PATH, params => [] )

Send a GET request to the given path with the given arguments


	my $deserialized_result = $client->get(
		path => '/path/to/resource',
		params => {
			field => value,
			field2 => value2,
		},
	);


the 'params' arg can be a hash ref or array ref, depending on whether you need multiple instances of the same key

	my $deserialized_result = $client->get(
		path => '/path/to/resource',
		params => [
			field => value,
			field => value2,
			field => value3,
		]
	);

If ->get encounters an error code (400, 500, etc) it will treat this as an exception, and raise it
(or return undef if $REST::Consumer::raise_exceptions has been explicitly set to 0 - but you shouldn't
do this; you should either wrap the entire invocation in an eval block, or use handlers below to
control the way REST::Consumer responds to exceptions.)

By default, ->get will attempt to deserialize the response body, and the deserialized structure will be its
return value. If the body cannot be deserialized (e.g. if it is a plaintext document) the body will be returned
(decoded from whatever transfer encoding it may have been encoded with, but not otherwise deserialized).

You can also specify a 'handlers' argument to ->get. This argument should be a hashref of <status, coderef>
pairs. Handlers are used to react to a particular HTTP response code or set of response codes. If a handler
matches the HTTP response, the return value of ->get will be the return value of that handler.
This allows you to return a data structure of your choice, even in case of HTTP errors.

The status codes consist of either 3-digit scalars, such as 404 or '418', or a three-character response class,
such as '2xx' or '5xx'. If an HTTP response returns a status code, a handler with that code will be looked for;
if none is found, a handler with a wildcard code will then be looked for. If neither is present, execution
will proceed as specified above.

A handler coderef is invoked with a single argument representing a handle to the handler's invocation --
$h in all the examples below. $h has several methods which can be used to access the request and response.
The handler should return data, which will be presented as the return value of the ->get operation.

A handler can also return flow-control objects. If a flow-control object is returned instead of a regular
object or scalar, the flow of the request processing will be altered. These flow-control objects are
instantiated via methods on $h; valid flow control objects are $h->retry, $h->fail, and $h->default.
For instance, a handler can return $h->default to proceed as if the handler code had not been specified.
In that case, the value returned by ->get will be the response's deserialized content (or an exception,
depending on the request's status code).

Here is an example of handlers being specified and returning values.

  # Obtain a welcome message from /welcome-message.
  my $custom_deserialized_result = $client->get(
     path => '/welcome-message',
     ...
     handlers => {
       2xx => sub {
         my ($h) = @_; # $h is a response handler invocation.
         if ($h->response_parseable) { # true if it's pareseable JSON
           return $h->parsed_response->{message};
           # ->parsed_response will throw an exception
           # if the response is not parseable
         } else {
           if ($h->response->content_type =~ qr{text/plain}) {
             # ->response_body is the unparsed body.
             # it is always available.
             return $h->response_body;
           } else {
             return $h->fail;
             # Returning $h->fail will invoke the standard failure mechanism,
             #   which will raise an exception or return undef, depending on
             #   the package configuration ($REST::Consumer::throw_exceptions
             #   is true by default - you ought to leave it that way, and use
             #   handlers to deal with exceptions, instead).
           }
         }
       },
       403 => sub { return 'Go away!'; },
       404 => sub { 'You're traveling through another dimension,' .
                    ' a dimension not only of sight and sound but of mind.' },
       418 => sub { return "I'm a little teapot, short and stout!" },
       420 => sub {  # (nonstandard status code / Twitter rate limiting).
         my ($h) = @_;
         return $h->retry;
         # Returning $h->retry will cause the request to be retried.
         # This operation respects the number of retries and the retry delay
         # specified at the REST::Consumer instantiation.
       },
       2xx => sub {
         my ($h) = @_;

         # (assuming a $self from enclosing scope)
         # ->response and ->request are HTTP::Response and HTTP::Request objects
         $self->log("Welcome message successfully located for %s", $h->request->uri);

         # Returning $h->default will resume normal REST::Consumer processing.
         # Depending on what sort of response this is, that may result in
         #   returning the response's content, retrying the request, or throwing
         #   an exception (or returning undef, if $REST::Consumer::ThrowExceptions
         #   is false.)
         return $h->default;
       },
     },
  );


=item B<post> (path => PATH, params => [key => value, key => value], content => {...} )

Send a POST request with the given path, params, and content.  The content must be a data structure that can be serialized to JSON.

	# content is serialized to json by default
	my $deserialized_result = $client->post(
		path => '/path/to/resource',
		content => { field => value }
	);


	# if you don't want it serialized, specify another content type
	my $deserialized_result = $client->post(
		path => '/path/to/resource',
		content => { field => value }
		content_type => 'multipart/form-data',
	);

	# you can also specify headers if needed
	my $deserialized_result = $client->post(
		path => '/path/to/resource',
		headers => [
			'x-custom-header' => 'monkeys',
		],
		content => { field => value }
	);

->post() returns the deserialized result by default. It also allows you to specify handlers. See the documentation for ->get().

=item B<delete> (path => PATH, params => [])

Send a DELETE request to the given path with the given arguments.

	my $result = $client->delete(
		path => '/path/to/resource',
		params => [
			field => value,
			field2 => value2,
		]
	);

->delete() returns the deserialized result by default. It also allows you to specify handlers. See the documentation for ->get().

=item B<get_response> (path => PATH, params => [key => value, key => value], headers => [key => value,....], content => {...}, handlers => {...}, method => METHOD )

Send a request with path, params, and content, using the specified method, e.g. POST.
But you already have a method ->post, so maybe the method is something like PROPFIND, BREW, or WHEN.

By default, ->get_response will return an HTTP::Response object.
->get_response also allows you to specify handlers.
See the documentation for ->get().

	my $response_obj = $client->get_response(
		method => 'GET',
		path   => '/path/to/resource',
		headers => [
			'x-header' => 'header',
		],
		params => [
			field => value,
			field2 => value2,
		],
    handlers => {},
	);

(N.B. If specifying method the methods BREW or WHEN, it is recommended that you
 supply a handler for the HTTP 418 response. See RFC 2324 for more information.)

=item B<get_processed_response> (path => PATH, params => [key => value, key => value], headers => [key => value,....], content => {...}, handlers => {...}, method => METHOD)

Send a request with path, params, and content, using the specified method, and get the deserialized content back.
->get_processed_response() also allows you to specify handlers. See the documentation for ->get().

If handlers for the resposnse have been specified, the return value will be whatever the handler returns.
If the content is JSON, it will be parsed. If the content is not JSON, it will be returned as a string.

=item B<get_http_request> ( path => PATH, params => [PARAMS], headers => [HEADERS], content => [], method => '' )

Get an HTTP::Request object for the given input.

(The request will not actually be issued.)

=back

=cut
