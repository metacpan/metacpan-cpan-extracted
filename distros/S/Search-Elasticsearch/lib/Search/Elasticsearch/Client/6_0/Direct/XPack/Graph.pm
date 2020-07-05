package Search::Elasticsearch::Client::6_0::Direct::XPack::Graph;
$Search::Elasticsearch::Client::6_0::Direct::XPack::Graph::VERSION = '6.81';
use Moo;
with 'Search::Elasticsearch::Client::6_0::Role::API';
with 'Search::Elasticsearch::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('xpack.graph');

1;

# ABSTRACT: Plugin providing Graph API for Search::Elasticsearch 6.x

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::6_0::Direct::XPack::Graph - Plugin providing Graph API for Search::Elasticsearch 6.x

=head1 VERSION

version 6.81

=head1 SYNOPSIS

    my $response = $es->xpack->graph->explore(...);

=head2 DESCRIPTION

This class extends the L<Search::Elasticsearch> client with a C<graph>
namespace, to support the API for the
L<Graph|https://www.elastic.co/guide/en/x-pack/current/xpack-graph.html> plugin for Elasticsearch.

=head1 METHODS

The full documentation for the Graph plugin is available here:
L<https://www.elastic.co/guide/en/graph/current/index.html>

=head2 C<explore()>

    $response = $es->xpack->graph->explore(
        index => $index | \@indices,        # optional
        type  => $type  | \@types,          # optional
        body  => {...}
    )

The C<explore()> method allows you to discover vertices and connections which relate
to your query.

See the L<explore docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/graph-explore-api.html>
for more information.

Query string parameters:
    C<error_trace>,
    C<human>,
    C<routing>,
    C<timeout>

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
