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

package Net::Upwork::API::Routers::Metadata;

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

=item get_categories_v2

    Get categories (V2)

B<Return value>

    JSON response as a string

=cut

sub get_categories_v2 {
    my $self = shift;

    return $self->client()->get("/profiles/v2/metadata/categories");
}

=item get_skills

    Get skills

B<Return value>

    JSON response as a string

=cut

sub get_skills {
    my $self = shift;

    return $self->client()->get("/profiles/v1/metadata/skills");
}

=item get_skills_v2

    Get skills V2

B<Return value>

    JSON response as a string

=cut

sub get_skills_v2 {
    my $self = shift;

    return $self->client()->get("/profiles/v2/metadata/skills");
}

=item get_specialties

    Get specialties

B<Return value>

    JSON response as a string

=cut

sub get_specialties {
    my $self = shift;

    return $self->client()->get("/profiles/v1/metadata/specialties");
}

=item get_regions

    Get regions

B<Return value>

    JSON response as a string

=cut

sub get_regions {
    my $self = shift;

    return $self->client()->get("/profiles/v1/metadata/regions");
}

=item get_tests

    Get tests

B<Return value>

    JSON response as a string

=cut

sub get_tests {
    my $self = shift;

    return $self->client()->get("/profiles/v1/metadata/tests");
}

=item get_reasons

    Get reasons

B<Parameters>

$params

    Hash of parameters

B<Return value>

    JSON response as a string

=cut

sub get_reasons {
    my $self = shift;
    my %params = @_;

    return $self->client()->get("/profiles/v1/metadata/reasons", %params);
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
