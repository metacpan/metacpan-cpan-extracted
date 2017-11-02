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

our $VERSION = '1.2.3';

=pod

=head1 NAME

API

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

$verifier

    OAuth verifier

B<Return value>

    A hash that contains access token and secret

=cut

sub get_access_token {
    my $self = shift;
    my ($verifier) = @_;

    chomp($verifier);

    $self->{client}{access_token} = $self->{client}{oauth_client}->get_access_token(
                    $self->{client}{request_token}{token},
                    $verifier,
                    token_secret => $self->{client}{request_token}{token_secret},
                );

    return {access_token => $self->{client}{access_token}{token}, access_secret => $self->{client}{access_token}{token_secret}}
}

=item get_authorization_url()

    Get Authorization Url and request token

B<Return value>

    A string for authorization in the browser

=cut

sub get_authorization_url {
    my $self = shift;

    $self->{client}{request_token} = $self->{client}{oauth_client}->get_request_token();
    return $self->{client}{oauth_client}->site_url($self->{client}{oauth_client}->_make_url('authorize', oauth_token => $self->{client}{request_token}{token}));
}

=item has_access_token()

    Check if access token has been already received

B<Return value>

    Boolean

=cut

sub has_access_token {
    my $self = shift;

    return defined $self->{client}{access_token} ||
            (!($self->{config}{access_token} eq "") && !($self->{config}{access_secret} eq ""));
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

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
