# ABSTRACT: DAO request - create
package PONAPI::DAO::Request::Create;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasData',
     'PONAPI::DAO::Request::Role::HasDataMethods';

sub execute {
    my $self = shift;
    my $doc = $self->document;

    my @headers;
    if ( $self->is_valid ) {
        $self->repository->create( %{ $self } );
        $doc->add_meta(
            detail => "successfully created the resource: "
                    . $self->type
                    . " => "
                    . $self->json->encode( $self->data )
        );

        $doc->set_status(201) unless $doc->has_status;

        my $document  = $doc->build;
        my $self_link = $document->{data}{links}{self};
        $self_link  //= "/$document->{data}{type}/$document->{data}{id}";

        push @headers, Location => $self_link;
    }

    return $self->response( @headers );
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Create - DAO request - create

=head1 VERSION

version 0.003003

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
