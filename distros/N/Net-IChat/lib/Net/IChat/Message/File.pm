package Net::IChat::Message::File;

use strict;
use warnings;

use EO;
use LWP::UserAgent;
use Class::Accessor::Chained;
use base qw( EO Class::Accessor::Chained );

our $VERSION = '0.01';

Net::IChat::Message::File->mk_accessors(
					qw(
					   url
					  )
				       );

exception Net::IChat::Message::File::CouldNotFetch;

sub parse {
  my $self = shift;
  my $doc  = shift;
  my $val  = $doc->findvalue('//iq');
  $val =~ s/\n//g;
  $self->url( $val );
  $self;
}

sub load {
  my $self = shift;
  my $ua   = LWP::UserAgent->new();
  my $response = $ua->get( $self->url );
  if ($response->is_success()) {
    return $response->content;
  } else {
    throw Net::IChat::Message::File::CouldNotFetch text => "could not fetch file: " . $response->status_line;
  }
}

1;

