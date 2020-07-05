package Search::Elasticsearch::Client::6_0::Direct::XPack::SSL;
$Search::Elasticsearch::Client::6_0::Direct::XPack::SSL::VERSION = '6.81';
use Moo;
with 'Search::Elasticsearch::Client::6_0::Role::API';
with 'Search::Elasticsearch::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('xpack.ssl');

1;

# ABSTRACT: Plugin providing SSL for Search::Elasticsearch 6.x

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::6_0::Direct::XPack::SSL - Plugin providing SSL for Search::Elasticsearch 6.x

=head1 VERSION

version 6.81

=head1 SYNOPSIS

    my $response = $es->xpack->ssl->certificates()

=head2 DESCRIPTION

This class extends the L<Search::Elasticsearch> client with an C<ssl>
namespace, to support the
L<SSL APIs|https://www.elastic.co/guide/en/elasticsearch/reference/current/security-api-ssl.html>.

=head1 GENERAL METHODS

=head2 C<certificates()>

    $response = $es->xpack->ssl->certificates()

The C<certificates()> method returns all the certificate information on a single node of Elasticsearch.

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
