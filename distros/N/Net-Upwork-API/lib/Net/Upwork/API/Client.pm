# Licensed under the Upwork's API Terms of Use;
# you may not use this file except in compliance with the Terms.
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author::    Maksym Novozhylov (mnovozhilov@upwork.com)
# Copyright:: Copyright 2015(c) Upwork.com
# License::   See LICENSE.txt and TOS - https://developers.upwork.com/api-tos.html

package Net::Upwork::API::Client;

use strict;
use warnings;

use Net::OAuth;
use Net::OAuth::Client;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

use constant BASE_HOST      => "https://www.upwork.com/";
use constant DEFAULT_EPOINT => "api";

use constant DATA_FORMAT  => "json";
use constant OVERLOAD_VAR => "http_method";

use constant URI_AUTH    => "/services/api/auth";
use constant URI_RTOKEN  => "/auth/v1/oauth/token/request";
use constant URI_ATOKEN  => "/auth/v1/oauth/token/access";

use constant ENTRY_POINT_API => "api";
use constant ENTRY_POINT_GDS => "gds";

=pod

=head1 NAME

Client

=head1 FUNCTIONS

=over 4

=item new($config)

Create a new Client

B<Parameters>

$config

    Config object

=cut

sub new {
    my $class = shift;
    my $config = shift;
    my %opts = @_;
    $opts{config} = $config;
    my $self = bless \%opts, $class;

    $self->get_oauth_client();

    return $self;
}

=item get_oauth_client

    Initialize OAuth client

=cut

sub get_oauth_client {
    my $self = shift;

    $self->{oauth_client} = Net::OAuth::Client->new(
        $self->{config}{consumer_key},
        $self->{config}{consumer_secret},
        site => BASE_HOST,
        request_token_path => "/" . DEFAULT_EPOINT . URI_RTOKEN,
        authorize_path => URI_AUTH,
        access_token_path => "/" . DEFAULT_EPOINT . URI_ATOKEN,
        signature_method => $self->{config}{signature_method},
        request_token_method => 'POST',
        access_token_method => 'POST',
        callback => $self->{config}{callback},
        debug => $self->{config}{debug},
    );
}

=item get

    GET request to protected resource

B<Parameters>

$uri

    Resource URL

$params

    Hash of parameters

B<Return value>

    String

=cut

sub get {
    my $self = shift;
    my $uri = shift;
    my %params = @_;

    return $self->send_request($uri, "GET", \%params);
}

=item post

    POST request to protected resource

B<Parameters>

$uri

    Resource URL

$params

    Hash of parameters

B<Return value>

    String

=cut

sub post {
    my $self = shift;
    my $uri = shift;
    my %params = @_;

    return $self->send_request($uri, "POST", \%params);
}

=item put

    PUT request to protected resource

B<Parameters>

$uri

    Resource URL

$params

    Hash of parameters

B<Return value>

    String

=cut

sub put {
    my $self = shift;
    my $uri = shift;
    my %params = @_;

    $params{&OVERLOAD_VAR} = 'put';

    return $self->send_request($uri, "POST", \%params);
}

=item delete

    DELETE request to protected resource

B<Parameters>

$uri

    Resource URL

$params

    Hash of parameters

B<Return value>

    String

=cut

sub delete {
    my $self = shift;
    my $uri = shift;
    my %params = @_;

    $params{&OVERLOAD_VAR} = 'delete';

    return $self->send_request($uri, "POST", \%params);
}

=item send_request

    Send a signed OAuth request to a specific protected resource

B<Parameters>

$uri

    Resource URI

$method

    Request method

$params

    API parameters

B<Return value>

    String, a response content

=cut

sub send_request {
    my ($self, $uri, $method, $params) = @_;

    if (defined $self->{config}{verify_ssl} && !$self->{config}{verify_ssl}) {
        $self->{oauth_client}{user_agent}{ssl_opts} = {verify_hostname => 0, SSL_verify_mode => SSL_VERIFY_NONE};
    }
    my $request = $self->{oauth_client}->_make_request(
                    "protected resource",
                    site => BASE_HOST,
                    token => $self->{config}{access_token} || $self->{access_token}{token},
                    token_secret => $self->{config}{access_secret} || $self->{access_token}{token_secret},
                    signature_method => $self->{config}{signature_method},
                    request_method => $method,
                    request_url => $self->{oauth_client}->site_url(format_uri($uri, $self->{epoint}), %$params),
                    callback => $self->{config}{callback},
                    debug => $self->{config}{debug},
                );
    $request->sign;

    my $response = $self->{oauth_client}->request(HTTP::Request->new(
        $method => $request->to_url
    ));

    return $response->decoded_content;
}

=item format_uri

    Create a path to a specific resource

B<Parameters>

$uri

    URI to the protected resource

$epoint

    Specific epoint

B<Return value>

    String

=cut

sub format_uri {
    my ($uri, $epoint) = @_;
    $epoint ||= DEFAULT_EPOINT;

    return $epoint . $uri . (($epoint eq DEFAULT_EPOINT) ? "." . DATA_FORMAT : "");
}

=item version

    Get version of native OAuth client

=cut

sub version {
    return $Net::OAuth::VERSION;
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
