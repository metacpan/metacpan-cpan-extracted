package POE::Component::Client::NSCA;
$POE::Component::Client::NSCA::VERSION = '0.18';
#ABSTRACT: a POE Component that implements send_nsca functionality

use strict;
use warnings;
use POE qw(Wheel::SocketFactory Filter::Stream Wheel::ReadWrite);
use Carp;
use Socket;
use integer;

use constant PROGRAM_VERSION => "1.2.0b4-Perl";
use constant MODIFICATION_DATE => "16-03-2006";

use constant OK	=> 0;
use constant ERROR => -1;

use constant TRUE => 1;
use constant FALSE => 0;

use constant STATE_CRITICAL => 	2	; # /* service state return codes */
use constant STATE_WARNING => 	1	;
use constant STATE_OK =>       	0	;
use constant STATE_UNKNOWN =>	3	; # Updated for Nagios.

use constant DEFAULT_SOCKET_TIMEOUT	=> 10	; # /* timeout after 10 seconds */
use constant DEFAULT_SERVER_PORT =>	5667	; # /* default port to use */

use constant MAX_INPUT_BUFFER =>	2048	; # /* max size of most buffers we use */
use constant MAX_HOST_ADDRESS_LENGTH =>	256	; # /* max size of a host address */
use constant MAX_HOSTNAME_LENGTH =>	64	;
use constant MAX_DESCRIPTION_LENGTH =>	128;
use constant MAX_PLUGINOUTPUT_LENGTH =>	512;
use constant MAX_PASSWORD_LENGTH =>     512;

use constant ENCRYPT_NONE =>            0       ; # /* no encryption */
use constant ENCRYPT_XOR =>             1       ; # /* not really encrypted, just obfuscated */
use constant ENCRYPT_DES =>             2       ; # /* DES */
use constant ENCRYPT_3DES =>            3       ; # /* 3DES or Triple DES */
use constant ENCRYPT_CAST128 =>         4       ; # /* CAST-128 */
use constant ENCRYPT_CAST256 =>         5       ; # /* CAST-256 */
use constant ENCRYPT_XTEA =>            6       ; # /* xTEA */
use constant ENCRYPT_3WAY =>            7       ; # /* 3-WAY */
use constant ENCRYPT_BLOWFISH =>        8       ; # /* SKIPJACK */
use constant ENCRYPT_TWOFISH =>         9       ; # /* TWOFISH */
use constant ENCRYPT_LOKI97 =>          10      ; # /* LOKI97 */
use constant ENCRYPT_RC2 =>             11      ; # /* RC2 */
use constant ENCRYPT_ARCFOUR =>         12      ; # /* RC4 */
use constant ENCRYPT_RC6 =>             13      ; # /* RC6 */            ; # /* UNUSED */
use constant ENCRYPT_RIJNDAEL128 =>     14      ; # /* RIJNDAEL-128 */
use constant ENCRYPT_RIJNDAEL192 =>     15      ; # /* RIJNDAEL-192 */
use constant ENCRYPT_RIJNDAEL256 =>     16      ; # /* RIJNDAEL-256 */
use constant ENCRYPT_MARS =>            17      ; # /* MARS */           ; # /* UNUSED */
use constant ENCRYPT_PANAMA =>          18      ; # /* PANAMA */         ; # /* UNUSED */
use constant ENCRYPT_WAKE =>            19      ; # /* WAKE */
use constant ENCRYPT_SERPENT =>         20      ; # /* SERPENT */
use constant ENCRYPT_IDEA =>            21      ; # /* IDEA */           ; # /* UNUSED */
use constant ENCRYPT_ENIGMA =>          22      ; # /* ENIGMA (Unix crypt) */
use constant ENCRYPT_GOST =>            23      ; # /* GOST */
use constant ENCRYPT_SAFER64 =>         24      ; # /* SAFER-sk64 */
use constant ENCRYPT_SAFER128 =>        25      ; # /* SAFER-sk128 */
use constant ENCRYPT_SAFERPLUS =>       26      ; # /* SAFER+ */

use constant TRANSMITTED_IV_SIZE =>     128     ; # /* size of IV to transmit - must be as big as largest IV needed for any crypto algorithm */


use constant NSCA_PACKET_VERSION_3 =>	3		; # /* packet version identifier */
use constant NSCA_PACKET_VERSION_2 =>	2		; # /* packet version identifier */
use constant NSCA_PACKET_VERSION_1 =>	1		; # /* older packet version identifier */

