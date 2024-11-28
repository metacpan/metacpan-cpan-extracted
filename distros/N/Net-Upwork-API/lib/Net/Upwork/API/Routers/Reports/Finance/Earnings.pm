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

package Net::Upwork::API::Routers::Reports::Finance::Earnings;

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

=item get_by_freelancer

    Generate Earning Reports for a Specific Freelancer

B<Parameters>

$freelancer_ref

    Freelancer reference

B<Return value>

    JSON response as a string

=cut

sub get_by_freelancer {
    my $self = shift;
    my $freelancer_ref = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item get_by_freelancers_team

    Generate Earning Reports for a Specific Freelancer's Team

B<Parameters>

$freelancer_team_ref

    Freelancer's team reference

B<Return value>

    JSON response as a string

=cut

sub get_by_freelancers_team {
    my $self = shift;
    my $freelancer_team_ref = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item get_by_freelancers_company

    Generate Earning Reports for a Specific Freelancer's Company

B<Parameters>

$freelancer_company_ref

    Freelancer's company reference

B<Return value>

    JSON response as a string

=cut

sub get_by_freelancers_company {
    my $self = shift;
    my $freelancer_company_ref = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item get_by_buyers_team

    Generate Earning Reports for a Specific Buyer's Team

B<Parameters>

$buyer_team_ref

    Buyer's team reference

B<Return value>

    JSON response as a string

=cut

sub get_by_buyers_team {
    my $self = shift;
    my $buyer_team_ref = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=item get_by_buyers_company

    Generate Earning Reports for a Specific Buyer's Company

B<Parameters>

$buyer_company_ref

    Buyer's company reference

B<Return value>

    JSON response as a string

=cut

sub get_by_buyers_company {
    my $self = shift;
    my $buyer_company_ref = shift;
    my %params = @_;

    die "The legacy API was deprecated. Please, use GraphQL call - see example in this library.";
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
