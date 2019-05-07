# ABSTRACT: request - role - has relationship-update-data
package PONAPI::Client::Request::Role::HasRelationshipUpdateData;

use Moose::Role;

with 'PONAPI::Client::Request::Role::HasData';
has data => (
    is       => 'ro',
    isa      => 'Maybe[HashRef|ArrayRef]',
    required => 1,
);

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Client::Request::Role::HasRelationshipUpdateData - request - role - has relationship-update-data

=head1 VERSION

version 0.002011

=head1 DESCRIPTION

Similar to L<PONAPI::Client::Request::Role::HasData>, but for relationship updates.
Unlike the rest of the spec, relationship updates can take not just a hashref of data,
but also undef, or an arrayref.

    # Replaces the specified relationship(s) with a one-to-one relationship to foo.
    $client->update_relationships( ..., data => { type => "foo", id => 4 } );

    # Replaces the
    $client->update_relationships( ..., data => [ { type => "foo", id => 4 }, { ... } ] );

    # Clears the relationship
    $client->update_relationships( ..., data => undef );
    $client->update_relationships( ..., data => [] );

The underlaying repository decides whether the one-to-one or one-to-many difference is
significant.

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
