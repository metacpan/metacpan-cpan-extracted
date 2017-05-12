# ABSTRACT: DAO request role - `update` & like related functionality
package PONAPI::DAO::Request::Role::UpdateLike;

use Moose::Role;

use PONAPI::Constants;
use PONAPI::Exception;

has respond_to_updates_with_200 => (
    is  => 'ro',
    isa => 'Bool',
);

has update_nothing_status => (
    is      => 'ro',
    isa     => 'Int',
    # http://jsonapi.org/format/#crud-updating-relationship-responses-204
    # Basically, we return a 204, UNLESS it's an ->update() call, in which
    # case it has to return a 404:
    # http://jsonapi.org/format/#crud-updating-responses-404
    default => sub { 204 },
);

sub _verify_update_response {
    my ( $self, $ret, @extra ) = @_;

    PONAPI::Exception->throw(
        internal => 1,
        message  => "update-like operation returned an unexpected value"
    ) unless exists $PONAPI_UPDATE_RETURN_VALUES{$ret};

    my $doc = $self->document;
    return if $doc->has_errors or $doc->has_status;

    if ( $self->respond_to_updates_with_200 ) {
        $doc->set_status(200);
        $self->repository->retrieve(
            type     => $self->type,
            id       => $self->id,
            document => $doc,
        ) if $ret == PONAPI_UPDATED_EXTENDED;
        return 1;
    }
    else {
        $doc->set_status(202);
    }

    return 1;
}

sub _add_success_meta {
    my ($self, $return_status) = @_;

    my $resource = $self->_get_resource_for_meta;

    my $detail = "successfully modified $resource";
    if ( $return_status == PONAPI_UPDATED_NOTHING ) {
        my $status = $self->update_nothing_status;
        $self->document->set_status($status);
        # This should NEVER show up in a response, because it would
        # mean a 204 with a body; I'm still leaving it here because
        # a 204+body is preferable to a server error due to an empty
        # document.
        $detail = "modified nothing for $resource"
    }

    $self->document->add_meta( detail => $detail );
}

sub _get_resource_for_meta {
    my $self = shift;

    my $link = $self->document->req_path
        // ( join "/" => grep defined, '', @{$self}{qw/type id rel_type/} );

    return $link . " => " . $self->json->encode( $self->data );
}

no PONAPI::Constants;
no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Role::UpdateLike - DAO request role - `update` & like related functionality

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
