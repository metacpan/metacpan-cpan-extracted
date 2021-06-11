package POE::Component::Server::NSCA;
$POE::Component::Server::NSCA::VERSION = '0.12';
#ABSTRACT: a POE Component that implements NSCA daemon functionality

use strict;
use warnings;
use Socket;
use Carp;
use Net::Netmask;
use Math::Random;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Block);

use constant MAX_INPUT_BUFFER =>        2048    ; # /* max size of most buffers we use */
use constant MAX_HOST_ADDRESS_LENGTH => 256     ; # /* max size of a host address */
use constant MAX_HOSTNAME_LENGTH =>     64      ;
use constant MAX_DESCRIPTION_LENGTH =>  128;
use constant OLD_PLUGINOUTPUT_LENGTH => 512;
use constant MAX_PLUGINOUTPUT_LENGTH => 4096;
use constant MAX_PASSWORD_LENGTH =>     512;
use constant TRANSMITTED_IV_SIZE =>     128;
use constant SIZEOF_U_INT32_T   => 4;
use constant SIZEOF_INT16_T     => 2;
use constant SIZEOF_INIT_PACKET => TRANSMITTED_IV_SIZE + SIZEOF_U_INT32_T;

use constant PROBABLY_ALIGNMENT_ISSUE => 4;

use constant SIZEOF_DATA_PACKET => SIZEOF_INT16_T + SIZEOF_U_INT32_T + SIZEOF_U_INT32_T + SIZEOF_INT16_T + MAX_HOSTNAME_LENGTH + MAX_DESCRIPTION_LENGTH + MAX_PLUGINOUTPUT_LENGTH + PROBABLY_ALIGNMENT_ISSUE;
use constant SIZEOF_OLD_PACKET  => SIZEOF_INT16_T + SIZEOF_U_INT32_T + SIZEOF_U_INT32_T + SIZEOF_INT16_T + MAX_HOSTNAME_LENGTH + MAX_DESCRIPTION_LENGTH + OLD_PLUGINOUTPUT_LENGTH + PROBABLY_ALIGNMENT_ISSUE;

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

my $HAVE_MCRYPT = 0;
eval {
	require Mcrypt;
	$HAVE_MCRYPT++;
};

# Lookups for loading.
my %mcrypts =   (       ENCRYPT_NONE,		"none",
			ENCRYPT_XOR,		"xor",
			ENCRYPT_DES,            "DES",
                        ENCRYPT_3DES,           "3DES",
                        ENCRYPT_CAST128,        "CAST_128",
                        ENCRYPT_CAST256,        "CAST-256",
                        ENCRYPT_XTEA,           "XTEA",
                        ENCRYPT_3WAY,           "THREEWAY",
                        ENCRYPT_BLOWFISH,       "BLOWFISH",
                        ENCRYPT_TWOFISH,        "TWOFISH",
                        ENCRYPT_LOKI97,         "LOKI97",
                        ENCRYPT_RC2,            "RC2",
                        ENCRYPT_ARCFOUR,        "ARCFOUR",
                        ENCRYPT_RC6,            "RC6",
                        ENCRYPT_RIJNDAEL128,    "RIJNDAEL_128",
                        ENCRYPT_RIJNDAEL192,    "RIJNDAEL_192",
                        ENCRYPT_RIJNDAEL256,    "RIJNDAEL_256",
                        ENCRYPT_MARS,           "MARS",
                        ENCRYPT_PANAMA,         "PANAMA",
                        ENCRYPT_WAKE,           "WAKE",
                        ENCRYPT_SERPENT,        "SERPENT",
                        ENCRYPT_IDEA,           "IDEA",
                        ENCRYPT_ENIGMA,         "ENGIMA",
                        ENCRYPT_GOST,           "GOST",
                        ENCRYPT_SAFER64,        "SAFER_SK64",
                        ENCRYPT_SAFER128,       "SAFER_SK128",
                        ENCRYPT_SAFERPLUS,      "SAFERPLUS",
                );

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak "$package requires a 'password' argument\n"
	unless defined $opts{password};
  croak "$package requires an 'encryption' argument\n"
	unless defined $opts{encryption};
  croak "'encryption' argument must be a valid numeric\n"
	unless defined $mcrypts{ $opts{encryption} };
  my $options = delete $opts{options};
  my $access = delete $opts{access} || [ Net::Netmask->new('any') ];
  $access = [ ] unless ref $access eq 'ARRAY';
  foreach my $acl ( @$access ) {
	next unless $acl->isa('Net::Netmask');
	push @{ $opts{access} }, $acl;
  }
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
		$self => { shutdown       => '_shutdown',
		},
		$self => [qw(
				_start
				_accept_client
				_accept_failed
				_conn_input
				_conn_error
				_conn_alarm
				register
				unregister
		)],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub session_id {
  return $_[0]->{session_id};
}

