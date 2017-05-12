#
# Copyright (C) 2009, 2010  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

package SRS::EPP::Proxy;

use MooseX::Singleton;
use MooseX::Params::Validate;
use SRS::EPP::Session;
use Event;
use Log::Log4perl qw(:easy);
use POSIX ":sys_wait_h";

with 'SRS::EPP::Proxy::SimpleConfig';
with 'MooseX::Getopt';
with 'MooseX::Log::Log4perl::Easy';
with 'MooseX::Daemonize';

has '+configfile' => (
	default => sub {
		[
			"$ENV{HOME}/.srs_epp_proxy.yaml",
			'/etc/srs-epp-proxy.yaml'
		];
		}
);

sub BUILD {
	my $self = shift;

	# should have already done SimpleConfig; with a bit of luck,
	# all properties in this master object may be specified there.

	# pass configuration via this method to log4perl
	my $logging = $self->logging;

	if ( !defined $logging ) {
		$logging = "INFO";
	}

	if ( !ref $logging and !-f $logging ) {

		# 'default'
		if ( $self->is_daemon ) {
			$logging = {
				rootLogger => "$logging, Syslog",
				"appender.Syslog" => "nz.net.nzrs.SyslogAppender",
				"appender.Syslog.logopt" => "pid",
				"appender.Syslog.Facility" => "daemon",
				"appender.Syslog.layout" =>
					"Log::Log4perl::Layout::SimpleLayout",
			};
		}
		else {
			$logging = {
				rootLogger => "$logging, Screen",
				"appender.Screen" => "Log::Log4perl::Appender::Screen",
				"appender.Screen.stderr" => 1,
				"appender.Screen.layout" =>
					"Log::Log4perl::Layout::SimpleLayout",
			};
		}
	}

	# prepend "log4perl." to config hashes
	if ( ref $logging and ref $logging eq "HASH" ) {
		for my $key ( keys %$logging ) {
			if (
				$key !~ /^log4perl\./
				and
				!exists $logging->{"log4perl.$key"}
				)
			{
				$logging->{"log4perl.$key"} =
					delete $logging->{$key};
			}
		}
	}
	
    $Log::Log4perl::JavaMap::user_defined{'nz.net.nzrs.SyslogAppender'} = 'SRS::EPP::Logging::SyslogAppender';

	Log::Log4perl->init($logging);

	# pass configuration options to the session class?
}

our $VERSION = "0.21";

has 'logging' =>
	is => "ro",
	isa => "HashRef[Str]",
	;

has 'listen' =>
	is => "ro",
	isa => "ArrayRef[Str]",
	metaclass => "Getopt",
	;

has 'listener' =>
	is => "rw",
	isa => "SRS::EPP::Proxy::Listener",
	default => sub {
	require SRS::EPP::Proxy::Listener;
	my $self = shift;
	SRS::EPP::Proxy::Listener->new(
		($self->listen ? (listen => $self->listen) : () ),
	);
	},
	lazy => 1,
	handles => {
	'init_listener' => 'init',
	},
	;

has 'ssl_key_file' =>
	metaclass => "Getopt",
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'ssl_cert_file' =>
	metaclass => "Getopt",
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'ssl_cert_dir' =>
	is => "ro",
	isa => "Str",
	default => "",
	;

