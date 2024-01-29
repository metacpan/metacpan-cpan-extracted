# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

package Search::Elasticsearch::Client::8_0::Direct::ConnectorSyncJob;
$Search::Elasticsearch::Client::8_0::Direct::ConnectorSyncJob::VERSION = '8.12';
use Moo;
with 'Search::Elasticsearch::Client::8_0::Role::API';
with 'Search::Elasticsearch::Role::Client::Direct';
__PACKAGE__->_install_api('connector_sync_job');

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::8_0::Direct::ConnectorSyncJob - A client for create and manage Elastic sync jobs

=head1 VERSION

version 8.12

=head1 DESCRIPTION

The sync jobs API provides a convenient way to create
and manage Elastic sync jobs in an internal index.

This API provides an alternative to relying solely on Kibana UI
for sync job management.

The full documentation for Sync job feature is available here:
L<https://www.elastic.co/guide/en/elasticsearch/reference/8.12/connector-apis.html#sync-job-apis>

It does L<Search::Elasticsearch::Role::Client::Direct>.

=head1 METHODS

=head2 C<put()>

    $response = $e->connector_sync_job->post(
        body => {
            id => "connector-id",
            job_type => "full",
            trigger_method => 'on_demand'
        }
    );

The C<post()> method create a connector sync job.

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: A client for create and manage Elastic sync jobs

