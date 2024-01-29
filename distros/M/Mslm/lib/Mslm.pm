package Mslm;

use 5.006;
use strict;
use warnings;
use Mslm::Common qw($default_base_url $default_user_agent $default_api_key DEFAULT_TIMEOUT);
use Mslm::EmailVerify;
use Mslm::OTP;

our $VERSION = '1.0';

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
    $self->{timeout} = $timeout;
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

    $self->{email_verify} = Mslm::EmailVerify->new(
        $self->{api_key},
        http_client => $self->{http_client},
        base_url    => $self->{base_url},
        user_agent  => $self->{user_agent},
        timeout     => $self->{timeout}
    );
    $self->{otp} = Mslm::OTP->new(
        $self->{api_key},
        http_client => $self->{http_client},
        base_url    => $self->{base_url},
        user_agent  => $self->{user_agent},
        timeout     => $self->{timeout}
    );

    bless $self, $class;
    return $self;
}

sub email_verify {
    my ($self) = @_;
    return $self->{email_verify};
}

sub otp {
    my ($self) = @_;
    return $self->{otp};
}

sub set_base_url {
    my ( $self, $base_url_str ) = @_;
    my $base_url = URI->new($base_url_str);
    $self->{base_url} = $base_url;
    $self->{email_verify}->set_base_url($base_url);
    $self->{otp}->set_base_url($base_url);
}

sub set_http_client {
    my ( $self, $http_client ) = @_;
    $self->{http_client} = $http_client;
    $self->{email_verify}->set_http_client($http_client);
    $self->{otp}->set_http_client($http_client);
}

sub set_user_agent {
    my ( $self, $user_agent ) = @_;
    $self->{user_agent} = $user_agent;
    $self->{email_verify}->set_user_agent($user_agent);
    $self->{otp}->set_user_agent($user_agent);
}

sub set_api_key {
    my ( $self, $api_key ) = @_;
    $self->{api_key} = $api_key;
    $self->{email_verify}->set_api_key($api_key);
    $self->{otp}->set_api_key($api_key);
}


1;
__END__

=head1 NAME

Mslm - The official Perl Library for Mslm APIs.

=head1 VERSION

Version 1.0
  - Initial release.

=cut

=head1 SYNOPSIS

Mslm - The official Perl Library for Mslm APIs. Mslm focuses on producing world-class business solutions. It's the bread-and-butter of our business to prioritize quality on everything we touch. Excellence is a core value that defines our culture from top to bottom.

  use Mslm;

  # Create a new instance
  my $mslm = Mslm->new($api_key, %opts);

  # Access Email Verification functionality
  my $email_verifier = $mslm->email_verify();

  # Access OTP functionality
  my $otp_handler = $mslm->otp();

=head1 DESCRIPTION

The official Perl SDK for Mslm APIs. Mslm focuses on producing world-class business solutions. It's the bread-and-butter of our business to prioritize quality on everything we touch. Excellence is a core value that defines our culture from top to bottom.

=head1 METHODS

=head2 new

Creates a new instance of Mslm.

=head3 Arguments

=over 4

=item * C<$api_key> (string) - The API key required for authentication.

=item * C<%opts> (hash) - Optional parameters. You can pass in the following opts: C<base_url>, C<user_agent>, C<timeout>, and C<http_client>. These settings can also be done via the setter functions named: C<set_base_url>, C<set_user_agent>, C<set_api_key>, C<set_http_client>.

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

=head2 email_verify

Returns an object for handling email verification using Mslm's EmailVerify functionality.

=head3 Example

  my $email_verifier = $mslm->email_verify->new('your_api_key');

=head2 otp

Returns an object for handling OTP (One-Time Password) functionality using Mslm's OTP service.

=head3 Example

  my $otp_handler = $mslm->otp->new('your_api_key');


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Mslm, C<< <usama.liaqat@mslm.io> >>

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022-now mslm

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


=cut

# End of Mslm