use Sys::Hostname qw(hostname);
has 'server_name' =>
	is => "ro",
	isa => "Str",
	lazy => 1,
	default => sub {
	my $self = shift;
	my @listen = @{ $self->listen };
	if ( @listen == 1 and $listen[0] !~ /^(?:\d+\.|\[)/ ) {

		# listen address seems a reasonable default...
		$listen[0];
	}
	else {
		hostname;
	}
	};

has 'ssl_engine' =>
	is => "rw",
	isa => "Net::SSLeay::OO::Context",
	;

has 'rfc_compliant_ssl' =>
	is => "rw",
	traits => [qw[Getopt]],
	isa => "Bool",
	;

use Net::SSLeay::OO;
use Net::SSLeay::OO::Error qw(die_if_ssl_error);
use Net::SSLeay::OO::Constants
	qw(MODE_ENABLE_PARTIAL_WRITE MODE_ACCEPT_MOVING_WRITE_BUFFER
	OP_ALL OP_NO_SSLv2 VERIFY_PEER VERIFY_FAIL_IF_NO_PEER_CERT
	FILETYPE_PEM);

sub init_ssl {
	my ($self) = @_;

	my $ctx = Net::SSLeay::OO::Context->new(
		use_default_verify_paths => 0,
	);
	$ctx->set_options(&OP_ALL | OP_NO_SSLv2);
	my $options = VERIFY_PEER;
	if ( $self->rfc_compliant_ssl) {
		$self->log_info(
			"Strict RFC5734-compliant SSL enabled (client certificates required)"
		);
		$options |= VERIFY_FAIL_IF_NO_PEER_CERT;
	}
	$ctx->set_verify($options);
	$self->log_info("SSL Certificates from ".$self->ssl_cert_dir);
	$ctx->load_verify_locations("", $self->ssl_cert_dir);
	$self->log_info(
		"SSL private key: ".$self->ssl_key_file
			.", public certificate chain: ".$self->ssl_cert_file
	);
	$ctx->use_PrivateKey_file($self->ssl_key_file, FILETYPE_PEM);
	$ctx->use_certificate_chain_file($self->ssl_cert_file);
	die_if_ssl_error;  # one last check...
	$self->ssl_engine($ctx);
}

sub init {
    my ($self) = @_;

	$self->log_info("Initializing PGP");
	$self->init_pgp;
	$self->log_info("Initializing SSL");
	$self->init_ssl;
	$self->log_info("Initializing URIs");
	$self->init_uris;
	$self->log_info("Initializing Listener");
	$self->init_listener;
}

has 'openpgp' =>
	is => "ro",
	isa => "SRS::EPP::OpenPGP",
	lazy => 1,
	default => sub {
	my $self = shift;
	require SRS::EPP::OpenPGP;
	my $pgp_dir = $self->pgp_dir;
	my $secring_file = "$pgp_dir/secring.gpg";
	my $pubring_file = "$pgp_dir/pubring.gpg";
	my $pgp = SRS::EPP::OpenPGP->new(
		public_keyring => $pubring_file,
		secret_keyring => $secring_file,
	);
	$pgp->uid($self->pgp_keyid) if $self->pgp_keyid;
	my $key = $pgp->default_signing_key;
	$pgp;
	},
	handles => ["pgp"],
	;

has 'pgp_keyid' =>
	metaclass => "Getopt",
	is => "ro",
	isa => "Str",
	;

has 'pgp_dir' =>
	is => "ro",
	isa => "Str",
	default => sub {
	$ENV{GNUPGHOME} || "$ENV{HOME}/.gnupg";
	},
	;

sub init_pgp {
    my ($self) = @_;

	$self->pgp;
}

has 'extensions' =>
	metaclass => "Getopt",
	is => "ro",
	isa => "HashRef",
	required => 0,
	;
	
has 'services' =>
	metaclass => "Getopt",
	is => "ro",
	isa => "ArrayRef",
	required => 1,
	;

sub init_uris {
    my ($self) = @_;

	# Register namespaces to be returned by greeting
	use XML::EPP;
	XML::EPP::register_obj_uri(
		@{ $self->services },
	);
	
	if ($self->extensions) {
		XML::EPP::register_ext_uri(
			%{ $self->extensions },
		);
	}
}

has 'running' =>
	is => "rw",
	isa => "Bool",
	default => 1,
	;

has 'child_pids' =>
	is => "ro",
	isa => "ArrayRef[Int]",
	default => sub { [] },
	;

has 'backend' =>
	is => "ro",
	isa => "Str",
	default => "https://srstest.srs.net.nz/srs/registrar",
	;

has 'timeout' =>
	is => "ro",
	isa => "Int",
	default => 300,
	;
	
has 'connection_count' =>
    is => 'rw',
    isa => 'Num',
    default => 0,
    traits  => ['Counter'],
    handles => {
        inc_connection_count   => 'inc',
        dec_connection_count   => 'dec',
        reset_connection_count => 'reset',
    },    
    ;
    
has 'max_connections' =>
	metaclass => "Getopt",
	is => "ro",
	isa => "Int",
	default => 50,
	;    

sub accept_one {
    my ($self) = @_;

	$self->log_trace("accepting connections");
	my $socket = $self->listener->accept
		or return;
		
    if ($self->connection_count >= $self->max_connections) {
        $self->log_info("At threshold of " . $self->connection_count . " simultaneous connections. " .
            "Not responding to connection attempt from " . $socket->peerhost);
        $socket->print("Server Busy");
        $socket->close();
        return;
    }
    
    $self->inc_connection_count;
    $self->log_debug("Connection begun. Connection count now at: " . $self->connection_count);

	if ( !$self->foreground and (my $pid = fork) ) {
		push @{ $self->child_pids }, $pid;
		$self->log_debug("forked $pid for connection");
		return ();
	}
	else {

		# We'll also want to know the address of the other end
		# of the socket, for checking it against the back-end
		# ACL
		my $peerhost = $socket->peerhost;
		$self->log_info("connection from $peerhost, starting SSL");
		$0 = "srs-epp-proxy [$peerhost] - SSL init";
		
        my $ssl;
        eval {
            # Don't use catch_signal(), as we need to handle it right away
            local $SIG{ALRM} = sub {
                die "Timed out waiting for a SSL handshake to complete\n";
            };

            alarm $self->timeout;
            $ssl = $self->ssl_engine->accept($socket);
            alarm 0;
        };

		my $error = $@;
		if ($error) {

			# We got an SSL error - send it back to the client, and close the connection
			$socket->print($error);
			$socket->close();
			die $error;
		}

		$0 = "srs-epp-proxy [$peerhost] - setup";

		# RFC3734 and updates specify the use of client
		# certificates.  So, fetch it and get its subject.
		my $client_cert = $ssl->get_peer_certificate;
		my $peer_cn;
		if ($client_cert) {

			# should use subjectAltName if present..
			$peer_cn = $client_cert->get_subject_name->cn;
			$self->log_info("have a valid peer certificate, cn=$peer_cn");
		}
		else {
			$self->log_info("no peer certificate presented");
		}

		# set the socket to non-blocking for event-driven fun.
		my $mode = (
			MODE_ENABLE_PARTIAL_WRITE |
				MODE_ACCEPT_MOVING_WRITE_BUFFER
		);
		$ssl->set_mode($mode);
		$socket->blocking(0);

		# create a new session...
		my $session = SRS::EPP::Session->new(
			io => $ssl,
			proxy => $self,
			socket => $socket,
			($self->timeout ? (timeout => $self->timeout) : ()),
			backend_url => $self->backend,
			event => "Event",
			peerhost => $peerhost,
			($self->rfc_compliant_ssl ? (peer_cn => lc $peer_cn) : ()),
		);

		# let it know it's connected.
		$session->connected;

		return $session;
	}
}

sub show_state {
    my $self = shift;
    my ($state,$session) = pos_validated_list(
        \@_,
        { isa => 'Str' }, 
        { isa => 'SRS::EPP::Session', optional => 1 },
    );

	my ($regid, $peer_host_or_cn);
	if ($session) {
		$regid = $session->user;
		$peer_host_or_cn = $session->peer_cn
			|| $session->peerhost;
	}
	$0 = "srs-epp-proxy [$peer_host_or_cn] - ".
		($regid?"registrar $regid - ":"").$state;
}

has signals =>
	is => "rw",
	isa => "HashRef[Int]",
	default => sub { {} },
	;

has handlers =>
	is => "rw",
	isa => "HashRef[CodeRef]",
	default => sub { {} },
	;

sub signal_handler {
    my ($self,$signal) = @_;

	$self->log_debug("caught SIG$signal");
	$self->signals->{$signal}++;
}

sub process_signals {
    my ($self) = @_;

	my $sig_h = $self->signals;
	while (my ($signal,$handler) = each %{ $self->handlers }) {
		if ($sig_h->{$signal}) {
			$sig_h->{$signal} = 0;
			$self->log_debug("processing SIG$signal");
			$handler->();
		}
	}
}

sub catch_signal {
    my $self = shift;
    my ($sig,$sub) = pos_validated_list(
        \@_,
        { isa => 'Str' }, 
        { isa => 'CodeRef' }
    );

	$self->handlers->{$sig} = $sub;
	$SIG{$sig} = sub { $self->signal_handler($sig) };
}

sub accept_loop {
    my ($self) = @_;

    # Setup sig handle for INT/TERM
    #  (note, shutting down via MooseX::Daemonize normally uses INT)
    my $sig_handler = sub {
    	$self->log_info("Shutting down.");
    	for my $kid ( @{ $self->child_pids } ) {
    		kill "TERM", $kid;
    	}
    	$self->running(0);
    };
    
    for my $sig (qw(INT TERM)) {
    	$self->catch_signal(
    		$sig => $sig_handler, 
    	);
    }
	
	if ( !$self->foreground ) {
		$self->catch_signal(CHLD => sub { 
		    $self->reap_children;
	    });
	}
	$0 = "srs-epp-proxy - listener";
	while ( $self->running ) {
		my $session = eval {
		    $self->accept_one;
		};
		my $error = $@;
		if ($error) {
            $self->log_error("Got error while accepting connection: $error");  
            exit unless $self->foreground;
		}
		
		if ($session) {
			unless ( $self->foreground ) {
				$self->catch_signal(
					TERM => sub {
						$session->shutdown;
					}
				);
			}
			$self->log_trace("accepted a new session, entering event loop");

			# if an untrapped error occurs, we have to just bail out.
			# events need to trap errors themselves to avoid this.
			local($Event::DIED) = sub {
				my $event = shift;
				my $exception = shift;
				my $estr = "Unhandled exception during ".$event->w->desc."; $exception";
				if ( open(my $out,">","/tmp/proxy-crashlog") ) {
					# Just in case the logging isn't working....
					print $out "$estr\n";
				}
				$self->log_error($estr);
				Event::unloop_all;
			};
			Event::loop();
			$self->log_info("Session ends");
			exit unless $self->foreground;
		}
		else {
			$self->log_trace("no new session, processing signals");
			$self->process_signals;
		}
	}
}

sub reap_children {
	my ($self) = @_;
	my $kid;
	my %reaped;
	do {
		$kid = waitpid(-1, WNOHANG);
		if ($kid > 0) {
			$reaped{$kid} = $?;
			$self->log_info(
				"child $kid, ".(
					$?&255
					?" killed by signal "
						.($?&127)
						.($?&128?" (core dumped)":"")
					:"exited with error code ".($?>>8)
					)
			);

			$self->dec_connection_count;
			$self->log_debug("Connection ended. Connection count now at: " . $self->connection_count); 			
			
		}
	} while ($kid > 0);
	my $child_pids = $self->child_pids;
	@$child_pids = grep { exists $reaped{$_} } @$child_pids;
}

{
	no warnings 'redefine';
	my $daemonize = \&daemonize;
	*daemonize = sub {
		my $self = shift;
		my %args = @_;
		$args{dont_close_all_files} = 1;
		$SIG{__DIE__} = sub {

			# be sure to re-throw exceptions whilst inside
			# eval { }
			if ($^S) {
				die @_;
			}
			else {
				$self->log_error("Uncaught exception, exiting: @_");
				$self->log_error("stack trace: ".Carp::longmess);
				exit(1);
			}
		};
		my $no_recurse;
		$SIG{__WARN__} = sub {
			return if $no_recurse;
			$no_recurse = 1;
			eval { $self->log_warn("caught warning: @_") };
			$no_recurse = 0;
		};
		$daemonize->($self, %args);
	};
}

before 'start' => sub {
	my $self = shift;
	$self->init;
};

after 'start' => sub {
	my $self = shift;
	if ($self->is_daemon) {
		$self->log_info("Dropping Privileges");
		$self->drop_privs;
		$self->accept_loop;
	}
};

has 'user' =>
	is => "ro",
	isa => "Str",
	default => "nobody",
	;

sub drop_privs {
    my ($self) = @_;

	if ( $< and $> ) {
		$self->log_info("Not dropping privilegs, already UID $<");
	}
	my $user = $self->user;
	my ($uid, $gid) = (getpwnam $user)[2,3] or do {
		$self->log_error("cannot drop privileges; no such user '$user'");
	};
	my $group = getgrgid($gid) || $gid;
	$self->log_debug("Setting UID:GID to $user:$group");

	$( = $) = $gid;
	$< = $> = $uid;
}

1;

__END__

=head1 NAME

SRS::EPP::Proxy - IETF EPP <=> SRS XML proxy software

=head1 SYNOPSIS

 my $proxy = SRS::EPP::Proxy->new(

     # where to listen for inbound connections
     listen => [ "$addr:$port", "[$addr6]:$port" ],

     # SSL engine: certificate for presentation
     ssl_key_file => $ssl_key_filename,
     ssl_cert_file => $ssl_key_filename,

     # path for verifying client certificates
     ssl_cert_dir => $ssl_cert_path,
     # and of course, revocations
     ssl_crl_file => $ssl_crl_file,

     # PGP home for dealing with the SRS
     pgp_dir => $path,

     );

 # initialises everything - listens on sockets, checks SSL
 # keys and PGP home dir valid
 $proxy->init();

 # main entry mechanism
 $proxy->accept_loop();

 # alternate piecemeal interfaces, mostly for testing
 $proxy->init_listener;
 $proxy->init_ssl;
 $proxy->init_pgp;
 my $session = $proxy->accept_one;  # doesn't fork

=head1 DESCRIPTION

SRS::EPP::Proxy implements an XML to XML gateway between two
contemporary protocols for domain name management; EPP as defined by
RFC 3730 and later, and the SRS protocol used by the .nz registry.

This module implements the SSL listener; it accepts connections, forks
a new child for each one, collects client certificate information
about the SSL connection as recommended by RFC 3734, and then starts
an Event loop (using L<Event>) and passes control to the
L<SRS::EPP::Session> module.

Other modules of interest; ie the key modules in this stack are:

=over

=item L<Moose>

Almost every module on this list is written using L<Moose>.

=item L<SRS::EPP::Session>

Implements the session logic which manages connections, and "oversees"
the general flow of converting incoming messages to messages which are
sent to the back-end.  Has slave classes for managing the various
queues which can build up.

=item L<Net::SSLeay::OO>

This module provides the interface to the OpenSSL library that this
stack uses, and in particular is used by SRS::EPP::Session to gather
information about the client certificate.

=item L<XML::Relax::Generate>

Relax NG to Moose class component.  The classes this module generates
are used as basis for below classes.

=item L<XML::Relax::Marshall>

XML to and from Moose data structure component.  This module can
create data structures which match the class structure made by
L<XML::Relax::Generate>

=item L<SRS::EPP::Message::*>

(based on) XML::Relax::Generate conversions of the various XML Schema
files in RFCs 3730 - 3733 (actually their later updates, RFC 4930 and
above) to Moose classes. These are marshalled to and from XML using
XML::Relax::Marshall, above.

=item L<SRS::Message::*>

These classes are similar conversions, but for the SRS protocol
messages.  These are based on a conversion of the Relax schema which
is used to generate the RFC (not yet assigned an IETF number).

=item L<Crypt::OpenPGP>

An oldie but a goodie, this module is a nice pure perl implementation
of PGP, which is used to sign requests and verify responses to and
from the SRS back-end system.

=back

=cut

