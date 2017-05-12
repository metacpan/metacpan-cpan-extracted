package Search::Elasticsearch::Plugin::XPack::2_0::License;

use Moo;
with 'Search::Elasticsearch::Plugin::XPack::2_0::Role::API';
with 'Search::Elasticsearch::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('license');

1;

# ABSTRACT: Plugin providing License API for Search::Elasticsearch 2.x

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Plugin::XPack::2_0::License - Plugin providing License API for Search::Elasticsearch 2.x

=head1 VERSION

version 5.02

=head1 SYNOPSIS

    use Search::Elasticsearch();

    my $es = Search::Elasticsearch->new(
        nodes    => \@nodes,
        plugins  => ['XPack']
    );

    my $response = $es->license->get();

=head2 DESCRIPTION

This class extends the L<Search::Elasticsearch> client with a C<license>
namespace, to support the API for the License plugin for Elasticsearch.
In other words, it can be used as follows:

    use Search::Elasticsearch();
    my $es = Search::Elasticsearch->new(
        nodes    => \@nodes,
        plugins  => ['XPack']
    );

    my $response = $es->license->get();

=head1 METHODS

The full documentation for the License plugin is available here:
L<https://www.elastic.co/guide/en/shield/current/license-management.html>

=head2 C<get()>

    $response = $es->license->get()

The C<get()> method returns the currently installed license.

See the L<license.get docs|https://www.elastic.co/guide/en/shield/current/license-management.html#listing-licenses>
for more information.

=head2 C<put()>

    $response = $es->license->put(
        body     => {...}          # required
    );

The C<put()> method adds or updates the license for the cluster. The C<body>
can be passed as JSON or as a string.

See the L<license.put docs|https://www.elastic.co/guide/en/shield/current/license-management.html#installing-license>
for more information.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
