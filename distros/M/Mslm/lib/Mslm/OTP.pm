package Mslm::OTP;

use 5.006;
use strict;
use warnings;
use Mslm::Common qw($default_base_url $default_user_agent $default_api_key DEFAULT_TIMEOUT);
use URI;
use LWP::UserAgent;
use JSON;

our $send_api_path    = '/api/otp/v1/send';
our $verify_api_path  = '/api/otp/v1/token_verify';

sub new {
    my ( $class, $api_key, %opts ) = @_;
    my $self       = {};
    my $timeout    = $opts{timeout}    || DEFAULT_TIMEOUT;
    my $user_agent = $opts{user_agent} || $default_user_agent;
    my $base_url   = $opts{base_url}   || $default_base_url;
    my $access_key = $api_key          || $default_api_key;
    $self->{base_url}   = URI->new($base_url);
    $self->{api_key}    = $access_key;
    $self->{user_agent} = $user_agent;
    my $default_http_client = LWP::UserAgent->new;
    $default_http_client->ssl_opts( 'verify_hostname' => 0 );
    $default_http_client->default_headers(
        HTTP::Headers->new(
            Accept => 'application/json'
        )
    );
    $default_http_client->agent($user_agent);
    $default_http_client->timeout($timeout);
    $self->{http_client} = $opts{http_client} || $default_http_client;

    $self->{common_client} = Mslm::Common->new(
        http_client => $self->{http_client},
        base_url    => $self->{base_url},
        user_agent  => $self->{user_agent},
        api_key     => $self->{api_key}
    );

    bless $self, $class;
    return $self;
}

sub error_msg {
    my $self = shift;

    return $self->{message};
}

sub set_base_url {
    my ( $self, $base_url_str ) = @_;
    my $base_url = URI->new($base_url_str);
    $self->{base_url} = $base_url;
    $self->{common_client}->set_base_url($base_url);
}

sub set_http_client {
    my ( $self, $http_client ) = @_;
    $self->{http_client} = $http_client;
    $self->{common_client}->set_http_client($http_client);
}

sub set_user_agent {
    my ( $self, $user_agent ) = @_;
    $self->{user_agent} = $user_agent;
    $self->{common_client}->set_user_agent($user_agent);
}

sub set_api_key {
    my ( $self, $api_key ) = @_;
    $self->{api_key} = $api_key;
    $self->{common_client}->set_api_key($api_key);
}

sub send {
    my ( $self, $otp_send_req, %opts ) = @_;

    # Check if $otp_send_req is a hash reference
    if ( ref($otp_send_req) ne 'HASH' ) {
        $self->{message} =
          "Invalid input format: \$otp_send_req must be a hash reference.";
        return undef;
    }

    # Validate keys in $otp_send_req
    my @required_keys = qw(phone tmpl_sms token_len expire_seconds);
    foreach my $key (@required_keys) {
        unless ( exists $otp_send_req->{$key} ) {
            $self->{message} =
              "Missing required key: $key in \$otp_send_req.";
            return undef;
        }
    }

    # Setting options just for this request
    my $common_client = $self->{common_client};
    my $base_url      = URI->new( $opts{base_url} ) || $self->{base_url};
    my $user_agent    = $opts{user_agent}           || $self->{user_agent};
    my $api_key       = $opts{api_key}              || $self->{api_key};
    my $http_client   = $opts{http_client}          || $self->{http_client};

    # Prepare and send request
    my $qp     = {};
    my $reqUrl = $common_client->prepare_url(
        $send_api_path,
        $qp,
        base_url => $base_url,
        api_key  => $api_key,
    );
    my $encoded_json_data = encode_json($otp_send_req);
    my ( $response, $msg ) =
      $common_client->req_and_resp( $http_client, 'POST', $reqUrl,
        $encoded_json_data, user_agent => $user_agent );
    $self->{message} = $msg;

    return defined $response ? $response : undef;
}

sub verify {
    my ( $self, $otp_token_verify_req, %opts ) = @_;

    # Check if $otp_token_verify_req is a hash reference
    if ( ref($otp_token_verify_req) ne 'HASH' ) {
        $self->{message} =
          "Invalid input format: \$otp_token_verify_req must be a hash reference.";
        return undef;
    }

    # Validate keys in $otp_token_verify_req
    my @required_keys = qw(phone token consume);
    foreach my $key (@required_keys) {
        unless ( exists $otp_token_verify_req->{$key} ) {
            $self->{message} =
              "Missing required key: $key in \$otp_token_verify_req.";
            return undef;
        }
    }

    # Setting options just for this request
    my $common_client = $self->{common_client};
    my $base_url      = URI->new( $opts{base_url} ) || $self->{base_url};
    my $user_agent    = $opts{user_agent}           || $self->{user_agent};
    my $api_key       = $opts{api_key}              || $self->{api_key};
    my $http_client   = $opts{http_client}          || $self->{http_client};

    # Prepare and send request
    my $qp     = {};
    my $reqUrl = $common_client->prepare_url(
        $verify_api_path,
        $qp,
        base_url => $base_url,
        api_key  => $api_key,
    );
    my $encoded_json_data = encode_json($otp_token_verify_req);
    my ( $response, $msg ) =
      $common_client->req_and_resp( $http_client, 'POST', $reqUrl,
        $encoded_json_data, user_agent => $user_agent );
    $self->{message} = $msg;

    return defined $response ? $response : undef;
}

1;
__END__

=head1 NAME

Mslm::OTP - Perl module for handling OTP (One-Time Password) functionality

=head1 SYNOPSIS

  use Mslm::OTP;

  my $otp = Mslm::OTP->new($api_key);

  # Sending OTP
  my $response = $otp->send({
      phone          => '03001234567',
      tmpl_sms       => 'Your verification code is: <otp>',
      token_len      => 6,
      expire_seconds => 60
  });

  # Verifying OTP token
  my $verification_result = $otp->verify({
      phone   => '1234567890',
      token   => '123456',
      consume => \1
  });

=head1 DESCRIPTION

The Mslm::OTP module provides methods to send OTP (One-Time Password) and verify the OTP token using an API.

=head1 METHODS

=head2 new

Creates a new instance of Mslm::OTP.

=head3 Arguments

=over 4

=item * C<$api_key> (string) - The API key required for authentication.

=item * C<%opts> (hash) - Optional parameters. You can pass in the following opts: C<base_url>, C<user_agent>, C<api_key>, and C<http_client>. These settings can also be done via the setter functions named: C<set_base_url>, C<set_user_agent>, C<set_api_key>, C<set_http_client>.

=back

=head2 error_msg

Returns a string containing the error message of the last operation, it returns an empty
string if the last operation was successful

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

=head2 send

Sends an OTP to the specified phone number.

=head3 Arguments

=over 4

=item * C<$otp_send_req> (hash reference) - A hash reference containing the OTP sending request parameters.

=item * C<%opts> (hash) - Optional parameters. You can pass in the following opts: C<base_url>, C<user_agent>, C<api_key>, and C<http_client>. These options will only work for the current request.

=back

=head2 verify

Verifies the OTP token.

=head3 Arguments

=over 4

=item * C<$otp_token_verify_req> (hash reference) - A hash reference containing the OTP token verification request parameters.

=item * C<%opts> (hash) - Optional parameters. You can pass in the following opts: C<base_url>, C<user_agent>, C<api_key>, and C<http_client>. These options will only work for the current request.

=back

=head1 AUTHOR

Mslm, C<< <usama.liaqat@mslm.io> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022-now mslm. All rights reserved.

=cut

# End of Mslm::OTP
