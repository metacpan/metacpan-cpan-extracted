package Net::IChat::Message::Text;

use strict;
use warnings;

use EO;
use Class::Accessor::Chained;
use base qw( EO Class::Accessor::Chained );

our $VERSION = '0.01';

Net::IChat::Message::Text->mk_accessors( qw( body ) );

sub parse {
  my $self = shift;
  my $doc  = shift;
  $self->body( $doc->findvalue( '//message/body' ) );
}

sub serialize {
  my $self = shift;
  my $text = $self->body;
  return qq{<message><body>$text</body></message>\r\n};
}

1;
