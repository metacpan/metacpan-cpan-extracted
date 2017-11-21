#!/usr/bin/env perl
# PODNAME: eris-dispatch-tcp.pl
# ABSTRACT: Example using POE::Component::Server::eris with a PoCo::Server::TCP Implementation

use strict;
use warnings;

use Getopt::Long::Descriptive;
use POE qw(
	Component::Server::TCP
	Component::Server::eris
);

# Process Arguments
my ($opt,$usage) = describe_options( '%c - %o',
    ['syslog-listen|sl:s', "Address to listen for incoming syslog, default: 0.0.0.0", { default => '0.0.0.0' } ],
    ['syslog-port|sp:i',   "TCP port to listen for incoming syslog, default 514", { default => 514 } ],
    [],
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

# Eris Server
my $SESSION = POE::Component::Server::eris->spawn(
		ListenAddress	=> $opt->eris_listen,
		ListenPort		=> $opt->eris_port,
        GraphitePort    => $opt->graphite_port,
        $opt->graphite_host ? ( GraphiteHost => $opt->graphite_host ) : (),
        $opt->graphite_prefix ? ( GraphitePrefix => $opt->graphite_prefix ) : (),
);

# Syslog "server"
my $SERVER = POE::Component::Server::TCP->new(
		Address		=> $opt->syslog_listen,
		Port		=> $opt->syslog_port,
        # Handle Inbound Syslog Data
		ClientConnected		=> \&client_connect,
		ClientInput			=> \&client_input,
		ClientDisconnected	=> \&client_term,
		ClientError			=> \&client_term,
);

#--------------------------------------------------------------------------#

#--------------------------------------------------------------------------#
# POE Main Loop
POE::Kernel->run();
exit 0;
#--------------------------------------------------------------------------#


#--------------------------------------------------------------------------#
# POE Event Functions
sub client_connect {
	my ($kernel,$heap,$ses) = @_[KERNEL,HEAP,SESSION];

	my $KID = $kernel->ID();
	my $CID = $heap->{client}->ID;
	my $SID = $ses->ID;

	$heap->{clients}{ $SID } = $heap->{client};
}
#--------------------------------------------------------------------------#

sub client_input {
	my ($kernel,$heap,$ses,$msg) = @_[KERNEL,HEAP,SESSION,ARG0];
	my $sid = $ses->ID;

	$kernel->post( $SESSION->{alias} => dispatch_message => $msg );
}
#--------------------------------------------------------------------------#

sub client_term {
	my ($kernel,$heap,$ses) = @_[KERNEL,HEAP,SESSION];
	my $sid = $ses->ID;

	delete $heap->{clients}{$sid};
}
#--------------------------------------------------------------------------#

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-dispatch-tcp.pl - Example using POE::Component::Server::eris with a PoCo::Server::TCP Implementation

=head1 VERSION

version 2.3

=head1 AUTHOR

Brad Lhotsky <brad@divsionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
