#!/usr/bin/env perl
# PODNAME: eris-dispatcher-stdin.pl
# ABSTRACT: Example Implementation for using with STDIN

use strict;
use warnings;

use Getopt::Long::Descriptive;
use POE qw(
    Wheel::ReadWrite
    Component::Server::eris
);

#--------------------------------------------------------------------------#
# Process Arguments
my ($opt,$usage) = describe_options( '%c - %o',
    ['eris-listen|el:s', "Address to listen for eris clients, default: 127.0.0.1", { default => '127.0.0.1' } ],
    ['eris-port|ep:i',   "TCP port to listen for incoming syslog, default 9514", { default => 9514 } ],
    [],
    ['graphite-host|g:s',  "Host to use to submit graphite metrics, default: disabled" ],
    ['graphite-port|gp:i', "Port for graphite metric submission, default: 2003", {default => 2003} ],
    ['graphite-prefix:s',  "Graphite prefix for metrics, default from POE::Component::Server::eris"],
    [],
    ['help',       "Show this message and exit.", { shortcircuit => 1 } ],
);

if( $opt->help ) {
    print $usage->text;
    exit 0;
}

#--------------------------------------------------------------------------#
# POE Session Initialization
#
# TCP Session Master
my $server = POE::Component::Server::eris->spawn(
    ListenAddress   => $opt->eris_listen,
    ListenPort      => $opt->eris_port,
    GraphitePort    => $opt->graphite_port,
    $opt->graphite_host   ? ( GraphiteHost => $opt->graphite_host ) : (),
    $opt->graphite_prefix ? ( GraphitePrefix => $opt->graphite_prefix ) : (),
);

# Syslog-ng Stream Master
POE::Session->create(
    inline_states => {
        _start      => \&stream_start,
        _stop       => sub { print "SESSION ", $_[SESSION]->ID, " stopped.\n"; },

        stream_line     => \&stream_line,
        stream_error    => \&stream_error,
    },
);


#--------------------------------------------------------------------------#
# POE Main Loop
POE::Kernel->run();
exit 0;
#--------------------------------------------------------------------------#


#--------------------------------------------------------------------------#
# POE Event Functions
sub stream_start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # Initialize the connection to STDIN as a POE::Wheel
    my $stdin = IO::Handle->new_from_fd( \*STDIN, 'r' );
    my $stderr = IO::Handle->new_from_fd( \*STDERR, 'w' );

    $heap->{stream} = POE::Wheel::ReadWrite->new(
        InputHandle     => $stdin,
        OutputHandle    => $stderr,
        InputEvent      => 'stream_line',
        ErrorEvent      => 'stream_error',
    );
}
#--------------------------------------------------------------------------#


sub stream_line {
    my ($kernel,$msg) = @_[KERNEL,ARG0];
    return unless length $msg;
    $kernel->post( $server->{ID} => dispatch_message => $msg );
}
#--------------------------------------------------------------------------#

sub stream_error {
    my ($kernel,$heap,$op,$errnum,$errstr,$id) = @_[KERNEL,HEAP,ARG0..ARG3];

    warn sprintf "Received stream_error on handle %d trying %s op [%d] %s",
        $id, $op, $errnum, $errstr;

    # Reached EOF on STDIN, shutdown
    if( $op eq 'read' && $id == $heap->{stream}->ID && $errnum == 0 ) {
        warn "Shutting down due to stream disconnect";
        #
        # Delete the Stream
        delete $heap->{stream};

        # Shutdown the dispatcher
        $kernel->call( $server->{ID} => server_shutdown => 'Stream lost' );

        # Bail early
        $kernel->stop;
    }
}
#--------------------------------------------------------------------------#

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-dispatcher-stdin.pl - Example Implementation for using with STDIN

=head1 VERSION

version 2.3

=head1 AUTHOR

Brad Lhotsky <brad@divsionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
