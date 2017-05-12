# Declare our package
package POE::Component::SSLify::NonBlock::ServerHandle;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = (qw$LastChangedRevision: 10 $)[1];

# Import the SSL death routines
use Net::SSLeay qw( die_now die_if_ssl_error );

our $globalinfos;
our $getserial = 0;

# Ties the socket
sub TIEHANDLE {
	my ( $class, $socket, $ctx, $params ) = @_;	

	my $self = bless {
		'ctx'		     => $ctx,
		'socket'	     => $socket,
		'fileno'	     => fileno( $socket ),
      'acceptstate' => 0,
      'crypting'    => 0,
      'debug'       => $params->{debug},
      'params'      => $params
	}, $class;

   unless ($params->{starttls}) {
      $self->dobeginSSL();
      return undef unless $self->HANDLESSL();
   }
	return $self;
}

sub dobeginSSL {
   my $self = shift;
   return if ($self->{crypting}++);

   $self->{ssl} = Net::SSLeay::new( $self->{ctx} ) or die_now( "Failed to create SSL $!" );
	Net::SSLeay::set_fd( $self->{ssl}, $self->{fileno} );

   if ($self->{params}->{clientcertrequest}) {
      my $orfilter = &Net::SSLeay::VERIFY_PEER
                   | &Net::SSLeay::VERIFY_CLIENT_ONCE;
      $orfilter |=  &Net::SSLeay::VERIFY_FAIL_IF_NO_PEER_CERT unless $self->{params}->{noblockbadclientcert};
      Net::SSLeay::set_verify ($self->{ssl}, $orfilter, \&VERIFY);
   }

   # BAD!
	#my $err = Net::SSLeay::accept( $ssl ) and die_if_ssl_error( 'ssl accept' );

   $globalinfos = [0, 0, []];
}

# Verifys client certificates
sub VERIFY {
   my ($ok, $x509_store_ctx) = @_;
   #print "VERIFY!\n";
   $globalinfos->[0] = $ok ? 1 : 2 if ($globalinfos->[0] != 2);
   $globalinfos->[1]++;
   if (my $x = Net::SSLeay::X509_STORE_CTX_get_current_cert($x509_store_ctx)) {
      push(@{$globalinfos->[2]},[Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($x)),
                                 Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($x)),
                                 ($getserial ? Net::SSLeay::X509_get_serialNumber($x) : undef)]);
   }
   return 1; # $ok; # 1=accept cert, 0=reject
}

# Process input for OpenSSL
sub HANDLESSL {
   my $self = shift;
   my $rv = Net::SSLeay::accept($self->{ssl});
   $self->{acceptstate} = 0;
   $rv == 0 ? $self->{acceptstate} = 0 : $rv > 0 ? $self->{acceptstate} = 3 : 1;
   if ($self->{acceptstate}) { 
      print "HANDLEACCEPT:SERVER:A:".$self->{acceptstate}.":\n"
         if ($self->{debug});
      if ($self->{acceptstate} > 2) {
         $self->{infos} = [((@$globalinfos)[0..2])];
         $globalinfos = [0, 0, []];
      }
      return $self->{acceptstate};
   }
   my $err = Net::SSLeay::get_error($self->{ssl},$rv);
   $self->{acceptstate} = $err == Net::SSLeay::ERROR_WANT_READ()  ? 1 : 
                          $err == Net::SSLeay::ERROR_WANT_WRITE() ? 2 : 3;
   print "HANDLEACCEPT:SERVER:B:".$self->{acceptstate}.":\n"
      if ($self->{debug});
   return $self->{acceptstate};
}

