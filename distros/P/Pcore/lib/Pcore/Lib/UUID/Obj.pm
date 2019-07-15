package Pcore::Lib::UUID::Obj;

use Pcore -class;

has bin => ( is => 'lazy' );
has str => ( is => 'lazy' );
has hex => ( is => 'lazy' );

sub _build_bin ($self) {
    if ( defined $self->{str} ) {
        return Data::UUID->from_string( $self->{str} );
    }
    elsif ( defined $self->{hex} ) {
        return Data::UUID->from_hexstring( $self->{hex} );
    }
    else {
        die q[UUID was not found];
    }
}

sub _build_str ($self) {
    return join '-', unpack 'H8H4H4H4H12', $self->bin;
}

sub _build_hex ($self) {
    return unpack 'h*', $self->bin;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::UUID::Obj

=head1 SYNOPSIS

    P->uuid->str;
    P->uuid->bin;
    P->uuid->hex;

=head1 DESCRIPTION

This is Data::UUID wrapper to use with Pcore::Lib interafce.

=head1 SEE ALSO

L<Data::UUID|https://metacpan.org/pod/Data::UUID>

=cut
