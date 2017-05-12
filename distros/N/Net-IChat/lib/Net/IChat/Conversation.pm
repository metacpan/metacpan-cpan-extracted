package Net::IChat::Conversation;

use strict;
use warnings;

use EO;
use XML::LibXML;
use Class::Accessor::Chained;
use Net::IChat::Message::Text;
use Net::IChat::Message::File;
use base qw( EO Class::Accessor::Chained );

our $VERSION = '0.01';

Net::IChat::Conversation->mk_accessors( qw( parser conversing_with ) );

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->parser( XML::LibXML->new );
    return 1;
  }
  return 0;
}

sub resetparser {
  my $self = shift;
  $self->parser( XML::LibXML->new );
}

sub socket {
  my $self = shift;
  if (@_) {
    $self->{ socket } = shift;
    $self->startstream( @_ );
    return $self;
  }
  return $self->{ socket };
}

sub fetch_clients {
  my $self = shift;
  my $hash= { map { ($_->address =>  $_) } @{ Net::IChat->clients } };
  return $hash;
}

sub determine_other_end {
  my $self = shift;
  $self->{ client_cache } ||= $self->fetch_clients;
  my $peername = $self->socket->peerhost;
  my $peerport = $self->socket->peerport;
  my $hosttext = $peername;
  my $ent      = $self->{ client_cache }->{ $hosttext };
  if (!defined( $ent )) {
    $self->{ client_cache } = $self->fetch_clients;
  }
  $self->conversing_with( $self->{ client_cache }->{ $hosttext } );
  return 1;
}

sub startstream {
  my $self = shift;
  my $to   = shift;
  my $sock = $self->socket;

  $self->determine_other_end;

  my $stream = sprintf(
		       qq{<stream:stream %s xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams">\r\n},
		       ($to) ? qq{to="$to"} : ''
		      );
  $sock->print( qq{<?xml version="1.0" encoding="UTF-8" ?>\r\n} );
  $sock->print( $stream );
  ## throw away pointless information
  ( undef, undef ) = ( $sock->getline, $sock->getline );
}

sub receive {
  my $self = shift;
  my $text = '';
  while( my $line = $self->socket->getline() ) {
    my $echo = $line;
    chomp $echo;
    $text .= $line;
    my $doc = eval { $self->parser->parse_string( $text ) };
    if (!$@) {
#      $self->resetparser;

      ## this is a really nasty hack
      if (index($text,'<id') > -1) {
	$text = '';
	next;
      }

      if ($doc->findvalue( '//message/body' )) {
	return $self->message->parse( $doc );
      } elsif ($doc->findvalue( '//iq' )) {
	return $self->file->parse( $doc );
      } else {
      }

      $text = '';
    } else {
    }
  }
}

sub send {
  my $self = shift;
  my $mesg = shift;
  if (ref($mesg)) {
    $self->socket->print( $mesg->serialize );
    return 1;
  } else {
    my $msg = $self->message;
    $msg->body( $mesg );
    $self->socket->print( $msg->serialize );
  }
}

sub end {
  my $self = shift;
  $self->socket->print( "</stream:stream>" );
  $self->socket->close();
}

sub message {
  return Net::IChat::Message::Text->new();
}

sub file {
  return Net::IChat::Message::File->new();
}

1;

