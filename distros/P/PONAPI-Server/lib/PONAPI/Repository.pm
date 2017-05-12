# ABSTRACT: Interface role for PONAPI::DAO repositories
package PONAPI::Repository;

use Moose::Role;

requires 'has_type';
requires 'has_relationship';
requires 'has_one_to_many_relationship';
requires 'type_has_fields';

requires 'retrieve';
requires 'retrieve_all';
requires 'retrieve_relationships';
requires 'retrieve_by_relationship';
requires 'create';
requires 'create_relationships';
requires 'update';
requires 'update_relationships';
requires 'delete';
requires 'delete_relationships';

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Repository - Interface role for PONAPI::DAO repositories

=head1 VERSION

version 0.003001

=head1 SYNOPSIS

    package My::PONAPI::Repository {
        use Moose;
        with 'PONAPI::Repository';

        sub has_type { ... }

        ...
    }

=head1 DESCRIPTION

A repository is an abstracted set of collections of resources, in the
"Uniform Resource Locator" sense, which may or may not directly
reflect your data source model. Your repository class merely needs to
define sensible behaviours for the required methods defined here in
C<PONAPI::Repository> and that may be as simple as a direct reflection
of your data source model or it may allow for more useful abtractions.
Classes implementing repositories for L<PONAPI::DAO> must consume the
C<PONAPI::Repository> role; this ensures that the methods required by
the DAO to fullfil the implementation are all present.

The arguments that each method can receive are expanded on in
L<PONAPI::DAO>; some differences are explained below. Keep in mind that,
with the exceptions of the C<has_*> methods, B<all> methods
will receive a C<document> argument, which is always an instance of
C<PONAPI::Document>, but not necessarily a B<new> instance.

=head1 REQUIRES

=head2 $obj->has_type( $type )

Must return true if the repository handles $type

=head2 $obj->has_relationship( $type1, $type2 )

Must return true if C<$type1> has a relationship to C<$type2>.

    # Do articles have comments?
    $obj->has_relationship('articles', 'comments');

=head2 $obj->has_one_to_many_relationship($type1, $type2)

Must return true if C<$type1> has a relationship to C<$type2>, and
that relationship is one-to-many.

=head2 retrieve

=head2 retrieve_all

=head2 retrieve_relationships

=head2 retrieve_by_relationship

=head2 create

=head2 update

Return value MUST be one of the C<PONAPI_UPDATE_*> constants provided by
C<PONAPI::Constants>, like C<PONAPI_UPDATED_EXTENDED>.

If the update operation updated more than what was requested (for example,
an C<updated> column in the table, and that column is part of the resource),
then it must return C<PONAPI_UPDATED_EXTENDED>; if the update on the primary
resource did nothing, then it must return C<PONAPI_UPDATED_NOTHING>.
In all other non-error situations, it must return C<PONAPI_UPDATED_NORMAL>
instead.

=head2 delete

=head2 create_relationships

See L</update>.

C<data> will be an arrayref of resources.

=head2 update_relationships

See L</update>.

C<data> will be either undef, a hashref, or an arrayref, depending on
what sort of relationship the request is trying to update.

=head2 delete_relationships

See L</update>.

C<data> will be an arrayref of resources.

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

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
