# Declare our package
package POE::Component::SSLify::NonBlock;
use strict;
use warnings;
use POE::Component::SSLify::NonBlock::ServerHandle;
use Exporter;

use vars qw( $VERSION @ISA );
$VERSION = '0.41';

@ISA = qw(Exporter);
use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( Server_SSLify_NonBlock SSLify_Options_NonBlock_ClientCert Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL Server_SSLify_NonBlock_SSLDone
                 Server_SSLify_NonBlock_GetClientCertificateIDs  Server_SSLify_NonBlock_ClientCertificateExists  Server_SSLify_NonBlock_ClientCertIsValid Server_SSLify_NonBlock_STARTTLS);

use Symbol qw( gensym );

sub Server_SSLify_NonBlock_SSLDone {
   my $socket = shift;
   my $acceptstateclient = tied( *$socket )->_get_self()->{acceptstate}
      if exists(tied( *$socket )->_get_self()->{acceptstate});
   return 1 if ($acceptstateclient > 2);
   return 0;
}

sub SSLify_Options_NonBlock_ClientCert {
   my $ctx = shift;
   my $cacrt = shift;
   my $count = shift || 5;
   # CA File einlesen, wenn wir eins haben
   Net::SSLeay::CTX_load_verify_locations($ctx, $cacrt, '') || die $!;

   # Setzen welche Clientzertifkate wir moegen...
   Net::SSLeay::CTX_set_client_CA_list($ctx, Net::SSLeay::load_client_CA_file($cacrt));

   # Wir ueberpruefen auch signierte Zertifikate....
   Net::SSLeay::CTX_set_verify_depth($ctx, $count);
}

# Okay, the main routine here!
sub Server_SSLify_NonBlock {
   # Get the socket!
   my $ctx = shift;
   my $socket = shift;
   my $params = shift;

   # Validation...
   if ( ! defined $socket ) {
      die "Did not get a defined socket";
   }

   # If we don't have a ctx ready, we can't do anything...
   if ( ! defined $ctx ) {
      die 'Please do SSLify_Options() first';
   }

   $socket->blocking( 0 );

   # Now, we create the new socket and bind it to our subclass of Net::SSLeay::Handle
   my $newsock = gensym();
   tie( *$newsock, 'POE::Component::SSLify::NonBlock::ServerHandle', $socket, $ctx, $params ) or die "Unable to tie to our subclass: $!";

   # All done!
   return $newsock;
}

sub Server_SSLify_NonBlock_ClientCertificateExists {
   my $socket = shift;
   my $infos = tied( *$socket )->_get_self()->{infos};
   return ((ref($infos) eq "ARRAY") && ($infos->[1]));
}

sub Server_SSLify_NonBlock_ClientCertIsValid {
   my $socket = shift;
   my $infos = tied( *$socket )->_get_self()->{infos};
   return Server_SSLify_NonBlock_ClientCertificateExists($socket) ? (($infos->[0] eq "1") && (ref($infos->[2]) eq "ARRAY") && scalar(@{$infos->[2]})) ? 1 : 0 : 0;
}

sub Server_SSLify_NonBlock_GetClientCertificateIDs {
   my $socket = shift;
   my $infos = tied( *$socket )->_get_self()->{infos};
   return Server_SSLify_NonBlock_ClientCertificateExists($socket) ? @{$infos->[2]} : undef;
}

