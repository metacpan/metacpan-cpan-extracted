package Net::IChat;

use strict;
use warnings;

use EO;
use Net::Rendezvous;
use Net::IChat::Client;
use Net::Rendezvous::Publish;
use Class::Accessor::Chained;
use base qw( EO Class::Accessor::Chained );

our $VERSION = '0.01';

{
  # Work around bug in Net::DNS::Packet's dn_expand_XS
  no warnings 'redefine';
  *Net::DNS::Packet::dn_expand = \&Net::DNS::Packet::dn_expand_PP;
}

sub me {
  my $class = shift;
  Net::IChat::Client->new();
}

sub clients {
  my $class = shift;
  my $res  = Net::Rendezvous->new('presence');
  $res->discover;
  [ map { Net::IChat::Client->new->mdns_entry( $_ ) } $res->entries ];
}

1;

=head1 NAME

Net::IChat - use apple's iChat as a messaging tool

=head1 SYNOPSIS

  use Net::IChat;
  use Net::IChat::Client;

  my $me = Net::IChat->me();
  $me->announce;

  my $clients = Net::IChat->clients();
  if (@$clients) {
    my $conversation = $clients->[0]->converse();
    $conversation->send('Hello');
    my $mesg = $conversation->receive();

    if ($mesg->can('body')) {
      print $mesg->body;
    }
  }

=head1 DESCRIPTION

Net::IChat allows you to write clients for Apple's Rendezvous iChat.

=cut
