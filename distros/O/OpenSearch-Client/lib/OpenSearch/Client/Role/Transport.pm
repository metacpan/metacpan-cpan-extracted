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

package OpenSearch::Client::Role::Transport;
$OpenSearch::Client::Role::Transport::VERSION = '3.007009';
use Moo::Role;

requires qw(perform_request);

use Try::Tiny;
use OpenSearch::Client::Util qw(parse_params is_compat);
use namespace::clean;

has 'serializer'       => ( is => 'ro', required => 1 );
has 'logger'           => ( is => 'ro', required => 1 );
has 'send_body_as_source' => ( is => 'ro', default  => 0 );
has 'cxn_pool'         => ( is => 'ro', required => 1 );

#===================================
sub BUILD {
#===================================
    my $self = shift;
    my $pool = $self->cxn_pool;
    is_compat( 'cxn_pool', $self, $pool );
    is_compat( 'cxn',      $self, $pool->cxn_factory->cxn_class );
    return $self;
}

#===================================
sub tidy_request {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $params->{method} ||= 'GET';
    $params->{path}   ||= '/';
    $params->{qs}     ||= {};
    $params->{ignore} ||= [];
    my $body = $params->{body};
    return $params unless defined $body;

    $params->{serialize} ||= 'std';
    $params->{data}
        = $params->{serialize} eq 'std'
        ? $self->serializer->encode($body)
        : $self->serializer->encode_bulk($body);

    if ( $self->send_body_as_source ) {
        $params->{qs}{source} = delete $params->{data};
        delete $params->{body};
    }
    
    if ( $params->{serialize} eq 'bulk' ) {
        $params->{mime_type} = 'application/x-ndjson';
    }
    
    $params->{mime_type} ||= $self->serializer->mime_type;
    return $params;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Role::Transport - Transport role providing interface between the client class and the OpenSearch cluster

=head1 VERSION

version 3.007009

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
