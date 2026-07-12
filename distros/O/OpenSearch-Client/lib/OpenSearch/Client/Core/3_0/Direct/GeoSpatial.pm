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

package OpenSearch::Client::Core::3_0::Direct::GeoSpatial;
$OpenSearch::Client::Core::3_0::Direct::GeoSpatial::VERSION = '3.007007';
use Moo;
with 'OpenSearch::Client::Core::3_0::Role::API';
with 'OpenSearch::Client::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('geospatial');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B<OpenSearch::Client::Core::3_0::Direct::GeoSpatial>

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

  use OpenSearch::Client;
  
  my $client = OpenSearch::Client->new( ... );
  
  my $response = $client->geospatial-><methodname>(
    valone => $value1,
    valtwo => $value2
  );

=head1 DESCRIPTION

B<IP2Geo processor>


The ip2geo processor adds information about the geographical location of an IPv4 or IPv6 address. The ip2geo processor uses IP geolocation (GeoIP) data from an external endpoint and therefore requires an additional component, datasource, that defines from where to download GeoIP data and how frequently to update the data.

L<See OpenSearch documentation for geospatial.|https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo>

=head1 METHODS
    
=head2 delete_ip2geo_datasource

Delete a specific IP2Geo data source.

I<Paths served by this method:>

=over

=item
C<DELETE /_plugins/geospatial/ip2geo/datasource/{name}>

=back

    $resp = $client->geospatial->delete_ip2geo_datasource(
        
         # path parameters
        
        'name'         =>  $name,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for geospatial-E<gt>delete_ip2geo_datasource|https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo/#deleting-the-ip2geo-data-source>
    
=head2 geojson_upload_post

Use an OpenSearch query to upload `GeoJSON`, operation will fail if index exists.
- When type is `geo_point`, only Point geometry is allowed
- When type is `geo_shape`, all geometry types are allowed (Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, GeometryCollection, Envelope).

I<Paths served by this method:>

=over

=item
C<POST /_plugins/geospatial/geojson/_upload>

=back

    $resp = $client->geospatial->geojson_upload_post(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for geospatial-E<gt>geojson_upload_post|https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo>
    
=head2 geojson_upload_put

Use an OpenSearch query to upload `GeoJSON` regardless if index exists.
- When type is `geo_point`, only Point geometry is allowed
- When type is `geo_shape`, all geometry types are allowed (Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, GeometryCollection, Envelope).

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/geospatial/geojson/_upload>

=back

    $resp = $client->geospatial->geojson_upload_put(
        
        'body'         =>  $body,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for geospatial-E<gt>geojson_upload_put|https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo>
    
=head2 get_ip2geo_datasource

Get one or more IP2Geo data sources, defaulting to returning all if no names specified.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/geospatial/ip2geo/datasource>

=item
C<GET /_plugins/geospatial/ip2geo/datasource/{name}>

=back

    $resp = $client->geospatial->get_ip2geo_datasource(
        
         # path parameters
        
        'name'         =>  $name,      # optional
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for geospatial-E<gt>get_ip2geo_datasource|https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo/#sending-a-get-request>
    
=head2 get_upload_stats

Retrieves statistics for all geospatial uploads.

I<Paths served by this method:>

=over

=item
C<GET /_plugins/geospatial/_upload/stats>

=back

    $resp = $client->geospatial->get_upload_stats(
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for geospatial-E<gt>get_upload_stats|https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo>
    
=head2 put_ip2geo_datasource

Create a specific IP2Geo data source.
Default values:
  - `endpoint`: `"https://geoip.maps.opensearch.org/v1/geolite2-city/manifest.json"`
  - `update_interval_in_days`: 3.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/geospatial/ip2geo/datasource/{name}>

=back

    $resp = $client->geospatial->put_ip2geo_datasource(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'name'         =>  $name,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for geospatial-E<gt>put_ip2geo_datasource|https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo/#data-source-options>
    
=head2 put_ip2geo_datasource_settings

Update a specific IP2Geo data source.

I<Paths served by this method:>

=over

=item
C<PUT /_plugins/geospatial/ip2geo/datasource/{name}/_settings>

=back

    $resp = $client->geospatial->put_ip2geo_datasource_settings(
        
        'body'         =>  $body,      # optional
        
         # path parameters
        
        'name'         =>  $name,      # required
        
         # Common API query string parameters
        
        'error_trace'  =>  $qval1,     # boolean
        'filter_path'  =>  $qval2,     # list
        'human'        =>  $qval3,     # boolean
        'pretty'       =>  $qval4,     # boolean
        'source'       =>  $qval5,     # string
    );

L<OpenSearch documentation for geospatial-E<gt>put_ip2geo_datasource_settings|https://docs.opensearch.org/docs/latest/ingest-pipelines/processors/ip2geo/#updating-an-ip2geo-data-source>

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

