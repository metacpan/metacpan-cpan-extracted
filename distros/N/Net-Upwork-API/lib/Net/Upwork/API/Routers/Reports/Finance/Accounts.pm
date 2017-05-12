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

package Net::Upwork::API::Routers::Reports::Finance::Accounts;

use strict;
use warnings;
use parent "Net::Upwork::API";

use constant ENTRY_POINT => Net::Upwork::API::Client::ENTRY_POINT_GDS;

=pod

=head1 NAME

Auth

=head1 FUNCTIONS

=over 4

=item new($api)

Create a new object for accessing Auth API

B<Parameters>

$api

    API object

=cut

sub new {
    my ($class, $api) = @_;
    return Net::Upwork::API::init_router($class, $api, ENTRY_POINT);
}

=item get_owned

    Generate Financial Reports for an owned Account

B<Parameters>

$freelancer_ref

    Freelancer reference

B<Return value>

    JSON response as a string

=cut

sub get_owned {
    my $self = shift;
    my $freelancer_ref = shift;
    my %params = @_;

    return $self->client()->get("/finreports/v2/financial_account_owner/" . $freelancer_ref, %params);
}

=item get_specific

    Generate Financial Reports for a Specific Account

B<Parameters>

$entity_ref

    Entity reference

B<Return value>

    JSON response as a string

=cut

sub get_specific {
    my $self = shift;
    my $entity_ref = shift;
    my %params = @_;

    return $self->client()->get("/finreports/v2/financial_accounts/" . $entity_ref, %params);
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
