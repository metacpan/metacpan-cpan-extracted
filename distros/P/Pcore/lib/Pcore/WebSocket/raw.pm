package Pcore::WebSocket::raw;

use Pcore -class;

with qw[Pcore::WebSocket::Handle];

has on_connect    => ();    # Maybe [CodeRef], ($self)
has on_disconnect => ();    # Maybe [CodeRef], ($self, $status)
has on_text       => ();    # Maybe [CodeRef], ($self, \$payload)
has on_binary     => ();    # Maybe [CodeRef], ($self, \$payload)

sub _on_connect ( $self, $status ) {
    $self->{on_connect}->( $self, $status ) if $self->{on_connect};

    return;
}

sub _on_disconnect ( $self, $status ) {
    $self->{on_disconnect}->( $self, $status ) if $self->{on_disconnect};

    return;
}

sub _on_text ( $self, $data_ref ) {
    $self->{on_text}->( $self, $data_ref ) if $self->{on_text};

    return;
}

sub _on_binary ( $self, $data_ref ) {
    $self->{on_binary}->( $self, $data_ref ) if $self->{on_binary};

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 12                   | * Private subroutine/method '_on_connect' declared but not used                                                |
## |      | 18                   | * Private subroutine/method '_on_disconnect' declared but not used                                             |
## |      | 24                   | * Private subroutine/method '_on_text' declared but not used                                                   |
## |      | 30                   | * Private subroutine/method '_on_binary' declared but not used                                                 |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebSocket::raw

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
