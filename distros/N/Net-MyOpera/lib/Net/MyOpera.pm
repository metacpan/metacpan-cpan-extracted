package Net::MyOpera;

use warnings;
use strict;

use Carp ();
use CGI ();
use LWP::UserAgent ();
use Net::OAuth 0.25;
use URI ();
use URI::Escape ();

use constant OAUTH_BASE_URL => 'https://auth.opera.com/service/oauth';
use constant STATUS_UPDATE_URL => 'http://my.opera.com/community/api/users/status.pl';

our $VERSION = '0.02';

# Opera supports only OAuth 1.0a
$Net::OAuth::PROTOCOL_VERSION = &Net::OAuth::PROTOCOL_VERSION_1_0A;

sub new {
	my ($class, %opts) = @_;

	$class = ref $class || $class;

	for (qw(consumer_key consumer_secret)) {
		if (! exists $opts{$_} || ! $opts{$_}) {
			Carp::croak "Missing '$_'. Can't instance $class\n";
		}
	}

	my $self = {
		_consumer_key => $opts{consumer_key},
		_consumer_secret => $opts{consumer_secret},
		_access_token => undef,
		_access_token_secret => undef,
		_request_token => undef,
		_request_token_secret => undef,
		_authorized => 0,
	};

	bless $self, $class;

	return $self;
}

sub authorized {
	my ($self) = @_;

	# We assume to be authorized if we have access token and access token secret
	my $acc_tok = $self->access_token();
	my $acc_tok_secret = $self->access_token_secret();

	# TODO: No real check if the token is still valid
	unless ($acc_tok && $acc_tok_secret) {
		return;
	}

	return 1;
}

sub access_token {
	my $self = shift;
	if (@_) {
		$self->{_access_token} = shift;
	}
	return $self->{_access_token};
}

sub access_token_secret {
	my $self = shift;
	if (@_) {
		$self->{_access_token_secret} = shift;
	}
	return $self->{_access_token_secret};
}

sub consumer_key {
	my ($self) = @_;
	return $self->{_consumer_key};
}

sub consumer_secret {
	my ($self) = @_;
	return $self->{_consumer_secret};
}

sub request_token {
	my $self = shift;
	if (@_) {
		$self->{_request_token} = shift;
	}
	return $self->{_request_token};
}

sub request_token_secret {
	my $self = shift;
	if (@_) {
		$self->{_request_token_secret} = shift;
	}
	return $self->{_request_token_secret};
}

sub get_authorization_url {
	my ($self) = @_;

	# Get a request token first
	# and then build the authorize URL
	my $oauth_resp = $self->request_request_token();

	my $req_tok = $oauth_resp->{oauth_token};
	my $req_tok_secret = $oauth_resp->{oauth_token_secret};

	# Store in the object for the access-token phase later
	$self->request_token($req_tok);
	$self->request_token_secret($req_tok_secret);

	return $self->oauth_url_for('authorize', oauth_token=> $req_tok);
}

sub _do_oauth_request {
	my ($self, $url) = @_;

	my $ua = $self->_user_agent();
	my $resp = $ua->get($url);

	if ($resp->is_success) {
		my $query = CGI->new($resp->content());
		return {
			ok => 1,
			$query->Vars
		};
	}

	return {
		ok => 0,
		errstr => $resp->status_line(),
	}
}

sub _user_agent {
	my $ua = LWP::UserAgent->new();
	return $ua;
}

sub oauth_url_for {
	my ($self, $step, %args) = @_;

	$step = lc $step;

	my $url = URI->new(OAUTH_BASE_URL . '/' . $step);
	$url->query_form(%args);

	return $url;
}

sub request_access_token {
	my ($self, %args) = @_;

    if (! exists $args{verifier}) {
        Carp::croak "The 'verifier' argument is required. Check the docs.";
    }

    my $verifier = $args{verifier};

	my %opt = (
		step           => 'access_token',
		request_method => 'GET',
		request_url    => $self->oauth_url_for('access_token'),
		token          => $self->request_token(),
		token_secret   => $self->request_token_secret(),
		verifier       => $verifier,
	);

	my $request = $self->_prepare_request(%opt);
	if (! $request) {
		Carp::croak "Unable to initialize access-token request";
	}

	my $access_token_url = $request->to_url();

	#print 'access_token_url:', $access_token_url, "\n";

	my $response = $self->_do_oauth_request($access_token_url);

	# Check if the request-token request failed
	if (! $response || ref $response ne 'HASH' || $response->{ok} == 0) {
		Carp::croak "Access-token request failed. Might be a temporary problem. Please retry later.";
	}

    # Store access token for future requests
    $self->access_token($response->{oauth_token});
    $self->access_token_secret($response->{oauth_token_secret});

    # And return them as well, so user can save them to persistent storage
	return (
        $response->{oauth_token},
        $response->{oauth_token_secret}
    );
}

