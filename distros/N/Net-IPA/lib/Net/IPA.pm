# Net::IPA.pm -- Perl 5 interface of the (Free)IPA JSON-RPC API
#
#   for more information about this api see: https://vda.li/en/posts/2015/05/28/talking-to-freeipa-api-with-sessions/
#
#   written by Nicolas Cisco (https://github.com/nickcis)
#   https://github.com/nickcis/perl-Net-IPA
#
#     Copyright (c) 2016 Nicolas Cisco. All rights reserved.
#     Licensed under the GPLv3, see LICENSE.md file for more information.

package Net::IPA;

our $VERSION = '1.0';

=head1 NAME

Net::IPA.pm -- Perl 5 interface of the (Free)IPA JSON-RPC API

=head1 SYNOPSIS

  use Net::IPA;

  my $ipa = new Net::IPA(
    hostname => 'ipa.server.com',
    cacert => '/etc/ipa/ca.cert',
  );

  # (a) Login can be done via Kerberos
  $ipa->login();

  # (b) Login can be done via Kerberos (creating the ticket)
  $ipa->login(
    username => 'admin',
    keytab => '/etc/ipa/admin.keytab'
  );

  # (c) Login can be done using username and password
  $ipa->login(
    username => 'admin',
    password => 'admin-password'
  );

  # Control error
  die $ipa->error if($ipa->error);

  # $user_show is of the type Net::IPA::Response
  my $user_show = $ipa->user_show('username');
  die 'Error: ' . $user_show->error_string() if($user_show->is_error);

  # Requests can be batched
  use Net::IPA::Methods;
  my @users_show = $ipa->batch(
    Net::IPA::Methods::user_show('username1'),
    Net::IPA::Methods::user_show('username2'),
    Net::IPA::Methods::user_show('username3'),
  );

  foreach my $user_show (@users_show){
    # $user_show is of the type Net::IPA::Response
    if($user_show->is_error){
        print 'Error: ' . $user_show->error_string() . "\n";
        next;
    }

    # Do something
  }

For methods look at the L<Net::IPA::Methods> module.

=cut

use strict;
use Net::IPA::Methods;
use Net::IPA::Response;

use vars qw($AUTOLOAD);
use Carp;

use JSON;
use LWP::UserAgent; # http://search.cpan.org/~ether/libwww-perl-6.15/lib/LWP/UserAgent.pm
use LWP::Authen::Negotiate; # http://search.cpan.org/~agrolms/LWP-Authen-Negotiate-0.06/lib/LWP/Authen/Negotiate.pm
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Headers;
use File::Spec::Functions qw(catdir);
use Authen::Krb5::Easy qw(kcheck kerror); # https://github.com/nickcis/perl-Authen-Krb5-Easy

use constant {
	AGENT => 'Perl / IPA',
	CACERT => "/etc/ipa/ca.crt",
	URL_TEMPLATE => '{protocol}://{hostname}{endpoint}',
	BASEPAGE => '/ipa',
	PROTOCOL => 'https',
	ROUTE_LOGIN_KERBEROS => "/session/login_kerberos",
	ROUTE_LOGIN_PASSWORD => "/session/login_password",
	ROUTE_JSON => "/session/json",
	IPA_CLIENT_VERSION => "2.156",
	COOKIE_NAME => 'ipa_session',
};

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = @_;
	my $self = {
		_hostname => $args{hostname} || "localhost",
		_cacert => $args{cacert} || CACERT,
		_protocol => $args{protocol} || PROTOCOL,
		_basepage => $args{basepage} || BASEPAGE,
		_url_template => $args{url_template} || URL_TEMPLATE,
		_agent => $args{agent} || AGENT,
		_ua => $args{ua} || undef,
		_cookie_name => $args{cookie_name} || COOKIE_NAME,
		_cookie_jar => $args{cookie_jar} || undef,
		_debug => $args{debug} || undef,
		_error => undef,
		_version => $args{version} || IPA_CLIENT_VERSION,
		_reconnect => exists $args{reconnect} ? $args{reconnect} : 1,
		_login_args => {},
		_expire_time => 0,
	};

	bless ($self, $class);
	$self->_init_ua() unless($self->{_ua});
	return $self;
}

sub version
{
	my ($self, $version) = @_;
	$self->{_version} = $version if($version);
	return $self->{_version};
}

sub _debug
{
	my ($self, $msg) = @_;
	return unless($self->{_debug});
	return $self->{_debug}->($msg) if(ref($self->{_debug}) eq "CODE");
	print $msg . "\n";
}

#** @function _init_ua private
# Inicializa LWP::UserAgent para hacer requests
#*
sub _init_ua
{
	my ($self) = @_;

	$self->{_cookie_jar} = HTTP::Cookies->new unless($self->{_cookie_jar});

	$self->{_ua} = LWP::UserAgent->new(
		agent => $self->{_agent},
		cookie_jar => $self->{_cookie_jar},
	);

	$self->{_ua}->default_header(
		referer => $self->_build_url()
	);

	$self->{_ua}->ssl_opts(
		SSL_ca_file => $self->{_cacert}
	);
}

#** Crea una url para el endpoint especificado
# @params Endpoint
# @return Devuelve el url
#*
sub _build_url
{
	my $self = shift;
	my $url = $self->{_url_template};
	my $endpoint = catdir($self->{_basepage}, @_);

	$url =~ s/{protocol}/$self->{_protocol}/g;
	$url =~ s/{hostname}/$self->{_hostname}/g;
	$url =~ s/{endpoint}/$endpoint/g;

	$self->_debug("url: $url");
	return $url;
}