sub getsockname {
  return unless $_[0]->{listener};
  return $_[0]->{listener}->getsockname();
}

sub _length_encoder {
  my $stuff = shift;
  return;
}

sub _length_decoder {
  my $stuff = shift;
  my $expected;

  if (length($$stuff) <= 0) {
     # not sure what the expected package size will be
     return;
  } elsif (length($$stuff) % SIZEOF_OLD_PACKET == 0) {
     # buffer size divisible by old packet size
     return SIZEOF_OLD_PACKET;
  } elsif (length($$stuff) % SIZEOF_DATA_PACKET == 0) {
     # buffer size divisible by the new packet size
     return SIZEOF_DATA_PACKET;
  } else {
     # buffer size not divisible, let it fill a little more
     return;
  }
}

sub _start {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
	$kernel->alias_set( $self->{alias} );
  }
  else {
	$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  $self->{filter} = POE::Filter::Block->new(LengthCodec => [ \&_length_encoder, \&_length_decoder ]);
  $self->{listener} = POE::Wheel::SocketFactory->new(
      ( defined $self->{address} ? ( BindAddress => $self->{address} ) : () ),
      ( defined $self->{port} ? ( BindPort => $self->{port} ) : ( BindPort => 5667 ) ),
      SuccessEvent   => '_accept_client',
      FailureEvent   => '_accept_failed',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );
  return;
}

sub register {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  my $sender_id = $sender->ID();
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
    %args = %{ $_[ARG0] };
  }
  elsif ( ref $_[ARG0] eq 'ARRAY' ) {
    %args = @{ $_[ARG0] };
  }
  else {
    %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  unless ( $args{event} ) {
    warn "No 'event' argument supplied\n";
    return;
  }
  if ( defined $self->{sessions}->{ $sender_id } ) {
    $self->{sessions}->{ $sender_id } = \%args;
  }
  else {
    $self->{sessions}->{ $sender_id } = \%args;
    $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  }
  return;
}

sub unregister {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  my $sender_id = $sender->ID();
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
    %args = %{ $_[ARG0] };
  }
  elsif ( ref $_[ARG0] eq 'ARRAY' ) {
    %args = @{ $_[ARG0] };
  }
  else {
    %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  my $data = delete $self->{sessions}->{ $sender_id };
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ ) if $data;
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{listener};
  delete $self->{clients};
  $kernel->refcount_decrement( $_, __PACKAGE__ ) for keys %{ $self->{sessions} };
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  return;
}

sub _accept_failed {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  warn "Listener: $wheel_id generated $operation error $errnum: $errstr\n";
  delete $self->{listener};
  $kernel->yield( '_shutdown' );
  return;
}

sub _accept_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport) = @_[KERNEL,OBJECT,ARG0..ARG2];
  my $sockaddr = inet_ntoa( ( unpack_sockaddr_in ( CORE::getsockname $socket ) )[1] );
  my $sockport = ( unpack_sockaddr_in ( CORE::getsockname $socket ) )[0];
  $peeraddr = inet_ntoa( $peeraddr );

  return unless grep { $_->match( $peeraddr ) } @{ $self->{access} };

  my $wheel = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Filter => $self->{filter},
	InputEvent => '_conn_input',
	ErrorEvent => '_conn_error',
	FlushedEvent => '_conn_flushed',
  );

  return unless $wheel;

  my $id = $wheel->ID();
  my $time = time();
  my $iv = join '', random_uniform_integer(128,0,9);
  my $init_packet = $iv . pack 'N', $time;
  $self->{clients}->{ $id } =
  {
	wheel    => $wheel,
	peeraddr => $peeraddr,
	peerport => $peerport,
	sockaddr => $sockaddr,
	sockport => $sockport,
	ts       => $time,
	iv	 => $iv,
  };
  $self->{clients}->{ $id }->{alarm} = $kernel->delay_set( '_conn_alarm', $self->{time_out} || 60, $id );
  $wheel->put( $init_packet );
  return;
}

