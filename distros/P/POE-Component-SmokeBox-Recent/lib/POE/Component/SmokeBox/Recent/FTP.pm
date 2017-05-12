package POE::Component::SmokeBox::Recent::FTP;
$POE::Component::SmokeBox::Recent::FTP::VERSION = '1.50';
#ABSTRACT: an extremely minimal FTP client

use strict;
use warnings;
use POE qw(Filter::Line Component::Client::DNS);
use Net::IP::Minimal qw(ip_get_version);
use Test::POE::Client::TCP;
use Carp qw(carp croak);

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak( "You must provide the 'address' parameter\n" ) unless $opts{address};
  croak( "You must provide the 'path' parameter\n" ) unless $opts{path};
  my $options = delete $opts{options};
  $opts{prefix} = 'ftp_' unless $opts{prefix};
  $opts{prefix} .= '_' unless $opts{prefix} =~ /\_$/;
  $opts{username} = 'anonymous' unless $opts{username};
  $opts{password} = 'anon@anon.org' unless $opts{password};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
    object_states => [
	$self => { map { ($_,"_$_" ) } qw(cmdc_socket_failed cmdc_input cmdc_disconnected datac_connected datac_disconnected datac_input) },
	$self => [qw(
		_start
		_retr_done
		_resolve
		_response
		_connect
	)],
     ],
     heap => $self,
     ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub _start {
  my ($kernel,$sender,$self) = @_[KERNEL,SENDER,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  $self->{cmds} = [
     [ '220', 'USER ' . $self->{username} ],
     [ '331', 'PASS ' . $self->{password} ],
#     [ '230', 'SIZE ' . $self->{path} ],
#     [ '213', 'PASV' ],
     [ '230', 'PASV' ],
  ];
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

  $self->{_resolver} = POE::Component::Client::DNS->spawn(
	Alias => 'Resolver-' . $self->{session_id},
  );

  $kernel->yield( '_resolve' );
  return;
}

sub _resolve {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  if ( ip_get_version( $self->{address} ) ) {
     # It is an address already
     $kernel->yield( '_connect', $self->{address} );
     return;
  }
  my $resp = $self->{_resolver}->resolve(
     host 	=> $self->{address},
     context 	=> { },
     event	=> '_response',
  );
  $kernel->yield( '_response', $resp ) if $resp;
  return;
}

sub _response {
  my ($kernel,$self,$resp) = @_[KERNEL,OBJECT,ARG0];
  if ( $resp->{error} and $resp->{error} ne 'NOERROR' ) {
     $kernel->yield( 'cmdc_socket_failed', $resp->{error} );
     return;
  }
  my @answers = $resp->{response}->answer;
  foreach my $answer ( $resp->{response}->answer() ) {
     next if $answer->type !~ /^A/;
     $kernel->yield( '_connect', $answer->rdatastr );
     return;
  }
  $kernel->yield( 'cmdc_socket_failed', 'Could not resolve address' );
  return;
}

sub _connect {
  my ($self,$address) = @_[OBJECT,ARG0];
  $self->{cmdc} = Test::POE::Client::TCP->spawn(
	address     => $address,
	port        => $self->{port} || 21,
	prefix      => 'cmdc',
	autoconnect => 1,
	filter	    => POE::Filter::Line->new( Literal => "\x0D\x0A" ),
  );
  return;
}

sub _cmdc_socket_failed {
  my ($kernel,$self,@errors) = @_[KERNEL,OBJECT,ARG0..$#_];
  $self->_send_event( $self->{prefix} . 'sockerr', @errors );
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $self->{cmdc}->shutdown() if $self->{cmdc};
  $self->{_resolver}->shutdown();
  delete $self->{cmdc};
  delete $self->{_resolver};
  return;
}

sub _cmdc_input {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  warn $input, "\n" if $self->{debug};
  my ($numeric) = $input =~ /^(\d+)\s+/;
  return unless $numeric;
  my $cmd = shift @{ $self->{cmds} };
  if ( $cmd and $numeric eq $cmd->[0] ) {
     warn ">>>>$cmd->[1]\n" if $self->{debug};
     $self->{cmdc}->send_to_server( $cmd->[1] );
     return;
  }
  if ( $numeric eq '227' ) {
     my (@ip, @port);
     (@ip[0..3], @port[0..1]) = $input =~ /(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)/;
     my $ip = join '.', @ip;
     my $port = $port[0]*256 + $port[1];
     $self->{datac} = Test::POE::Client::TCP->spawn(
	address => $ip,
	port    => $port,
	autoconnect => 1,
	prefix  => 'datac',
     );
     return;
  }
  if ( $numeric =~ /^5/ ) {
     # Something went wrong
     $self->{cmdc}->send_to_server( 'QUIT' );
     $self->_send_event( $self->{prefix} . 'error', $input );
     $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
     return;
  }
  if ( $numeric eq '150' ) {
     # Transfer in progress
     $self->{transfer} = 2;
  }
  if ( $numeric eq '226' ) {
     $kernel->yield( '_retr_done' );
  }
  if ( $numeric eq '221' ) {
    $self->{cmdc}->shutdown();
    delete $self->{cmdc};
  }
  return;
}

sub _cmdc_disconnected {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{cmdc}->shutdown();
  delete $self->{cmdc};
  return;
}

sub _datac_connected {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{cmdc}->send_to_server( 'RETR ' . $self->{path} );
  return;
}

sub _datac_disconnected {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  if ( $self->{transfer} ) {
     $kernel->yield( '_retr_done' );
  }
  $self->{datac}->shutdown();
  delete $self->{datac};
  return;
}

sub _datac_input {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  warn $input, "\n" if $self->{debug};
  $self->_send_event( $self->{prefix} . 'data', $input );
  return;
}

sub _retr_done {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{transfer}--;
  unless ( $self->{transfer} ) {
     $self->_send_event( $self->{prefix} . 'done' );
     $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
     warn "Transfer complete\n" if $self->{debug};
     $self->{cmdc}->send_to_server( 'QUIT' );
     return;
  }
  return;
}

sub _send_event {
  my $self = shift;
  $poe_kernel->post( $self->{sender_id}, @_ );
  return;
}

'Get me that file, sucker'

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Recent::FTP - an extremely minimal FTP client

=head1 VERSION

version 1.50

=head1 SYNOPSIS

  # Obtain the RECENT file from a given CPAN mirror.
  use strict;
  use warnings;
  use File::Spec;
  use POE qw(Component::SmokeBox::Recent::FTP);

  my $site = shift || die "You must provide a site parameter\n";
  my $path = shift || '/';

  POE::Session->create(
     package_states => [
  	main => [qw(_start ftp_sockerr ftp_error ftp_data ftp_done)],
     ]
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Recent::FTP->spawn(
  	address => $site,
  	path    => File::Spec::Unix->catfile( $path, 'RECENT' )
    );
    return;
  }

  sub ftp_sockerr {
    warn join ' ', @_[ARG0..$#_];
    return;
  }

  sub ftp_error {
    warn "Error: '" . $_[ARG0] . "'\n";
    return;
  }

  sub ftp_data {
    print $_[ARG0], "\n";
    return;
  }

  sub ftp_done {
    warn "Transfer complete\n";
    return;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox::Recent::FTP is the small helper module used by L<POE::Component::SmokeBox::Recent> to
do FTP client duties.

It only implements an ascii type passive FTP C<RETR>.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of parameters:

  'address', the hostname/address of the FTP site to connect to, mandatory;
  'path', the path to the file you want to retrieve from the site, mandatory;
  'session', optional if the poco is spawned from within another session;
  'prefix', specify an event prefix other than the default of 'ftp';

=back

=head1 OUTPUT EVENTS

The component sends the following events. If you have changed the C<prefixi> option in C<spawn> then substitute C<ftp>
with the event prefix that you specified.

=over

=item C<ftp_sockerr>

Generated if there is a problem connecting to the given FTP host/address. C<ARG0> contains the name of the operation that failed. C<ARG1> and C<ARG2> hold numeric and string values for C<$!>, respectively.

=item C<ftp_error>

Generated if there is an FTP error. C<ARG0> contains the error sent by the server.

=item C<ftp_data>

One of these events will be emitted for each line of file you have specified to be retrieved. C<ARG0> contains that line.

=item C<ftp_done>

Emitted when the transfer has finished.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
