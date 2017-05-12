#
#
# vim: syntax=perl

use warnings;
use strict;

use Test::More 'no_plan';
BEGIN {
    use_ok 'POE';
    use_ok 'Sprocket';
    use_ok 'POE::Filter::Line';
    use_ok 'POE::Filter::Stream';
    use_ok 'POE::Wheel::Run';
}

SKIP: {

eval "use File::FDpasser";
if ( $@ ) {
    skip "File::FDpasser is unavilable";
}
    
use_ok 'Sprocket::Util::FDpasser';

my %opts = (
    LogLevel => 1,
    TimeOut => 0,
);

my $passer = Sprocket::Util::FDpasser->new(
    EndpointFile => 'fdpasser',
);

POE::Session->create( inline_states => {
    _start => sub {
        $poe_kernel->delay( shutdown => 5 => 1 );
        $poe_kernel->alias_set( 'test' );
        $passer->attach_hook(
            'sprocket.fdpasser.accept',
            $sprocket->callback( $_[SESSION] => 'fdpass' )
        );
        $_[HEAP]->{wheel} = POE::Wheel::Run->new(
            Program     => sub {
                my $ls = endp_connect("fdpasser") || die "endp_create: $!\n";
                my $rc = send_file( $ls, *STDIN{IO} );
                close(STDIN);
            },
            StdinEvent  => 'stdin',     # Flushed all data to the child's STDIN.
            StdoutEvent => 'stdout',    # Received data from the child's STDOUT.
            StderrEvent => 'stderr',    # Received data from the child's STDERR.
            ErrorEvent  => 'oops',          # An I/O error occurred.
            CloseEvent  => 'child_closed',  # Child closed all output handles.
            StderrFilter => POE::Filter::Line->new(),   # Child errors are lines.
            StdioFilter => POE::Filter::Line->new(),    # Or some other filter.
        );
    },
    stdin => sub {
    #    warn "stdin:".$_[ARG0]."\n";
    },
    stdout => sub {
    #    warn "Stdout:".$_[ARG0]."\n";
    },
    stderr => sub {
    #    warn "stderr:".$_[ARG0]."\n";
    },
    oops => sub {
    #    warn "oops:".$_[ARG0]."\n";
    },
    child_closed => sub {
        $poe_kernel->yield( 'shutdown' );
    },
    fdpass => sub {
        my ( $self, $event ) = @_[ OBJECT, ARG0 ];
        warn "event: ".$event->hook." with ".$event->{fh};
    },
    shutdown => sub {
        my $failed = $_[ ARG0 ];
        Test::More::fail("test failed")
            if ( $failed );
        $_[HEAP]->{wheel}->kill(9) if ( $_[HEAP]->{wheel} );
        delete $_[HEAP]->{wheel};
        $poe_kernel->alias_remove( 'test' );
        $poe_kernel->alarm_remove_all();
        $sprocket->shutdown_all();
        return;
    },
    _stop => sub { }
} );


$poe_kernel->run();

}