# Read something from the socket
sub READ {
	# Get ourself!
	my $self = shift;
   my( $buf, $len, $offset ) = \( @_ );

   if ($self->{crypting}) {
      # Get the pointers to buffer, length, and the offset

      return -1 unless exists($self->{'acceptstate'});

      if ($self->{'acceptstate'} < 3) {
         $self->{'acceptstate'} = $self->HANDLESSL();
         if ($self->{'acceptstate'} < 3) {
            return -1 unless $self->{'acceptstate'};
            # Currently we can't read cause we're in handshake!
            print "Currently we can't read cause we're in handshake!\n"
               if ($self->{debug});
            $$buf = "";
            return -2;
         }
      }

      # If we have no offset, replace the buffer with some input
      if ( ! defined $$offset ) {
         $$buf = Net::SSLeay::read( $self->{'ssl'}, $$len );

         # Are we done?
         if ( defined $$buf ) {
            return length( $$buf );
         } else {
            # Nah, clear the buffer too...
            $$buf = "";
            return;
         }
      }

      # Now, actually read the data
      defined( my $read = Net::SSLeay::read( $self->{'ssl'}, $$len ) ) or return undef;

      # Figure out the buffer and offset
      my $buf_len = length( $$buf );

      # If our offset is bigger, pad the buffer
      if ( $$offset > $buf_len ) {
         $$buf .= chr( 0 ) x ( $$offset - $buf_len );
      }

      # Insert what we just read into the buffer
      substr( $$buf, $$offset ) = $read;

      # All done!
      return length( $read );
   } else {
      return sysread( $self->{'socket'}, $$buf, 
         (defined($len)    ? $$len    : undef),
         (defined($offset) ? $$offset : undef) );
   }
}

# Write some stuff to the socket
sub WRITE {
	# Get ourself + buffer + length + offset to write
	my( $self, $buf, $len, $offset ) = @_;

   if ($self->{crypting}) {
      # If we have nothing to offset, then start from the beginning
      if ( ! defined $offset ) {
         $offset = 0;
      }

      return -1 unless exists($self->{'acceptstate'});

      if ($self->{'acceptstate'} < 3) {
         $self->{'acceptstate'} = $self->HANDLESSL();
         if ($self->{'acceptstate'} < 3) {
            return -1 unless $self->{'acceptstate'};
            # Currently we can't read cause we're in handshake!
            print "Currently we can't read cause we're in handshake!\n"
               if ($self->{debug});
            return -2;
         }
      }

      # We count the number of characters written to the socket
      my $wrote_len = Net::SSLeay::write( $self->{'ssl'}, substr( $buf, $offset, $len ) );

      # Did we get an error or number of bytes written?
      # Net::SSLeay::write() returns the number of bytes written, or -1 on error.
      #if ( $wrote_len < 0 ) {
         # The normal syswrite() POE uses expects 0 here.
      #   return 0;
      #} else {
         # All done!
         return $wrote_len;
      #}
   } else {
      return syswrite( $self->{'socket'}, $buf, $len, $offset );
   }
}

# Sets binmode on the socket
# Thanks to RT #27117
sub BINMODE {
	my $self = shift;
	if (@_) {
		my $mode = shift;
		binmode $self->{'socket'}, $mode;
	} else {
		binmode $self->{'socket'};
	}
}

# Closes the socket
sub CLOSE {
	my $self = shift;
	if ( defined $self->{'socket'} ) {
		Net::SSLeay::free( $self->{'ssl'} );
		close( $self->{'socket'} );
		undef $self->{'socket'};

		# do we need to do CTX_free?
		if ( exists $self->{'client'} ) {
			Net::SSLeay::CTX_free( $self->{'ctx'} );
		}
	}

	return 1;
}

# Add DESTROY handler
sub DESTROY {
	my $self = shift;

	# Did we already CLOSE?
	if ( defined $self->{'socket'} ) {
		# Guess not...
		$self->CLOSE();
	}
}

sub FILENO {
	my $self = shift;
	return $self->{'fileno'};
}

# Not implemented TIE's
sub READLINE {
	die 'Not Implemented';
}

sub PRINT {
	die 'Not Implemented';
}

# Returns our hash
sub _get_self {
   my $self = shift;
   return $self;
}

# End of module
1;

__END__

=head1 NAME

POE::Component::SSLify::NonBlock::ServerHandle - server object for POE::Component::SSLify::NonBlock

=head1 ABSTRACT

	See POE::Component::SSLify::NonBlock

=head1 DESCRIPTION

	This is a tied socket for non-blocking ssl access.

=head1 FUNCTIONS

=head2 HANDLESSL

Processes input for OpenSSL.

=head2 VERIFY

Verifys client certificates.

=head2 dobeginSSL

Postprocesses a new SSL handling.

=head1 SEE ALSO

L<POE::Component::SSLify::NonBlock>

=head1 AUTHOR

pRiVi E<lt>pRiVi@cpan.orgE<gt>

=head1 PROPS, COPYRIGHT AND LICENSE

This code is based on Apocalypse module POE::Component::SSLify, improved by client certification code and non-blocking sockets.

Copyright 2010 by Markus Mueller/Apocalypse/Rocco Caputo/Dariusz Jackowski.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