sub Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL {
   my $socket = shift;
   my $crlfilename = shift;
   my $infos = tied( *$socket )->_get_self()->{infos};
   my @certids = Server_SSLify_NonBlock_GetClientCertificateIDs($socket);
   if (scalar(@certids)) {
      my $found = 0;
      my $badcrls = 0;
      my $jump = 0;
      print("----- SSL Infos BEGIN ---------------"."\n")
         if (tied( *$socket )->_get_self()->{debug});
      foreach (@{$infos->[2]}) {
         my $crlstatus = Net::SSLeay::verify_serial_against_crl_file($crlfilename, $_->[2]);
         $badcrls++ if $crlstatus;
         $crlstatus = $crlstatus ? "INVALID (".($crlstatus !~ m,^CRL:, ? hexdump($crlstatus) : $crlstatus).")" : "VALID";
         my $t = ("  " x $jump++);
         if (ref($_) eq "ARRAY") {
            if (tied( *$socket )->_get_self()->{debug}){
               print(" ".$t."  |---[ Subcertificate ]---\n") if $t;
               print(" ".$t."  | Subject Name: ".$_->[0]."\n");
               print(" ".$t."  | Issuer Name : ".$_->[1]."\n");
               print(" ".$t."  | Serial      : ".hexdump($_->[2])."\n");
               print(" ".$t."  | CRL Status  : ".$crlstatus."\n");
            }
         } else {
            print(" NOCERTINFOS!"."\n")
               if (tied( *$socket )->_get_self()->{debug});
            return 0;
         }
      }
      print("----- SSL Infos END -----------------"."\n")
         if (tied( *$socket )->_get_self()->{debug});
      return 1 unless $badcrls;
   }
   return 0;
}

sub Server_SSLify_NonBlock_STARTTLS {
   my $socket = shift;
   my $self = tied( *$socket )->_get_self();
   $self->dobeginSSL();
}

sub hexdump { join ':', map { sprintf "%02X", $_ } unpack "C*", $_[0]; }

__END__

=head1 NAME

POE::Component::SSLify::NonBlock - Nonblocking SSL for POE with client certificate verification.

=head1 SYNOPSIS

=head2 Server-side usage

   # Import the modules
   use POE::Component::SSLify qw( SSLify_Options SSLify_GetCTX );
   use POE::Component::SSLify::NonBlock qw( Server_SSLify_NonBlock );

   # Set the key + certificate file, only one time needed.
   eval { SSLify_Options( 'server.key', 'server.crt' ) };
   if ( $@ ) {
      # Unable to load key or certificate file...
   }

   # Create a normal SocketFactory wheel or something
   my $factory = POE::Wheel::SocketFactory->new( ... );

   # Converts the socket into a SSL socket POE can communicate with, every time on new socket needed.
   eval { $socket = Server_SSLify_NonBlock( SSLify_GetCTX(), $socket, { } ) };
   if ( $@ ) {
      # Unable to SSLify it...
   }

   # Now, hand it off to ReadWrite
   my $rw = POE::Wheel::ReadWrite->new(
      Handle   =>   $socket,
      ...
   );

=head1 ABSTRACT

Nonblocking SSL for POE with client certificate verification.

=head1 DESCRIPTION

This component represents a common way of using ssl on a server, which
needs to ensure that no client can block the whole server. Further
it allows to verificate client certificates.

=head2 Non-Blocking needed, especially on client certificate verification

SSL is a protocol which interacts with the client during the handshake multiple times. If
the socket is blocking, as on pure POE::Component::SSLify, a client can block the whole
server.
Especially if you want to do client certificate verification, the user has the
abilty to choose a client certificate. In this situation the ssl handshake is waiting,
and in blocked mode the whole server also stops responding.

=head2 Client certificate verification

You have three opportunities to do client certificate verification:

  Easiest way: 
    Verify the certificate and let OpenSSL reject the connection during ssl handshake if there is no certificate or it is unstrusted.

  Advanced way:
    Verify the certificate and poe handler determines if there is no certificate or it is unstrusted.

  Complicated way:
    Verify the certificate and poe handler determines if there is no certificate, it is unstrusted or if it is blocked by a CRL.

=head3 Easiest way: Client certificat rejection in ssl handshake

