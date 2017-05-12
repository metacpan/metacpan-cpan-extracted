package Pcore::Util::Sys;

use Pcore;

sub cpus_num {
    state $cpus_num = do {
        require Sys::CpuAffinity;

        Sys::CpuAffinity::getNumCpus();
    };

    return $cpus_num;
}

sub hostname {
    state $hostname = do {
        require Sys::Hostname;    ## no critic qw[Modules::ProhibitEvilModules]

        Sys::Hostname::hostname();
    };

    return $hostname;
}

sub get_free_port ($ip = undef) {
    state $init = !!require Socket;

    if ($ip) {
        $ip = Socket::inet_aton $ip;
    }
    else {
        $ip = "\x7f\x00\x00\x01";    # 127.0.0.1
    }

    for ( 1 .. 10 ) {
        socket my $socket, Socket::AF_INET(), Socket::SOCK_STREAM(), 0 or next;

        bind $socket, Socket::pack_sockaddr_in 0, $ip or next;

        my $sockname = getsockname $socket or next;

        my ( $bind_port, $bind_ip ) = Socket::sockaddr_in($sockname);

        return $bind_port;
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
## |    2 | 32                   | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut
