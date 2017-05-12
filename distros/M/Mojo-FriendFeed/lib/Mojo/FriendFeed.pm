package Mojo::FriendFeed 0.05;

use Mojo::Base 'Mojo::EventEmitter';
use v5.16;

use Mojo::UserAgent;
use Mojo::URL;

use Scalar::Util 'weaken';

use constant DEBUG => $ENV{MOJO_FRIENDFEED_DEBUG};

has [qw/request username remote_key/] => '';

has ua => sub { Mojo::UserAgent->new->inactivity_timeout(0) };

has url => sub {
  my $self = shift;
  my $req  = $self->request || '';
  my $url  = 
    Mojo::URL
      ->new("http://friendfeed-api.com/v2/updates$req")
      ->query( updates => 1 );
  if ($self->username) {
    $url->userinfo($self->username . ':' . $self->remote_key);
  }
  return $url;
};

sub listen {
  my $self = shift;
  my $ua   = $self->ua;
  my $url  = $self->url->clone;
  warn "Subscribing to: $url\n" if DEBUG;

  weaken $self;

  $ua->get( $url => sub {
    my ($ua, $tx) = @_;

    return unless $self;

    warn "Received message: @{[$tx->res->body]}" if DEBUG;

    my $json = $tx->res->json;
    unless ($tx->success and $json) {
      $self->emit( error => $tx, ($json || {})->{errorCode} );
      return;
    }

    $self->emit( entry => $_ ) for @{ $json->{entries} };

    return unless $self;

    if ($json->{realtime}) {
      my $url  = $self->url->clone->query(cursor => $json->{realtime}{cursor});
      $ua->get( $url => __SUB__ );
    } 
  });
}

1;

=head1 NAME

Mojo::FriendFeed - A non-blocking FriendFeed listener for Mojolicious

=head1 SYNOPSIS

 use Mojo::Base -strict;
 use Mojo::IOLoop;
 use Mojo::FriendFeed;
 use Data::Dumper;

 my $ff = Mojo::FriendFeed->new( request => '/feed/cpan' );
 $ff->on( entry => sub { say Dumper $_[1] } );
 $ff->listen;

 Mojo::IOLoop->start;

=head1 DESCRIPTION

A simple non-blocking FriendFeed listener for use with the Mojolicious toolkit.
Its code is highly influenced by Miyagawa's L<AnyEvent::FriendFeed::Realtime>.

=head1 EVENTS

Mojo::FriendFeed inherits all events from L<Mojo::EventEmitter> and implements the following new ones.

=head2 entry

 $ff->on( entry => sub {
   my ($ff, $entry) = @_;
   ...
 });

Emitted when a new entry has been received, once for each entry.
It is passed the instance and the data decoded from the JSON response.

=head2 error

 $ff->on( error => sub {
   my ($ff, $tx, $ff_error) = @_;
   ...
 });

Emitted for transaction errors. 
Fatal if not handled.
It is passed the instance, the transaction object, and the "errorCode" sent from FriendFeed if available.
Note that after emitting the error event, the C<listen> method exits, though you may use this hook to re-attach if desired.
Note also that the transaction object's C<error> method is likely to be useful, though note that its behavior changes slightly in Mojolicious 5.0.

 $ff->on( error => sub { shift->listen } );

=head1 ATTRIBUTES

Mojo::FriendFeed inherits all attributes from L<Mojo::EventEmitter> and implements the following new ones.

=head2 request 

The feed to request. Default is an empty string.

=head2 ua

An instance of L<Mojo::UserAgent> for making the feed request.

=head2 url

The (generated) url of the feed. Using the default value is recommended.

=head2 username 

Your FriendFeed username. If set, authentication will be used.

=head2 remote_key

Your FriendFeed API key. Unused unless C<username> is set.

=head1 METHODS

Mojo::FriendFeed inherits all methods from L<Mojo::EventEmitter> and implements the following new ones.

=head2 listen

Connects to the feed and attaches events. Note that this does not start an IOLoop and will not block.

=head1 SEE ALSO

=over

=item *

L<Mojolicious> - High performance non-blocking web framework and toolkit for Perl

=item *

L<Mojo::IRC> - IRC interaction for use with the Mojolicious' L<Mojo::IOLoop>

=item *

L<AnyEvent::FriendFeed::Realtime> - The inspiration for this module, useful when using L<AnyEvent>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-FriendFeed> 

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
