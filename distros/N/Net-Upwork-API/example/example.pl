#!/usr/bin/env perl
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
# Copyright:: Copyright 2018(c) Upwork.com
# License::   See LICENSE.txt and TOS - https://developers.upwork.com/api-tos.html

use lib "./lib"; # UPDATE IF NEEDED
use Data::Dumper;
use Net::Upwork::API;
use Net::Upwork::API::Routers::Auth;
use Net::Upwork::API::Routers::Graphql;

$config = Net::Upwork::API::Config->new(
    'client_id'     => 'xxxxxxxx',
    'client_secret' => 'xxxxxxxx',
    'redirect_uri'  => 'https://your-call-back-url.here',
#    'grant_type' => 'client_credentials', # used for Client Credentials Grant
#    'access_token'  => 'xxxxxxxx',
#    'refresh_token' => 'xxxxxxxx', # used by Code Authorization Grant
#    'expires_in' => 86399 # TTL. `expires_at` should be enough for basic usage but you may find this option useful for own needs
#    'expires_at' => 1234567890 # timestamp, either get from the Net::OAuth2::AccessToken object or set like time()+actual_expires_in
);

$api = Net::Upwork::API->new($config);
if (!$api->has_access_token()) {
  # start Code Authorization Grant
    my $authz_url = $api->get_authorization_url();

    print "Visit the authorization url and provide oauth_verifier for further authorization\n";
    print $authz_url . "\n";
    $| = "";
    $code = <STDIN>;
    
    my $session = $api->get_access_token($code);
  # end Code Authorization Grant
    #my $session = $api->get_access_token(); # Client Credentials Grant
    #print Dumper $session; # Net::OAuth2::AccessToken object
    #print Dumper $session->access_token;
    #print Dumper $session->refresh_token;
    #print Dumper $session->expires_in;
    # store access token data in safe place!
} else {
    $session = $api->set_access_token_session();
    #print Dumper $session; # Net::OAuth2::AccessToken object
    #
    # WARNING: set_access_token_session() will refresh the access token for you
    # in case it's expired, i.e. expires_at < time(). Make sure you replace the
    # old token accordingly in your security storage.
}

$auth = Net::Upwork::API::Routers::Auth->new($api);
$data = $auth->get_user_info();

print Dumper $data;

my $query = <<'EOF';
query {
      user {
        id
        nid
        rid
      }
      organization {
        id
      }
    }
EOF
$graphql = Net::Upwork::API::Routers::Graphql->new($api);
#$graphql->set_org_uid_header('1234567890'); # Organization UID (optional)
%params = (
    'query' => $query
);
$data2 = $graphql->execute(%params);

print Dumper $data2;
