package Pcore::Lib::Sys::ForkTmpl;

use Pcore -const;
use AnyEvent::Util;
use Pcore::Lib::Data qw[to_cbor from_cbor];
use IO::FDPass;

our ( $CHILD_PID, $CHILD_FH );

const our $FORK_CMD_RUN_NODE => 1;

END {
    kill 'TERM', $CHILD_PID if defined $CHILD_PID;    ## no critic qw[InputOutput::RequireCheckedSyscalls]
}

_fork_tmpl();

sub _fork_tmpl {
    ( my $read_fh, $CHILD_FH ) = AnyEvent::Util::portable_socketpair();

    # parent
    if ( $CHILD_PID = fork ) {
        Pcore::_CORE_INIT_AFTER_FORK();

        require Pcore::Handle;

        close $read_fh or die $!;
    }

    # child
    else {
        undef $CHILD_PID;

        # run process in own PGRP
        # setpgrp;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

        close $CHILD_FH or die $!;

        _tmpl_proc($read_fh);
    }

    return;
}

sub run_node ( $type, $args ) {
    my $msg = to_cbor {
        cmd  => $FORK_CMD_RUN_NODE,
        type => $type,
        args => $args,
    };

    syswrite $CHILD_FH, pack( 'L', length $msg ) . $msg or die $!;

    IO::FDPass::send fileno $CHILD_FH, $args->{fh};

    return;
}

# TEMPLATE PROCESS
sub _tmpl_proc ( $fh ) {

    # child
    $0 = 'Pcore::Lib::Sys::ForkTmpl';    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    local $SIG{TERM} = sub { exit 128 + 15 };

    while () {

        # exit on fh close
        sysread $fh, my $len, 4 or exit;

        # exit on fh close
        sysread $fh, my $data, unpack 'L', $len or exit;

        $data = from_cbor $data;

        if ( $data->{cmd} == $FORK_CMD_RUN_NODE ) {
            $data->{args}->{fh} = IO::FDPass::recv fileno $fh;
        }

        # parent
        if (fork) {
            open my $fh1, '>&=', $data->{args}->{fh} or die $!;
            close $fh1 or die $!;
        }

        # child
        else {

            # run process in own PGRP
            # setpgrp;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

            close $fh or die $!;

            undef $SIG{TERM};

            _forked_proc($data);
        }
    }

    exit;
}

# FORKED FROM TEMPLATE PROCESS
sub _forked_proc ( $data ) {
    Pcore::_CORE_INIT_AFTER_FORK();

    # redefine watcher in the forked process
    $SIG->{TERM} = AE::signal TERM => sub { exit 128 + 15 };

    if ( $data->{cmd} == $FORK_CMD_RUN_NODE ) {
        require Pcore::Node::Node;

        $0 = $data->{type};    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

        P->class->load( $data->{type} );

        Pcore::Node::Node::run( $data->{type}, $data->{args} );
    }

    exit;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 23, 106              | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Sys::ForkTmpl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