sub request_request_token {
	my ($self) = @_;

	my %opt = (
		step => 'request_token',
        callback => 'oob',
		request_method => 'GET',
		request_url => $self->oauth_url_for('request_token'),
	);

	my $request = $self->_prepare_request(%opt);
	if (! $request) {
		Carp::croak "Unable to initialize request-token request";
	}

	my $request_token_url = $request->to_url();
	my $response = $self->_do_oauth_request($request_token_url);

	# Check if the request-token request failed
	if (! $response || ref $response ne 'HASH' || $response->{ok} == 0) {
		Carp::croak "Request-token request failed. Might be a temporary problem. Please retry later.";
	}

	return $response;
}

sub _fill_default_values {
	my ($self, $req) = @_;

	$req ||= {};

	$req->{step}  ||= 'request_token';
	$req->{nonce} ||= _random_string(32);
	$req->{request_method} ||= 'GET';
	$req->{consumer_key} ||= $self->consumer_key();
	$req->{consumer_secret} ||= $self->consumer_secret();

	# Opera OAuth provider supports only HMAC-SHA1
	$req->{signature_method} = 'HMAC-SHA1';
	$req->{timestamp} ||= time();
	$req->{version} = '1.0';

	return $req;
}

sub _prepare_request {
	my ($self, %opt) = @_;

	# Fill in the default OAuth request values
	$self->_fill_default_values(\%opt);

	# Use Net::OAuth to obtain a valid request object
	my $step = delete $opt{step};
	my $request = Net::OAuth->request($step)->new(%opt);

	# User authorization step doesn't need signing
	if ($step ne 'user_auth') {
    	$request->sign;
	}

	return $request;
}

sub _random_string {
    my ($length) = @_;
    if (! $length) { $length = 16 } 
    my @chars = ('a'..'z','A'..'Z','0'..'9');
    my $str = '';
    for (1 .. $length) {
        $str .= $chars[ int rand @chars ];
    }
    return $str;
}

sub update {
	my ($self, $args) = @_;

	# Nothing to update?
	if (! $args) {
		return;
	}

	my $new_status = $args->{status};

	my $status_update_url = URI->new(STATUS_UPDATE_URL);

    $status_update_url->query_form(
        new_status => $new_status
    );

	#warn "status-update-url: $status_update_url\n";
    #warn "access-token: " . $self->access_token() . "\n";
    #warn "access-token-secret: " . $self->access_token_secret() . "\n";

	my %opt = (
		step => 'protected_resource',
		request_method => 'GET',
		request_url => $status_update_url,
		token => $self->access_token(),
		token_secret => $self->access_token_secret(),
        new_status => $new_status,
	);

	my $request = $self->_prepare_request(%opt);
	if (! $request) {
		Carp::croak "Unable to initialize status-update request";
	}

	my $status_update_oauth_url = $request->to_url() . '&new_status=' . URI::Escape::uri_escape_utf8($new_status);
	my $response = $self->_do_oauth_request($status_update_oauth_url);

	#warn "status-update-oauth-url: " . $status_update_oauth_url . "\n";

	if (! $response || ref $response ne 'HASH' || $response->{ok} == 0) {
		Carp::croak "Status update request failed. Might be a temporary problem. Please retry later.";
	}

	return $response->{ok};
}

1;

__END__

=pod

=head1 NAME

Net::MyOpera - a Perl interface to the My Opera Community API

=head1 SYNOPSIS

Example:

    use Net::MyOpera;

    my $myopera = Net::MyOpera->new(
        consumer_key => '{your-consumer-key-here}',
        consumer_secret => '{your-consumer-secret-here}',
    );

    my $result = $myopera->update('If you see this, OAuth worked!');

In reality, it's a bit more complicated than that, but look at the
example script provided in C<examples/myopera-status>. That should
work out of the box.

