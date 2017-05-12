#$Id: hubcli.pm 593 2010-01-30 11:11:27Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/hubcli.pm $
#reserved for future 8), but something works
package    #hide from cpan
  Net::DirectConnect::hubcli;
use strict;
use Net::DirectConnect;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
no warnings qw(uninitialized);
our $VERSION = ( split( ' ', '$Revision: 593 $' ) )[1];
use base 'Net::DirectConnect';

sub init {
  my $self = shift;
  %$self = ( %$self,, @_ );
  #$self->baseinit();
  $self->get_peer_addr();
  $self->log( 'info', "[$self->{'number'}] Incoming client $self->{'host'}:$self->{'port'}" ) if $self->{'incoming'};
  $self->{'parse'} ||= {
    'Supports' => sub {
      #$self->supports_parse( $_[0], $self->{'NickList'}->{ $self->{'peernick'} } );
      $self->supports_parse( $_[0], $self->{'peer_supports'} );
    },
    'Key' => sub {
    },
    'ValidateNick' => sub {
      #$self->log('dev', 'denide', $_[0], Dumper $self->{'NickList'}),
      #!return $self->cmd('ValidateDenide') if exists $self->{'NickList'}{ $_[0] } and $self->{'NickList'}{ $_[0] }{'online'};
      $self->{'peer_nick'}                          = $_[0];
      $self->{'NickList'}->{ $self->{'peer_nick'} } = $self->{'peer_supports'};
      $self->{'status'}                             = 'connected';
      $self->cmd('Hello');
    },
    'Version' => sub {
      $self->{'NickList'}{ $self->{'peer_nick'} }{'Version'} = $_[0];
    },
    'GetNickList' => sub {
      $self->cmd('NickList');
      $self->cmd('OpList');
    },
    'MyINFO' => sub {
      my ( $nick, $info ) = $_[0] =~ /\S+\s+(\S+)\s+(.*)/;
      return if $nick ne $self->{'peer_nick'};
      $self->{'NickList'}{$nick}{'Nick'} = $nick;
      $self->info_parse( $info, $self->{'NickList'}{$nick} );
      $self->{'NickList'}{$nick}{'online'} = 1;
    },
    'GetINFO' => sub {
      my $to = shift;
    },
    'chatline' => sub {
      $self->{'parent'}->rcmd( 'chatline', @_ );
    },
  };
  $self->{'cmd'} ||= {
    'Lock'           => sub { $self->sendcmd( 'Lock',    $self->{'Lock'} ); },
    'HubName'        => sub { $self->sendcmd( 'HubName', $self->{'HubName'} ); },
    'ValidateDenide' => sub { $self->sendcmd('ValidateDenide'); },
    'Hello'          => sub { $self->sendcmd( 'Hello',   $self->{'peer_nick'} ); },
    'NickList'       => sub {
      $self->sendcmd( 'NickList', join '$$', grep { !$self->{'NickList'}{$_}{'oper'} } keys %{ $self->{'NickList'} } );
    },
    'OpList' => sub {
      $self->sendcmd( 'OpList', join '$$', grep { $self->{'NickList'}{$_}{'oper'} } keys %{ $self->{'NickList'} } );
    },
    'chatline_from' => sub {
      my $from = shift;
      #return if $self->{'_chatline_rec'};
      for (@_) {
        return unless $self->{'socket'};
        $self->log( 'dcdmp', "($self->{'number'}) we send [", "<$from> $_|", "]:", $self->{'socket'}->send("<$from> $_|"), $! );
        #$self->log('dbg', 'sleep', $self->{'min_chat_delay'}),
      }
    },
    'chatline' => sub {
      my ( $nick, $text ) = $_[0] =~ /^<([^>]+)> (.+)$/;
      #$self->{'_chatline_rec'} = 1;
      $self->log( 'dbg', "[$self->{'number'}]",    'chatline Rstart', );
      $self->log( 'dbg', "[$self->{'number'}] to", $_->{'number'} ),
        #TO API
        $_->cmd( 'chatline_from', $self->{'peer_nick'}, $text )
        for grep { $_ and $_ ne $self } values( %{ $self->{'parent'}{'clients'} } );
      #$self->{'parent'}->rcmd('chatline_from', $self->{'peer_nick'}, $text);
      #delete $self->{'_chatline_rec'};
    },
  };
  $self->{'handler_int'} ||= {
    'disconnect_aft' => sub {
      #$self->{'NickList'}{$self->{'peer_nick'}}{'online'} = 0;
      delete $self->{'NickList'}{ $self->{'peer_nick'} };
      $self->log( 'dev', 'deleted', $self->{'peer_nick'}, Dumper $self->{'NickList'} );
    },
  };
  $self->{'sendbuf'} = 1;
  $self->cmd('Lock');
  $self->{'sendbuf'} = 0;
  $self->cmd('HubName');
}
1;
