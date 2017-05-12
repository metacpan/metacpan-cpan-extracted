package Search::Elasticsearch::Role::Serializer;
$Search::Elasticsearch::Role::Serializer::VERSION = '5.02';
use Moo::Role;

requires qw(encode decode encode_pretty encode_bulk mime_type);

1;

# ABSTRACT: An interface for Serializer modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Role::Serializer - An interface for Serializer modules

=head1 VERSION

version 5.02

=head1 DESCRIPTION

There is no code in this module. It defines an interface for
Serializer implementations, and requires the following methods:

=over

=item *

C<encode()>

=item *

C<encode_pretty()>

=item *

C<encode_bulk()>

=item *

C<decode()>

=item *

C<mime_type()>

=back

See L<Search::Elasticsearch::Serializer::JSON> for more.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