Generally you can use the "Server-side usage" example above, but you have to enable the client certification
feature with the "clientcertrequest" parameter. The Server_SSLify_NonBlock function allows a hash for parameters:

   use POE::Component::SSLify qw( SSLify_Options SSLify_GetCTX );
   use POE::Component::SSLify::NonBlock qw( Server_SSLify_NonBlock SSLify_Options_NonBlock_ClientCert Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL Server_SSLify_NonBlock_ClientCertificateExists Server_SSLify_NonBlock_ClientCertIsValid Server_SSLify_NonBlock_SSLDone );
   use POE qw( Wheel::SocketFactory Driver::SysRW Filter::Stream Wheel::ReadWrite );

   eval { SSLify_Options( 'server.key', 'server.crt' ) };
   die "SSLify_Options: ".$@ if ( $@ );

   eval { SSLify_Options_NonBlock_ClientCert(SSLify_GetCTX(), 'ca.crt') };
   die "SSLify_Options_NonBlock_ClientCert: ".$@ if ( $@ );

   POE::Session->create(
      inline_states => {
         _start => sub {
            my ( $heap, $kernel ) = @_[ HEAP, KERNEL ];
            $heap->{server_wheel} = POE::Wheel::SocketFactory->new(
               BindAddress  => "0.0.0.0",
               BindPort     => 443,
               Reuse        => 'yes',
               SuccessEvent => 'client_accept',
               FailureEvent => 'accept_failure',
            );
         },
         client_accept => sub {
            my ( $heap, $kernel, $socket ) = @_[ HEAP, KERNEL, ARG0 ];
            eval { $socket = Server_SSLify_NonBlock( SSLify_GetCTX(), $socket, {
               clientcertrequest => 1,
               debug => 1
            } ) };
            if ( $@ ) {
               print "SSL Failed: ".$@."\n";
               delete $heap->{server}->{$wheel_id}->{wheel};
            }
            my $io_wheel = POE::Wheel::ReadWrite->new(
               Handle     => $socket,
               Driver     => POE::Driver::SysRW->new,
               Filter     => POE::Filter::Stream->new,
               InputEvent => 'client_input'
            );
            $heap->{server}->{$io_wheel->ID()}->{wheel} = $io_wheel;
            $heap->{server}->{$io_wheel->ID()}->{socket} = $socket;
         },
         client_input => sub {
            my ( $heap, $kernel, $input, $wheel_id ) = @_[ HEAP, KERNEL, ARG0, ARG1 ];
            $heap->{server}->{$wheel_id}->{wheel}->put("[".$wheel_id."] Yeah! You're authenticated!\n") if $canwrite;
            $kernel->yield("disconnect" => $wheel_id);
         },
         disconnect => sub {
            my ($heap, $kernel, $wheel_id) = @_[HEAP, KERNEL, ARG0];
            $kernel->delay(close_delayed => 1, $wheel_id)
               unless ($heap->{server}->{$wheel_id}->{disconnecting}++);
         },
         close_delayed => sub {
            my ($kernel, $heap, $wheel_id) = @_[KERNEL, HEAP, ARG0];
            delete $heap->{server}->{$wheel_id}->{wheel};
            delete $heap->{server}->{$wheel_id}->{socket};
         }
      }
   );
    
   $poe_kernel->run();

Now the server sends the request for a client certificate during SSL handshake. By default,
POE::Component::SSLify::NonBlock aborts the connection if "clientcertrequest" is set and there
is no client certificat or the certificate is not trusted.