#** Performs IPA autentification.
#   The autentification can be by providing username and password or through kerberos.
#   In order to autentificate throught kerberos the ticket must already be created,
#   (i.e: `kinit -k -t <keytab>`) or the param keytab has to be provided.
#
#   If username and password are provided, autentification is done by username and password, if not,
#   autentification is done through kerberos.  Kinit is called if a keytab is provided.
#
# @params (
#    username => [mandatory] IPA username
#    password => (optional) IPA password
#    keytab => (optional) Absolute path to the keytab file
# )
#
# @return 0: Ok, != 0: Error
#*
sub login
{
	my ($self, %args) = @_;
	$self->{_login_args} = \%args if($self->{_reconnect});
	my $http_headers = $self->{_ua}->default_headers()->clone;
	my $url;
	my $data = undef;

	if($args{username} && $args{password}){
		$http_headers->header(
			'Content-Type' => "application/x-www-form-urlencoded",
			Accept => "text/plain",
		);

		$url = $self->_build_url(ROUTE_LOGIN_PASSWORD);
		$data = "user=". $args{username} . "&password=" . $args{password};
	}else{
		if($args{keytab} && $args{username}) {
			unless(kcheck($args{keytab}, $args{username})){
				$self->{_error} = kerror();
				return -1;
			} 
		}
		$url = $self->_build_url(ROUTE_LOGIN_KERBEROS);
	}

	my $request = HTTP::Request->new('POST', $url, $http_headers, $data);
	my $response = $self->{_ua}->request($request);
	$self->_debug($response->as_string);
	unless($response->is_success){
		$self->{_error} = 'Login Failed :: HTTP Code: ' . $response->code . ' ('. $response->message(). ')';
		return 0;
	}

	$self->_scan_cookies();

	return 1;
}

sub _scan_cookies
{
	my ($self) = @_;
	$self->{_cookie_jar}->scan(sub {
		my ($version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard, $hash) = @_;
		return unless($key eq $self->{_cookie_name});
		$self->{_expire_time} = $expires;
	});
}

#** Check current error status.
# Lo que devuelva esta funcion se evaluara como verdadero cuando se haya producido algun error
# @return False (undef): No error. If there is an error, this method will return a string describing the error.
#*
sub error
{
	my ($self) = @_;
	$self->{_error} = $_[1] if(1 > scalar @_);
	return $self->{_error};
}

#** Performs a request to the JSON api.
# @params $method: Ipa method name
# @params $args: (Array ref) Ipa parameters
# @params $_kargs (Hash ref) Ipa named parameters
# @return Net::IPA::Response
#*
sub request
{
	my ($self, $method, $args, $_kargs) = @_;

	return $self->_request({
		#id => 0,
		method => $method,
		params => [ $args, $_kargs ],
	});
}

#** [private] Internal method for perfoming api requests.
# @params $_options: (Hash ref) { method => , params => [ args, kargs ] }
# @return Net::IPA::Response
#*
sub _request
{
	my ($self, $_options) = @_;

	$self->{_error} = undef;
	$self->login(%{$self->{_login_args}}) if($self->{_reconnect} && time() > $self->{_expire_time});

	my $url = $self->_build_url(ROUTE_JSON);
	my %options = %$_options;
	$options{params}->[1]->{version} = $self->{_version} if($self->{_version} and not(exists $options{params}->[1]->{version}));

	my $data = to_json(\%options);

	my $http_headers = $self->{_ua}->default_headers()->clone;
	$http_headers->header(
		'Content-Type' => "application/json",
		Accept => "application/json",
	);
	my $request = HTTP::Request->new('POST', $url, $http_headers, $data);
	my $response = $self->{_ua}->request($request);

	$self->_debug($data);
	$self->_debug($response->decoded_content);

	$self->_scan_cookies();

	return new Net::IPA::Response({
		error => {
			code => -1,
			name => 'HttpError',
			message => 'Code: ' . $response->code . ' (' . $response->message() . ')'
		}
	}) unless($response->is_success);
	return new Net::IPA::Response(from_json($response->decoded_content));
}

#** AUTOLOAD is used to implement the methods of Net::IPA::Methods.
#   This allows the programmer to call:
#     $ipa->user_add( ... );
#
#   Instead of:
#     $ipa->method('user_add', ... );
#
#   In order to see all available method check the Net::IPA::Methods module.
#*
sub AUTOLOAD
{
	my $sub = $AUTOLOAD;
	(my $name = $sub) =~ s/.*:://;
	my $method = Net::IPA::Methods->can($name);
	if($method){
		my $self = shift;
		my $ret = $method->(@_);
		return $self->_request($ret);
	}

	croak "Can't locate object method \"$name\" via package \"Net::IPA\"";
}

#** Performs batch requests.
#   Batch requests are done in order to perform many IPA api requests
#   in only one http request.
# @param @batch: All IPA requests (must be created with Net::IPA::Method:* functions)
# @return array of all Net::IPA::Response of the batched actions.
#*
sub batch
{
	my ($self, @batch) = @_;
	my $response = $self->request(
		'batch',
		\@batch,
		{}
	);

	my @ret;
	if($response->is_error || ref($response->{result}->{results}) ne 'ARRAY'){
		push @ret, $response;
	}else{
		foreach my $r (@{$response->{result}->{results}}){
			push @ret, new Net::IPA::Response($r);
		}
	}
	return wantarray ? @ret : \@ret;
}

1;
