#!/usr/bin/env perl
# PODNAME: eris-dispatch-tcp.pl
# ABSTRACT: Example using POE::Component::Server::eris with a PoCo::Server::TCP Implementation

use strict;
use warnings;
use POE qw(
	Component::Server::TCP
	Component::Server::eris
);

# POE Session Initialization

# Eris Dispatcher
my $SESSION = POE::Component::Server::eris->spawn(
	ListenAddress		=> '127.0.0.1',
	ListenPort			=> 9514,
);

# TCP Session Master
POE::Component::Server::TCP->new(
		Alias		=> 'server',
		Address		=> '127.0.0.1',
		Port		=> 9513,

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

version 2.0

=head1 AUTHOR

Brad Lhotsky <brad@divsionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