=head3 Advanced way: Client certificat reject in POE Handler

   use POE::Component::SSLify qw( SSLify_Options SSLify_GetCTX );
   use POE::Component::SSLify::NonBlock qw( Server_SSLify_NonBlock SSLify_Options_NonBlock_ClientCert Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL Server_SSLify_NonBlock_ClientCertificateExists Server_SSLify_NonBlock_ClientCertIsValid Server_SSLify_NonBlock_SSLDone );
   use POE qw( Wheel::SocketFactory Driver::SysRW Filter::Stream Wheel::ReadWrite );

   eval { SSLify_Options( 'server.key', 'server.crt' ) };
   die "SSLify_Options: ".$@ if ( $@ );

   eval { SSLify_Options_NonBlock_ClientCert(SSLify_GetCTX(), 'ca.crt') };
   die "SSLify_Options_NonBlock_ClientCert: ".$@ if ( $@ );

   POE::Session->create(
      inline_states => {
         _start => sub {
            my ( $heap, $kernel ) = @_[ HEAP, KERNEL ];
            $heap->{server_wheel} = POE::Wheel::SocketFactory->new(
               BindAddress  => "0.0.0.0",
               BindPort     => 443,
               Reuse        => 'yes',
               SuccessEvent => 'client_accept',
               FailureEvent => 'accept_failure',
            );
         },
         client_accept => sub {
            my ( $heap, $kernel, $socket ) = @_[ HEAP, KERNEL, ARG0 ];
            eval { $socket = Server_SSLify_NonBlock( SSLify_GetCTX(), $socket, {
               clientcertrequest => 1,
               noblockbadclientcert => 1,
               debug => 1
            } ) };
            if ( $@ ) {
               print "SSL Failed: ".$@."\n";
               delete $heap->{server}->{$wheel_id}->{wheel};
            }
            my $io_wheel = POE::Wheel::ReadWrite->new(
               Handle     => $socket,
               Driver     => POE::Driver::SysRW->new,
               Filter     => POE::Filter::Stream->new,
               InputEvent => 'client_input'
            );
            $heap->{server}->{$io_wheel->ID()}->{wheel} = $io_wheel;
            $heap->{server}->{$io_wheel->ID()}->{socket} = $socket;
         },
         client_input => sub {
            my ( $heap, $kernel, $input, $wheel_id ) = @_[ HEAP, KERNEL, ARG0, ARG1 ];
            my $canwrite = exists $heap->{server}->{$wheel_id}->{wheel} &&
                             (ref($heap->{server}->{$wheel_id}->{wheel}) eq "POE::Wheel::ReadWrite");
            my $socket = $heap->{server}->{$wheel_id}->{socket};
            return unless Server_SSLify_NonBlock_SSLDone($socket);
            if (!(Server_SSLify_NonBlock_ClientCertificateExists($socket))) {
               $heap->{server}->{$wheel_id}->{wheel}->put("[".$wheel_id."] NoClientCertExists\n") if $canwrite;
               return $kernel->yield("disconnect" => $wheel_id);
            } elsif(!(Server_SSLify_NonBlock_ClientCertIsValid($socket))) {
              $heap->{server}->{$wheel_id}->{wheel}->put("[".$wheel_id."] ClientCertInvalid\n") if $canwrite;
               return $kernel->yield("disconnect" => $wheel_id);
            }
            $heap->{server}->{$wheel_id}->{wheel}->put("[".$wheel_id."] Yeah! You're authenticated!\n") if $canwrite;
            $kernel->yield("disconnect" => $wheel_id);
         },
         disconnect => sub {
            my ($heap, $kernel, $wheel_id) = @_[HEAP, KERNEL, ARG0];
            $kernel->delay(close_delayed => 1, $wheel_id)
               unless ($heap->{server}->{$wheel_id}->{disconnecting}++);
         },
         close_delayed => sub {
            my ($kernel, $heap, $wheel_id) = @_[KERNEL, HEAP, ARG0];
            delete $heap->{server}->{$wheel_id}->{wheel};
            delete $heap->{server}->{$wheel_id}->{socket};
         }
      }
   );
    
   $poe_kernel->run();

=head3 Complicated way: Client certificate reject in POE Handler with CRL support

