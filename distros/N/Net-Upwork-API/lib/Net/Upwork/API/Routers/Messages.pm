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
# Copyright:: Copyright 2016(c) Upwork.com
# License::   See LICENSE.txt and TOS - https://developers.upwork.com/api-tos.html

package Net::Upwork::API::Routers::Messages;

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

=item get_rooms

    Retrive rooms information

B<Return value>

    JSON response as a string

=cut

sub get_rooms {
    my $self = shift;
    my $company = shift;
    my %params = @_;

    return $self->client()->get("/messages/v3/" . $company . "/rooms", %params);
}

=item get_room_details

    Get a specific room information

B<Return value>

    JSON response as a string

=cut

sub get_room_details {
    my $self = shift;
    my $company = shift;
    my $room_id = shift;
    my %params = @_;

    return $self->client()->get("/messages/v3/" . $company . "/rooms/" . $room_id, %params);
}

=item get_room_messages

    Get messages from a specific room

B<Return value>

    JSON response as a string

=cut

sub get_room_messages {
    my $self = shift;
    my $company = shift;
    my $room_id = shift;
    my %params = @_;

    return $self->client()->get("/messages/v3/" . $company . "/rooms/" . $room_id . "/stories", %params);
}

=item get_room_by_offer

    Get a specific room by offer ID

B<Return value>

    JSON response as a string

=cut

sub get_room_by_offer {
    my $self = shift;
    my $company = shift;
    my $offer_id = shift;
    my %params = @_;

    return $self->client()->get("/messages/v3/" . $company . "/rooms/offers/" + $offer_id, %params);
}

=item get_room_by_application

    Get a specific room by application ID

B<Return value>

    JSON response as a string

=cut

sub get_room_by_application {
    my $self = shift;
    my $company = shift;
    my $application_id = shift;
    my %params = @_;

    return $self->client()->get("/messages/v3/" . $company . "/rooms/applications/" + $application_id, %params);
}

=item get_room_by_contract

    Get a specific room by contract ID

B<Return value>

    JSON response as a string

=cut

sub get_room_by_contract {
    my $self = shift;
    my $company = shift;
    my $contract_id = shift;
    my %params = @_;

    return $self->client()->get("/messages/v3/" . $company . "/rooms/contracts/" + $contract_id, %params);
}

=item create_room

    Create a new room

B<Return value>

    JSON response as a string

=cut

sub create_room {
    my $self = shift;
    my $company = shift;
    my %params = @_;

    return $self->client()->post("/messages/v3/" . $company . "/rooms", %params);
}

=item send_message_to_room

    Send a message to a room

B<Return value>

    JSON response as a string

=cut

sub send_message_to_room {
    my $self = shift;
    my $company = shift;
    my $room_id = shift;
    my %params = @_;

    return $self->client()->post("/messages/v3/" . $company . "/rooms/" . $room_id . '/stories', %params);
}

=item update_room_settings

    Update a room settings

B<Return value>

    JSON response as a string

=cut

sub update_room_settings {
    my $self = shift;
    my $company = shift;
    my $room_id = shift;
    my $username = shift;
    my %params = @_;

    return $self->client()->put("/messages/v3/" . $company . "/rooms/" . $room_id . "/users/" . $username, %params);
}

=item update_room_metadata

    Update the metadata of a room

B<Return value>

    JSON response as a string

=cut

sub update_room_metadata {
    my $self = shift;
    my $company = shift;
    my $room_id = shift;
    my %params = @_;

    return $self->client()->put("/messages/v3/" . $company . "/rooms/" . $room_id, %params);
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2016

=cut

1;
