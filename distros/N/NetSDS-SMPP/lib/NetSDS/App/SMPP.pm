#===============================================================================
#
#         FILE:  SMPP.pm
#
#  DESCRIPTION:  Flexible SMPP server application framework
#
#        NOTES:  Based on NetSDS::App, Net::SMPP and IO::Select
#       AUTHOR:  Michael Bochkaryov (RATTLER), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  23.10.2008 15:18:46 EEST
#===============================================================================

=head1 NAME

NetSDS::App::SMPP - SMPP application superclass

=head1 SYNOPSIS

	package SMPPServer;

	use base qw(NetSDS::App::SMPP);

	exit 1;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::App::SMPP;

use 5.8.0;
use strict;
use warnings;

use Errno qw(:POSIX);

use Net::SMPP;
use IO::Socket::INET;
use IO::Select;

use NetSDS::Util::String;
use NetSDS::Util::Convert;

use IPC::ShareLite;
use JSON;

use base qw(NetSDS::App);

use version; our $VERSION = "1.200";

# Default listen IP address and TCP port
use constant DEFAULT_BIND_ADDR   => '127.0.0.1';
use constant DEFAULT_LISTEN_PORT => '9900';
use constant SYSTEM_NAME         => 'NETSDS';

# SMPP PDU command_id table
use constant cmd_tab => {
	0x80000000 => 'generic_nack',
	0x00000001 => 'bind_receiver',
	0x80000001 => 'bind_receiver_resp',
	0x00000002 => 'bind_transmitter',
	0x80000002 => 'bind_transmitter_resp',
	0x00000003 => 'query_sm',
	0x80000003 => 'query_sm_resp',
	0x00000004 => 'submit_sm',
	0x80000004 => 'submit_sm_resp',
	0x80000005 => 'deliver_sm_resp',
	0x00000006 => 'unbind',
	0x80000006 => 'unbind_resp',
	0x00000007 => 'replace_sm',
	0x80000007 => 'replace_sm_resp',
	0x00000008 => 'cancel_sm',
	0x80000008 => 'cancel_sm_resp',
	0x00000009 => 'bind_transceiver',
	0x80000009 => 'bind_transceiver_resp',
	0x0000000b => 'outbind',
	0x00000015 => 'enquire_link',
	0x80000015 => 'enquire_link_resp',
};

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([...])>

Constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('listener');     # Listening socket
__PACKAGE__->mk_accessors('in_queue');     # Queue socket for incoming events (MT)
__PACKAGE__->mk_accessors('out_queue');    # Queue socket for outgoing events (MO, DLR)
__PACKAGE__->mk_accessors('selector');     # IO::Select handler
__PACKAGE__->mk_accessors('handlers');     # SMPP sessions handlers
__PACKAGE__->mk_accessors('shm');          # Shared memory interconnection area

sub initialize {

	my ( $this, %params ) = @_;

	# Common application initialization
	$this->SUPER::initialize(%params);

	# Initialize signals processing
	$this->set_signal_processors();

	# Create select() handler for incoming events
	$this->selector( IO::Select->new() );

	# Initialize queue listener for outgoing events
	$this->_init_out_queue();
	$this->selector->add( $this->out_queue );

	# Initialize queue for incoming (MT) events
	$this->_init_in_queue();

	# Initialize listening socket and add to select()
	$this->_init_listener();
	$this->selector->add( $this->listener );

	# Set initial empty array of handlers hashref
	$this->handlers( {} );

	# Initialize SHM area
	$this->_init_shm();

} ## end sub initialize

sub _init_shm {

	my ($this) = @_;

	# Create SHM segment for data exchange between
	# SMPP server and Queue processor
	my $shm = new IPC::ShareLite(
		-key     => $this->conf->{shm}->{segment},
		-create  => 'yes',
		-destroy => 'yes'
	);

	if ( !$shm ) {
		$this->log( "error", "Cant create shared memory segment" );
		$this->speak("Cant create shared memory segment");
		die $!;
	}

	# Initialize shared memory clients list
	# Structure: hash reference with system_id => 1
	$shm->store( encode_json( {} ) );

	$this->shm($shm);

} ## end sub _init_shm

sub set_signal_processors {

	my ( $this, %params ) = @_;

	#$SIG{CHLD} = 'IGNORE';
	#$SIG{HUP}  = 'IGNORE';
	#$SIG{TERM} = 'IGNORE';
	#$SIG{PIPE} = sub { warn "FUCK!\n" };

}

