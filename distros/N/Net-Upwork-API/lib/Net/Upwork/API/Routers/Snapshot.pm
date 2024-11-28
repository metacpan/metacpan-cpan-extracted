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

package Net::Upwork::API::Routers::Snapshot;

use strict;
use warnings;
use parent "Net::Upwork::API";

use constant ENTRY_POINT => Net::Upwork::API::Client::ENTRY_POINT_API;

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

=item get_by_contract

    Get snapshot info by specific contract

B<Parameters>

$contract

    Contract number

$ts

    Timestamp

B<Return value>

    JSON response as a string

=cut

sub get_by_contract {
    my $self = shift;
    my $contract = shift;
    my $ts = shift;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item update_by_contract

    Update snapshot info by specific contract

B<Parameters>

$contract

    Contract number

$ts

    Timestamp

$params

    Hash of parameters

B<Return value>

    JSON response as a string

=cut

sub update_by_contract {
    my $self = shift;
    my $contract = shift;
    my $ts = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item delete_by_contract

    Delete snapshot info by specific contract

B<Parameters>

$contract

    Contract number

$ts

    Timestamp

B<Return value>

    JSON response as a string

=cut

sub delete_by_contract {
    my $self = shift;
    my $contract = shift;
    my $ts = shift;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
