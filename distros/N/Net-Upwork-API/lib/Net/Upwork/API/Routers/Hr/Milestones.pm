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

package Net::Upwork::API::Routers::Hr::Milestones;

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

=item get_active_milestone

    Get active Milestone for specific Contract

B<Parameters>

$contract_id

    Contract ID

B<Return value>

    JSON response as a string

=cut

sub get_active_milestone {
    my $self = shift;
    my $contract_id = shift;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item get_submissions

    Get active Milestone for specific Contract

B<Parameters>

$milestone_id

    Milestone ID

B<Return value>

    JSON response as a string

=cut

sub get_submissions {
    my $self = shift;
    my $milestone_id = shift;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item create

    Create a new Milestone

B<Parameters>

$params

    Hash of parameters

B<Return value>

    JSON response as a string

=cut

sub create {
    my $self = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item edit

    Edit an existing Milestone

B<Parameters>

$milestone_id

    Milestone ID

$params

    Hash of parameters

B<Return value>

    JSON response as a string

=cut

sub edit {
    my $self = shift;
    my $milestone_id = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item activate

    Activate an existing Milestone

B<Parameters>

$milestone_id

    Milestone ID

$params

    Hash of parameters

B<Return value>

    JSON response as a string

=cut

sub activate {
    my $self = shift;
    my $milestone_id = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item approve

    Approve an existing Milestone

B<Parameters>

$milestone_id

    Milestone ID

$params

    Hash of parameters

B<Return value>

    JSON response as a string

=cut

sub approve {
    my $self = shift;
    my $milestone_id = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item delete

    Delete existent milestone

B<Parameters>

$milestone_id

    Milestone ID

B<Return value>

    JSON response as a string

=cut

sub delete {
    my $self = shift;
    my $milestone_id = shift;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
