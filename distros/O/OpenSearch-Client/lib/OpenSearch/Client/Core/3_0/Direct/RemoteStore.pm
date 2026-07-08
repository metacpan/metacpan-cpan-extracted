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

package OpenSearch::Client::Core::3_0::Direct::RemoteStore;
$OpenSearch::Client::Core::3_0::Direct::RemoteStore::VERSION = '3.007006';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('remote_store');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::RemoteStore>

=head1 VERSION

version 3.007006

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->remote_store-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<Restoring from a backup>


Remote-backed storage offers OpenSearch users a new way to protect against data loss by automatically creating backups of all index transactions and sending them to remote storage.

L<See OpenSearch documentation for remote_store.|https://opensearch.org/docs/latest/opensearch/remote/>

=head1 METHODS
    
=head2 restore

Restores from remote store.

I<Paths served by this method:>

=over

=item
C<POST /_remotestore/_restore>

=back

    $resp = $client->remote_store->restore(
        
        'body'                     =>  $body,      # optional
        
         # Endpoint specific query string parameters
        
        'cluster_manager_timeout'  =>  $qval1,     # string
        'wait_for_completion'      =>  $qval2,     # boolean
        
         # Common API query string parameters
        
        'error_trace'              =>  $qval3,     # boolean
        'filter_path'              =>  $qval4,     # list
        'human'                    =>  $qval5,     # boolean
        'pretty'                   =>  $qval6,     # boolean
        'source'                   =>  $qval7,     # string
    );

L<OpenSearch documentation for remote_store-E<gt>restore|https://opensearch.org/docs/latest/opensearch/remote/#restoring-from-a-backup>

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

