#$Id: http.pm 742 2011-01-14 00:14:31Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/http.pm $
package    #hide from cpan
  Net::DirectConnect::http;
use Data::Dumper;    #dev only
#$Data::Dumper::Sortkeys = 1;
#$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
use Net::DirectConnect;
#use Net::DirectConnect::hubcli;
use strict;
no warnings qw(uninitialized);
our $VERSION = ( split( ' ', '$Revision: 742 $' ) )[1];
#our @ISA = ('Net::DirectConnect');
use base 'Net::DirectConnect';

sub init {
  my $self = shift;
  $self->log( 'dev', 'httpcli init' );
  #%$self = (    %$self,
  local %_ = (
    #
    #'incomingclass' => 'Net:DirectConnect::httpcli',
    'auto_connect' => 0, 'auto_listen' => 0, 'protocol' => 'http',
    #'myport'        => 80,
    #'myport_base'   => 8000,
    #'myport_random' => 99,
    #'myport_tries'  => 5,
    #'HubName'       => 'Net::DirectConnect test hub',
    'allow'   => '127.0.0.1',
    'cmd_bef' => undef,
    'cmd_aft' => "\n",
  );
  $self->{$_} //= $_{$_} for keys %_;
  local %_ = @_;
  $self->{$_} = $_{$_} for keys %_;
  #$self->{$_} ||= $self->{'parent'}{$_} ||= {} for qw(peers peers_sid peers_cid want share_full share_tth);
  #$self->{$_} ||= $self->{'parent'}{$_}  for qw(allow);
  #$self->baseinit();
  #$self->{'parse'} ||= $self->{'parent'}{'parse'};
  #$self->{'cmd'}   ||= $self->{'parent'}{'cmd'};
  $self->{'handler_int'}{'unknown'} ||= sub {
    my $self = shift if ref $_[0];
    #$self->log( 'dev', "unknown1", Dumper \@_ );
    ( $self->{http_headers}{ $_[0] } = $_[1] ) =~ s/^: |\s+$//g;
    #};
  };
  #$self->{'handler'}{  'unknown'}||=sub {
  #my $self = shift if ref $_[0];
  #$self->log( 'dev', "unknown2", @_ );
  #};
  #};
  #'GET' => sub {
  $self->{'parse'} ||= {
    'DELLLLLLLnoGET' => sub {
      my $self = shift if ref $_[0];
      my ( $url, $prot ) = split /\s/, $_[0];
      $self->log( 'dev', "get $url : $prot" );
      $self->{'http_geturl'} = $url;
    },
    #"\x0D" => sub {$self->log('dev', 'can send');    },
    '' => sub {
      my $self = shift if ref $_[0];
      #$self->log( 'dev', 'can send2', Dumper $self->{'handler_int'} );
      my $c = "HTTP/1.1 200 OK\nContent-Type: text/html; charset=utf-8\n\n";
      ( $self->{'http_geturl'} ) = split ' ', $self->{http_headers}{GET};
      if ( $self->{'http_geturl'} eq '/' ) {
        $c .= "<html><body>" . "clients:<br/>" . (
          join ', ',
          map {
            "$_($self->{clients}{$_}{status}"
              . (
              !$self->{clients}{$_}{'filebytes'} ? () : ":$self->{clients}{$_}{'filebytes'}/$self->{clients}{$_}{'filetotal'}" )
              . ")"
            } sort keys %{ $self->{clients} }
          )
          . "<hr/>peers:<br/>"
          . (
          join '<br/> ',
          map {
            join ' ', $_->{INF}{NI}, $_->{INF}{SS}, $_->{INF}{I4},
            } sort {
            $b->{INF}{SS} <=> $a->{INF}{SS}
            } values %{ $self->{peers_cid} }
          )
          . "<pre>"    #.Dumper($self->{peers})
                       #."<pre>" . Dumper($self)
          . "</html>";
      } elsif ( $self->{'http_geturl'} =~ m{^/dl/(.+)$} ) {
        $self->{parent}{parent}->download($1);
        $c .= "try dl [$1]";
      }
      $c .= "<hr/><pre>" . Dumper( $self->{http_headers} );
      $self->send( Encode::encode 'utf8', $c );
      $self->destroy();
    },
  };
  #$self->{'parser'} = sub {   my $self = shift;$self->log('dev', 'myparser', Dumper @_); };
  $self->log( 'dev', 'httpcli inited' );
}
1;
