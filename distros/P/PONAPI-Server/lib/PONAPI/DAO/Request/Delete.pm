# ABSTRACT: DAO request - delete
package PONAPI::DAO::Request::Delete;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::HasID';

sub execute {
    my $self = shift;
    my $doc = $self->document;

    if ( $self->is_valid ) {
        $self->repository->delete( %{ $self } );
        $doc->add_meta(
            detail => "successfully deleted the resource /"
                    . $self->type
                    . "/"
                    . $self->id
        );
    }

    return $self->response();
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Delete - DAO request - delete

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
