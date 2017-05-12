package Sloth::Representation;
BEGIN {
  $Sloth::Representation::VERSION = '0.05';
}
# ABSTRACT: An object capable of creating a representation of a resource

use Moose::Role;


requires 'content_type', 'serialize';

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Sloth::Representation - An object capable of creating a representation of a resource

=head1 METHODS

=head2 content_type

    $self->content_type

B<Required>. Classes which consume this role must implement this method.

Returns either a string of the content-type that this representation
represents (ie, 'application/xml'), or a regular expression to match
against a content type (ie, qr{.+/.+}).

=head2 serialize

    $self->serialize($resource);

B<Required>. Classes which consume this role must implement this method.

Takes a resource, returned by processing a L<Sloth::Method>, and creates
a representation of the resource. For example, a JSON representation
might just return the result of L<JSON::Any/encode_json>.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Charles <sloth.cpan@ocharles.org.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

