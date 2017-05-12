package Search::Elasticsearch::Serializer::JSON::Cpanel;
$Search::Elasticsearch::Serializer::JSON::Cpanel::VERSION = '5.02';
use Cpanel::JSON::XS;
use Moo;

has 'JSON' =>
    ( is => 'ro', default => sub { Cpanel::JSON::XS->new->utf8(1) } );

with 'Search::Elasticsearch::Role::Serializer::JSON';

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Serializer::JSON::Cpanel - A JSON Serializer using Cpanel::JSON::XS

=head1 VERSION

version 5.02

=head1 SYNOPSIS

    $e = Search::Elasticsearch(
        serializer => 'JSON::Cpanel'
    );

=head1 DESCRIPTION

While the default serializer, L<Search::Elasticsearch::Serializer::JSON>,
tries to choose the appropriate JSON backend, this module allows you to
choose the L<Cpanel::JSON::XS> backend specifically.

This class does L<Search::Elasticsearch::Role::Serializer::JSON>.

=head1 SEE ALSO

=over

=item * L<Search::Elasticsearch::Serializer::JSON>

=item * L<Search::Elasticsearch::Serializer::JSON::XS>

=item * L<Search::Elasticsearch::Serializer::JSON::PP>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: A JSON Serializer using Cpanel::JSON::XS

