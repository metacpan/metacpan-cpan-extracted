package Mslm::Common;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use URI;
use Exporter qw(import);
our @EXPORT_OK = qw($default_base_url $default_user_agent $default_api_key DEFAULT_TIMEOUT);

use constant HTTP_TOO_MANY_REQUEST => 429;
use constant DEFAULT_TIMEOUT       => 120;
our $default_base_url   = 'https://mslm.io';
our $default_user_agent = 'mslm/perl/1.0';
our $default_api_key    = '';

sub new {
    my ( $class, %opts ) = @_;
    my $self = {
        http_client => $opts{http_client}
          || "",    # HTTP client used for making requests.
        base_url    => $opts{base_url} 
          || "",    # Base URL for API requests.
        user_agent  => $opts{user_agent}
          || "",    # User-agent used when communicating with the API.
        api_key     => $opts{api_key}
          || ""     # The API key used for authentication & authorization.
    };

    bless $self, $class;
    return $self;
}

sub set_base_url {
    my ( $self, $base_url_str ) = @_;
    my $base_url = URI->new($base_url_str);
    $self->{base_url} = $base_url;
}

sub set_http_client {
    my ( $self, $http_client ) = @_;
    $self->{http_client} = $http_client;
}

sub set_user_agent {
    my ( $self, $user_agent ) = @_;
    $self->{user_agent} = $user_agent;
}

sub set_api_key {
    my ( $self, $api_key ) = @_;
    $self->{api_key} = $api_key;
}

sub prepare_url {
    my ( $self, $urlPath, $qp, %opts ) = @_;
    my $reqUrl  = $opts{base_url} || $self->{base_url};
    my $api_key = $opts{api_key}  || $self->{api_key};
    $reqUrl->path($urlPath);

    my $reqUrlQp = {};
    foreach my $key ( keys %$qp ) {
        $reqUrlQp->{$key} = $qp->{$key};
    }
    $reqUrlQp->{'apikey'} = $api_key;
    if ( $opts{disable_url_encoding} ) {
        my $query_string = '';
        foreach my $key ( keys %$reqUrlQp ) {
            my $value = $reqUrlQp->{$key};
            $query_string .= '&'           if $query_string && $value;
            $query_string .= "$key=$value" if $value;
        }
        $reqUrl->query($query_string);
    }
    else {
        $reqUrl->query_form($reqUrlQp);
    }

    return $reqUrl;
}

sub req_and_resp {
    my ( $self, $http_client, $method, $reqUrl, $data, %opts ) = @_;

    my $user_agent = $opts{user_agent} || $self->{user_agent};
    my $req        = HTTP::Request->new( $method, $reqUrl );
    $req->content($data) if defined $data;
    my $http_c = $http_client;
    $http_c->agent($user_agent);

    my $response = $http_c->request($req);
    if ( $response->is_success ) {
        my $decoded_json = decode_json( $response->decoded_content );
        return ( $decoded_json, '' );
    }
    if ( $response->code == HTTP_TOO_MANY_REQUEST ) {
        return ( undef, 'Your API request limit has reached.' );
    }

    return ( undef, $response->status_line );
}

1;
=pod

=head1 NAME

Mslm::Common - Perl module containing common functions for API interactions

=head1 SYNOPSIS

  use Mslm::Common;

  # Create a new instance
  my $common = Mslm::Common->new(
      http_client => $http_client,
      base_url    => $base_url,
      user_agent  => $user_agent,
      api_key     => $api_key
  );

  # Set base URL
  $common->set_base_url('https://example.com');

  # Set HTTP client
  $common->set_http_client($custom_LWP_UserAgent);

  # Set user agent
  $common->set_user_agent('my-custom-agent/1.0');

  # Set API key
  $common->set_api_key('my-api-key');

=head1 DESCRIPTION

The Mslm::Common module contains common functions for handling API interactions such as setting base URL, HTTP client, user agent, and API key.

=head1 METHODS

=head2 new

Creates a new instance of Mslm::Common.

=head3 Arguments

=over 4

=item * C<%opts> (hash) - Optional parameters. You can pass in the following opts: C<base_url>, C<user_agent>, C<api_key>, and C<http_client>. These settings can also be done via the setter functions named: C<set_base_url>, C<set_user_agent>, C<set_api_key>, C<set_http_client>.

=back

=head2 set_base_url

Sets the base URL for API requests.

=head3 Arguments

=over 4

=item * C<$base_url_str> (string) - The base URL to be set for API requests.

=back

=head2 set_http_client

Sets the HTTP client for making requests.

=head3 Arguments

=over 4

=item * C<$http_client> (LWP::UserAgent) - The HTTP client to be set.

=back

=head2 set_user_agent

Sets the user agent for API requests.

=head3 Arguments

=over 4

=item * C<$user_agent> (string) - The user agent string to be set.

=back

=head2 set_api_key

Sets the API key for authentication.

=head3 Arguments

=over 4

=item * C<$api_key> (string) - The API key to be set.

=back

=head2 prepare_url

Prepares the URL for making API requests.

=head3 Arguments

=over 4

=item * C<$urlPath> (string) - The path for the API request.

=item * C<$qp> (hash reference) - Query parameters for the API request.

=item * C<%opts> (hash) - Optional parameters. You can pass in the following opts: C<base_url>, C<api_key>, and C<disable_url_encoding>. These options will only work for the current request.

=back

=head2 req_and_resp

Performs the API request and fetches the response.

=head3 Arguments

=over 4

=item * C<$http_client> (LWP::UserAgent) - The HTTP client to be used for the request.

=item * C<$method> (string) - The HTTP method for the request.

=item * C<$reqUrl> (string) - The URL for the request.

=item * C<$data> (bytes)- Data to be sent with the request (if any). Must be a string of bytes.

=item * C<%opts> (hash) - Optional parameters. You can pass in the opt: C<user_agent>.

=back

=head1 AUTHOR

Mslm, C<< <usama.liaqat@mslm.io> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022-now mslm. All rights reserved.

=cut

# End of Mslm::Common
