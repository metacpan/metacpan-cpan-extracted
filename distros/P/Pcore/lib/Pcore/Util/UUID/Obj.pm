package Pcore::Util::UUID::Obj;

use Pcore -class;

has bin => ( is => 'lazy', isa => Str );
has str => ( is => 'lazy', isa => Str );
has hex => ( is => 'lazy', isa => Str );

sub _build_bin ($self) {
    return defined $self->{str} ? $Pcore::Util::UUID::UUID->from_string( $self->{str} ) : defined $self->{hex} ? $Pcore::Util::UUID::UUID->from_hexstring( $self->{hex} ) : die q[UUID was not found];
}

sub _build_str ($self) {
    return $Pcore::Util::UUID::UUID->to_string( $self->bin );
}

sub _build_hex ($self) {
    return $Pcore::Util::UUID::UUID->to_hexstring( $self->bin );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::UUID::Obj

=head1 SYNOPSIS

    P->uuid->str;
    P->uuid->bin;
    P->uuid->hex;

=head1 DESCRIPTION

This is Data::UUID wrapper to use with Pcore::Util interafce.

=head1 SEE ALSO

L<Data::UUID|https://metacpan.org/pod/Data::UUID>

=cut
