package POE::Component::MetaCPAN::Recent;
$POE::Component::MetaCPAN::Recent::VERSION = '1.04';
#ABSTRACT: Obtain uploaded CPAN dists via MetaCPAN.

use strict;
use warnings;
use Carp;
use POE qw[Component::SmokeBox::Recent::HTTP];
use URI;
use HTTP::Request;
use HTTP::Response;
use JSON::PP;
use Time::Piece;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak "$package requires an 'event' argument\n" unless $opts{event};
  $opts{delay} = 180 unless $opts{delay};
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
    object_states => [
      $self => {
        shutdown      => '_shutdown',
        http_sockerr  => '_get_connect_error',
        http_timeout  => '_get_connect_error',
        http_response => '_handle_recent',
      },
      $self => [ qw(_start _get_recent _real_shutdown) ],
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
  $self->{_shutdown} = 1;
  return if $self->{_http_requests};
  $kernel->yield( '_real_shutdown' );
  return;
}

sub _real_shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
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
  $self->{timestamp} = 0;
  # Start requesting
  $kernel->yield('_get_recent');
  return;
}

sub _get_recent {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->delay('_get_recent');
  if ( $self->{shutdown} ) {
    $kernel->yield('_real_shutdown');
    return;
  }
  POE::Component::SmokeBox::Recent::HTTP->spawn(
     uri => URI->new( 'http://fastapi.metacpan.org/release/recent?type=l&page=1&page_size=100' ),
  );
  $self->{_http_requests}++;
  return;
}

sub _handle_recent {
  my ($kernel,$self,$http_resp) = @_[KERNEL,OBJECT,ARG0];
  $self->{_http_requests}--;
  if ( $http_resp and $http_resp->code() == 200 ) {
    my $recents = eval { decode_json( $http_resp->content() ) };
    SWITCH: {
      last SWITCH unless $recents;
      last SWITCH unless $recents->{releases};
      last SWITCH unless ref $recents->{releases} eq 'ARRAY';
      my @uploads;
      RELEASES: foreach my $recent ( @{ $recents->{releases} } ) {
        my $ts = Time::Piece->strptime($recent->{date},"%Y-%m-%dT%H:%M:%S")->epoch;
        $self->{timestamp} = $ts unless $self->{timestamp};
        last RELEASES if $ts <= $self->{timestamp};
        $recent->{ts} = $ts;
        push @uploads, $recent;
      }
      foreach my $upload ( reverse @uploads ) {
        $self->{timestamp} = delete $upload->{ts};
        $kernel->post( $self->{sender_id}, $self->{event}, $upload );
      }
    }
  }
  $kernel->yield('_real_shutdown') if $self->{shutdown};
  $kernel->delay('_get_recent', $self->{delay}) unless $self->{shutdown};
  return;
}

sub _get_connect_error {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{_http_requests}--;
  $kernel->delay('_get_recent', $self->{delay});
  return;
}

"Fooby Dooby Foo Bar";

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::MetaCPAN::Recent - Obtain uploaded CPAN dists via MetaCPAN.

=head1 VERSION

version 1.04

=head1 SYNOPSIS

  use strict;
  use POE qw(Component::MetaCPAN::Recent);

  $|=1;

  POE::Session->create(
        package_states => [
          'main' => [qw(_start upload)],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::MetaCPAN::Recent->spawn(
        event => 'upload',
    );
    return;
  }

  sub upload {
    use Data::Dumper;
    print Dumper( $_[ARG0] ), "\n";
    return;
  }

=head1 DESCRIPTION

POE::Component::MetaCPAN::Recent is a L<POE> component that alerts newly uploaded CPAN
distributions. It obtains this information from polling L<http://fastapi.metacpan.org/release/recent>.

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

An event will be triggered for each new CPAN upload. The event will have ARG0 set to the C<hashref> of the
upload

=head1 SEE ALSO

L<POE>

L<POE::Component::SmokeBox::Recent::HTTP>

L<http://fastapi.metacpan.org/release/recent>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
