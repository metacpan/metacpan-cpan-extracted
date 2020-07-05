package Search::Elasticsearch::Client::1_0;

our $VERSION='6.81';
use Search::Elasticsearch 6.00 ();

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::1_0 - Thin client with full support for Elasticsearch 1.x APIs

=head1 VERSION

version 6.81

=head1 DESCRIPTION

The L<Search::Elasticsearch::Client::1_0> package provides a client
compatible with Elasticsearch 1.x.  It should be used in conjunction
with L<Search::Elasticsearch> as follows:

    $e = Search::Elasticsearch->new(
        client => "1_0::Direct"
    );

See L<Search::Elasticsearch::Client::1_0::Direct> for documentation
about how to use the client itself.

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: Thin client with full support for Elasticsearch 1.x APIs