WARNING: To use this you have to patch the lines from net-ssleay-patch fike into Net::SSLeay
(you find the patch in the base path of the tar.gz packet). Then recompile and reinstall the Net::SSLeay package.

   use POE::Component::SSLify qw( SSLify_Options SSLify_GetCTX );
   use POE::Component::SSLify::NonBlock qw( Server_SSLify_NonBlock SSLify_Options_NonBlock_ClientCert Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL Server_SSLify_NonBlock_ClientCertificateExists Server_SSLify_NonBlock_ClientCertIsValid Server_SSLify_NonBlock_SSLDone );
   use POE qw( Wheel::SocketFactory Driver::SysRW Filter::Stream Wheel::ReadWrite );

   eval { SSLify_Options( 'server.key', 'server.crt' ) };
   die "SSLify_Options: ".$@ if ( $@ );

   eval { SSLify_Options_NonBlock_ClientCert(SSLify_GetCTX(), 'ca.crt') };
   die "SSLify_Options_NonBlock_ClientCert: ".$@ if ( $@ );

   POE::Session->create(
      inline_states => {
         _start => sub {
            my ( $heap, $kernel ) = @_[ HEAP, KERNEL ];
            $heap->{server_wheel} = POE::Wheel::SocketFactory->new(
               BindAddress  => "0.0.0.0",
               BindPort     => 443,
               Reuse        => 'yes',
               SuccessEvent => 'client_accept',
               FailureEvent => 'accept_failure',
            );
         },
         client_accept => sub {
            my ( $heap, $kernel, $socket ) = @_[ HEAP, KERNEL, ARG0 ];
            eval { $socket = Server_SSLify_NonBlock( SSLify_GetCTX(), $socket, {
               clientcertrequest => 1,
               noblockbadclientcert => 1,
               getserial => 1,
               debug => 1
            } ) };
            if ( $@ ) {
               print "SSL Failed: ".$@."\n";
               delete $heap->{server}->{$wheel_id}->{wheel};
            }
            my $io_wheel = POE::Wheel::ReadWrite->new(
               Handle     => $socket,
               Driver     => POE::Driver::SysRW->new,
               Filter     => POE::Filter::Stream->new,
               InputEvent => 'client_input'
            );
            $heap->{server}->{$io_wheel->ID()}->{wheel} = $io_wheel;
            $heap->{server}->{$io_wheel->ID()}->{socket} = $socket;
         },
         client_input => sub {
            my ( $heap, $kernel, $input, $wheel_id ) = @_[ HEAP, KERNEL, ARG0, ARG1 ];
            my $canwrite = exists $heap->{server}->{$wheel_id}->{wheel} &&
                             (ref($heap->{server}->{$wheel_id}->{wheel}) eq "POE::Wheel::ReadWrite");
            my $socket = $heap->{server}->{$wheel_id}->{socket};
            return unless Server_SSLify_NonBlock_SSLDone($socket);
            if (!(Server_SSLify_NonBlock_ClientCertificateExists($socket))) {
               $heap->{server}->{$wheel_id}->{wheel}->put("[".$wheel_id."] NoClientCertExists\n") if $canwrite;
               return $kernel->yield("disconnect" => $wheel_id);
            } elsif(!(Server_SSLify_NonBlock_ClientCertIsValid($socket))) {
              $heap->{server}->{$wheel_id}->{wheel}->put("[".$wheel_id."] ClientCertInvalid\n") if $canwrite;
               return $kernel->yield("disconnect" => $wheel_id);
            } elsif(!(Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL($socket, 'ca.crl'))) {
               $heap->{server}->{$wheel_id}->{wheel}->put("[".$wheel_id."] CRL\n") if $canwrite;
               return $kernel->yield("disconnect" => $wheel_id);
            }
            $heap->{server}->{$wheel_id}->{wheel}->put("[".$wheel_id."] Yeah! You're authenticated!\n") if $canwrite;
            $kernel->yield("disconnect" => $wheel_id);
         },
         disconnect => sub {
            my ($heap, $kernel, $wheel_id) = @_[HEAP, KERNEL, ARG0];
            $kernel->delay(close_delayed => 1, $wheel_id)
               unless ($heap->{server}->{$wheel_id}->{disconnecting}++);
         },
         close_delayed => sub {
            my ($kernel, $heap, $wheel_id) = @_[KERNEL, HEAP, ARG0];
            delete $heap->{server}->{$wheel_id}->{wheel};
            delete $heap->{server}->{$wheel_id}->{socket};
         }
      }
   );
    
   $poe_kernel->run();

=head2 STARRTTLS

