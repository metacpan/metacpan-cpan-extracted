package Reddit::Client::Request;

use strict;
use warnings;
use Carp;

use JSON           qw/encode_json decode_json/;
use LWP::UserAgent qw//;
use HTTP::Request  qw//;
use URI::Encode    qw/uri_encode/;
use URI::Escape    qw/uri_escape/; # next update, also line 122
use Data::Dumper;

require Reddit::Client;

use fields (
    'user_agent',
    'method',
    'url',
    'query',
    'post_data',
    'cookie',
    'modhash',
    'token',
    'tokentype',
	'request_errors',
	'print_response',
	'print_request',
	'print_request_on_error',
	'last_token',
);

sub new {
    my ($class, %param) = @_;
    my $self = fields::new($class);
    $self->{user_agent} = $param{user_agent} || croak 'Expected "user_agent"';
    $self->{url}        	= $param{url}        || croak 'Expected "url"';
    $self->{query}      	= $param{query};
    $self->{post_data}  	= $param{post_data};
    $self->{cookie}     	= $param{cookie};
    $self->{modhash}    	= $param{modhash};
    $self->{token}			= $param{token};
    $self->{tokentype}		= $param{tokentype};
    $self->{request_errors} = $param{request_errors} || 0;
    $self->{print_response} = $param{print_response} || 0;
    $self->{print_request}  = $param{print_request} || 0;
	$self->{print_request_on_error} = $param{print_request_on_error} || 0;
	$self->{last_token}		= $param{last_token};

    if (defined $self->{query}) {
        ref $self->{query} eq 'HASH' || croak 'Expected HASH ref for "query"';
        $self->{url} = sprintf('%s?%s', $self->{url}, build_query($self->{query}))
    }

    if (defined $self->{post_data}) {
        ref $self->{post_data} eq 'HASH' || croak 'Expected HASH ref for "post_data"';
    }

    $self->{method} = $param{method} || 'GET';
    $self->{method} = uc $self->{method};

    return $self;
}

sub build_query {
    my $param = shift or return '';
    my $opt   = { encode_reserved => 1 };
    join '&', map {uri_encode($_, $opt) . '=' . uri_encode($param->{$_}, $opt)} sort keys %$param;
}

sub build_request {
    my $self    = shift;
    my $request = HTTP::Request->new();

    $request->uri($self->{url});
    $request->header("Authorization"=> "$self->{tokentype} $self->{token}") if $self->{tokentype} && $self->{token};

    if ($self->{method} eq 'POST') {
        my $post_data = $self->{post_data} || {};
        $post_data->{modhash} = $self->{modhash} if $self->{modhash};
        $post_data->{uh}      = $self->{modhash} if $self->{modhash};

        $request->method('POST');
        $request->content_type('application/x-www-form-urlencoded');
        $request->content(build_query($post_data));
    } elsif ($self->{method} eq 'DELETE') {
		$request->method('DELETE');
    } elsif ($self->{method} eq 'PUT') {
        my $post_data = $self->{post_data} || {};
        $post_data->{modhash} = $self->{modhash} if $self->{modhash};
        $post_data->{uh}      = $self->{modhash} if $self->{modhash};

		$request->method('PUT');
        $request->content_type('application/x-www-form-urlencoded');
        $request->content(build_query($post_data));
    } else {
        $request->method('GET');
    }

    return $request;
}

sub send {
    my $self    = shift;
    my $request = $self->build_request;

    Reddit::Client::DEBUG('%4s request to %s', $self->{method}, $self->{url});

    my $ua  = LWP::UserAgent->new(agent => $self->{user_agent}, env_proxy => 1);
    my $res = $ua->request($request);

	if ($self->{print_request}) {
		print Dumper($request);
		print Dumper($res);
	} elsif ($self->{print_response}) {
		print $res->content . "\n";
	}

	# response is an HTTP::Response object, sent is HTTP::Request

    if ($res->is_success) {
        return $res->content;
    } else {
		# I don't know what the fuck any of this is
		# print request unless we already printed it
		if ($self->{print_request_on_error} and !$self->{print_request}) {
			print Dumper($request);
			print Dumper($res);
		} elsif ($self->{request_errors}) {
			my $json; 
			my $success = eval { $json = decode_json $res->{_content}; };

			# If Reddit returned valid json, add it to a hash and print it
			if ($success) {
				my $err = {
					error		=> 1,
					code		=> $res->code,
					status_line	=> $res->status_line,
					data		=> $json,
				};
				
				my $rtn = encode_json $err;
				die "$rtn\n";

			} else {
				die "Request error: HTTP ".$res->status_line .", Content: $res->{_content}";
			}
			#die $res->{_content}."\n";
		} else { # default: print status line and exit
			#croak sprintf("Request error: HTTP %s last token: %s time: %s", $res->status_line, $self->{last_token}, time);
			die sprintf("Request error: HTTP %s\n", $res->status_line);
		}
    }
}

