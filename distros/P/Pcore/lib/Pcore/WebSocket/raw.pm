package Pcore::WebSocket::raw;

use Pcore -class;

with qw[Pcore::WebSocket::Handle];

has on_disconnect => ();    # Maybe [CodeRef], ($self, $status)
has on_text       => ();    # Maybe [CodeRef], ($self, \$payload)
has on_bin        => ();    # Maybe [CodeRef], ($self, \$payload)

sub _on_connect ( $self ) {
    return $self;
}

sub _on_disconnect ( $self ) {
    $self->{on_disconnect}->($self) if $self->{on_disconnect};

    return;
}

sub _on_text ( $self, $data_ref ) {
    if ( $self->{on_text} ) {
        Coro::async_pool {
            $self->{on_text}->( $self, $data_ref );

            return;
        };
    }

    return;
}

sub _on_bin ( $self, $data_ref ) {
    if ( $self->{on_bin} ) {
        Coro::async_pool {
            $self->{on_bin}->( $self, $data_ref );

            return;
        };
    }

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
## |      | 11                   | * Private subroutine/method '_on_connect' declared but not used                                                |
## |      | 15                   | * Private subroutine/method '_on_disconnect' declared but not used                                             |
## |      | 21                   | * Private subroutine/method '_on_text' declared but not used                                                   |
## |      | 33                   | * Private subroutine/method '_on_bin' declared but not used                                                    |
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