Starting version 0.40, you can do SSL after plain text. This is often called "STARTTLS",
"AUTH TLS" or "AUTH SSL". Here an FTP example:

   use POE::Component::SSLify qw( SSLify_Options SSLify_GetCTX );
   use POE::Component::SSLify::NonBlock qw( Server_SSLify_NonBlock SSLify_Options_NonBlock_ClientCert Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL Server_SSLify_NonBlock_ClientCertificateExists Server_SSLify_NonBlock_ClientCertIsValid Server_SSLify_NonBlock_SSLDone Server_SSLify_NonBlock_STARTTLS);
   use POE qw( Wheel::SocketFactory Driver::SysRW Filter::Stream Wheel::ReadWrite );

   eval { SSLify_Options( 'server.key', 'server.crt' ) };
   die "SSLify_Options: ".$@ if ( $@ );

   eval { SSLify_Options_NonBlock_ClientCert(SSLify_GetCTX(), 'ca.crt' ) };
   die "SSLify_Options_NonBlock_ClientCert: ".$@ if ( $@ );

   POE::Session->create(
      inline_states => {
         _start => sub {
            my ( $heap, $kernel ) = @_[ HEAP, KERNEL ];
            $heap->{server_wheel} = POE::Wheel::SocketFactory->new(
               BindAddress  => "0.0.0.0",
               BindPort     => 443,
               Reuse        => 'yes',
               SuccessEvent => 'client_accept',
               FailureEvent => 'accept_failure',
            );
         },
         client_accept => sub {
            my ( $heap, $kernel, $socket ) = @_[ HEAP, KERNEL, ARG0 ];
            eval { $socket = Server_SSLify_NonBlock( SSLify_GetCTX(), $socket, {
               debug => 1,
               starttls => 1
            } ) };
            if ( $@ ) {
               print "SSL Failed: ".$@."\n";
               delete $heap->{server}->{$wheel_id}->{wheel};
            }
            my $io_wheel = POE::Wheel::ReadWrite->new(
               Handle     => $socket,
               Driver     => POE::Driver::SysRW->new,
               Filter     => POE::Filter::Stream->new,
               InputEvent => 'client_input'
            );
            $heap->{server}->{$io_wheel->ID()}->{wheel} = $io_wheel;
            $heap->{server}->{$io_wheel->ID()}->{socket} = $socket;
            $io_wheel->put("220 ProFTPD\r\n");
         },
         client_input => sub {
            my ( $heap, $kernel, $input, $wheel_id ) = @_[ HEAP, KERNEL, ARG0, ARG1 ];
            my $canwrite = exists $heap->{server}->{$wheel_id}->{wheel} &&
                             (ref($heap->{server}->{$wheel_id}->{wheel}) eq "POE::Wheel::ReadWrite");
            my $socket = $heap->{server}->{$wheel_id}->{socket};
            if (($input =~ /TLS/i) ||
                ($input =~ /SSL/i)) {
               $heap->{server}->{$wheel_id}->{wheel}->put("220 starttls\r\n");
               $heap->{server}->{$wheel_id}->{wheel}->flush();
               Server_SSLify_NonBlock_STARTTLS($socket);
            }
            return unless Server_SSLify_NonBlock_SSLDone($socket);
            $heap->{server}->{$wheel_id}->{wheel}->put("220 Yeah! You're authenticated!\n") if ($canwrite && (!$heap->{server}->{$wheel_id}->{disconnecting}));
            $kernel->yield("disconnect" => $wheel_id);
         },
         disconnect => sub {
            my ($heap, $kernel, $wheel_id) = @_[HEAP, KERNEL, ARG0];
            $kernel->delay(close_delayed => 1, $wheel_id)
               unless ($heap->{server}->{$wheel_id}->{disconnecting}++);
         },
         close_delayed => sub {
            my ($kernel, $heap, $wheel_id) = @_[KERNEL, HEAP, ARG0];
            delete $heap->{server}->{$wheel_id}->{wheel};
            delete $heap->{server}->{$wheel_id}->{socket};
         }
      }
   );
    
   $poe_kernel->run();

=head1 FUNCTIONS

=head2 SSLify_Options_NonBlock_ClientCert($ctx, $cacrt)

Configures ssl ctx(context) to request from the client a
certificate for authentication, which is verificated against
the configured CA in the file $cacrt.

   SSLify_Options_NonBlock_ClientCert(SSLify_GetCTX(), 'ca.crt');

Note:

   SSLify_Options from POE::Component::SSLify must be called first!

=head2 Server_SSLify_NonBlock($ctx, $socket, %$options)

Similar to Server_SSLify from POE::Component::SSLify. It needs further the CTX of POE::Component::SSLify and a hash for special options:

   my $socket = shift;   # get the socket from somewhere
   $socket = Server_SSLify_NonBlock(SSLify_GetCTX(), $socket, { option1 => 1, option1 => 2,... });

