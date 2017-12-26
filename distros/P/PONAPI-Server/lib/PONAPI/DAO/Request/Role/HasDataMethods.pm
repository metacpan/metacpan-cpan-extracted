# ABSTRACT: DAO request role - `data` methods
package PONAPI::DAO::Request::Role::HasDataMethods;

use Moose::Role;

sub _validate_data {
    my $self = shift;

    # these are chained to avoid multiple errors on the same issue
    $self->check_data_has_type
        and $self->check_data_type_match
        and $self->check_data_attributes
        and $self->check_data_relationships;
}

sub check_data_has_type {
    my $self = shift;

    for ( $self->_get_data_elements ) {
        next if ref($_||'') ne 'HASH';

        return $self->_bad_request( "request data has no `type` key" )
            if !exists $_->{'type'};
    }

    return 1;
}

sub check_data_type_match {
    my $self = shift;

    for ( $self->_get_data_elements ) {
        return $self->_bad_request( "conflict between the request type and the data type", 409 )
            unless $_->{'type'} eq $self->type;
    }

    return 1;
}

sub check_data_attributes {
    my $self = shift;
    my $type = $self->type;

    for my $e ( $self->_get_data_elements ) {
        next unless $e and exists $e->{attributes};
        $self->repository->type_has_fields( $type, [ keys %{ $e->{'attributes'} } ] )
            or return $self->_bad_request(
                "Type `$type` does not have at least one of the attributes in data"
            );
    }

    return 1;
}

sub check_data_relationships {
    my $self = shift;
    my $type = $self->type;

    for my $e ( $self->_get_data_elements ) {
        next unless $e and exists $e->{relationships};

        if ( %{ $e->{relationships} } ) {
            for my $rel_type ( keys %{ $e->{relationships} } ) {
                if ( !$self->repository->has_relationship( $type, $rel_type ) ) {
                    return $self->_bad_request(
                        "Types `$type` and `$rel_type` are not related",
                        404
                    );
                }
                elsif ( !$self->repository->has_one_to_many_relationship( $type, $rel_type )
                        and ref $e->{relationships}{$rel_type} eq 'ARRAY'
                        and @{ $e->{relationships}{$rel_type} } > 1
                    ) {
                    return $self->_bad_request(
                        "Types `$type` and `$rel_type` are one-to-one, but got multiple values"
                    );
                }
            }
        }
    }

    return 1;
}

sub _get_data_elements {
    my $self = shift;
    return ( ref $self->data eq 'ARRAY' ? @{ $self->data } : $self->data );
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Role::HasDataMethods - DAO request role - `data` methods

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
