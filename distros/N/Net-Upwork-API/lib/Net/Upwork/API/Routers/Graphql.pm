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
# Copyright:: Copyright 2021(c) Upwork.com
# License::   See LICENSE.txt and TOS - https://developers.upwork.com/api-tos.html

package Net::Upwork::API::Routers::Graphql;

use strict;
use warnings;
use parent "Net::Upwork::API";
use JSON::MaybeXS qw/encode_json/;

use constant ENTRY_POINT => Net::Upwork::API::Client::ENTRY_POINT_GQL;

=pod

=head1 NAME

Graphql

=head1 FUNCTIONS

=over 4

=item new($api)

Create a new object for accessing GraphQL API

B<Parameters>

$api

    API object

=cut

sub new {
    my ($class, $api) = @_;
    return Net::Upwork::API::init_router($class, $api, ENTRY_POINT);
}

=item set_org_uid_header

    Configure X-Upwork-API-TenantId header

B<Parameters>

$tenant_id

    Organization UID

B<Return value>

    void

=cut

sub set_org_uid_header {
    my ($self, $tenant_id) = @_;

    $self->{tenant_id} = $tenant_id;
}

=item execute

    Execute GraphQL request

B<Return value>

    JSON response as a string

=cut

sub execute {
    my $self = shift;
    my %params = @_;

    my $json = encode_json \%params;

    return $self->client()->graphql_request($json, $self->{tenant_id});
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2021

=cut

1;
