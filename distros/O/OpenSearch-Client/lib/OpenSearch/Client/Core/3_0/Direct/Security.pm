# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package OpenSearch::Client::Core::3_0::Direct::Security;
$OpenSearch::Client::Core::3_0::Direct::Security::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('security');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Security>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->security-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Security in OpenSearch>


Manage access control and authentication tokens.

L<See OpenSearch documentation for security.|https://docs.opensearch.org/latest/security/access-control/api/>

=head1 METHODS
    
=head2 authinfo

Returns or updates authentication information for the currently authenticated user.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/authinfo>

=item
C<POST /_plugins/_security/authinfo>

=back

    $resp = $client->security->authinfo(
        
         # Endpoint specific query string parameters
        
        'auth_type'    =>  $qval1,     # string
        'verbose'      =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for security-E<gt>authinfo|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 authtoken

Returns the authorization token for the current user.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_security/api/authtoken>

=back

    $resp = $client->security->authtoken(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>authtoken|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 change_password

Changes the password for the current user.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/account>

=back

    $resp = $client->security->change_password(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>change_password|https://opensearch.org/docs/latest/security/access-control/api/#change-password>
    
=head2 config_upgrade_check

Checks whether or not an upgrade can be performed and which security resources can be updated.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/_upgrade_check>

=back

    $resp = $client->security->config_upgrade_check(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>config_upgrade_check|https://opensearch.org/docs/latest/security/access-control/api/#configuration-upgrade-check>
    
=head2 config_upgrade_perform

Assists the cluster operator with upgrading missing default values and stale default definitions.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_security/api/_upgrade_perform>

=back

    $resp = $client->security->config_upgrade_perform(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>config_upgrade_perform|https://opensearch.org/docs/latest/security/access-control/api/#configuration-upgrade>
    
=head2 create_action_group

Creates or replaces the specified action group.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/actiongroups/{action_group}>

=back

    $resp = $client->security->create_action_group(
        
        'body'          =>  $body,      # optional
        
         # path parameters
        
        'action_group'  =>  $action_group,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>create_action_group|https://opensearch.org/docs/latest/security/access-control/api/#create-action-group>
    
=head2 create_allowlist

Creates or replaces APIs permitted for users on the allow list. Requires a super admin certificate or REST API permissions.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/allowlist>

=back

    $resp = $client->security->create_allowlist(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>create_allowlist|https://opensearch.org/docs/latest/security/access-control/api/#access-control-for-the-api>
    
=head2 create_role

Creates or replaces the specified role.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/roles/{role}>

=back

    $resp = $client->security->create_role(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'role'         =>  $role,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>create_role|https://opensearch.org/docs/latest/security/access-control/api/#create-role>
    
=head2 create_role_mapping

Creates or replaces the specified role mapping.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/rolesmapping/{role}>

=back

    $resp = $client->security->create_role_mapping(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'role'         =>  $role,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>create_role_mapping|https://opensearch.org/docs/latest/security/access-control/api/#create-role-mapping>
    
=head2 create_tenant

Creates or replaces the specified tenant.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/tenants/{tenant}>

=back

    $resp = $client->security->create_tenant(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'tenant'       =>  $tenant,    # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>create_tenant|https://opensearch.org/docs/latest/security/access-control/api/#create-tenant>
    
=head2 create_update_tenancy_config

Creates or replaces the multi-tenancy configuration. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/tenancy/config>

=back

    $resp = $client->security->create_update_tenancy_config(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>create_update_tenancy_config|https://opensearch.org/docs/latest/security/multi-tenancy/dynamic-config/#configuring-multi-tenancy-with-the-rest-api>
    
=head2 create_user

Creates or replaces the specified user.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/internalusers/{username}>

=back

    $resp = $client->security->create_user(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>create_user|https://opensearch.org/docs/latest/security/access-control/api/#create-user>
    
=head2 create_user_legacy

Creates or replaces the specified user. Legacy API.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/user/{username}>

=back

    $resp = $client->security->create_user_legacy(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>create_user_legacy|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 delete_action_group

Deletes the specified action group.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_security/api/actiongroups/{action_group}>

=back

    $resp = $client->security->delete_action_group(
        
         # path parameters
        
        'action_group'  =>  $action_group,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>delete_action_group|https://opensearch.org/docs/latest/security/access-control/api/#delete-action-group>
    
=head2 delete_distinguished_name

Deletes all distinguished names in the specified cluster or node allowlist. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_security/api/nodesdn/{cluster_name}>

=back

    $resp = $client->security->delete_distinguished_name(
        
         # path parameters
        
        'cluster_name'  =>  $cluster_name,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>delete_distinguished_name|https://opensearch.org/docs/latest/security/access-control/api/#delete-distinguished-names>
    
=head2 delete_role

Deletes the specified role.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_security/api/roles/{role}>

=back

    $resp = $client->security->delete_role(
        
         # path parameters
        
        'role'         =>  $role,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>delete_role|https://opensearch.org/docs/latest/security/access-control/api/#delete-role>
    
=head2 delete_role_mapping

Deletes the specified role mapping.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_security/api/rolesmapping/{role}>

=back

    $resp = $client->security->delete_role_mapping(
        
         # path parameters
        
        'role'         =>  $role,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>delete_role_mapping|https://opensearch.org/docs/latest/security/access-control/api/#delete-role-mapping>
    
=head2 delete_tenant

Deletes the specified tenant.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_security/api/tenants/{tenant}>

=back

    $resp = $client->security->delete_tenant(
        
         # path parameters
        
        'tenant'       =>  $tenant,    # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>delete_tenant|https://opensearch.org/docs/latest/security/access-control/api/#delete-action-group>
    
=head2 delete_user

Deletes the specified internal user.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_security/api/internalusers/{username}>

=back

    $resp = $client->security->delete_user(
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>delete_user|https://opensearch.org/docs/latest/security/access-control/api/#delete-user>
    
=head2 delete_user_legacy

Delete the specified user. Legacy API.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_security/api/user/{username}>

=back

    $resp = $client->security->delete_user_legacy(
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>delete_user_legacy|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 flush_cache

Flushes the Security plugin's user, authentication, and authorization cache.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_security/api/cache>

=back

    $resp = $client->security->flush_cache(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>flush_cache|https://opensearch.org/docs/latest/security/access-control/api/#flush-cache>
    
=head2 generate_obo_token

Generates a `On-Behalf-Of` token for the current user.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_security/api/generateonbehalfoftoken>

=back

    $resp = $client->security->generate_obo_token(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>generate_obo_token|https://opensearch.org/docs/latest/security/access-control/authentication-tokens/#api-endpoint>
    
=head2 generate_user_token

Generates an authorization token for the specified user.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_security/api/internalusers/{username}/authtoken>

=back

    $resp = $client->security->generate_user_token(
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>generate_user_token|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 generate_user_token_legacy

Generates authorization token for the given user. Legacy API. Not Implemented.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_security/api/user/{username}/authtoken>

=back

    $resp = $client->security->generate_user_token_legacy(
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>generate_user_token_legacy|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 get_account_details

Returns account information for the current user.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/account>

=back

    $resp = $client->security->get_account_details(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_account_details|https://opensearch.org/docs/latest/security/access-control/api/#get-account-details>
    
=head2 get_action_group

Retrieves one action group.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/actiongroups/{action_group}>

=back

    $resp = $client->security->get_action_group(
        
         # path parameters
        
        'action_group'  =>  $action_group,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_action_group|https://opensearch.org/docs/latest/security/access-control/api/#get-action-group>
    
=head2 get_action_groups

Retrieves all action groups.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/actiongroups>

=back

    $resp = $client->security->get_action_groups(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_action_groups|https://opensearch.org/docs/latest/security/access-control/api/#get-action-groups>
    
=head2 get_all_certificates

Retrieves the cluster security certificates.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/certificates>

=back

    $resp = $client->security->get_all_certificates(
        
         # Endpoint specific query string parameters
        
        'cert_type'    =>  $qval1,     # string
        'timeout'      =>  $qval2,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for security-E<gt>get_all_certificates|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 get_allowlist

Retrieves the current list of allowed APIs accessible to a normal user.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/allowlist>

=back

    $resp = $client->security->get_allowlist(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_allowlist|https://opensearch.org/docs/latest/security/access-control/api/#access-control-for-the-api>
    
=head2 get_audit_configuration

Retrieves the audit configuration.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/audit>

=back

    $resp = $client->security->get_audit_configuration(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_audit_configuration|https://opensearch.org/docs/latest/security/access-control/api/#audit-logs>
    
=head2 get_certificates

Retrieves the cluster security certificates.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/ssl/certs>

=back

    $resp = $client->security->get_certificates(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_certificates|https://opensearch.org/docs/latest/security/access-control/api/#get-certificates>
    
=head2 get_configuration

Returns the current Security plugin configuration in a JSON format.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/securityconfig>

=back

    $resp = $client->security->get_configuration(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_configuration|https://opensearch.org/docs/latest/security/access-control/api/#get-configuration>
    
=head2 get_dashboards_info

Retrieves the current values for dynamic security settings for OpenSearch Dashboards.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/dashboardsinfo>

=back

    $resp = $client->security->get_dashboards_info(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_dashboards_info|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 get_distinguished_name

Retrieves all node distinguished names. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/nodesdn/{cluster_name}>

=back

    $resp = $client->security->get_distinguished_name(
        
         # path parameters
        
        'cluster_name'  =>  $cluster_name,  # required
        
         # Endpoint specific query string parameters
        
        'show_all'      =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval2,     # boolean
        'filter_path'   =>  $qval3,     # list
        'human'         =>  $qval4,     # boolean
        'pretty'        =>  $qval5,     # boolean
        'source'        =>  $qval6,     # string
    );

L<OpenSearch documentation for security-E<gt>get_distinguished_name|https://opensearch.org/docs/latest/security/access-control/api/#get-distinguished-names>
    
=head2 get_distinguished_names

Retrieves all node distinguished names. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/nodesdn>

=back

    $resp = $client->security->get_distinguished_names(
        
         # Endpoint specific query string parameters
        
        'show_all'     =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for security-E<gt>get_distinguished_names|https://opensearch.org/docs/latest/security/access-control/api/#get-distinguished-names>
    
=head2 get_node_certificates

Retrieves the specified node's security certificates.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/certificates/{node_id}>

=back

    $resp = $client->security->get_node_certificates(
        
         # path parameters
        
        'node_id'      =>  $node_id,   # required
        
         # Endpoint specific query string parameters
        
        'cert_type'    =>  $qval1,     # string
        'timeout'      =>  $qval2,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval3,     # boolean
        'filter_path'  =>  $qval4,     # list
        'human'        =>  $qval5,     # boolean
        'pretty'       =>  $qval6,     # boolean
        'source'       =>  $qval7,     # string
    );

L<OpenSearch documentation for security-E<gt>get_node_certificates|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 get_permissions_info

Retrieves the evaluated REST API permissions for the currently logged in user.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/permissionsinfo>

=back

    $resp = $client->security->get_permissions_info(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_permissions_info|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 get_role

Retrieves one role.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/roles/{role}>

=back

    $resp = $client->security->get_role(
        
         # path parameters
        
        'role'         =>  $role,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_role|https://opensearch.org/docs/latest/security/access-control/api/#get-role>
    
=head2 get_role_mapping

Retrieves the specified role mapping.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/rolesmapping/{role}>

=back

    $resp = $client->security->get_role_mapping(
        
         # path parameters
        
        'role'         =>  $role,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_role_mapping|https://opensearch.org/docs/latest/security/access-control/api/#get-role-mapping>
    
=head2 get_role_mappings

Retrieves all role mappings.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/rolesmapping>

=back

    $resp = $client->security->get_role_mappings(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_role_mappings|https://opensearch.org/docs/latest/security/access-control/api/#get-role-mappings>
    
=head2 get_roles

Retrieves all roles.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/roles>

=back

    $resp = $client->security->get_roles(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_roles|https://opensearch.org/docs/latest/security/access-control/api/#get-roles>
    
=head2 get_sslinfo

Retrieves information about the SSL configuration.

I<Paths served by this method:>

=over

=item
C<GET /_opendistro/_security/sslinfo>

=back

    $resp = $client->security->get_sslinfo(
        
         # Endpoint specific query string parameters
        
        'show_dn'      =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for security-E<gt>get_sslinfo|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 get_tenancy_config

Retrieves the multi-tenancy configuration. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/tenancy/config>

=back

    $resp = $client->security->get_tenancy_config(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_tenancy_config|https://opensearch.org/docs/latest/security/multi-tenancy/dynamic-config/#configuring-multi-tenancy-with-the-rest-api>
    
=head2 get_tenant

Retrieves the specified tenant.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/tenants/{tenant}>

=back

    $resp = $client->security->get_tenant(
        
         # path parameters
        
        'tenant'       =>  $tenant,    # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_tenant|https://opensearch.org/docs/latest/security/access-control/api/#get-tenant>
    
=head2 get_tenants

Retrieves all tenants.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/tenants>

=back

    $resp = $client->security->get_tenants(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_tenants|https://opensearch.org/docs/latest/security/access-control/api/#get-tenants>
    
=head2 get_user

Retrieve information about the specified internal user.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/internalusers/{username}>

=back

    $resp = $client->security->get_user(
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_user|https://opensearch.org/docs/latest/security/access-control/api/#get-user>
    
=head2 get_user_legacy

Retrieve one user. Legacy API.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/user/{username}>

=back

    $resp = $client->security->get_user_legacy(
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_user_legacy|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 get_users

Retrieve all internal users.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/internalusers>

=back

    $resp = $client->security->get_users(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_users|https://opensearch.org/docs/latest/security/access-control/api/#get-users>
    
=head2 get_users_legacy

Retrieve all internal users. Legacy API.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/user>

=back

    $resp = $client->security->get_users_legacy(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>get_users_legacy|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 health

Checks to see if the Security plugin is running.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/health>

=item
C<POST /_plugins/_security/health>

=back

    $resp = $client->security->health(
        
         # Endpoint specific query string parameters
        
        'mode'         =>  $qval1,     # string
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval2,     # boolean
        'filter_path'  =>  $qval3,     # list
        'human'        =>  $qval4,     # boolean
        'pretty'       =>  $qval5,     # boolean
        'source'       =>  $qval6,     # string
    );

L<OpenSearch documentation for security-E<gt>health|https://opensearch.org/docs/latest/security/access-control/api/#health-check>
    
=head2 migrate

Migrates the security configuration from v6 to v7.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_security/api/migrate>

=back

    $resp = $client->security->migrate(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>migrate|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 patch_action_group

Updates the individual attributes of an action group.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/actiongroups/{action_group}>

=back

    $resp = $client->security->patch_action_group(
        
        'body'          =>  $body,      # optional
        
         # path parameters
        
        'action_group'  =>  $action_group,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_action_group|https://opensearch.org/docs/latest/security/access-control/api/#patch-action-group>
    
=head2 patch_action_groups

Creates, updates, or deletes multiple action groups in a single request.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/actiongroups>

=back

    $resp = $client->security->patch_action_groups(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_action_groups|https://opensearch.org/docs/latest/security/access-control/api/#patch-action-groups>
    
=head2 patch_allowlist

Updates the current list of APIs accessible for users on the allow list.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/allowlist>

=back

    $resp = $client->security->patch_allowlist(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_allowlist|https://opensearch.org/docs/latest/security/access-control/api/#access-control-for-the-api>
    
=head2 patch_audit_configuration

Updates the specified fields in the audit configuration.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/audit>

=back

    $resp = $client->security->patch_audit_configuration(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_audit_configuration|https://opensearch.org/docs/latest/security/access-control/api/#audit-logs>
    
=head2 patch_configuration

Updates the existing security configuration using the REST API. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/securityconfig>

=back

    $resp = $client->security->patch_configuration(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_configuration|https://opensearch.org/docs/latest/security/access-control/api/#patch-configuration>
    
=head2 patch_distinguished_name

Updates the distinguished cluster name for the specified cluster. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/nodesdn/{cluster_name}>

=back

    $resp = $client->security->patch_distinguished_name(
        
        'body'          =>  $body,      # optional
        
         # path parameters
        
        'cluster_name'  =>  $cluster_name,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_distinguished_name|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 patch_distinguished_names

Bulk updates specified node distinguished names. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/nodesdn>

=back

    $resp = $client->security->patch_distinguished_names(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_distinguished_names|https://opensearch.org/docs/latest/security/access-control/api/#update-all-distinguished-names>
    
=head2 patch_role

Updates the individual attributes of a role.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/roles/{role}>

=back

    $resp = $client->security->patch_role(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'role'         =>  $role,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_role|https://opensearch.org/docs/latest/security/access-control/api/#patch-role>
    
=head2 patch_role_mapping

Updates the individual attributes of a role mapping.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/rolesmapping/{role}>

=back

    $resp = $client->security->patch_role_mapping(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'role'         =>  $role,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_role_mapping|https://opensearch.org/docs/latest/security/access-control/api/#patch-role-mapping>
    
=head2 patch_role_mappings

Creates or updates multiple role mappings in a single request.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/rolesmapping>

=back

    $resp = $client->security->patch_role_mappings(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_role_mappings|https://opensearch.org/docs/latest/security/access-control/api/#patch-role-mappings>
    
=head2 patch_roles

Creates, updates, or deletes multiple roles in a single call.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/roles>

=back

    $resp = $client->security->patch_roles(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_roles|https://opensearch.org/docs/latest/security/access-control/api/#patch-roles>
    
=head2 patch_tenant

Adds, deletes, or modifies a single tenant.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/tenants/{tenant}>

=back

    $resp = $client->security->patch_tenant(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'tenant'       =>  $tenant,    # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_tenant|https://opensearch.org/docs/latest/security/access-control/api/#patch-tenant>
    
=head2 patch_tenants

Adds, deletes, or modifies multiple tenants in a single request.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/tenants>

=back

    $resp = $client->security->patch_tenants(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_tenants|https://opensearch.org/docs/latest/security/access-control/api/#patch-tenants>
    
=head2 patch_user

Updates individual attributes for an internal user.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/internalusers/{username}>

=back

    $resp = $client->security->patch_user(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'username'     =>  $username,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_user|https://opensearch.org/docs/latest/security/access-control/api/#patch-user>
    
=head2 patch_users

Creates, updates, or deletes multiple internal users in a single request.

I<Paths served by this method:>

=over

=item
C<PATCH /_plugins/_security/api/internalusers>

=back

    $resp = $client->security->patch_users(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>patch_users|https://opensearch.org/docs/latest/security/access-control/api/#patch-users>
    
=head2 post_dashboards_info

Retrieves the current values for dynamic security settings for OpenSearch Dashboards.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_security/dashboardsinfo>

=back

    $resp = $client->security->post_dashboards_info(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>post_dashboards_info|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 reload_http_certificates

Reloads the HTTP communication certificates.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/ssl/http/reloadcerts>

=back

    $resp = $client->security->reload_http_certificates(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>reload_http_certificates|https://opensearch.org/docs/latest/security/access-control/api/#reload-http-certificates>
    
=head2 reload_transport_certificates

Reloads the transport communication certificates.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/ssl/transport/reloadcerts>

=back

    $resp = $client->security->reload_transport_certificates(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>reload_transport_certificates|https://opensearch.org/docs/latest/security/access-control/api/#reload-transport-certificates>
    
=head2 tenant_info

Retrieves the names of current tenants. Requires super admin or `kibanaserver` permissions.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/tenantinfo>

=item
C<POST /_plugins/_security/tenantinfo>

=back

    $resp = $client->security->tenant_info(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>tenant_info|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 update_audit_configuration

Updates the audit configuration.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/audit/config>

=back

    $resp = $client->security->update_audit_configuration(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>update_audit_configuration|https://opensearch.org/docs/latest/security/access-control/api/#audit-logs>
    
=head2 update_configuration

Updates the settings for an existing security configuration. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/securityconfig/config>

=back

    $resp = $client->security->update_configuration(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>update_configuration|https://opensearch.org/docs/latest/security/access-control/api/#update-configuration>
    
=head2 update_distinguished_name

Adds or updates the specified distinguished names in the cluster or node allowlist. Requires super admin or REST API permissions.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_security/api/nodesdn/{cluster_name}>

=back

    $resp = $client->security->update_distinguished_name(
        
        'body'          =>  $body,      # optional
        
         # path parameters
        
        'cluster_name'  =>  $cluster_name,  # required
        
         # Common API query string parameters
        
        'error_trace'   =>  $qval1,     # boolean
        'filter_path'   =>  $qval2,     # list
        'human'         =>  $qval3,     # boolean
        'pretty'        =>  $qval4,     # boolean
        'source'        =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>update_distinguished_name|https://opensearch.org/docs/latest/security/access-control/api/#update-distinguished-names>
    
=head2 validate

Checks whether the v6 security configuration is valid and ready to be migrated to v7.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/api/validate>

=back

    $resp = $client->security->validate(
        
         # Endpoint specific query string parameters
        
        'accept_invalid'  =>  $qval1,     # boolean
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval2,     # boolean
        'filter_path'     =>  $qval3,     # list
        'human'           =>  $qval4,     # boolean
        'pretty'          =>  $qval5,     # boolean
        'source'          =>  $qval6,     # string
    );

L<OpenSearch documentation for security-E<gt>validate|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 who_am_i

Gets the identity information for the user currently logged in.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/whoami>

=item
C<POST /_plugins/_security/whoami>

=back

    $resp = $client->security->who_am_i(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>who_am_i|https://docs.opensearch.org/latest/security/access-control/api/>
    
=head2 who_am_i_protected

Gets the identity information for the user currently logged in. To use this operation, you must have access to this endpoint when authorization at REST layer is enabled.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_security/whoamiprotected>

=back

    $resp = $client->security->who_am_i_protected(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for security-E<gt>who_am_i_protected|https://docs.opensearch.org/latest/security/access-control/api/>

=head1 MANUAL

Documentation index L<OpenSearch::Client::Manual>

=head1 HISTORY

This distribution is derived from L<Search::Elasticsearch> version 7.714.
All subsequent changes are unique to this distribution.

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt> ( current maintainer )

=head1 CREDITS

L<OpenSearch::Client> is based on L<Search::Elasticsearch> version 7.714
by Enrico Zimuel E<lt>enrico.zimuel@elastic.coE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson ( this distribution )

Copyright (C) 2021 by Elasticsearch BV ( original distribution ) 

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004


=cut