sub _init_listener {

	my ( $this, %params ) = @_;

	# Get bind address and TCP port
	my $bind_addr = DEFAULT_BIND_ADDR;
	my $bind_port = DEFAULT_LISTEN_PORT;

	# If configuration exists, use parameters
	if ( $this->conf and $this->conf->{smpp} ) {

		# Get bind IP address
		if ( defined $this->conf->{smpp}->{host} ) {
			$bind_addr = $this->conf->{smpp}->{host};
		}

		# Get bind TCP port
		if ( defined $this->conf->{smpp}->{port} ) {
			$bind_port = $this->conf->{smpp}->{port};
		}

	} else {
		$this->speak("Oops! No configuration found!");
	}

	# Create listening socket
	$this->listener(
		Net::SMPP->new_listen(
			$bind_addr,
			port              => $bind_port,
			smpp_version      => 0x34,
			interface_version => 0x00,
			addr_ton          => 0x00,
			addr_npi          => 0x01,
			source_addr_ton   => 0x00,
			source_addr_npi   => 0x01,
			dest_addr_ton     => 0x00,
			dest_addr_npi     => 0x01,
			system_type       => SYSTEM_NAME,
			facilities_mask   => 0x00010003,
		)
	);

	# If cant listen, die with error message
	if ( !$this->listener() ) {
		$this->log( 'error', "Cant open listening TCP socket on port $bind_port" );
		die("ERROR! Cant open listening TCP socket on port $bind_port. Closing application!\n");
	} else {
		$this->log( "info", "Listening on TCP port $bind_port" );
	}

} ## end sub _init_listener

sub _init_in_queue {

	my ( $this, %params ) = @_;

	$this->in_queue(
		NetSDS::Queue->new(
			server => '127.0.0.1:22201',
		)
	);

}

sub _init_out_queue {

	my ( $this, %params ) = @_;

	$this->out_queue(
		IO::Socket::INET->new(
			PeerAddr => '127.0.0.1',
			PeerPort => '9999',
			Proto    => 'tcp',
		)
	);

	if ( $this->out_queue ) {
		$this->log( "info", "Successfully connected to OUT Queue server" );
	} else {
		$this->log( "error", "Cant connect to ougoing queue server" );
		die("ERROR! Cant connect to outgoing queue server");
	}

} ## end sub _init_out_queue

sub main_loop {

	my ( $this, %params ) = @_;

	# Run user defined hooks on startup
	$this->start();

	# Run main process loop
	while ( !$this->{to_finalize} ) {

		# Wait for incoming events on all sockets
		my ( $sel_r, $sel_w, $sel_x ) = IO::Select->select( $this->selector, undef, undef );

		# Go through available for reading sockets
		if ( $sel_r and my @readers = @{$sel_r} ) {

			# Check all sockets ready for reading
			foreach my $reader (@readers) {

				no warnings 'uninitialized';

				if ( $reader eq $this->listener ) {

					# Process incoming connection
					$this->_accept_incoming();

				} elsif ( $reader eq $this->out_queue ) {

					# Process ougoing queue
					$this->_process_out_queue();

				} else {

					# Process events from established SMPP connection
					foreach my $hdl_key ( keys %{ $this->handlers } ) {
						if ( $this->handlers->{$hdl_key} and ( $this->handlers->{$hdl_key}->{smpp} eq $reader ) ) {
							$this->_process_socket( $this->handlers->{$hdl_key} );
						}
					}

				}
				;    ## end if ( $reader eq $this->listener )

				use warnings 'all';

			} ## end foreach my $reader (@readers)

		} ## end if ( $sel_r and my @readers...

	} ## end while ( !$this->{to_finalize...

	# Run user defined hooks on shutdown
	$this->stop();

} ## end sub main_loop

#***********************************************************************

=item B<_accept_incoming()> - accept incoming SMPP connection

Internal method providing TCP connection accept and add new handler.

=cut 

#-----------------------------------------------------------------------

sub _accept_incoming {

	my ( $this, %params ) = @_;
	$this->log( "info", "New connection arrived on SMPP socket" );

	# Try to accept incoming connection
	if ( my $conn = $this->listener->accept() ) {

		$this->log( "info", "TCP connection accepted" );
		$this->speak("New client accepted");

		# Add socket to IO::Select object
		$this->selector->add($conn);

		# Determine connection key as "host:port" string
		my $hdl_id = $conn->peerhost . ":" . $conn->peerport;

		# Create internal connection descriptor
		my $handler = {
			id            => $hdl_id,    # identifier
			smpp          => $conn,      # SMPP socket
			system_id     => undef,      # client system_id
			authenticated => undef,      # is authenticated
			out_seq       => 1,          # sequence_id for correct responses
			unacked       => 0,          # counter for unaccepted commands
		};

		# Add descriptor to connections table
		$this->{handlers}->{$hdl_id} = $handler;

	} else {
		$this->log( "error", "Cant accept() incoming connection" );
	}

} ## end sub _accept_incoming

sub _process_out_queue {
	my ( $this, %params ) = @_;

	# Try to get next line from Queue server over TCP socket
	if ( my $line = $this->out_queue->getline() ) {

		# Return if keepalive
		if ( $line =~ '-MARK-' ) {
			$this->speak("Keepalive from queue server");
			return 1;
		}

		# FIXME - provide incorrect data handling
		my $mo = decode_json( conv_base64_str($line) );

		use Data::Dumper;
		print Dumper($mo);

		# Check if know system_id
		if ( $mo->{client} ) {
			# Looking for proper ESME
			foreach my $hdl ( values %{ $this->handlers } ) {
				if ( $hdl->{system_id} eq $mo->{client} ) {
					if ( ( $hdl->{mode} eq 'transceiver' ) and ( $hdl->{mode} eq 'receiver' ) ) {
						$this->_deliver_sm( $hdl, $mo );    # send deliver_sm to ESME
					}
				}
			}
		} else {
			$this->log( "warning", "MO event without client (system_id)" );
		}

	} ## end if ( my $line = $this->out_queue...
} ## end sub _process_out_queue

