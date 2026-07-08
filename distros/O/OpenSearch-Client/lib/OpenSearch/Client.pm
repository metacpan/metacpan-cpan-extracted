# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from that work are contained in the NOTICE
# file distributed with this work.
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

package OpenSearch::Client;

use Moo 2.001000 ();

use OpenSearch::Client::Util qw(parse_params load_plugin);
use namespace::clean;

our $VERSION = '3.007006';

my %Default_Plugins = (
    client      => [ 'OpenSearch::Client::Core',         '3_0::Direct' ],
    cxn_factory => [ 'OpenSearch::Client::Cxn::Factory', '' ],
    cxn_pool    => [ 'OpenSearch::Client::CxnPool',      'Static' ],
    logger      => [ 'OpenSearch::Client::Logger',       'LogAny' ],
    serializer  => [ 'OpenSearch::Client::Serializer',   'JSON' ],
    transport   => [ 'OpenSearch::Client::Transport',    '' ],
);

my @Load_Order = qw(
    serializer
    logger
    cxn_factory
    cxn_pool
    transport
    client
);

#===================================
sub new {
#===================================
    my ( $class, $params ) = parse_params(@_);

    $params->{cxn} ||= 'HTTPTiny';
    my $plugins = delete $params->{plugins} || [];
    $plugins = [$plugins] unless ref $plugins eq 'ARRAY';

    for my $name (@Load_Order) {
        my ( $base, $default ) = @{ $Default_Plugins{$name} };
        my $sub_class = $params->{$name} || $default;
        my $plugin_class = load_plugin( $base, $sub_class );
        $params->{$name} = $plugin_class->new($params);
    }

    for my $name (@$plugins) {
        my $plugin_class
            = load_plugin( 'OpenSearch::Client::Plugin', $name );
        $plugin_class->_init_plugin($params);
    }

    return $params->{client};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client - An unofficial Perl client for OpenSearch

=head1 VERSION

version 3.007006

=head1 SYNOPSIS

    use OpenSearch::Client;
    
    # Connect to localhost:9200:

    my $client = OpenSearch::Client->new();

=head1 DESCRIPTION

L<OpenSearch::Client> is an unofficial Perl client for OpenSearch.

It is derived from L<Search::Elasticsearch>.

The module was created as the OpenSearch and Elasticsearch APIs diverged after OpenSearch was forked.

L<Search::Elasticsearch> is no longer maintained as Elasticsearch no longer include Perl as a supported client.

=head1 MANUAL

For documentation index see L<OpenSearch::Client::Manual>

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
