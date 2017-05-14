#$Id: http.pm 998 2013-08-14 12:21:20Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/http.pm $
package    #hide from cpan
  Net::DirectConnect::http;
use Data::Dumper;    #dev only
#$Data::Dumper::Sortkeys = 1;
#$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
use Net::DirectConnect;
#use Net::DirectConnect::hubcli;
use strict;
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
our $VERSION = ( split( ' ', '$Revision: 998 $' ) )[1];
#our @ISA = ('Net::DirectConnect');
use base 'Net::DirectConnect';

sub init {
  my $self = shift;
  #$self->log( 'dev', 'httpcli init' );
  #%$self = (    %$self,
  local %_ = (
    #'incomingclass' => 'Net:DirectConnect::httpcli',
    'auto_connect' => 0,
    'auto_listen'  => 0,
    'protocol'     => 'http',
    #);  $self->{$_} = $_{$_} for keys %_;
    # local %_ = (
    #'myport'        => 80,
    #'myport'        => 443,
    #modules => [],
    #'myport_base'   => 8000,
    #'myport_random' => 99,
    #'myport_tries'  => 5,
    'myport_inc' => 1,
    #'HubName'       => 'Net::DirectConnect test hub',
    'allow'   => '127.0.0.1',
    'cmd_bef' => undef,
    'cmd_aft' => "\n",
  );
  $self->{$_} //= $_{$_} for keys %_;
  local %_ = @_;
  #warn "$_=$_{$_}";
  $self->{$_} = $_{$_} for keys %_;
  #$self->{$_} ||= $self->{'parent'}{$_} ||= {} for qw(peers peers_sid peers_cid want share_full share_tth);
  $self->{$_} ||= $self->{'parent'}{$_} for qw(http_download http_control http_allow);    #allow
                                                                                          #$self->baseinit();
        #$self->{'parse'} ||= $self->{'parent'}{'parse'};
        #$self->{'cmd'}   ||= $self->{'parent'}{'cmd'};
  $self->{'allow'} = $self->{http_allow} if defined $self->{http_allow};
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
    "\x0D" => sub {    #$self->log('dev', 'can send');    },
                       #'' => sub {
      my $self = shift if ref $_[0];
      #$self->log( 'dev', 'can send2', Dumper $self->{'handler_int'}, $self->{http_headers} );
      ( $self->{'http_geturl'} ) = split ' ', $self->{http_headers}{GET};
      ( $self->{'http_getfile'} ) = $self->{'http_geturl'} =~ m{^/(.+)};
      my $c = "HTTP/1.1 200 OK" . "\nContent-Type: text/html; charset=utf-8\n\n";
      if ( $self->{'http_control'} and $self->{'http_geturl'} eq '/' ) {
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
                       #. "<pre>" . Dumper($self)
          . "</html>";
      } elsif ( $self->{'http_download'} and my $full = $self->{"share_full"}{ $self->{'http_getfile'} } ) {
        my ($name) = $full =~ m{([^/]+)$};
        my $size   = -s $full;
        my $sizep  = $size + 1;
        my ( $from, $to ) = $self->{http_headers}{Range} =~ /^bytes=(\d+)\-(\d*)/;
        $to ||= $size if $from;
        my $type = { xml => 'text/xml' }->{ lc +( $name =~ m/\.(\w+)/ )[0] } || 'binary/octet-stream';
        $c =
            "HTTP/1.1 "
          . ( $from ? "206 Partial Content" : "200 OK" )
          . "\nContent-Type: $type"
          . "\nContent-Length: $size"
          . "\nAccept-Ranges: bytes\n"
          . ( !$from ? () : "Content-Range: bytes $from-$to/$sizep\n" )
          . "Content-Disposition: attachment; filename=$name\n\n";
        #$self->log( 'dev', "hdr[$c]" );
        $self->send( Encode::encode 'utf8', $c, Encode::FB_WARN );
        $self->file_send( $self->{"share_full"}{ $self->{'http_getfile'} }, $from, $to );
        return;
        #$c .= "gettii[$self->{'http_getfile'}]";
      } elsif ( $self->{'http_control'} and $self->{'http_geturl'} =~ m{^/dl/(.+)$} ) {
        $self->{parent}{parent}->download($1);
        $c .= "try dl [$1]";
      }
      #$c .= "<hr/><pre>" . Dumper( $self->{http_headers} );
      $self->send( Encode::encode 'utf8', $c, Encode::FB_WARN );
      $self->destroy();
    },
  };
  #$self->{'parser'} = sub {   my $self = shift;$self->log('dev', 'myparser', Dumper @_); };
  #$self->log( 'dev', 'httpcli inited' );
}
1;
