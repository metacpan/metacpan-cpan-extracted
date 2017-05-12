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

package Net::Upwork::API::Config;

use strict;
use warnings;

=pod

=head1 NAME

Config

=head1 FUNCTIONS

=over 4

=item new(%params)

Create a new Config

B<Parameters>

$params

    List of configuration options

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    $opts{consumer_key} ||= "";
    $opts{consumer_secret} ||= "";
    $opts{access_token} ||= "";
    $opts{access_secret} ||= "";
    $opts{callback} ||= "oob";
    $opts{signature_method} ||= "HMAC-SHA1";
    $opts{debug} ||= 0;
    unless ($opts{consumer_key} && $opts{consumer_secret}) {
        die "You must specify a consumer key and a secret in the config\n";
    }
    my $self = bless \%opts, $class;

    return $self;
}

=back

=head1 AUTHOR

Maksym Novozhylov C<< <mnovozhilov@upwork.com> >>

=head1 COPYRIGHT

Copyright E<copy> Upwork Global Corp., 2015

=cut

1;
