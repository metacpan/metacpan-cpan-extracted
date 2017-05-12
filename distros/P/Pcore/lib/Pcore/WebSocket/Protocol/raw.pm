package Pcore::WebSocket::Protocol::raw;

use Pcore -class;

has protocol => ( is => 'ro', isa => Str, default => q[], init_arg => undef );

has on_text   => ( is => 'ro', isa => CodeRef, reader => undef );
has on_binary => ( is => 'ro', isa => CodeRef, reader => undef );
has on_pong   => ( is => 'ro', isa => CodeRef, reader => undef );

with qw[Pcore::WebSocket::Handle];

sub before_connect_server ( $self, $env, $args ) {
    return;
}

sub before_connect_client ( $self, $args ) {
    return;
}

sub on_connect_server ( $self ) {
    return;
}

sub on_connect_client ( $self, $headers ) {
    return;
}

sub on_disconnect ( $self, $status ) {
    return;
}

sub on_text ( $self, $data_ref ) {
    $self->{on_text}->($data_ref) if $self->{on_text};

    return;
}

sub on_binary ( $self, $data_ref ) {
    $self->{on_binary}->($data_ref) if $self->{on_binary};

    return;
}

sub on_pong ( $self, $data_ref ) {
    $self->{on_pong}->($data_ref) if $self->{on_pong};

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebSocket::Protocol::raw

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
