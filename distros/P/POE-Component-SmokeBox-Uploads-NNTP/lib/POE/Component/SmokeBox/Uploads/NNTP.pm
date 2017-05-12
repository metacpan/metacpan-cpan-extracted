package POE::Component::SmokeBox::Uploads::NNTP;
$POE::Component::SmokeBox::Uploads::NNTP::VERSION = '1.02';
#ABSTRACT: Obtain uploaded CPAN modules via NNTP.

use strict;
use warnings;
use Carp;
use POE qw(Component::Client::NNTP);
use Email::Simple;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak "$package requires an 'event' argument\n" unless $opts{event};
  $opts{nntp} = 'nntp.perl.org' unless $opts{nntp};
  $opts{group} = 'perl.cpan.uploads' unless $opts{group};
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
        object_states => [
	   $self => { shutdown        => '_shutdown',
		      connect         => '_connect',
		      poll	      => '_poll',
		      nntp_registered => '_nntp_registered',
		      nntp_socketerr  => '_nntp_socketerr',
		      nntp_disconnected => '_nntp_disconnected',
		      nntp_200	      => '_nntp_200',
		      nntp_211	      => '_nntp_211',
		      nntp_220	      => '_nntp_220',
	   },
           $self => [ qw(_start _dispatch) ],
        ],
        heap => $self,
        ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ ) unless $self->{alias};
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $kernel->post( $self->{nntpclient}->session_id(), 'shutdown' );
  return;
}

sub _start {
  my ($kernel,$session,$sender,$self) = @_[KERNEL,SESSION,SENDER,OBJECT];
  $self->{session_id} = $session->ID();
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
  $self->{nntpclient} = POE::Component::Client::NNTP->spawn( 'nntp' . $self->{session_id},
	{ NNTPServer => $self->{nntp}, Port => $self->{nntp_port} } );
  return;
}

sub _nntp_registered {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $kernel->yield( 'connect', $sender->ID() );
  return;
}

sub _connect {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,ARG0];
  $kernel->post( $sender, 'connect' );
  return;
}

sub _nntp_socketerr {
  my ($kernel,$self,$sender,$error) = @_[KERNEL,OBJECT,SENDER,ARG0];
  warn "Socket error: $error\n";
  $kernel->delay( 'connect', 60, $sender->ID() );
  return;
}

sub _nntp_disconnected {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $kernel->delay( 'connect', 60, $sender->ID() );
  return;
}

sub _poll {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->post ( $self->{nntpclient}->session_id(), 'group', $self->{group} );
  undef;
}

sub _nntp_200 {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->yield( 'poll' );
  undef;
}

sub _nntp_211 {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  my ($estimate,$first,$last,$group) = split( /\s+/, $_[ARG0] );

  if ( defined $self->{articles}->{ $group } ) {
        # Check for new articles
        if ( $estimate >= $self->{articles}->{ $group } ) {
           for my $article ( $self->{articles}->{ $group } .. $estimate ) {
                $kernel->post ( $sender => article => $article );
           }
           $self->{articles}->{ $group } = $estimate + 1;
        }
  }
  else {
        $self->{articles}->{ $group } = $estimate + 1;
  }
  $kernel->delay( 'poll' => ( $self->{poll} || 60 ) );
  undef;
}

sub _nntp_220 {
  my ($kernel,$self,$text) = @_[KERNEL,OBJECT,ARG0];
  my $article = Email::Simple->new( join "\n", @{ $_[ARG1] } );
  my $subject = $article->header('Subject');
  if ( my ($upload) = $subject =~ m!^CPAN Upload:\s+(\w+/\w+/\w+/.+(\.tar\.(gz|bz2)|\.tgz|\.zip))$!i ) {
	$kernel->call( $self->{session_id}, '_dispatch', $upload );
  }
  return;
}

sub _dispatch {
  my ($kernel,$self,$module) = @_[KERNEL,OBJECT,ARG0];
  $kernel->post( $self->{sender_id}, $self->{event}, $module );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Uploads::NNTP - Obtain uploaded CPAN modules via NNTP.

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use strict;
  use POE qw(Component::SmokeBox::Uploads::NNTP);

  $|=1;

  POE::Session->create(
        package_states => [
          'main' => [qw(_start upload)],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Uploads::NNTP->spawn(
        event => 'upload',
    );
    return;
  }

  sub upload {
    print $_[ARG0], "\n";
    return;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox::Uploads::NNTP is a L<POE> component that alerts newly uploaded CPAN
distributions. It obtains this information from polling an NNTP server ( by default the C<perl.cpan.uploads> group on C<nntp.perl.org> ).

L<POE::Component::Client::NNTP> is used to handle the interaction with the NNTP server.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of parameters:

  'event', the event handler in your session where each new upload alert should be sent, mandatory;
  'session', optional if the poco is spawned from within another session;

The 'session' parameter is only required if you wish the output event to go to a different
session than the calling session, or if you have spawned the poco outside of a session.

Returns an object.

=back

=head1 METHODS

=over

=item C<session_id>

Returns the POE::Session ID of the component.

=item C<shutdown>

Terminates the component.

=back

=head1 INPUT EVENTS

=over

=item C<shutdown>

Terminates the component.

=back

=head1 OUTPUT EVENTS

An event will be triggered for each new CPAN upload. The event will have ARG0 set to the path of the
upload:

  B/BI/BINGOS/POE-Component-SmokeBox-Uploads-NNTP-0.01.tar.gz

Suitable for feeding to the smoke tester of your choice.

=head1 SEE ALSO

L<POE>

L<POE::Component::Client::NNTP>

L<http://www.nntp.perl.org/>

L<http://log.perl.org/2008/02/goodbye-cpan-te.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
