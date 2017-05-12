package POE::Component::SmokeBox::Uploads::RSS;
$POE::Component::SmokeBox::Uploads::RSS::VERSION = '1.04';
#ABSTRACT: Obtain uploaded CPAN modules via RSS.

use strict;
use warnings;
use Carp;
use POE qw(Component::RSSAggregator Component::Client::HTTP);
use HTTP::Request;
use HTML::LinkExtor;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak "$package requires an 'event' argument\n" unless $opts{event};
  $opts{feed} = 'http://search.cpan.org/uploads.rdf' unless $opts{feed};
  $opts{name} = 'search-cpan-recent' unless $opts{name};
  $opts{delay} = 1800 unless $opts{delay};
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
        object_states => [
	   $self => { shutdown => '_shutdown', },
           $self => [ qw(_start _dispatch _feed_url _handle_feed _real_shutdown) ],
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
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ ) unless $self->{alias};
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $kernel->post( $self->{http_id}, 'shutdown' ) unless $self->{http_alias};
  $kernel->post( $self->{rssagg}, 'shutdown' );
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
  if ( $self->{http_alias} ) {
     my $http_ref = $kernel->alias_resolve( $self->{http_alias} );
     $self->{http_id} = $http_ref->ID() if $http_ref;
  }
  unless ( $self->{http_id} ) {
    $self->{http_id} = 'smokeboxrss' . $$ . $self->{session_id};
    POE::Component::Client::HTTP->spawn(
	Alias           => $self->{http_id},
	FollowRedirects => 2,
        Timeout         => 60,
        Agent           => 'Mozilla/5.0 (X11; U; Linux i686; en-US; '
                . 'rv:1.1) Gecko/20020913 Debian/1.1-1',
    );
  }
  $self->{rssagg} = 'rssagg' . $self->{session_id};
  POE::Component::RSSAggregator->new(
            alias    => $self->{rssagg},
            callback => $session->postback('_handle_feed'),
            http_alias => $self->{http_id},
            tmpdir   => $self->{tmpdir} || '.',        # optional caching
  );
  my $feed = {
                url   => $self->{feed},
                name  => $self->{name},
                delay => $self->{delay},
  };
  $kernel->post( $self->{rssagg}, 'add_feed', $feed );
  return;
}

sub _handle_feed {
  my ($kernel,$self,$feed) = (@_[KERNEL,OBJECT], $_[ARG1]->[0]);
  for my $headline ( reverse $feed->late_breaking_news ) {
    $kernel->post(
        $self->{http_id},
        'request',
        '_feed_url',
        HTTP::Request->new( GET => $headline->url ),
        $headline->headline,
    );
    $self->{_http_requests}++;
  }
  return;
}

sub _feed_url {
  my ($kernel,$self,$request_packet,$response_packet) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $http_resp = $response_packet->[0];
  $self->{_http_requests}--;
  return unless $http_resp and $http_resp->code() == 200;
  my $tag    = $request_packet->[1];
  my $p = HTML::LinkExtor->new();
  $p->parse( $http_resp->content() );
  foreach my $link ( $p->links() ) {
     if ( $link->[0] eq 'a' and $link->[2] =~ /\Q$tag\E/ ) {
        ( my $module = $link->[2] ) =~ s#/CPAN/authors/id/##;
	$kernel->call( $self->{session_id}, '_dispatch', $module );
        last;
     }
  }
  $kernel->yield( '_real_shutdown' ) if $self->{_shutdown} and $self->{_http_requests} == 0;
  return;
}

sub _dispatch {
  my ($kernel,$self,$module) = @_[KERNEL,OBJECT,ARG0];
  $kernel->post( $self->{sender_id}, $self->{event}, $module );
  return;
}

"This town ain't big enough for the both of us";

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Uploads::RSS - Obtain uploaded CPAN modules via RSS.

=head1 VERSION

version 1.04

=head1 SYNOPSIS

  use strict;
  use POE qw(Component::SmokeBox::Uploads::RSS);

  $|=1;

  POE::Session->create(
        package_states => [
          'main' => [qw(_start upload)],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Uploads::RSS->spawn(
        event => 'upload',
    );
    return;
  }

  sub upload {
    print $_[ARG0], "\n";
    return;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox::Uploads::RSS is a L<POE> component that alerts newly uploaded CPAN
distributions. It obtains this information from polling an RSS feed ( by default L<http://search.cpan.org/uploads.rdf>.

L<POE::Component::RSSAggregator> is used to handle the RSS feed monitoring and L<POE::Component::Client::HTTP> used to obtain the full author path for each new upload.

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

  B/BI/BINGOS/POE-Component-SmokeBox-Uploads-RSS-0.01.tar.gz

Suitable for feeding to the smoke tester of your choice.

=head1 SEE ALSO

L<POE>

L<POE::Component::RSSAggregator>

L<POE::Component::Client::HTTP>

L<http://search.cpan.org/uploads.rdf>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