sub _deliver_sm {

	my ( $this, $hdl, $mo ) = @_;

	if ( $mo->{id} ) {

		# Set default parameters (for MO SM)
		my $message_id       = $mo->{id};
		my $esm_class        = 0x00;
		my $source_addr_ton  = 0x01;
		my $source_addr_npi  = 0x01;
		my $source_addr      = $mo->{from};
		my $dest_addr_ton    = 0x00;
		my $dest_addr_npi    = 0x01;
		my $destination_addr = $mo->{to};
		my $msg_text         = "";

		# Set ESM class
		if ( $mo->{dlr} ) {
			$esm_class = 0x04;         # DLR
			$msg_text  = $mo->{dlr};
		} else {
			$msg_text = $mo->{text};    # FIXME - here should be UDH + UD
		}

		# Send deliver_sm
		$hdl->{smpp}->deliver_sm(
			source_addr_ton  => $source_addr_ton,    # International (MSISDN)
			source_addr_npi  => $source_addr_npi,    # E.164
			source_addr      => $source_addr,
			dest_addr_ton    => $dest_addr_ton,      # Unknown (default)
			dest_addr_npi    => $dest_addr_npi,      # E.164
			destination_addr => $destination_addr,
			esm_class        => $esm_class,          # MO data (UDH + UD) or DLR
			short_message    => $msg_text,
			async            => 1,
		);

	} ## end if ( $mo->{id} )

	$hdl->{out_seq}++;
} ## end sub _deliver_sm

sub cmd_deliver_sm_resp {

	return 1;

}

sub _process_socket {
	my ( $this, $hdl ) = @_;

	# Determine peer IP and port
	my $peer_addr = $hdl->{smpp}->peerhost;
	my $peer_port = $hdl->{smpp}->peerport;

	# Try to read PDU
	my $pdu = $hdl->{smpp}->read_pdu();
	if ( !$pdu ) {

		# Disconnect if EOF
		if ( $hdl->{smpp}->eof() ) {

			$this->speak("EOF from ${peer_addr}:${peer_port}");
			$this->log( "warning", "EOF from ${peer_addr}:${peer_port}" );

			# Remove socket from select()
			$this->selector->remove( $hdl->{smpp} );

			# Close socket and remove record
			$hdl->{smpp}->close();
			undef $this->{handlers}->{ $hdl->{id} };

			# Update SHM struture (only for defined system_id)
			if ( $hdl->{system_id} ) {
				$this->shm->lock;
				my $list = decode_json( $this->shm->fetch );
				delete $list->{ $hdl->{system_id} };
				$this->shm->store( encode_json($list) );
				$this->shm->unlock;
			}

		} else {

			$this->speak("Incoming event arrived but no SMPP PDU!");
			$this->log( "warning", "Incoming event arrived from [${peer_addr}:${peer_port}] but no SMPP PDU!" );

		}

	} else {

		# Process incoming PDU
		my $pdu_cmd = "unknown";
		if ( cmd_tab->{ $pdu->{cmd} } ) {
			$pdu_cmd = cmd_tab->{ $pdu->{cmd} };
		}

		$this->speak("PDU arrived: $pdu_cmd");

		# Determine method name to dispatch PDU call
		my $method_name = "cmd_" . $pdu_cmd;

		if ( $pdu_cmd eq 'enquire_link' ) {

			# process enqiure_link locally
			$this->cmd_enquire_link( $pdu, $hdl );

		} elsif ( ( $pdu_cmd =~ /^bind_(transceiver|transmitter|receiver)/ ) and $this->can($method_name) ) {

			# Process known authentication methods
			$this->$method_name( $pdu, $hdl );

		} elsif ( $this->can($method_name) and $hdl->{authenticated} ) {

			# process known PDUs
			$this->$method_name( $pdu, $hdl );

		} else {

			# PDU unknown - damn it
			$this->cmd_unknown( $pdu, $hdl );

		}

	} ## end else [ if ( !$pdu )

} ## end sub _process_socket

sub cmd_enquire_link {

	my ( $this, $pdu, $hdl ) = @_;

	$this->speak( "enquire_link from " . $hdl->{id} );

	my $resp = $hdl->{smpp}->enquire_link_resp(
		seq    => $pdu->{seq},
		status => 0x00000000,
	);

}

sub cmd_unknown {

	my ( $this, $pdu, $hdl ) = @_;

	$this->speak( "Uknown PDU arrived from " . $hdl->{id} );
	$this->log( "error", "Unknown PDU received, sending generic_nack" );

	my $resp = $hdl->{smpp}->generic_nack(
		seq    => $pdu->{seq},
		status => 0x00000003,    # ESME_RINVCMDID
	);

}

1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


