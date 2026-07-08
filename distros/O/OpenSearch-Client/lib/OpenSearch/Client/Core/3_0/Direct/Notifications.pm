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

package OpenSearch::Client::Core::3_0::Direct::Notifications;
$OpenSearch::Client::Core::3_0::Direct::Notifications::VERSION = '3.007006';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('notifications');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::Notifications>

=head1 VERSION

version 3.007006

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->notifications-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Notifications>


The Notifications plugin provides a central location for all of your notifications from OpenSearch plugins. Using the plugin, you can configure which communication service you want to use and see relevant statistics and troubleshooting information. Currently, the Alerting and ISM plugins have integrated with the Notifications plugin.

L<See OpenSearch documentation for notifications.|https://docs.opensearch.org/latest/observing-your-data/notifications/index/>

=head1 METHODS
    
=head2 create_config

Create channel configuration.

I<Paths served by this method:>

=over

=item
C<POST /_plugins/_notifications/configs>

=back

    $resp = $client->notifications->create_config(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for notifications-E<gt>create_config|https://opensearch.org/docs/latest/observing-your-data/notifications/api/#create-channel-configuration>
    
=head2 delete_config

Delete a channel configuration.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_notifications/configs/{config_id}>

=back

    $resp = $client->notifications->delete_config(
        
         # path parameters
        
        'config_id'    =>  $config_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for notifications-E<gt>delete_config|https://opensearch.org/docs/latest/observing-your-data/notifications/api/#delete-channel-configuration>
    
=head2 delete_configs

Delete multiple channel configurations.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/_notifications/configs>

=back

    $resp = $client->notifications->delete_configs(
        
         # Endpoint specific query string parameters
        
        'config_id'       =>  $qval1,     # string
        'config_id_list'  =>  $qval2,     # string
        
         # Common API query string parameters
        
        'error_trace'     =>  $qval3,     # boolean
        'filter_path'     =>  $qval4,     # list
        'human'           =>  $qval5,     # boolean
        'pretty'          =>  $qval6,     # boolean
        'source'          =>  $qval7,     # string
    );

L<OpenSearch documentation for notifications-E<gt>delete_configs|https://opensearch.org/docs/latest/observing-your-data/notifications/api/#delete-channel-configuration>
    
=head2 get_config

Get a specific channel configuration.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_notifications/configs/{config_id}>

=back

    $resp = $client->notifications->get_config(
        
         # path parameters
        
        'config_id'    =>  $config_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for notifications-E<gt>get_config|https://docs.opensearch.org/latest/observing-your-data/notifications/index/>
    
=head2 get_configs

Get multiple channel configurations with filtering.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_notifications/configs>

=back

    $resp = $client->notifications->get_configs(
        
        'body'                                          =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'chime.url'                                     =>  $qval1,     # string
        'chime.url.keyword'                             =>  $qval2,     # string
        'config_id'                                     =>  $qval3,     # string
        'config_id_list'                                =>  $qval4,     # list
        'config_type'                                   =>  $qval5,     # string
        'created_time_ms'                               =>  $qval6,     # number
        'description'                                   =>  $qval7,     # string
        'description.keyword'                           =>  $qval8,     # string
        'email.email_account_id'                        =>  $qval9,     # string
        'email.email_group_id_list'                     =>  $qval10,    # string
        'email.recipient_list.recipient'                =>  $qval11,    # string
        'email.recipient_list.recipient.keyword'        =>  $qval12,    # string
        'email_group.recipient_list.recipient'          =>  $qval13,    # string
        'email_group.recipient_list.recipient.keyword'  =>  $qval14,    # string
        'is_enabled'                                    =>  $qval15,    # boolean
        'last_updated_time_ms'                          =>  $qval16,    # number
        'microsoft_teams.url'                           =>  $qval17,    # string
        'microsoft_teams.url.keyword'                   =>  $qval18,    # string
        'name'                                          =>  $qval19,    # string
        'name.keyword'                                  =>  $qval20,    # string
        'query'                                         =>  $qval21,    # string
        'ses_account.from_address'                      =>  $qval22,    # string
        'ses_account.from_address.keyword'              =>  $qval23,    # string
        'ses_account.region'                            =>  $qval24,    # string
        'ses_account.role_arn'                          =>  $qval25,    # string
        'ses_account.role_arn.keyword'                  =>  $qval26,    # string
        'slack.url'                                     =>  $qval27,    # string
        'slack.url.keyword'                             =>  $qval28,    # string
        'smtp_account.from_address'                     =>  $qval29,    # string
        'smtp_account.from_address.keyword'             =>  $qval30,    # string
        'smtp_account.host'                             =>  $qval31,    # string
        'smtp_account.host.keyword'                     =>  $qval32,    # string
        'smtp_account.method'                           =>  $qval33,    # string
        'sns.role_arn'                                  =>  $qval34,    # string
        'sns.role_arn.keyword'                          =>  $qval35,    # string
        'sns.topic_arn'                                 =>  $qval36,    # string
        'sns.topic_arn.keyword'                         =>  $qval37,    # string
        'text_query'                                    =>  $qval38,    # string
        'webhook.url'                                   =>  $qval39,    # string
        'webhook.url.keyword'                           =>  $qval40,    # string
        
         # Common API query string parameters
        
        'error_trace'                                   =>  $qval41,    # boolean
        'filter_path'                                   =>  $qval42,    # list
        'human'                                         =>  $qval43,    # boolean
        'pretty'                                        =>  $qval44,    # boolean
        'source'                                        =>  $qval45,    # string
    );

L<OpenSearch documentation for notifications-E<gt>get_configs|https://opensearch.org/docs/latest/observing-your-data/notifications/api/#list-all-notification-configurations>
    
=head2 list_channels

List created notification channels.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_notifications/channels>

=back

    $resp = $client->notifications->list_channels(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for notifications-E<gt>list_channels|https://opensearch.org/docs/latest/observing-your-data/notifications/api/#list-all-notification-channels>
    
=head2 list_features

List supported channel configurations.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_notifications/features>

=back

    $resp = $client->notifications->list_features(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for notifications-E<gt>list_features|https://opensearch.org/docs/latest/observing-your-data/notifications/api/#list-supported-channel-configurations>
    
=head2 send_test

Send a test notification.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/_notifications/feature/test/{config_id}>

=item
C<POST /_plugins/_notifications/feature/test/{config_id}>

=back

    $resp = $client->notifications->send_test(
        
         # path parameters
        
        'config_id'    =>  $config_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for notifications-E<gt>send_test|https://opensearch.org/docs/latest/observing-your-data/notifications/api/#send-test-notification>
    
=head2 update_config

Update channel configuration.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/_notifications/configs/{config_id}>

=back

    $resp = $client->notifications->update_config(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'config_id'    =>  $config_id,  # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for notifications-E<gt>update_config|https://opensearch.org/docs/latest/observing-your-data/notifications/api/#update-channel-configuration>

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

