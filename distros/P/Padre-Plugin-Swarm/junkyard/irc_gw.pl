#!/usr/bin/env perl
use strict;
#use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::IRC::Client;
use Data::Dumper;
use JSON;
use Padre::Swarm::Transport::Multicast;
my $gatewayid = rand() . $$;

my $swarm = Padre::Swarm::Transport::Multicast->new();
$swarm->subscribe_channel( 12000 , 1);
$swarm->start;
my ($socket) = $swarm->channels->{12000};
my $io = AnyEvent::Handle->new(
   fh => $socket,
   on_eof => sub { $swarm->shutdown },
   on_read => sub { $_[0]->push_read( json => \&swarm_relay ) ; },
   on_error => sub { warn "Error @_ " },
   
);

my $con = AnyEvent::IRC::Client->new;
my ($nick, $user, $real) = qw/padre_swarm Padre-Swarm-IRCGW andrewb/;


sub swarm_relay {
   my ($handle,$payload )= @_;
   #my ($channel,$client,$payload) =$swarm->receive_from( 12000 );
   
   warn "Test for loops ";
   return if ( $con->nick eq $payload->{entity} ) ; # no loops to self
   return if ( $payload->{gw} eq $gatewayid ); # dont relay gateways
   
   warn "RELAY: " . Dumper $payload;
   
   $con->send_chan( '#padre', 'PRIVMSG',
    '#padre',
    ":$payload->{message}",  "via swarm relay from $payload->{user}"
   );
   
   
}

my $c = AnyEvent->condvar;

$con->reg_cb (
   connect => sub {
      my ($con, $err) = @_;
      if (defined $err) {
         warn "Connect ERROR! => $err\n";
         $c->broadcast;
      } else {
         warn "Connected! Yay!\n";
      }

      $con->send_srv( JOIN => '#padre' );
      $con->register( $nick , $user, $real );
   },
   disconnect => sub {
      warn "Oh, got a disconnect: $_[1], exiting...\n";
      $c->broadcast;
   }
);

$con->reg_cb(
   publicmsg => sub {
      my ($handle,$channel,$ircmsg)= @_;
      my $nick = $con->nick;
      
      my $body = join (' ',@{ $ircmsg->{params} } );
      my $msg = { 
            user => $ircmsg->{prefix}, 
            message => $body , 
            type => 'chat',
            to => $channel,
            gw => $gatewayid,
            entity => $con->nick, };
            
      $swarm->tell_channel( 12000, JSON::encode_json $msg );
      #$io->push_write( json => $msg );
   }
);

$con->connect ("irc.perl.org", 6667 ,
 { nick => $nick , user => $user , real => $real }

);



$c->wait;
