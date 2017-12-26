# ABSTRACT: DAO request - retrieve by relationship
package PONAPI::DAO::Request::RetrieveByRelationship;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasFields',
     'PONAPI::DAO::Request::Role::HasFilter',
     'PONAPI::DAO::Request::Role::HasInclude',
     'PONAPI::DAO::Request::Role::HasPage',
     'PONAPI::DAO::Request::Role::HasSort',
     'PONAPI::DAO::Request::Role::HasID',
     'PONAPI::DAO::Request::Role::HasRelationshipType';

sub execute {
    my $self = shift;

    if ( $self->is_valid ) {
        my $repo        = $self->repository;
        my $document    = $self->document;
        my $one_to_many = $repo->has_one_to_many_relationship($self->type, $self->rel_type);

        $document->convert_to_collection if $one_to_many;

        $repo->retrieve_by_relationship( %{ $self } );

        $document->add_null_resource
            unless $one_to_many or $document->has_resource_builders;
    }

    return $self->response();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::RetrieveByRelationship - DAO request - retrieve by relationship

=head1 VERSION

version 0.003002

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