sub _conn_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{clients}->{ $wheel_id };
  return 1;
}

sub _conn_error {
  my ($self,$errstr,$id) = @_[OBJECT,ARG2,ARG3];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  return;
}

sub _conn_alarm {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  return;
}

sub _conn_input {
  my ($kernel,$self,$packet,$id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_conn_exists( $id );
  my $client = $self->{clients}->{ $id };
  $kernel->alarm_remove( delete $client->{alarm} );
  my $data_packet_length = length($packet);
  my $input = _decrypt( $packet, $self->{encryption}, $client->{iv}, $self->{password}, $data_packet_length );
  return unless $input; # something wrong with the decryption
  my $version = unpack 'n', substr $input, 0, 4;
  return unless $version == 3 or $client->{version_already_checked}; # Wrong version received
  $client->{version_already_checked} = 1;
  my $crc32 = unpack 'N', substr $input, 4, 4;
  my $ts = unpack 'N', substr $input, 8, 4;
  my $rc = unpack 'n', substr $input, 12, 2;
  my $firstbit = substr $input, 0, 4;
  my $secondbit = substr $input, 8;
  my $checksum = _calculate_crc32( $firstbit . pack('N', 0) . $secondbit );
  my @data = unpack 'a[64]a[128]a[512]', substr $input, 14;
  s/\000.*$// for @data;
  my $result = {
   version      => $version,
   crc32        => $crc32,
   checksum     => $checksum,
   return_code  => $rc,
   timestamp    => $ts,
  };
  $result->{$_} = shift @data for qw(host_name svc_description plugin_output);
  $result->{$_} = $client->{$_} for qw(peeraddr peerport sockaddr sockport ts iv);
  $kernel->post( $_, $self->{sessions}->{$_}->{event}, $result, $self->{sessions}->{$_}->{context} )
	for keys %{ $self->{sessions} };
  return;
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
        }
	else {
          $crc = ($crc >> 1);
        }
     }
     $crc32_table->[$i] = $crc;
  }
  return $crc32_table;
}

# central switchboard for encryption methods.
sub _decrypt {
  my ($data_packet_string, $encryption_method, $iv_salt, $password, $data_packet_length) = @_;

  my $crypted;
  if ($encryption_method == ENCRYPT_NONE) {
       $crypted = $data_packet_string;
  }
  elsif ($encryption_method == ENCRYPT_XOR) {
       $crypted = _decrypt_xor($data_packet_string, $iv_salt, $password, $data_packet_length);
  }
  else {
       $crypted = _decrypt_mcrypt( $data_packet_string, $encryption_method, $iv_salt, $password );
  }
  return $crypted;
}

sub _decrypt_xor {
  my ($data_packet_string, $iv_salt, $password, $data_packet_length) = @_;

  my @out = split(//, $data_packet_string);
  my @salt_iv = split(//, $iv_salt);
  my @salt_pw = split(//, $password);

  my $y = 0;
  my $x = 0;

  #/* rotate over IV we received from the server... */
  while ($y < $data_packet_length) {
     #/* keep rotating over IV */
     $out[$y] = $out[$y] ^ $salt_iv[$x % scalar(@salt_iv)];

     $y++;
     $x++;
  }

  if (scalar(@salt_pw) > 0) {
    #/* rotate over password... */
    $y=0;
    $x=0;
    while ($y < $data_packet_length){
        #/* keep rotating over password */
        $out[$y] = $out[$y] ^ $salt_pw[$x % scalar(@salt_pw)];

        $y++;
        $x++;
    }
  }
  return join '', @out;
}

sub _decrypt_mcrypt {
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
           my $td = Mcrypt->new( algorithm => &{\&{"Mcrypt::".$routine}}(), mode => Mcrypt::CFB(), verbose => 0 );
           my $key = $password;
           my $iv = substr $iv_salt, 0, $td->{IV_SIZE};
           if( defined( $td ) ){
               $td->init($key, $iv);
	       for (my $i = 0; $i < length( $data_packet_string ); $i++ ) {
		 $crypted .= $td->decrypt( substr $data_packet_string, 0+$i, 1 );
	       }
               $td->end();
           }
           $evalok++;
        };
	warn "$@\n" if $@;
     }
  } else {
    warn "Mcrypt module missing\n";
  }
  return $crypted;
}