use constant SIZEOF_U_INT32_T   => 4;
use constant SIZEOF_INT16_T     => 2;
use constant SIZEOF_INIT_PACKET => TRANSMITTED_IV_SIZE + SIZEOF_U_INT32_T;

use constant PROBABLY_ALIGNMENT_ISSUE => 4;

use constant SIZEOF_DATA_PACKET => SIZEOF_INT16_T + SIZEOF_U_INT32_T + SIZEOF_U_INT32_T + SIZEOF_INT16_T + MAX_HOSTNAME_LENGTH + MAX_DESCRIPTION_LENGTH + MAX_PLUGINOUTPUT_LENGTH + PROBABLY_ALIGNMENT_ISSUE;

# Work out whether we have the mcrypt libraries on board.
my $HAVE_MCRYPT = 0;
eval {
	require Mcrypt;
	$HAVE_MCRYPT++;
};

# Lookups for loading.
my %mcrypts =   (       ENCRYPT_DES,            "des",
                        ENCRYPT_3DES,           "3des",
                        ENCRYPT_CAST128,        "cast-128",
                        ENCRYPT_CAST256,        "cast-256",
                        ENCRYPT_XTEA,           "xtea",
                        ENCRYPT_3WAY,           "threeway",
                        ENCRYPT_BLOWFISH,       "blowfish",
                        ENCRYPT_TWOFISH,        "twofish",
                        ENCRYPT_LOKI97,         "loki97",
                        ENCRYPT_RC2,            "rc2",
                        ENCRYPT_ARCFOUR,        "arcfour",
                        ENCRYPT_RC6,            "rc6",
                        ENCRYPT_RIJNDAEL128,    "rijndael-128",
                        ENCRYPT_RIJNDAEL192,    "rijndael-192",
                        ENCRYPT_RIJNDAEL256,    "rijndael-256",
                        ENCRYPT_MARS,           "mars",
                        ENCRYPT_PANAMA,         "panama",
                        ENCRYPT_WAKE,           "wake",
                        ENCRYPT_SERPENT,        "serpent",
                        ENCRYPT_IDEA,           "idea",
                        ENCRYPT_ENIGMA,         "engima",
                        ENCRYPT_GOST,           "gost",
                        ENCRYPT_SAFER64,        "safer-sk64",
                        ENCRYPT_SAFER128,       "safer-sk128",
                        ENCRYPT_SAFERPLUS,      "saferplus",
                );