sub token_request {
	my ($self, %param) = @_;

	my $url = "https://$param{client_id}:$param{secret}\@www.reddit.com/api/v1/access_token";

    my $ua = LWP::UserAgent->new(agent => $param{user_agent});
	my $req = HTTP::Request->new(POST => $url);
	$req->header('content-type' => 'application/x-www-form-urlencoded');

	#my $postdata = "grant_type=password&username=$username&password=$password";
	my $postdata;
		
	if ($param{auth_type} eq 'script') {
		$postdata = "grant_type=password&username=$param{username}&password=" . uri_escape($param{password});
	} elsif ($param{auth_type} eq 'webapp') {
		$postdata = "grant_type=refresh_token&refresh_token=".uri_escape($param{refresh_token});
	} else { die "Request:token_request: invalid auth type"; }

	$req->content($postdata);

	my $res = $ua->request($req);

	if ($res->is_success) {
		return $res->decoded_content;
	} else {
		# this is sometimes called in static context
		#if ($self->{request_errors}) {
		#	croak "Request error: HTTP ".$res->status_line .", Content: $res->{_content}";
		#} else {
			croak sprintf("Request error: HTTP %s", $res->status_line);
		#}
		#croak sprintf('Request error: HTTP %s', $res->status_line);
	}
}

sub refresh_token_request {
	my ($self, %data)	= @_;

    # create user agent
    my $ua      = new LWP::UserAgent( agent=> $data{ua} );
    # create new request
    my $request = new HTTP::Request();
    # set the request method
    $request->method("POST");
    # set request url
    my $url = "https://$data{client_id}:$data{secret}\@www.reddit.com/api/v1/access_token";
    $request->uri($url);

	my $reqdata = {
        grant_type  => 'authorization_code',
        code        => $data{code},
        redirect_uri=> $data{redirect_uri},
        duration    => 'permanent',
    };

    $request->content_type('application/x-www-form-urlencoded');

    my $opt   = { encode_reserved => 1 };
    my $encoded = join '&', map { uri_encode($_, $opt) . '=' . uri_encode($reqdata->{$_}, $opt) } sort keys %$reqdata;

    $request->content($encoded);

    my $result = $ua->request($request);

	if ($data{print_request}) {
		print Dumper($request);
		print Dumper($result);
	}

    if ($result->is_success) {
        my $j = decode_json $result->content;
        my $tok = $j->{refresh_token};

		return $tok;
    } else {
		print "Request error: HTTP ".$result->status_line.", Content:\n$result->{_content}\n";
        print "refresh_token_request: something went wrong. To aid in debugging, you can set 'print_request' to true when creating a new Reddit::Client object. This will print the entire content of the request and response.\n";

		die;
    }

}

1;

__END__

=pod

=head1 NAME

Reddit::Client::Request

=head1 DESCRIPTION

HTTP request driver for Reddit::Client. Uses LWP to perform GET and POST requests
to the reddit.com servers. This module is used internally by the Reddit::Client
and is not designed for external use.

=head1 SUBROUTINES/METHODS

=over

=item new(%params)

Creates a new Reddit::Request::API instance. Parameters:

    user_agent    User agent string
    url           Target URL
    query         Hash of query parameters
    post_data     Hash of POST parameters
    cookie        Reddit session cookie
    modhash       Reddit session modhash


=item build_query($query)

Builds a URI-escaped query string from a hash of query parameters. This is *not*
a method of the class, but a package routine.


=item build_request

Builds an HTTP::Request object for LWP::UserAgent.


=item send

Performs the HTTP request and returns the result. Croaks on HTTP error.


=back

=head1 AUTHOR

L<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut
