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

package Net::Upwork::API::Routers::Reports::Time;

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

=item get_by_team_full 

    Generate Time Reports for a Specific Team (with financial info)

B<Parameters>

$company

    Company

$team

    Team

B<Return value>

    JSON response as a string

=cut

sub get_by_team_full {
    my $self = shift;
    my $company = shift;
    my $team = shift;
    my %params = @_;

    return get_by_type($company, $team, "", 0, %params);
}

=item get_by_team_limited 

    Generate Time Reports for a Specific Team (hide financial info)

B<Parameters>

$company

    Company

$team

    Team

B<Return value>

    JSON response as a string

=cut

sub get_by_team_limited {
    my $self = shift;
    my $company = shift;
    my $team = shift;
    my %params = @_;

    return get_by_type($company, $team, "", 1, %params);
}

=item get_by_agency

    Generating Agency Specific Reports

B<Parameters>

$company

    Company

$agency

    Agency

B<Return value>

    JSON response as a string

=cut

sub get_by_agency {
    my $self = shift;
    my $company = shift;
    my $agency = shift;
    my %params = @_;

    return get_by_type($company, "", $agency, 0, %params);
}

=item get_by_company

    Generating Company Wide Reports

B<Parameters>

$company

    Company

B<Return value>

    JSON response as a string

=cut

sub get_by_company {
    my $self = shift;
    my $company = shift;
    my %params = @_;

    return get_by_type($company, "", "", 0, %params);
}

=item get_by_freelancer_limited

    Generating Freelancer's Specific Reports (hide financial info)

B<Parameters>

$freelancer_id

    Freelancer ID

B<Return value>

    JSON response as a string

=cut

sub get_by_freelancer_limited {
    my $self = shift;
    my $freelancer_id = shift;
    my %params = @_;

    return $self->client()->get("/timereports/v1/providers/" . $freelancer_id . "/hours", %params);
}

=item get_by_freelancer_full

    Generating Freelancer's Specific Reports (with financial info)

B<Parameters>

$freelancer_id

    Freelancer ID

B<Return value>

    JSON response as a string

=cut

sub get_by_freelancer_full {
    my $self = shift;
    my $freelancer_id = shift;
    my %params = @_;

    return $self->client()->get("/timereports/v1/providers/" . $freelancer_id, %params);
}

=item get_by_type

    Get by type

B<Parameters>

$company

    Company

$team

    Team

$agency

    Agency

$hide_fin_data

    Hide financial data flag

$params

    Hash of parameters

B<Return value>

    String

=cut

sub get_by_type {
    my $self = shift;
    my $company = shift;
    my $team = shift;
    my $agency = shift;
    my $hide_fin_data = shift;
    my %params = @_;

    my $url = "";
    if (length $team) {
        $url = "/teams/" . $team;
        if ($hide_fin_data) {
            $url .= "/hours";
        } elsif (length $agency) {
            $url = "/agencies/" . $agency;
        }
    }

    return $self->client()->get("/timereports/v1/companies/" . $company . $url, %params);
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