'Hon beiriant goes at hun ar ddeg';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::NSCA - a POE Component that implements NSCA daemon functionality

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use strict;
  use POE;
  use POE::Component::Server::NSCA;
  use POSIX;

  my $nagios_cmd = '/usr/local/nagios/var/rw/nagios.cmd';

  my $nscad = POE::Component::Server::NSCA->spawn(
	password => 'moocow',
	encryption => 1,
  );

  POE::Session->create(
	package_states => [
	   'main' => [qw(_start _message)],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
     $poe_kernel->post( $nscad->session_id(), 'register', event => '_message', context => 'moooo!' );
     return;
  }

  sub _message {
     my ($message,$context) = @_[ARG0,ARG1];

     print "Received message from: ", $message->{peeraddr}, "\n";

     # Send the check to the Nagios command file

     my $time = time();
     my $string;

     if ( $message->{svc_description} ) {
	$string = "[$time] PROCESS_SERVICE_CHECK_RESULT";
	$string = join ';', $string, $message->{host_name}, $message->{svc_description}, 
		    $message->{return_code}, $message->{plugin_output};
     }
     else {
	$string = "[$time] PROCESS_HOST_CHECK_RESULT";
	$string = join ';', $string, $message->{host_name}, $message->{return_code},
		    $message->{plugin_output};
     }

     print { sysopen (my $fh , $nagios_cmd, POSIX::O_WRONLY) or die "$!\n"; $fh } $string, "\n";

     return;
  }

=head1 DESCRIPTION

POE::Component::Server::NSCA is a L<POE> component that implements C<NSCA daemon> functionality.
This is the daemon program that accepts service check information from remote machines using
C<send_nsca> client or L<POE::Component::Client::NSCA>.

The component implements the network handling of accepting service check information from 
multiple clients, but doesn't deal with submitting the service checks to C<Nagios>. Instead
you will be provided with the service check results as events and decide how to deal with the
results as you see fit.

It is based in part on code shamelessly borrowed from L<Net::Nsca> and optionally supports 
encryption using the L<Mcrypt> module.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of parameters, mandatory ones are indicated:

  'password', password that should be used to encrypt the packet, mandatory;
  'encryption', the encryption method to use, see below, mandatory;
  'alias', set an alias on the component;
  'address', bind the listening socket to a particular address, default is IN_ADDR_ANY;
  'port', specify a port to listen on, default is 5667;
  'time_out', specify a time out in seconds for socket connections, default is 60;
  'access', an arrayref of Net::Netmask objects that will be granted access, default is 'any';

Returns a POE::Component::Server::NSCA object.

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

=back

=head1 METHODS

=over

=item C<session_id>

Returns the L<POE::Session> ID of the component.

=item C<shutdown>

Terminates the component. Shuts down the listener and disconnects connected clients and
unregisters registered sessions.

=item C<getsockname>

Access to the L<POE::Wheel::SocketFactory> method of the underlying listening socket.

=back

=head1 INPUT EVENTS

These are events from other POE sessions that our component will handle:

=over

=item C<register>

This will register the sending session. Takes a number of parameters:

   'event', the name of the event in the registering session that will be triggered, mandatory;
   'context', a scalar containing any reference data that your session demands;

The component will increment the refcount of the calling session to make sure it hangs around for events.
Therefore, you should use either C<unregister> or C<shutdown> to terminate registered sessions.

=item C<unregister>

This will unregister the sending session.

=back

=head1 OUTPUT EVENTS

Registered sessions will receive events with the following parameters:

=over

=item C<ARG0>

ARG0 will contain a hashref with the following key/values:

 'version', the version of NSCA protocol in use. Will be 3;
 'host_name', the hostname for which the check is applicable;
 'svc_description', the service description, not applicable for host checks;
 'return_code', the result code of the check;
 'plugin_output', any output from the check plugin;
 'peeraddr', the IP address of the client that gave us the check information;
 'peerport', the IP address of the client that gave us the check information;
 'crc32', the checksum provided by the client;
 'checksum', the checksum as the poco calculated it;
 'timestamp', the clients timestamp;

=item C<ARG1>

ARG1 will contain the value of the 'context' that was specified ( if applicable ) when the session
registered.

=back

=head1 PROVENANCE

Based on L<Net::Nsca> by P Kent

Which was originally derived from work by Ethan Galstad.

=head1 SEE ALSO

L<POE>

L<Net::Netmask>

L<Net::Nsca>

L<Mcrypt>

L<http://www.nagios.org/>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Chris Williams, P Kent and Ethan Galstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
