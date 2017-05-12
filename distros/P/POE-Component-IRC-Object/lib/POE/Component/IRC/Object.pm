# $Id: Object.pm,v 1.3 2002/07/02 14:36:39 matt Exp $

package POE::Component::IRC::Object;
use strict;
use POE;
use POE::Component::IRC;

use vars qw($VERSION $AUTOLOAD);

$VERSION = '0.02';

sub new {
    my $class = shift;
    die __PACKAGE__ . "->new() params must be a hash" if @_ % 2;
    my %params = @_;
    
    my $self = bless \%params, $class;
    $self->init();
    return $self;
}

my $id = 0;

sub init {
    my ($self) = @_;
    
    my $name = sprintf("pocoirc_irc_%06d", ++$id);
    # warn("Creating IRC object $name\n");
    $self->{__IRC} = $name;
    POE::Component::IRC->new($name);
    
    POE::Session->create(
        object_states => [
            $self => [ '_start', '_stop', '_default' ],
        ],
    );
}

sub _start {
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    
    # warn("_start - registering all\n");
    
    $kernel->post($self->{__IRC}, "register", "all");
    
    my $hash = {};
    $hash->{Nick} = $self->{Nick} if $self->{Nick};
    $hash->{Server} = $self->{Server} if $self->{Server};
    $hash->{Port} = $self->{Port} if $self->{Port};
    $hash->{Username} = $self->{Username} if $self->{Username};
    $hash->{Ircname} = $self->{Ircname} if $self->{Ircname};
    
    $kernel->post($self->{__IRC}, "connect", $hash);
}

sub _stop {
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    # warn("stopping\n");
    $self->{__Quitting} = 1;
    $kernel->post($self->{__IRC}, "quit");
}

sub _default {
    my ($self, $kernel, $state, $args) = @_[OBJECT, KERNEL, ARG0, ARG1];
    my @new_ = @_[ 1 .. (ARG0-1) ];
    push @new_, @$args;
    $self->$state(@new_);
    return 0;
}

sub irc_socketerr {
    warn("irc_socket error: ", $_[ARG0], "\n");
    warn("Perhaps your server name or port is incorrect, or your net access is down\n");
}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/^.*://;
    $poe_kernel->post($self->{__IRC}, $method, @_);
}

sub irc_error {
    my ($self, $kernel, $server) = @_[OBJECT, KERNEL, ARG0];
    $self->{__irc_connected} = 0;
    $kernel->yield('reconnect');
}

sub reconnect {
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
    return if $heap->{__irc_connected};
    
    my $hash = {};
    $hash->{Nick} = $self->{Nick} if $self->{Nick};
    $hash->{Server} = $self->{Server} if $self->{Server};
    $hash->{Port} = $self->{Port} if $self->{Port};
    $hash->{Username} = $self->{Username} if $self->{Username};
    $hash->{Ircname} = $self->{Ircname} if $self->{Ircname};
    
    $kernel->post($self->{__IRC}, "connect", $hash);

    # try again in 2 seconds (may have succeeded, but we test that at the top
    $kernel->delay_set( 'reconnect', 2 );
}

sub irc_connected {
    $_[OBJECT]->{__irc_connected} = 1;
}

1;

__END__

=head1 NAME

POE::Component::IRC::Object - A slightly simpler OO interface to PoCoIRC

=head1 SYNOPSIS

  package ElizaBot;
  use Chatbot::Eliza;
  use POE;
  use POE::Component::IRC::Object;
  use base qw(POE::Component::IRC::Object);
  
  BEGIN { $chatbot = Chatbot::Eliza->new(); }
  
  sub irc_001 {
    $_[OBJECT]->join( "#elizabot" );
    print "Joined channel #elizabot\n";
  }
  
  sub irc_public {
    my ($self, $kernel, $who, $where, $msg) = 
      @_[OBJECT, KERNEL, ARG0, ARG1, ARG2];
    
    $msg =~ s/^doctor[:,]?\s+//;
    
    my ($nick, undef) = split(/!/, $who, 2);
    my $channel = $where->[0];
    
    my $response = $chatbot->transform($msg);
    $self->privmsg( $channel, "$nick: $response" );
  }
  
  sub irc_join {
    my ($self, $who, $channel) = 
      @_[OBJECT, ARG0, ARG1];
    
    my ($nick, undef) = split(/!/, $who, 2);
    $self->privmsg( $channel, "$nick: How can I help you?" );
  }
  
  package main;
  use POE;
  
  ElizaBot->new(
    Nick => 'doctor',
    Server => 'grou.ch',
    Port => 6667,
  );
  
  $poe_kernel->run();
  exit(0);

=head1 DESCRIPTION

Quite simply, I didn't like the way the module POE::Component::IRC worked.
I felt like it required me to do too many things - create a PoCo::IRC
instance for each IRC client, and then create a session, and in the
C<_start> for the session I was supposed to connect to the server and
do all the right things.

For an IRC client that connects to multiple channels from one piece of
code this is good. But for me it was too flexible. So I wrote this module.

Oh, and this module also saves you some typing.

Basic usage is to create a subclass of this module. In that subclass define
events according to the event names in L<POE::Component::IRC>.

This module has pretty good reconnect code in (i.e. reconnect if we
get disconnected by accident, and keep retrying indefinitely). But it will
break if you redefine the irc_error, irc_connected, or reconnect methods.
So don't do that ;-)

Any methods that you call on the object will be passed through as
C<$kernel->post()> calls to the underlying POE::Component::IRC object. This
makes it very easy to return messages, via C<< $self->privmsg($channel, $text) >>
and so on.

=head1 BUGS

Probably some. Some may consider it a bug that the whole module uses AUTOLOAD
and _default to send calls to the right place.

=head1 LICENSE

This is free software. You may use and distribute it under the same terms as
perl itself.

=head1 AUTHOR

Matt Sergeant - matt@sergeant.org

=cut