=head1 DESCRIPTION

This module will be useful to you if you are a member of, or you
use, the My Opera Community (L<http://my.opera.com>).

There's a nice development plan for this code. For now, you can
set your own My Opera status, which is of course really awesome on
its level :-)

If you know how L<Net::Twitter> works, then you will have no problem
using L<Net::MyOpera> because it behaves in the same way, and
in fact, it's even API compatible. The API is based on OAuth.

If you're not familiar with OAuth, go to L<http://oauth.net> and
read the documentation there. There's also some very nice
tutorials out there. Search for C<"OAuth tutorial"> in your
favorite search engine.

That means that if you use the provided example script, in the
C<examples/myopera-status> file, just by instancing L<Net::Twitter>
instead of L<Net::MyOpera>, and changing the API keys of course,
you should be able to update your Twitter status as well.

To use this module, B<you will need your set of OAuth API keys>.
To get your own OAuth consumer key and secret, you need to go to:

  https://auth.opera.com/service/oauth/

where you will be able to B<sign up to the My Opera Community>
and B<create your own application> and get your set of consumer keys.

If you don't want to do it, you can use (temporarily) use the
Test application keys, for command line/desktop based applications:

  Consumer key: test_desktop_key
  Consumer secret: p2FlOFGr3XFm5gOwEKKDcg3CvA4pp0BC

=head1 SUBROUTINES/METHODS

=head2 CLASS CONSTRUCTOR

=head3 C<new( %args )>

Class constructor. 

There's two, both mandatory, arguments,
B<consumer_key> and B<consumer_secret>.

Example:

    my $myopera = Net::MyOpera->new(
        consumer_key => '...',
        consumer_secret => '...',
    );

To get your own consumer key and secret, you need to head over to:

  https://auth.opera.com/service/oauth/

where you will be able to sign up to the My Opera Community
and create your own application and get your set of consumer keys.

If you don't want to do it, you can use (temporarily) use the
Test application keys, for command line/desktop based applications:

  Consumer key: test_desktop_key
  Consumer secret: p2FlOFGr3XFm5gOwEKKDcg3CvA4pp0BC

=head2 INSTANCE METHODS

=head3 C<access_token()>

=head3 C<access_token($new_value)>

=head3 C<access_token_secret()>

=head3 C<access_token_secret($new_value)>

=head3 C<consumer_key()>

=head3 C<consumer_key($new_value)>

=head3 C<consumer_secret()>

=head3 C<consumer_secret($new_value)>

=head3 C<request_token()>

=head3 C<request_token($new_value)>

=head3 C<request_token_secret()>

=head3 C<request_token_secret($value)>

All of these are simple accessors/mutators, to store access token and secret data.
This store is volatile. It doesn't get saved on disk or database.

=head3 C<authorized()>

Returns true if you already have a valid access token that's also
authorized. If not, you will need to get a request token.
You need to be familiar with the OAuth protocol flow.
Refer to L<http://oauth.net/>.

=head3 C<get_authorization_url()>

Returns the URL that a user can use to authorize the request token.
Under the hood, it first requests a new request token.

=head3 C<oauth_url_for($oauth_phase)>

=head3 C<oauth_url_for($oauth_phase, %arguments)>

Internal method to generate URLs towards the Opera OAuth server.

=head3 C<request_access_token( verifier => $verifier )>

When the request token is authorized by the user, the user will
be given a "verifier" code. You need to have the user input the
verifier code, and use it for this method.

In case of success, this method will return you both the
OAuth access token and access token secret, which you
will be able to use to finally perform the API requests,
namely status update.

=head3 C<request_request_token()>

Requests and returns a new request token.
First step of the OAuth flow. You can use this method
B<also> to quickly check that your set of API keys work
as expected.

If they don't work, the method will croak (die badly
with an error message).

=head3 C<update($new_status)>

Updates your My Opera status with the C<$new_status> string.
You B<must be authorized> first. Check the C<authorized()> method
and/or the OAuth documentation at L<http://oauth.net/>.

=head1 AUTHOR

Cosimo Streppone, E<lt>cosimo@opera.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-myopera at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-MyOpera>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::MyOpera

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-MyOpera>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-MyOpera>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-MyOpera>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-MyOpera>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c), 2009-2010 Opera Software ASA.
All rights reserved.

