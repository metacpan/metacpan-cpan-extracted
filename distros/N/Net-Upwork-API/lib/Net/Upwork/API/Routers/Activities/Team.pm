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

package Net::Upwork::API::Routers::Activities::Team;

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

=item get_list

    List all oTask/Activity records within a team

B<Parameters>

$company

    Company ID

$team

    Team ID

B<Return value>

    JSON response as a string

=cut

sub get_list {
    my $self = shift;
    my $company = shift;
    my $team = shift;

    return get_by_type($self, $company, $team);
}

=item get_specific_list

    List all oTask/Activity records within a Company by specified code(s)

B<Parameters>

$company

    Company ID

$team

    Team ID

$code

    Code(s)

B<Return value>

    JSON response as a string

=cut

sub get_specific_list {
    my $self = shift;
    my $company = shift;
    my $team = shift;
    my $code = shift;

    return get_by_type($self, $company, $team, $code);
}

=item add_activity

    Create an oTask/Activity record within a team

B<Parameters>

$company

    Company ID

$team

    Team ID

$params

    Hash of params

B<Return value>

    JSON response as a string

=cut

sub add_activity {
    my $self = shift;
    my $company = shift;
    my $team = shift;
    my %params = @_;

    return $self->client()->post("/otask/v1/tasks/companies/" . $company . "/teams/" . $team . "/tasks", %params);
}

=item update_activities

    Update specific oTask/Activity record within a team

B<Parameters>

$company

    Company ID

$team

    Team ID

$code

    Code

$params

    Hash of params

B<Return value>

    JSON response as a string

=cut

sub update_activities {
    my $self = shift;
    my $company = shift;
    my $team = shift;
    my $code = shift;
    my %params = @_;

    return $self->client()->put("/otask/v1/tasks/companies/" . $company . "/teams/" . $team . "/tasks/" . $code, %params);
}

=item archive_activities

    Archive specific oTask/Activity record within a team

B<Parameters>

$company

    Company ID

$team

    Team ID

$code

    Code

B<Return value>

    JSON response as a string

=cut

sub archive_activities {
    my $self = shift;
    my $company = shift;
    my $team = shift;
    my $code = shift;

    return $self->client()->put("/otask/v1/tasks/companies/" . $company . "/teams/" . $team . "/archive/" . $code);
}

=item unarchive_activities

    Unarchive specific oTask/Activity record within a team

B<Parameters>

$company

    Company ID

$team

    Team ID

$code

    Code

B<Return value>

    JSON response as a string

=cut

sub unarchive_activities {
    my $self = shift;
    my $company = shift;
    my $team = shift;
    my $code = shift;

    return $self->client()->put("/otask/v1/tasks/companies/" . $company . "/teams/" . $team . "/unarchive/" . $code);
}

=item update_batch

    Update a group of oTask/Activity records within a company

B<Parameters>

$company

    Company ID

$params

    Hash of params

B<Return value>

    JSON response as a string

=cut

sub update_batch {
    my $self = shift;
    my $company = shift;
    my %params = @_;

    return $self->client()->put("/otask/v1/tasks/companies/" . $company . "/tasks/batch", %params);
}

=item get_by_type

    Get by type

B<Parameters>

$company

    Company ID

$team

    Team ID

$code

    Optional, code.

B<Return value>

    String

=cut

sub get_by_type {
    my ($self, $company, $team, $code) = @_;
    $code ||= "";

    my $url = "";
    unless ($code eq "") {
        $url .= "/" . $code;
    }

    return $self->client()->get("/otask/v1/tasks/companies/" . $company . "/teams/" . $team . "/tasks" . $url);
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
