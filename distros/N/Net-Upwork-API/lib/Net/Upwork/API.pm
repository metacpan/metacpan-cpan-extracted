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

package Net::Upwork::API;

use strict;
use warnings;

use Net::Upwork::API::Config;
use Net::Upwork::API::Client;

our $VERSION = '2.1.4';

use constant TOKEN_TYPE_BEARER => 'Bearer';

=pod

=head1 NAME

Net::Upwork::API - Perl bindings for Upwork API (OAuth2).

=head1 FUNCTIONS

=over 4

=item new($config)

Create a new Config

B<Parameters>

$config

    Config object

=cut

sub new {
    my $class = shift;
    my $config = shift;
    my %opts = @_;
    $opts{config} = $config;

    my $client = Net::Upwork::API::Client->new($config);
    $opts{client} = $client;

    my $self = bless \%opts, $class;

    return $self;
}

=item init_router

    Initialize router

B<Parameters>

$class

    Class

$api

    API object

$epoint

    Entry point for the router

B<Return value>

    Object

=cut

sub init_router {
    my $class = shift;
    my $api = shift;
    my $epoint = shift;
    my %opts = @_;

    $opts{client} = $api->{client};
    $opts{client}{epoint} = $epoint;
    my $self = bless \%opts, $class;

    return $self;
}

=item get_access_token()

    Get access token key/secret pair

B<Parameters>

$code

    Authorization Code, see https://tools.ietf.org/html/rfc6749.html#section-1.3.1

B<Return value>

    Net::OAuth2::AccessToken object 

=cut

sub get_access_token {
    my $self = shift;
    my ($code) = @_;

    chomp($code);

    $self->{client}{access_token_session} = $self->{client}{oauth_client}->get_access_token($code);

    return $self->{client}{access_token_session};
}

=item get_authorization_url()

    Get Authorization Url and request token

B<Return value>

    A string for authorization in the browser

=cut

sub get_authorization_url {
    my $self = shift;

    return $self->{client}{request_token} = $self->{client}{oauth_client}->authorize_response->as_string;
}

=item has_access_token()

    Check if access token has been already received

B<Return value>

    Boolean

=cut

sub has_access_token {
    my $self = shift;

    return defined $self->{client}{access_token} ||
            (!($self->{config}{access_token} eq "") && !($self->{config}{refresh_token} eq ""));
}

=item set_access_token_session()

    Sets the AccessToken session based on the provided config

B<Return value>

    Net::OAuth2::AccessToken object

=cut

sub set_access_token_session() {
    my $self = shift;

    $self->{client}{access_token_session} = Net::OAuth2::AccessToken->new(
        profile      => $self->{client}->get_oauth_client,
        auto_refresh => 0,
	(
	    access_token  => $self->{config}{access_token},
	    refresh_token => $self->{config}{refresh_token},
	    token_type    => TOKEN_TYPE_BEARER,
	    expires_in    => $self->{config}{expires_in},
	    expires_at    => $self->{config}{expires_at}
	)
    );

    # expire? then refresh
    if ($self->{config}{expires_at} < time()) {
        $self->{client}{access_token_session}->refresh();
    }
}

=item client()

    Get client object

B<Return value>

    Object

=cut

sub client {
    my $self = shift;
    return $self->{client};
}

=back

=head1 LICENSE

This is released under the Apache Version 2.0
License. See L<https://www.apache.org/licenses/LICENSE-2.0>.

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2018

=cut

1;
