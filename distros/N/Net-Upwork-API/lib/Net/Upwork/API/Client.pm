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

use Net::OAuth2::Profile::WebServer;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use LWP::UserAgent;

use constant BASE_HOST      => "https://www.upwork.com";
use constant DEFAULT_EPOINT => "api";
use constant GRAPHQL_EPOINT => "https://api.upwork.com/graphql";

use constant DATA_FORMAT  => "json";
use constant OVERLOAD_VAR => "http_method";

use constant URI_AUTH    => "/ab/account-security/oauth2/authorize";
use constant URI_ATOKEN  => "/api/v3/oauth2/token";

use constant ENTRY_POINT_API => "api";
use constant ENTRY_POINT_GDS => "gds";
use constant ENTRY_POINT_GQL => "graphql";

use constant UPWORK_LIBRARY_USER_AGENT => "Github Upwork API Perl Client";

our $lwp;

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

    $lwp = LWP::UserAgent->new();
    $lwp->agent(UPWORK_LIBRARY_USER_AGENT);

    $self->{oauth_client} = Net::OAuth2::Profile::WebServer->new(
	client_id	   => $self->{config}{client_id},
        client_secret	   => $self->{config}{client_secret},
	access_token       => $self->{config}{access_token},
	refresh_token      => $self->{config}{refresh_token},
	expires_in         => $self->{config}{expires_in},
	expires_at         => $self->{config}{expires_at},
	site		   => BASE_HOST,
        authorize_path     => URI_AUTH,
	access_token_path  => URI_ATOKEN,
	refresh_token_path => URI_ATOKEN,
	redirect_uri       => $self->{config}{redirect_uri},
	user_agent         => $lwp
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

    my $_method = lc $method;
    my $response = $self->{access_token_session}->$_method($self->{oauth_client}->site_url(format_uri($uri, $self->{epoint}), %$params));

    return $response->decoded_content;
}

=item graphql_request

    Send a signed GraphQL request to a specific OAuth2 protected resource

B<Parameters>

$params

    API parameters

B<Return value>

    String, a response content

=cut

sub graphql_request {
    my ($self, $json, $tenant_id) = @_;

    my $req = HTTP::Request->new('POST', GRAPHQL_EPOINT);
    $req->header(
        'Content-Type' => 'application/json',
        'Authorization' => sprintf("%s %s", $self->{access_token_session}->token_type(), $self->{access_token_session}->access_token())
    );
    if (defined($tenant_id)) {
        $req->header('X-Upwork-API-TenantId' => $tenant_id);
    }
    $req->content($json);

    my $res = $lwp->request($req);

    return $res->decoded_content;
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

Copyright E<copy> Upwork Global Corp., 2018

=cut

1;
