# ABSTRACT: DAO request role - `relationship type`
package PONAPI::DAO::Request::Role::HasRelationshipType;

use Moose::Role;

has rel_type => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_rel_type',
);

sub _validate_rel_type {
    my ( $self, $args ) = @_;

    return $self->_bad_request( "`relationship type` is missing for this request" )
        unless $self->has_rel_type;

    my $type     = $self->type;
    my $rel_type = $self->rel_type;

    if ( !$self->repository->has_relationship( $type, $rel_type ) ) {
        return $self->_bad_request( "Types `$type` and `$rel_type` are not related", 404 )
    }
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Role::HasRelationshipType - DAO request role - `relationship type`

=head1 VERSION

version 0.003001

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
