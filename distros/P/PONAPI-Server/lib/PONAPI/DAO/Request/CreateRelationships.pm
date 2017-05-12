# ABSTRACT: DAO request - create relationships
package PONAPI::DAO::Request::CreateRelationships;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::UpdateLike',
     'PONAPI::DAO::Request::Role::HasDataBulk',
     'PONAPI::DAO::Request::Role::HasDataMethods',
     'PONAPI::DAO::Request::Role::HasID',
     'PONAPI::DAO::Request::Role::HasRelationshipType';

sub check_data_type_match { 1 } # to avoid code duplications in HasDataMethods

sub execute {
    my $self = shift;

    if ( $self->is_valid ) {
        my @ret = $self->repository->create_relationships( %{ $self } );
        $self->_add_success_meta(@ret)
            if $self->_verify_update_response(@ret);
    }

    return $self->response();
}

sub _validate_rel_type {
    my ( $self, $args ) = @_;

    return $self->_bad_request( "`relationship type` is missing for this request" )
        unless $self->has_rel_type;

    my $type     = $self->type;
    my $rel_type = $self->rel_type;

    return $self->_bad_request( "Types `$type` and `$rel_type` are not related", 404 )
        unless $self->repository->has_relationship( $type, $rel_type );

    return $self->_bad_request( "Types `$type` and `$rel_type` are one-to-one" )
        unless $self->repository->has_one_to_many_relationship( $type, $rel_type );
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::CreateRelationships - DAO request - create relationships

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
