package OAuth::Simple;

use 5.010;
use strict;
use warnings;

use HTTP::Request::Common;
require LWP::UserAgent;
require JSON;
require Carp;

our $VERSION = '1.03';


sub new {
    my $class = shift;
    my $self = bless {@_}, $class;

    Carp::croak("app_id, secret and postback required for this action")
      unless ($self->{app_id} && $self->{secret} && $self->{postback});

    $self->{ua}   ||= LWP::UserAgent->new();
    $self->{json} ||= JSON->new;

    return $self;
}


sub authorize {
    my ($self, $params) = @_;

    my %params; %params = %$params if $params && %$params;

    my $url = delete $params{url};
    Carp::croak("Authorize method URL required for this action") unless ($url);
    $url = URI->new($url);
    $url->query_form(
        client_id     => $self->{app_id},
        redirect_uri  => $self->{postback},
        %params,
    );

    return $url;
}

sub request_access_token {
    my ( $self, $params ) = @_;

    my %params; %params = %$params if $params && %$params;

    my ( $url, $code, $raw, $http_method ) = delete @params{ qw(url code raw http_method) };
    Carp::croak("code and url required for this action") unless $code && $url;

    my $response = $self->{ua}->request($self->prepare_http_request(
        url         => $url,
        http_method => $http_method,
        params      => {
            client_secret => $self->{secret},
            client_id     => $self->{app_id},
            code          => $code,
            redirect_uri  => $self->{postback},
            %params,
        },
    ));

    return $response->decoded_content unless $response->is_success;
    return $response->content if $raw;
    return $self->{json}->decode($response->content);
}

sub request_data {
    my ( $self, $params ) = @_;

    my %params; %params = %$params if $params && %$params;

    my ( $url, $access_token, $raw, $http_method, $token_name ) = 
        delete @params{ qw(url access_token raw http_method token_name) };
    Carp::croak("url required for this action")
      unless ($url);
    Carp::croak("access_token required for this action")
      unless ($access_token || $self->{no_token});


    my $response = $self->{ua}->request($self->prepare_http_request(
        url         => $url,
        http_method => $http_method,
        params      => {
            $self->{no_token} ? () : ( ($token_name || 'access_token') => $access_token ),
            %params
        },
    ));
    
    return 0 unless $response->is_success;
    return $response->content if $raw;    
    return $self->{json}->decode($response->content);
}

sub prepare_http_request {
    my ( $self, %params ) = @_;
    
    $params{http_method} ||= 'GET';

    my $req;
    if ($params{http_method} eq 'GET') {
        my $url = URI->new($params{url});
        $url->query_form( %{$params{params}} ) if $params{params};
        $req = GET $url;
    }
    else {
        $req = POST $params{url},
        $self->{headers} && %{ $self->{headers} } ? %{ $self->{headers} } : (),
        Content => $params{params};
    }

    return $req;
}


1;


__END__

=pod

=head1 NAME

OAuth::Simple - Simple OAuth authorization on your site

=head1 SYNOPSIS

  my $oauth = OAuth::Simple->new(
      app_id     => 'YOUR APP ID',
      secret     => 'YOUR APP SECRET',
      postback   => 'POSTBACK URL',
  );
  my $url = $oauth->authorize( {url => 'https://www.facebook.com/dialog/oauth', scope => 'email', response_type => 'code'} );
  # Your web app redirect method.
  $self->redirect($url);
  # Get access_token.
  # Facebook returns data not in JSON. Use the raw mode and parse.
  my $access = $oauth->request_access_token( {url => 'https://graph.facebook.com/oauth/access_token', code => $args->{code}, raw => 1} );
  # Get user profile data.
  my $profile_data = $oauth->request_data( {url => 'https://graph.facebook.com/me', access_token => $access} );  


=head1 DESCRIPTION

Use this module for input VK OAuth authorization on your site

=head1 METHODS

=head2 new

  my $oauth = OAuth::Simple->new(
      app_id     => 'YOUR APP ID',
      secret     => 'YOUR APP SECRET',
      postback   => 'POSTBACK URL',
  );

The C<new> constructor lets you create a new B<OAuth::Simple> object.

=head2 authorize

	my $url = $oauth->authorize( {url => $authorize_server_url, option => 'value'} );
	# Your web app redirect method.
	$self->redirect($url);

This method returns a URL, for which you want to redirect the user.

=head3 Options

See information about options on your OAuth server.

=head3 Response

Method returns URI object.

=head2 request_access_token

  my $access = $oauth->request_access_token( {url => $server_url, code => $args->{code}} );

This method gets access token from OAuth server.

=head3 Options

    * code         - returned in redirected get request from authorize API method;
    * raw          - do not decode JSON, return raw data;
    * http_method  - set http method: GET(default), POST, etc.

=head3 Response

Method returns HASH object.

=head2 request_data

  my $profile_data = $oauth->request( {
      url          => $api_method_url,
      access_token => $access_token,
      raw          => 1,
      http_method  => 'POST',
      token_name   => 'ouath_token',
  });

This method sends requests to OAuth server.

=head3 Options

    * url (required)          - api method url;
    * params (not required)   - other custom params on OAuth server;
    * access_token (required) - access token;
    * raw                     - do not decode JSON, return raw data (default 0);
    * http_method             - set http method: GET(default), POST, etc;
    * token_name              - access token parameter name (default 'access_token').

=head3 Response

Method returns HASH object with requested data.

=head2 prepare_http_request

Returns HTTP::Request object.

=head1 OBJECT OPTIONS

=head2 no_token

If this parameter is 1, OAuth::Simple will not add access token parameter in request body.
This option can be needed on working with The OAuth 2.0 Authorization Framework: Bearer Token Usage services.
This services accepts access tokens only in special HTTP header.

  OAuth::Simple->new(no_token => 1);

=head2 headers

Set HTTP headers, which used in prepare_http_request method.

  OAuth::Simple->new( headers => { Content_Type => 'form-data' } );

=head1 SUPPORT

Github: https://github.com/Foxcool/OAuth-Simple

Bugs & Issues: https://github.com/Foxcool/OAuth-Simple/issues

=head1 AUTHOR

Alexander Babenko (foxcool@cpan.org) for Setup.ru (http://setup.ru)

=head1 CONTRIBUTORS

sugar: Anton Ukolov (aukolov@aukolov.ru)

=head1 COPYRIGHT

Copyright (c) 2012 - 2013 Alexander Babenko.

=cut
