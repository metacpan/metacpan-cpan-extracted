package Search::Elasticsearch::Client::2_0;

our $VERSION='5.02';
use Search::Elasticsearch 5.02 ();

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::2_0 - Thin client with full support for Elasticsearch 2.x APIs

=head1 VERSION

version 5.02

=head1 DESCRIPTION

The L<Search::Elasticsearch::Client::2_0> package provides a client
compatible with Elasticsearch 2.x.  It should be used in conjunction
with L<Search::Elasticsearch> as follows:

    $e = Search::Elasticsearch->new(
        client => "2_0::Direct"
    );

See L<Search::Elasticsearch::Client::2_0::Direct> for documentation
about how to use the client itself.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: Thin client with full support for Elasticsearch 2.x APIs