Options are:

   clientcertrequest
      The client gets requested for a client certificat during 
      ssl handshake

   noblockbadclientcert
      If the client does not provide a client certificate or the
      client certificate is untrusted, the connection will not
      be aborted. You can check for the errors via the functions
      Server_SSLify_NonBlock_ClientCertificateExists and
      Server_SSLify_NonBlock_ClientCertIsValid.

   debug
      Get debug messages during ssl handshake. Especially usefull
      for Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL.

   getserial
      Request the serial of the client certificate during
      ssl handshake.
      
      WARNING: You have to patch Net::SSLeay to provide the
               Net::SSLeay::X509_get_serialNumber function
               before you can set the getserial option! See the
               file net-ssleay-patch in the base path of the
               tar.gz of the packet.

   starttls
      Don't actually do SSL but later. It is initiated if you
      call Server_SSLify_NonBlock_STARTTLS.

Note:

   SSLify_Options from POE::Component::SSLify must be set first!

=head2 Server_SSLify_NonBlock_SSLDone

Checks if the SSL handshake has been completed.

   Server_SSLify_NonBlock_SSLDone($socket);

=head2 Server_SSLify_NonBlock_ClientCertificateExists($socket)

Verify if the client commited a valid client certificate.

  Server_SSLify_NonBlock_ClientCertificateExists($socket);

=head2 Server_SSLify_NonBlock_ClientCertIsValid($socket)

Verify if the client certificate is trusted by a loaded CA (see SSLify_Options_NonBlock_ClientCert).

  Server_SSLify_NonBlock_ClientCertIsValid($socket);

=head2 Server_SSLify_NonBlock_STARTTLS($socket)

Initiates SSL after plain text conversation. You have to use the
starttls option in Server_SSLify_NonBlock.

  Server_SSLify_NonBlock_STARTTLS($socket)

See STARTTLS example above.

=head2 Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL($socket, $crlfile)

Opens a CRL file, and verify if the serial of the client certificate
is not contained in the CRL file. No file caching is done, each call opens
the file again.

Note: If your CRL file is missing, can not be opened is empty, or has no blocked
      certificate at all, every call will get blocked.

  Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL($socket, 'ca.crl');
  
   WARNING: You have to patch Net::SSLeay to provide the
            Net::SSLeay::verify_serial_against_crl_file function
            before you can set the getserial option! See the
            file net-ssleay-patch in the base path of the tar.gz
            of the packet.

=head2 Server_SSLify_NonBlock_GetClientCertificateIDs($socket)

Fetches the IDs as array of the clients certifcate and its
signees.

Retruns empty list if you did not patch Net::SSLeay.

=head2 hexdump($string)

Returns string data in hex format.

For example:

  perl -e 'use POE::Component::SSLify::NonBlock; print POE::Component::SSLify::NonBlock::hexdump("test")."\n";'
  74:65:73:74

=head2 Futher functions...

You can use all functions from POE::Component::SSLify !

=head1 NOTES

=head2 Based on POE::Component::SSLify

This module is based on POE::Component::SSLify, so POE::Component::SSLify::NonBlock has the same issues.

=head1 EXPORT

Puts all of the above functions in @EXPORT_OK so you have to request them directly

=head1 BUGS

=head2 Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL: certificate serials

Server_SSLify_NonBlock_ClientCertVerifyAgainstCRL also verifies against the serial 
of the CA! Make sure that you never use the serial of the CA for client certificates!

=head2 Win32

I did not test POE::Component::SSLify::NonBlock on Win32 platforms at all!

=head1 SEE ALSO

L<POE::Component::SSLify>

L<Net::SSLeay>

=head1 AUTHOR

pRiVi E<lt>pRiVi@cpan.orgE<gt>

=head1 PROPS

This code is based on Apocalypse module POE::Component::SSLify, improved by client certification code and non-blocking sockets.

Copyright 2010 by Markus Mueller/Apocalypse/Rocco Caputo/Dariusz Jackowski.

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Markus Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