sub send_nsca {
  my $package = shift;
  my %params = @_;
  $params{lc $_} = delete $params{$_} for keys %params;
  croak "$package requires a 'host' argument\n"
	unless $params{host};
  croak "$package requires an 'event' argument\n"
	unless $params{event};
  croak "$package requires a 'password' argument\n"
	unless $params{password} || $params{encryption} eq ENCRYPT_XOR;
  croak "$package requires an 'encryption' argument\n"
	unless defined $params{encryption};
  croak "$package requires a 'message' argument and it must be a hashref\n"
	unless $params{message} and ref $params{message} eq 'HASH';
  foreach my $item ( qw(host_name return_code plugin_output) ) {
     croak "'message' hashref must have a '$item' key\n" 
	unless defined $params{message}->{$item};
  }
  _correct_message( $params{message} );
  $params{port} = 5667 unless defined $params{port};
  $params{timeout} = 10 unless defined $params{timeout} and $params{timeout} =~ /^\d+$/;
  my $options = delete $params{options};
  my $self = bless \%params, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => [ qw(_start _connect _sock_up _sock_err _sock_in _sock_flush _sock_down _send_response _timeout) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub _start {
  my ($kernel,$sender,$self) = @_[KERNEL,SENDER,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  $self->{filter} = POE::Filter::Stream->new();
  if ( $kernel == $sender and !$self->{session} ) {
	croak "Not called from another POE session and 'session' wasn't set\n";
  }
  my $sender_id;
  if ( $self->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $self->{session} ) ) {
	$sender_id = $ref->ID();
    }
    else {
	croak "Could not resolve 'session' to a valid POE session\n";
    }
  }
  else {
    $sender_id = $sender->ID();
  }
  $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  $self->{sender_id} = $sender_id;
  $kernel->yield( '_connect' );
  return;
}

sub _connect {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{sockfactory} = POE::Wheel::SocketFactory->new(
	SocketProtocol => 'tcp',
	RemoteAddress => $self->{host},
	RemotePort => $self->{port},
	SuccessEvent => '_sock_up',
	FailureEvent => '_sock_err',
  );
  $kernel->delay( '_timeout', $self->{timeout} );
  return;
}

sub _timeout {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{sockfactory};
  delete $self->{socket};
  $kernel->yield( '_send_response', 'timeout' );
  return;
}

sub _sock_err {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->delay( '_timeout' );
  delete $self->{sockfactory};
  $kernel->yield( '_send_response', 'sockerr', @_[ARG0..ARG2] );
  return;
}

sub _sock_up {
  my ($kernel,$self,$socket) = @_[KERNEL,OBJECT,ARG0];
  $kernel->delay( '_timeout' );
  delete $self->{sockfactory};
  $self->{socket} = new POE::Wheel::ReadWrite
    ( Handle     => $socket,
      Filter     => $self->{filter},
      InputEvent => '_sock_in',
      ErrorEvent => '_sock_down',
      FlushedEvent => '_sock_flush',
  );
  $self->{state} = 'init';
  $kernel->delay( '_timeout', $self->{timeout} );
  return;
}

sub _sock_down {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{socket};
  $kernel->delay( '_timeout' );
  return;
}

sub _sock_in {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  unless ( length( $input ) == SIZEOF_INIT_PACKET ) {
	$kernel->yield( '_send_response', 'badinit', length( $input ) );
	delete $self->{socket};
	return;
  }
  my $init_packet = {
      iv => substr($input, 0, TRANSMITTED_IV_SIZE),
      timestamp => substr($input, TRANSMITTED_IV_SIZE, SIZEOF_U_INT32_T),
  };
  my $data_packet_string_a = pack('n', NSCA_PACKET_VERSION_3) . "\000\000";
  my $data_packet_string_b =
	$init_packet->{timestamp} .
	pack('n', $self->{message}->{return_code}) .
	pack(('a'.MAX_HOSTNAME_LENGTH), $self->{message}->{host_name}) .
	pack(('a'.MAX_DESCRIPTION_LENGTH), $self->{message}->{svc_description} || '') .
	pack(('a'.MAX_PLUGINOUTPUT_LENGTH), $self->{message}->{plugin_output}) .
	"\000\000";
  my $crc = _calculate_crc32( $data_packet_string_a . pack( 'N', 0 ) . $data_packet_string_b);
  my $data_packet_string = $data_packet_string_a . pack('N', $crc) . $data_packet_string_b;
  my $data_packet_string_crypt = _encrypt($data_packet_string, $self->{encryption}, $init_packet->{iv}, $self->{password} );
  unless ( $data_packet_string_crypt ) {
	$kernel->yield( '_send_response', 'badencrypt' );
	delete $self->{socket};
	return;
  }
  $self->{socket}->put( $data_packet_string_crypt );
  return;
}

sub _sock_flush {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->delay( '_timeout' );
  delete $self->{socket};
  $kernel->yield( '_send_response', 'success' );
  return;
}

sub _send_response {
  my ($kernel,$self,$type) = @_[KERNEL,OBJECT,ARG0];
  my $response = { };
  $response->{$_} = $self->{$_} for qw(host message context);
  SWITCH: {
     if ( $type eq 'badinit' ) {
	$response->{error} = 'Error: bad initialisation string from peer expected' . SIZEOF_INIT_PACKET . ' got ' . $_[ARG1];
	last SWITCH;
     }
     if ( $type eq 'badencrypt' ) {
	$response->{error} = 'Error: There was a problem with the encryption';
	last SWITCH;
     }
     if ( $type eq 'sockerr' ) {
	$response->{error} = 'Error: socket error: ' . join(' ', @_[ARG1..$#_]);
	last SWITCH;
     }
     if ( $type eq 'timeout' ) {
	$response->{error} = sprintf("Error: Socket timeout after %d seconds.", $self->{timeout} );
	last SWITCH;
     }
     $response->{success} = 1;
  }
  $kernel->post( $self->{sender_id}, $self->{event}, $response );
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $kernel->alarm_remove_all();
  return;
}

# truncates long fields
sub _correct_message {
  my $message = shift;

  $message->{'svc_description'} = '' unless defined $message->{'svc_description'};
  if (length( $message->{'host_name'} ) >= MAX_HOSTNAME_LENGTH) {
     warn("Hostname too long - truncated");
     $message->{'host_name'} = substr($message->{'host_name'}, 0, MAX_HOSTNAME_LENGTH-1);
  }
  if (length( $message->{'svc_description'} ) >= MAX_DESCRIPTION_LENGTH) {
     warn("Description too long - truncated");
     $message->{'svc_description'} = substr($message->{'svc_description'}, 0, MAX_DESCRIPTION_LENGTH-1);
  }
  if (length( $message->{'plugin_output'} ) >= MAX_PLUGINOUTPUT_LENGTH) {
     warn("Plugin Output too long - truncated");
     $message->{'plugin_output'} = substr($message->{'plugin_output'}, 0, MAX_PLUGINOUTPUT_LENGTH-1);
  }
  return $message;
}


#/* calculates the CRC 32 value for a buffer */
sub _calculate_crc32 {
        my $string = shift;

        my $crc32_table = _generate_crc32_table();
        my $crc = 0xFFFFFFFF;

        foreach my $tchar (split(//, $string)) {
                my $char = ord($tchar);
                $crc = (($crc >> 8) & 0x00FFFFFF) ^ $crc32_table->[($crc ^ $char) & 0xFF];
        }

        return ($crc ^ 0xFFFFFFFF);
}

#/* build the crc table - must be called before calculating the crc value */
sub _generate_crc32_table {
        my $crc32_table = [];
        my $poly = 0xEDB88320;

        for (my $i = 0; $i < 256; $i++){
                my $crc = $i;
                for (my $j = 8; $j > 0; $j--) {
                        if ($crc & 1) {
                                $crc = ($crc >> 1) ^ $poly;
                        } else {
                                $crc = ($crc >> 1);
                        }
                }
                $crc32_table->[$i] = $crc;
        }
        return $crc32_table;
}

# central switchboard for encryption methods.
sub _encrypt {
        my ($data_packet_string, $encryption_method, $iv_salt, $password) = @_;

        my $crypted;
        if ($encryption_method == ENCRYPT_NONE) {
                $crypted = $data_packet_string;
        } elsif ($encryption_method == ENCRYPT_XOR) {
                $crypted = _encrypt_xor($data_packet_string, $iv_salt, $password);
        } else {
                $crypted = _encrypt_mcrypt( $data_packet_string, $encryption_method, $iv_salt, $password );
        }
        return $crypted;
}

sub _encrypt_xor {
        my ($data_packet_string, $iv_salt, $password) = @_;

        my @out = split(//, $data_packet_string);
        my @salt_iv = split(//, $iv_salt);
        my @salt_pw = split(//, $password);

        my $y = 0;
        my $x = 0;

        #/* rotate over IV we received from the server... */
        while ($y < SIZEOF_DATA_PACKET) {
                #/* keep rotating over IV */
                $out[$y] = $out[$y] ^ $salt_iv[$x % scalar(@salt_iv)];

                $y++;
                $x++;
        }

        if ($password) {
            #/* rotate over password... */
            $y=0;
            $x=0;
            while ($y < SIZEOF_DATA_PACKET){
                    #/* keep rotating over password */
                    $out[$y] = $out[$y] ^ $salt_pw[$x % scalar(@salt_pw)];

                    $y++;
                    $x++;
            }
        }
        return( join('',@out) );
}

sub _encrypt_mcrypt {
  my ( $data_packet_string, $encryption_method, $iv_salt, $password ) = @_;
  my $crypted;
  my $evalok = 0;
  if( $HAVE_MCRYPT ){
     # Initialise the routine
     if( defined( $mcrypts{$encryption_method} ) ){
        # Load the routine.
        my $routine = $mcrypts{$encryption_method};
        eval {
           # This sometimes dies with 'mcrypt is not of type MCRYPT'.
           my $td = Mcrypt->new( algorithm => $routine, mode => 'cfb', verbose => 0 );
           my $key = $password;
           my $iv = substr $iv_salt, 0, $td->{IV_SIZE};
           if( defined( $td ) ){
               $td->init($key, $iv);
	       for (my $i = 0; $i < length( $data_packet_string ); $i++ ) {
		 $crypted .= $td->encrypt( substr $data_packet_string, 0+$i, 1 );
	       }
               $td->end();
           }
           $evalok++;
        };
	warn "$@\n" if $@;
     }
  }

  # Mcrypt is fastest, but for some routines, there are alternatives if
  # your perl Mcrypt <-> libmcrypt linkage isn't working.
  if( ! $evalok && ! defined( $crypted ) && defined( $encryption_method )){
      if( defined( $mcrypts{$encryption_method} ) && 1 == 2 ){
         my $routine = '_encrypt_' . $mcrypts{$encryption_method};
         if( $routine !~ /_$/ ){
            eval {
              $crypted = $routine->( $data_packet_string, $encryption_method, $iv_salt, $password );
            };
         }
      }
   }
   return( $crypted );
}


'Yn anfon i maes an SOS';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Client::NSCA - a POE Component that implements send_nsca functionality

=head1 VERSION

version 0.18

=head1 SYNOPSIS

   use strict;
   use POE qw(Component::Client::NSCA);
   use Data::Dumper;

   POE::Session->create(
	inline_states => {
		_start =>
		sub {
		   POE::Component::Client::NSCA->send_nsca(
			host    => $hostname,
			event   => '_result',
			password => 'moocow',
			encryption => 1, # Lets use XOR
			message => {
					host_name => 'bovine',
					svc_description => 'chews',
					return_code => 0,
					plugin_output => 'Chewing okay',
			},
		   );
		   return;
		},
		_result =>
		sub {
		   my $result = $_[ARG0];
		   print Dumper( $result );
		   return;
		},
	}
   );

   $poe_kernel->run();
   exit 0;

=head1 DESCRIPTION

POE::Component::Client::NSCA is a L<POE> component that implements C<send_nsca> functionality.
This is the client program that is used to send service check information from a remote machine to
an nsca daemon on the central machine that runs C<Nagios>.

It is based in part on code shamelessly borrowed from L<Net::Nsca> and optionally supports 
encryption using the L<Mcrypt> module.

=head1 CONSTRUCTOR

=over

=item C<send_nsca>

Takes a number of parameters:

  'host', the hostname or IP address to connect to, mandatory;
  'event', the event handler in your session where the result should be sent, mandatory;
  'password', password that should be used to encrypt the packet, mandatory;
  'encryption', the encryption method to use, see below, mandatory;
  'message', a hashref containing details of the message to send, see below, mandatory;
  'session', optional if the poco is spawned from within another session;
  'port', the port to connect to, default is 5667;
  'context', anything you like that'll fit in a scalar, a ref for instance;
  'timeout', number of seconds to wait for socket timeouts, default is 10;

The 'session' parameter is only required if you wish the output event to go to a different
session than the calling session, or if you have spawned the poco outside of a session.

The 'encryption' method is an integer value indicating the type of encryption to employ:

       0 = None        (Do NOT use this option)
       1 = Simple XOR  (No security, just obfuscation, but very fast)

       2 = DES
       3 = 3DES (Triple DES)
       4 = CAST-128
       5 = CAST-256
       6 = xTEA
       7 = 3WAY
       8 = BLOWFISH
       9 = TWOFISH
       10 = LOKI97
       11 = RC2
       12 = ARCFOUR

       14 = RIJNDAEL-128
       15 = RIJNDAEL-192
       16 = RIJNDAEL-256

       19 = WAKE
       20 = SERPENT

       22 = ENIGMA (Unix crypt)
       23 = GOST
       24 = SAFER64
       25 = SAFER128
       26 = SAFER+

Methods 2-26 require that the L<Mcrypt> module is installed.

The 'message' hashref must contain the following keys:

  'host_name', the host that this check is for, mandatory;
  'return_code', the result code for the check, mandatory;
  'plugin_output', the output from the check, mandatory;
  'svc_description', the service description ( required if this is a service not a host check );

The poco does it's work and will return the output event with the result.

=back

=head1 OUTPUT EVENT

This is generated by the poco. ARG0 will be a hash reference with the following keys:

  'host', the hostname given;
  'message', the message that was sent;
  'context', anything that you specified;
  'success', indicates that the check was successfully sent to the NSCA daemon;
  'error', only exists if something went wrong;

=head1 PROVENANCE

Based on L<Net::Nsca> by P Kent

Which was originally derived from work by Ethan Galstad.

=head1 SEE ALSO

L<POE>

L<Net::Nsca>

L<Mcrypt>

L<http://www.nagios.org/>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams, P Kent and Ethan Galstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
