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

package OpenSearch::Client::Cxn::Factory;
$OpenSearch::Client::Cxn::Factory::VERSION = '3.007005';
use Moo;
use OpenSearch::Client::Util qw(parse_params load_plugin);
use namespace::clean;

has 'cxn_class'          => ( is => 'ro', required => 1 );
has '_factory'           => ( is => 'ro', required => 1 );
has 'default_host'       => ( is => 'ro', default  => 'http://localhost:9200' );
has 'max_content_length' => ( is => 'rw', default  => 104_857_600 );

#===================================
sub BUILDARGS {
#===================================
    my ( $class, $params ) = parse_params(@_);
    my %args = (%$params);
    delete $args{nodes};

    my $cxn_class
        = load_plugin( 'OpenSearch::Client::Cxn', delete $args{cxn} );
    $params->{_factory} = sub {
        my ( $self, $node ) = @_;
        $cxn_class->new(
            %args,
            node               => $node,
            max_content_length => $self->max_content_length
        );
    };
    $params->{cxn_args}  = \%args;
    $params->{cxn_class} = $cxn_class;
    return $params;
}

#===================================
sub new_cxn { shift->_factory->(@_) }
#===================================

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Cxn::Factory - Used by CxnPools to create new Cxn instances.

=head1 VERSION

version 3.007005

=head1 DESCRIPTION

This class is used by the L<OpenSearch::Client::Role::CxnPool> implementations
to create new L<OpenSearch::Client::Role::Cxn>-based instances. It holds on
to all the configuration options passed to L<OpenSearch/new()> so
that new Cxns can use them.

It contains no user serviceable parts.

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
