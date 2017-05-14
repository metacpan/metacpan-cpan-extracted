#$Id: clihub.pm 998 2013-08-14 12:21:20Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/clihub.pm $
package    #hide from cpan
  Net::DirectConnect::clihub;
use strict;
no strict qw(refs);
use warnings "NONFATAL" => "all";
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use utf8;
use Time::HiRes qw(time sleep);
use Data::Dumper;    #dev only
$Data::Dumper::Sortkeys = $Data::Dumper::Indent = 1;
use Net::DirectConnect;
use Net::DirectConnect::clicli;
#use Net::DirectConnect::http;
our $VERSION = ( split( ' ', '$Revision: 998 $' ) )[1];
use base 'Net::DirectConnect';

sub name_to_ip($) {
  my ($name) = @_;
  unless ( $name =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
    local $_ = ( gethostbyname($name) )[4];
    return ( $name, 1 ) unless length($_) == 4;
    $name = inet_ntoa($_);
  }
  return $name;
}

sub init {
  my $self = shift;
  #%$self = (
  #%$self,
  local %_ = (
    'Nick' => 'NetDCBot',
    'port' => 411,
    'host' => 'localhost',
    'Pass' => '',
    'key'  => 'zzz',
    #'auto_wait'        => 1,
    'supports_avail' => [ qw(
        NoGetINFO
        NoHello
        UserIP2
        UserCommand
        TTHSearch
        OpPlus
        Feed
        MCTo
        HubTopic
        )
    ],
    'search_every'         => 10,
    'search_every_min'     => 10,
    'auto_connect'         => 1,
    'auto_bug'             => 1,
    'reconnects'           => 99999,
    'NoGetINFO'            => 1,                              #test
    'NoHello'              => 1,
    'UserIP2'              => 1,
    'TTHSearch'            => 1,
    'Version'              => '1,0091',
    'auto_GetNickList'     => 1,
    'follow_forcemove'     => 1,
    'incomingclass'        => 'Net::DirectConnect::clicli',
    'disconnect_recursive' => 1,
  );
  $self->{$_} //= $_{$_} for keys %_;
  $self->{'periodic'}{ __FILE__ . __LINE__ } = sub {
    my $self = shift if ref $_[0];
    $self->search_buffer() if $self->{'socket'};
  };
  #$self->log($self, 'inited',"MT:$self->{'message_type'}", ' with', Dumper  \@_);
  #$self->baseinit();
  #share_full share_tth want
  $self->{$_} ||= $self->{'parent'}{$_} ||= {} for qw( NickList IpList PortList PortList_udp);    #handler
                                                                                                  #$self->{'NickList'} ||= {};
                                                                                                  #$self->{'IpList'}   ||= {};
                                                                                                  #$self->{'PortList'} ||= {};
         #$self->log( $self, 'inited3', "MT:$self->{'message_type'}", ' with' );
         #You are already in the hub.
         #  $self->{'parse'} ||= {
  $self->module_load('filelist');
  local %_ = (
    'chatline' => sub {
      my $self = shift if ref $_[0];
      #$self->log( 'dev', Dumper \@_);
      my ( $nick, $text ) = $_[0] =~ /^(?:<|\* )(.+?)>? (.+)$/s;
      #$self->log('dcdev', 'chatline parse', Dumper(\@_,$nick, $text));
      $self->log( 'warn', "[$nick] oper: already in the hub [$self->{'Nick'}]" ), $self->nick_generate(), $self->reconnect(),
        if ( ( !keys %{ $self->{'NickList'} } or $self->{'NickList'}{$nick}{'oper'} )
        and $text eq 'You are already in the hub.' );
      if ( $self->{'NickList'}{$nick}{'oper'} or $self->{'NickList'}{$nick}{'hubbot'} or $nick eq 'Hub-Security' ) {
        if (
          $text =~
/Минимальный интервал поиска составляет: \(Minimum search interval is:\) (\d+)секунд \(seconds\)/
          or $text =~ /^(?:Minimum search interval is|Минимальный интервал поиска):(\d+)s/
          or $text =~ /Search ignored\.  Please leave at least (\d+) seconds between search attempts\./  #Hub-Security opendchub
          or $text =~
/Минимальный интервал между поисковыми запросами:(\d+)сек., попробуйте чуть позже/
          or $text =~ /You can do 1 searches in (\d+) seconds/
          )
        {
          $self->{'search_every'} = int( rand(5) + $1 || $self->{'search_every_min'} );
          $self->log( 'warn', "[$nick] oper: set min interval = $self->{'search_every'}" );
          $self->search_retry();
        }
        if ( $text =~
             /(?:Пожалуйста )?подождите (\d+) секунд перед следующим поиском\./i
          or $text =~ /(?:Please )?wait (\d+) seconds before next search\./i
          or $text eq 'Пожалуйста не используйте поиск так часто!'
          or $text eq "Please don't flood with searches!"
          or $text eq 'Sorry Hub is busy now, no search, try later..' )
        {
          $self->{'search_every'} += int( rand(5) + $1 || $self->{'search_every_min'} );
          $self->log( 'warn', "[$nick] oper: increase min interval => $self->{'search_every'}" );
          $self->search_retry();
        }
      }
      if ( !$self->{count_parse}{chatline} and $text =~ /PtokaX/i ) {
        #$self->log( 'dev', "[$nick] - probably hub bot" );
        $self->{'NickList'}{$nick}{'hubbot'} = 1;
      }
      $self->search_retry(),
        if $self->{'NickList'}->{$nick}{'oper'} and $text eq 'Sorry Hub is busy now, no search, try later..';
    },
    'welcome' => sub {
      my $self = shift if ref $_[0];
      my ( $nick, $text ) = $_[0] =~ /^(?:<|\* )(.+?)>? (.+)$/s;
      if ( !keys %{ $self->{'NickList'} } or !exists $self->{'NickList'}->{$nick} or $self->{'NickList'}->{$nick}{'oper'} ) {
        if ( $text =~ /^Bad nickname: unallowed characters, use these (\S+)/ )
          #
        {
          my $try = $self->{'Nick'};
          $try =~ s/[^\Q$1\E]//g;
          $self->log( 'warn', "CHNICK $self->{'Nick'} -> $try" );
          $self->{'Nick'} = $try if length $try;
        } elsif ( $text =~ /Bad nickname: Wait (\d+)sec before reconnecting/i
          or $text =~
          /Пожалуйста подождите (\d+) секунд до повторного подключения\./
          or $text =~ /Do not reconnect too fast. Wait (\d+) secs before reconnecting./ )
        {
          #sleep $1 + 1;
          $self->work( $1 + 10 );
        } elsif ( $self->{'auto_bug'} and $nick eq 'VerliHub' and $text =~ /^This Hub Is Running Version 0.9.8d/i ) {    #_RC1
          ++$self->{'bug_MyINFO_last'};
          $self->log( 'dev', "possible bug fixed [$self->{'bug_MyINFO_last'}]" );
        }
      }
    },
    'Lock' => sub {
      my $self = shift if ref $_[0];
      #$self->log( "lockparse", @_ );
      $self->{'sendbuf'} = 1;
      $self->cmd('Supports');
      my ($lock) = $_[0] =~ /^(.+?)(\s+Pk=.+)?\s*$/is;
      #print "lock[$1]\n";
      #$self->log( 'dev', "lock from [$_[0]] = [$lock]");
      $self->cmd( 'Key', $self->lock2key($lock) );
      $self->{'sendbuf'} = 0;
      $self->cmd('ValidateNick');
    },
    'Hello' => sub {
      my $self = shift if ref $_[0];
      #$self->log('info', "HELLO recieved, connected. me=[$self->{'Nick'}]", @_);
      return unless $_[0] eq $self->{'Nick'};
      $self->{'sendbuf'} = 1;
      $self->cmd('Version');
      $self->{'sendbuf'} = 0 unless $self->{'auto_GetNickList'};
      $self->cmd('MyINFO') unless $self->{'bug_MyINFO_last'};
      $self->{'sendbuf'} = 0, $self->cmd('GetNickList') if $self->{'auto_GetNickList'};
      $self->{'sendbuf'} = 0, $self->cmd('MyINFO')      if $self->{'bug_MyINFO_last'};
      $self->{'status'}  = 'connected';
      $self->cmd('BotINFO') if $self->{botinfo};
      $self->cmd('make_hub');
    },
    'Supports' => sub {
      my $self = shift if ref $_[0];
      $self->supports_parse( $_[0], $self );
    },
    'ValidateDenide' => sub {
      my $self = shift if ref $_[0];
      $self->log( 'warn', "ValidateDenide", $self->{'Nick'}, @_ );
      $self->cmd('nick_generate');
      $self->cmd('ValidateNick');
    },
    'To' => sub {
      my $self = shift if ref $_[0];
      #$self->log( 'msg', "Private message to", @_ );
      #@_;
      undef;
    },
    'MyINFO' => sub {
      my $self = shift if ref $_[0];
      my ( $nick, $info ) = $_[0] =~ /\S+\s+(\S+)\s+(.*)/;
      $self->{'NickList'}->{$nick}{'Nick'} = $nick;
      $self->info_parse( $info, $self->{'NickList'}{$nick} );
      $self->{'NickList'}->{$nick}{'online'} = 1;
    },
    'UserIP' => sub {
      my $self = shift if ref $_[0];
      /(\S+)\s+(\S+)/, $self->{'NickList'}{$1}{'ip'} = $2, $self->{'IpList'}{$2} = $self->{'NickList'}{$1},
        $self->{'IpList'}{$2}{'port'} = $self->{'PortList'}{$2}
        for grep $_, split /\$\$/, $_[0];
    },
    'HubName' => sub {
      my $self = shift if ref $_[0];
      $self->{'HubName'} = $_[0];
    },
    'HubTopic' => sub {
      my $self = shift if ref $_[0];
      $self->{'HubTopic'} = $_[0];
    },
    'NickList' => sub {
      my $self = shift if ref $_[0];
      $self->{'NickList'}->{$_}{'online'} = 1 for grep $_, split /\$\$/, $_[0];
      $self->GetINFO() if $self->{auto_GetINFO};
    },
    'OpList' => sub {
      my $self = shift if ref $_[0];
      $self->{'NickList'}->{$_}{'oper'} = 1 for grep $_, split /\$\$/, $_[0];
    },
    'ForceMove' => sub {
      my $self = shift if ref $_[0];
      my ($to) = grep { length $_ } split /;/, $_[0];
      $self->log( 'warn', "ForceMove to $to :: ", @_ );
      $self->disconnect();
      sleep(1);
      $self->connect($to) if $self->{'follow_forcemove'} and $to;
    },
    'Quit' => sub {
      my $self = shift if ref $_[0];
      $self->{'NickList'}->{ $_[0] }{'online'} = 0;
    },
    'ConnectToMe' => sub {
      my $self = shift if ref $_[0];
      my ( $nick, $host, $port ) = $_[0] =~ /\s*(\S+)\s+(\S+)\:(\S+)/;
      $self->{'IpList'}{$host}{'port'} = $self->{'PortList'}->{$host} = $port;
      #$self->log('dev', "portlist: $host = $self->{'PortList'}->{$host} :=$port");
      $self->log("ignore flooding attempt to [$host:$port ] ($self->{flood}{$host})"), $self->{flood}{$host} = time + 30,
        return
        if $self->{flood}{$host} > time;
      $self->{flood}{$host} = time + 60;
      return if $self->{'clients'}{ $host . ':' . $port }->{'socket'};
      $self->{'clients'}{ $host . ':' . $port } = Net::DirectConnect::clicli->new(
        #!        %$self, $self->clear(),
        parent => $self, 'host' => $host, 'port' => $port,
#'want'         => \%{ $self->{'want'} },        'NickList'     => \%{ $self->{'NickList'} },        'IpList'       => \%{ $self->{'IpList'} },        'PortList'     => \%{ $self->{'PortList'} },        'handler'      => \%{ $self->{'handler'} },
#'want'         => $self->{'want'},
#'NickList'     => $self->{'NickList'},
#'IpList'       => $self->{'IpList'},
#'PortList'     => $self->{'PortList'},
#'handler'      => $self->{'handler'},
#'share_tth'      => $self->{'share_tth'},
#'reconnects'           => 0,
        'auto_connect' => 1,
      );
    },
    'RevConnectToMe' => sub {
      my $self = shift if ref $_[0];
      my ( $to, $from ) = split /\s+/, $_[0];
      #$self->log( 'dev', "[$from eq $self->{'Nick'}] ($_[0])" );
      #$self->log( 'dev', 'go ctm' ),
      $self->cmd( 'ConnectToMe', $to ) if $from eq $self->{'Nick'};
    },
    'GetPass' => sub {
      my $self = shift if ref $_[0];
      $self->cmd('MyPass');
    },
    'BadPass' => sub {
      my $self = shift if ref $_[0];
    },
    'LogedIn' => sub {
      my $self = shift if ref $_[0];
    },
    'Search' => sub {
      my $self = shift if ref $_[0];
      my $search = $_[0];
      $self->make_hub();
      my $params = { 'time' => int( time() ), 'hub' => $self->{'hub_name'}, };
      ( $params->{'who'}, $params->{'cmds'} ) = split /\s+/, $search;
      $params->{'cmd'} = [ split /\?/, $params->{'cmds'} ];
      if ( $params->{'who'} =~ /^Hub:(.+)$/ ) { $params->{'nick'} = $1; }
      else                                    { ( $params->{'ip'}, $params->{'udp'} ) = split /:/, $params->{'who'}; }
      if   ( $params->{'cmd'}[4] =~ /^TTH:([0-9A-Z]{39})$/ ) { $params->{'tth'}    = $1; }
      else                                                   { $params->{'string'} = $params->{'cmd'}[4]; }
      $self->{'PortList_udp'}->{ $params->{'ip'} } = $params->{'udp'} if $params->{'udp'};
      $params->{'string'} =~ tr/$/ /;
      #$self->cmd('make_hub');
      #r$self->{'share_tth'}
      my $found = $self->{'share_full'}{ $params->{'tth'} } || $self->{'share_full'}{ $params->{'string'} };
      my $tth = $self->{'share_tth'}{$found};
      if (
            $found
        and $tth
        #$params->{'tth'} and $self->{'share_tth'}{ $params->{'tth'} }
        )
      {
        $self->log(
          'adcdev', 'Search', $params->{'who'},
          #$self->{'share_tth'}{ $params->{'tth'} },
          $found, -s $found, -e $found,
          ),
          #$self->{'share_tth'}{ $params->{'tth'} } =~ tr{\\}{/};
          #$self->{'share_tth'}{ $params->{'tth'} } =~ s{^/+}{};
          my $path;
        if ( $self->{'adc'} ) {
          $path = $self->adc_path_encode(
            $found
              #$self->{'share_tth'}{ $params->{'tth'} }
          );
        } else {
          $path = $found;    #$self->{'share_tth'}{ $params->{'tth'} };
          $path =~ s{^\w:}{};
          $path =~ s{^\W+}{};
          $path =~ tr{/}{\\};
          $path = Encode::encode $self->{charset_protocol}, Encode::decode( $self->{charset_fs}, $path, Encode::FB_WARN ),
            Encode::FB_WARN
            if $self->{charset_fs} ne $self->{charset_protocol};
        }
        local @_ = (
          'SR', (
            #( $self->{'M'} eq 'P' or !$self->{'myport_tcp'} or !$self->{'myip'} )            ?
            $self->{'Nick'}
              #: $self->{'myip'} . ':' . $self->{'myport_tcp'}
          ),
          $path . "\x05" . ( -s $found or -1 ),
          $self->{'S'} . '/'
            . $self->{'S'} . "\x05"
            .
            #"TTH:"            . $params->{'tth'}
            ( $params->{'tth'} ? $params->{'cmd'}[4] : "TTH:" . $tth )
            #. ( $self->{'M'} eq 'P' ? " ($self->{'host'}:$self->{'port'})" : '' ),
            #. (  " ($self->{'host'}:$self->{'port'})\x05$params->{'nick'}"  ),
            . (
            #" ($self->{'host'}:$self->{'port'})"
            #" (".name_to_ip($self->{'host'}).":$self->{'port'})"
            #" (".inet_ntoa(gethostbyname ($self->{'host'})).":$self->{'port'})"
            " ($self->{'hostip'}:$self->{'port'})" . ( ( $params->{'ip'} and $params->{'udp'} ) ? '' : "\x05$params->{'nick'}" )
            ),
#. ( $self->{'M'} eq 'P' ? " ($self->{'host'}:$self->{'port'})\x05$params->{'nick'}" : '' ),
#{ SI => -s $self->{'share_tth'}{ $params->{TR} },SL => $self->{INF}{SL},FN => $self->adc_path_encode( $self->{'share_tth'}{ $params->{TR} } ),=> $params->{TO} || $self->make_token($peerid),TR => $params->{TR}}
        );
        if ( $params->{'ip'} and $params->{'udp'} ) {
          $self->send_udp( $params->{'ip'}, $params->{'udp'}, $self->{'cmd_bef'} . join ' ', @_ );
        } else {
          $self->cmd(@_);
        }
      }
#'SR', ( $self->{'M'} eq 'P' ? "Hub:$self->{'Nick'}" : "$self->{'myip'}:$self->{'myport_udp'}" ),        join '?',
#Hub:	[Outgoing][80.240.208.42:4111]	 	$SR prrrrroo0 distr\s60\games\10598_paintball2.zip621237 1/2TTH:3TFVOXE2DS6W62RWL2QBEKZBQLK3WRSLG556ZCA (80.240.208.42:4111)breathe|
#$SR prrrrroo0 distr\moscow\mom\Mo\P\Paintball.htm1506 1/2TTH:NRRZNA5MYJSZGMPQ634CPGCPX3ZBRLKHAACPAFQ (80.240.208.42:4111)breathe|
#$SR prrrrroo0 distr\moscow\mom\Map\P\Paintball.htm3966 1/2TTH:QLRRMET6MSNJTIRKBDLQYU6RMI5QVZDZOGAXEXA (80.240.208.42:4111)breathe|
#$SR ILICH ЕГТС_07_2007\bases\sidhouse.DBF120923801 6/8TTH:4BAKR7LLXE65I6S4HASIXWIZONBEFS7VVZ7QQ2Y (80.240.211.183:411)
#$SR gellarion7119 MuZonnO\Mark Knopfler - Get Lucky (2009)\mark_knopfler_-_you_cant_beat_the_house.mp36599140 7/7TTH:IDPHZ4AJIIWDYOFEKCCVJUNVIPGSGTYFW5CGEQQ (80.240.211.183:411)
#$SR 13th_day Картинки\еще девки\sacrifice_penthouse02.jpg62412 0/20TTH:GHMWHVBKRLF52V26VFO4M4RUQ65NC3YKWIW7FPI (80.240.211.183:411)
#DIRECT:
#$SR server1 server\Unsorted\Desperate.Housewives.S04.720p.HDTV.x264\desperate.housewives.s04e03.720p.hdtv.x264.Rus.Eng.mkv1194423977 2/2TTH:6YWRGDXNQJEOGSB4Q7Y3Y7XRM7EXPLUK7GBRJ3A (80.240.211.183:411)
#$SR MikMEBX Deep purple\1980-1988\08-The House Of Blue Light.1987 10/10[ f12p.ru ][ F12P-HUB ] - день единства... вспомните хорошее и улыбнитесь друг другу.. пусть это будет днем гармонии (80.240.211.183)
#PASSIVE
#$SR ILICH ЕГТС_07_2007\bases\sidhouse.DBF120923801 6/8TTH:4BAKR7LLXE65I6S4HASIXWIZONBEFS7VVZ7QQ2Y (80.240.211.183:411)
#$SR gellarion7119 MuZonnO\Mark Knopfler - Get Lucky (2009)\mark_knopfler_-_you_cant_beat_the_house.mp36599140 7/7TTH:IDPHZ4AJIIWDYOFEKCCVJUNVIPGSGTYFW5CGEQQ (80.240.211.183:411)
#$SR SALAGA Видео\Фильмы\XXX\xxx Penthouse.avi732665856 0/5TTH:3OFCM6GPQZNBNAMV6SRDFHFPK2X76EO6UCIO7ZQ (80.240.211.183:411)
      return $params;
    },
    'SR' => sub {
      my $self = shift if ref $_[0];
#$self->log( 'dev', "SR", @_ , 'parent=>', $self->{parent}, 'h=', $self->{handler}, Dumper($self->{handler}), 'ph=', $self->{parent}{handler}, Dumper($self->{parent}{handler}), ) if $self;
      $self->make_hub();
      my $params = { 'time' => int( time() ), 'hub' => $self->{'hub_name'}, };
      ( $params->{'nick'}, $params->{'str'} ) = split / /, $_[0], 2;
      $params->{'str'} = [ split /\x05/, $params->{'str'} ];
      $params->{'file'} = shift @{ $params->{'str'} };
      ( $params->{'filename'} ) = $params->{'file'} =~ m{([^\\]+)$};
      ( $params->{'ext'} )      = $params->{'filename'} =~ m{[^.]+\.([^.]+)$};
      ( $params->{'size'}, $params->{'slots'} )  = split / /, shift @{ $params->{'str'} };
      ( $params->{'tth'},  $params->{'ipport'} ) = split / /, shift @{ $params->{'str'} };
      ( $params->{'tth'}, $params->{'ipport'} ) = ( $params->{'size'}, $params->{'slots'} ) unless $params->{'tth'};
      ( $params->{'target'} ) = shift @{ $params->{'str'} };
      $params->{'tth'} =~ s/^TTH://;
      ( $params->{'ipport'}, $params->{'ip'}, $params->{'tcp'} ) = $params->{'ipport'} =~ /\(((\S+):(\d+))\)/;
      delete $params->{'str'};
      #( $params->{'slotsopen'}, $params->{'S'} ) = split /\//, $params->{'slots'};
      #$params->{'slotsfree'} = $params->{'S'} - $params->{'slotsopen'};
      ( $params->{'slotsfree'}, $params->{'S'} ) = split /\//, $params->{'slots'};
      #$params->{'slotsfree'} = $params->{'S'} - $params->{'slotsopen'};
      $params->{'string'} = $self->{'search_last_string'};
      $self->{'NickList'}{ $params->{'nick'} }{$_} = $params->{$_} for qw(S ip tcp);
      $self->{'PortList'}->{ $params->{'ip'} }     = $params->{'tcp'};
      $self->{'IpList'}->{ $params->{'ip'} }       = $self->{'NickList'}{ $params->{'nick'} };
      $params->{'TR'}                              = $params->{'tth'};
      $params->{FN}                                = $params->{'filename'};
      my $peerid = $params->{'nick'};
      $params->{CID} = $peerid;
      #($params->{'file'}) = $params->{FN} =~ m{([^\\/]+)$};
      my $wdl = $self->{'want_download'}{ $params->{'TR'} } || $self->{'want_download'}{ $params->{'filename'} };
      if ($wdl) {    #exists $self->{'want_download'}{ $params->{'TR'} } ) {
                     #$self->{'want_download'}{ $params->{'TR'} }
        $wdl->{$peerid} = $params;    #maybe not all
        if ( $params->{'filename'} ) { ++$self->{'want_download_filename'}{ $params->{TR} }{ $params->{'filename'} }; }
        $self->{'want_download'}{ $params->{TR} }{$peerid} = $params;    # _tth_from
      }
      return $params;
    },
    'UserCommand' => sub {
      my $self = shift if ref $_[0];
    },
    #};
  );
  $self->{'parse'}{$_} ||= $_{$_} for keys %_;

=COMMANDS








=cut  

  #$self->{'cmd'} = {
  local %_ = (
    'connect_aft' => sub {
      my $self = shift if ref $_[0];
      #$self->log( 'dbg', "nothing to do after connect");
    },
    'chatline' => sub {
      my $self = shift if ref $_[0];
      for (@_) {
        if ( $self->{'min_chat_delay'} and ( time - $self->{'last_chat_time'} < $self->{'min_chat_delay'} ) ) {
          $self->log( 'dbg', 'sleep', $self->{'min_chat_delay'} - time + $self->{'last_chat_time'} );
          $self->wait_sleep( $self->{'min_chat_delay'} - time + $self->{'last_chat_time'} );
        }
        $self->{'last_chat_time'} = time;
        $self->log(
          'dcdmp',
          "($self->{'number'}) we send [",
          "<$self->{'Nick'}> $_|",
          "]:", $self->send("<$self->{'Nick'}> $_|"), $!
        );
      }
    },
    'To' => sub {
      my $self = shift if ref $_[0];
      my $to = shift;
      $self->sendcmd( 'To:', $to, "From: $self->{'Nick'} \$<$self->{'Nick'}> $_" ) for (@_);
    },
    'Key' => sub {
      my $self = shift if ref $_[0];
      $self->sendcmd( 'Key', $_[0] );
    },
    'ValidateNick' => sub {
      my $self = shift if ref $_[0];
      $self->sendcmd( 'ValidateNick', $self->{'Nick'} );
    },
    'Version' => sub {
      my $self = shift if ref $_[0];
      $self->sendcmd( 'Version', $self->{'Version'} );
    },
    'MyINFO' => sub {
      my $self = shift if ref $_[0];
      $self->sendcmd( 'MyINFO', '$ALL', $self->myinfo() );
    },
    'GetNickList' => sub {
      $self->sendcmd('GetNickList');
    },
    'GetINFO' => sub {
      my $self = shift if ref $_[0];
      @_ = grep { $self->{'NickList'}{$_}{'online'} and !$self->{'NickList'}{$_}{'info'} } keys %{ $self->{'NickList'} }
        unless @_;
      local $self->{'sendbuf'} = 1;
      $self->sendcmd( 'GetINFO', $_, $self->{'Nick'} ) for @_;
      $self->sendcmd();
    },
    'BotINFO' => sub {
      my $self = shift if ref $_[0];
      $self->sendcmd( 'BotINFO', $self->{botinfo} );
    },
    'ConnectToMe' => sub {
      my $self = shift if ref $_[0];
      $self->log( 'dcdbg', "cannot ConnectToMe from passive mode" ), return
        if $self->{'M'} eq 'P' and !$self->{'allow_passive_ConnectToMe'};
      $self->log( 'err', "please define myip" ), return unless $self->{'myip'};
      $self->sendcmd( 'ConnectToMe', $_[0], "$self->{'myip'}:$self->{'myport'}" );
    },
    'RevConnectToMe' => sub {
      my $self = shift if ref $_[0];
      $self->log( "send", ( 'RevConnectToMe', $self->{'Nick'}, $_[0] ), ref $_[0] );
      $self->sendcmd( 'RevConnectToMe', $self->{'Nick'}, $_[0] );
    },
    'MyPass' => sub {
      my $self = shift if ref $_[0];
      my $pass = ( $_[0] or $self->{'Pass'} );
      $self->sendcmd( 'MyPass', $pass ) if $pass;
    },
    'Supports' => sub {
      my $self = shift if ref $_[0];
      $self->sendcmd( 'Supports', $self->supports() || return );
    },
    'Quit' => sub {
      my $self = shift if ref $_[0];
      $self->sendcmd( 'Quit', $self->{'Nick'} );
      $self->disconnect();
    },
    'SR' => sub {
      my $self = shift if ref $_[0];
      $self->sendcmd( 'SR', @_ );
    },
    'Search' => sub {
      my $self = shift if ref $_[0];
      #$self->log('devsearch', "mode=[$self->{'M'}]");
      $self->sendcmd( 'Search', ( $self->{'M'} eq 'P' ? "Hub:$self->{'Nick'}" : "$self->{'myip'}:$self->{'myport_udp'}" ),
        join '?', @_ );
    },
    'search_nmdc' => sub {
      my $self = shift if ref $_[0];
      local @_ = @_;
      $_[0] =~ tr/ /$/;
      @_ = ( ( 'F', 'T', '0', undef )[ 0 .. 3 - $#_ ], reverse @_ );
      $_[3] ||= ( $_[4] =~ s/^(TTH:)?([A-Z0-9]{39})$/TTH:$2/ ? '9' : '1' ) unless defined $_[3];
      #
      #$self->cmd( 'search_buffer', 'F', 'T', '0', '1', @_ );
      $self->search_buffer(@_);
    },
    'search_tth' => sub {
      my $self = shift if ref $_[0];
      $self->{'search_last_string'} = undef;
      $self->search_nmdc(@_);
    },
    'search_string' => sub {
      my $self = shift if ref $_[0];
      #my $string = $_[0];
      $self->{'search_last_string'} = $_[0];    #$string;
                                                #$string =~ tr/ /$/;
      $self->search_nmdc(@_);
    },
    'search_send' => sub {
      my $self = shift if ref $_[0];
      #$self->log( 'devsearchsend', "$self->{'M'} ne 'P' and $self->{'myip'} and $self->{'myport_udp'}" );
      $self->sendcmd(
        'Search', (
          ( $self->{'M'} ne 'P' and $self->{'myip'} and $self->{'myport_udp'} )
          ? "$self->{'myip'}:$self->{'myport_udp'}"
          : 'Hub:' . $self->{'Nick'}
        ),
        join '?',
        @{ $_[0] || $self->{'search_last'} }
      );
    },
    #
    'stat_hub' => sub {
      my $self = shift if ref $_[0];
      local %_;
      #for my $w qw(SS) {
      #++$_{UC},
      local @_ = grep { length $_ and $_ ne $self->{'Nick'} } keys %{ $self->{'NickList'} };
      $_{SS} += $self->{'NickList'}{$_}{'sharesize'} for @_;
      #}
      $_{UC} = @_;
      return \%_;
    },
    #};
  );
  $self->{'cmd'}{$_} ||= $_{$_} for keys %_;
  #$self->log( 'dev', "0making listeners [$self->{'M'}]" );
  if ( $self->{'M'} eq 'A' or !$self->{'M'} ) {
    #$self->log( 'dev', "making listeners: tcp, class=", $self->{'incomingclass'} );
    $self->{'clients'}{'listener_tcp'} = $self->{'incomingclass'}->new(
      #%$self, $self->clear(),
      #'want'        => \%{ $self->{'want'} },
      #'NickList'    => \%{ $self->{'NickList'} },
      #'IpList'      => \%{ $self->{'IpList'} },
      #'PortList'    => \%{ $self->{'PortList'} },
      #'handler'     => \%{ $self->{'handler'} },
      #'share_tth'      => $self->{'share_tth'},
      'myport'      => $self->{'myport'},
      'auto_listen' => 1,
      'parent'      => $self,
    );
    $self->{'myport'} = $self->{'myport_tcp'} = $self->{'clients'}{'listener_tcp'}{'myport'};
    $self->log( 'err', "cant listen tcp (file transfers)" ) unless $self->{'myport_tcp'};
    #$self->log( 'dev', "making listeners: udp" );
    $self->{'clients'}{'listener_udp'} = $self->{'incomingclass'}->new(
      #%$self, $self->clear(),
      'parent' => $self, 'Proto' => 'udp', 'myport' => $self->{myport_udp},
      #?    'want'     => \%{ $self->{'want'} },
      #?    'NickList' => \%{ $self->{'NickList'} },
      #?    'IpList'   => \%{ $self->{'IpList'} },
      #?    'PortList' => \%{ $self->{'PortList'} },
      #'handler' => \%{ $self->{'handler'} },
      #'handler' => $self->{'handler'} ,
      #$self->{'clients'}{''} = $self->{'incomingclass'}->new( %$self, $self->clear(),
      #'LocalPort'=>$self->{'myport'},
      #'debug'=>1,
      #'nonblocking' => 0,
      'parse' => {
        'SR'  => $self->{'parse'}{'SR'},
        'PSR' => sub {                     #U
          my $self = shift if ref $_[0];
          #my $self =  ref $_[0] ? shift() : $self;
          $self->log( 'dev', "PSR", @_ ) if $self;
        },
        'UPSR' => sub {                    # TODO
          my $self = shift if ref $_[0];
          #my $self =  ref $_[0] ? shift() : $self;
          #!$self->log( 'dev', "UPSR", 'udp' ) if $self;
          for ( split /\n+/, $_[0] ) { return $self->parser($_) if /^\$SR/; }
          #$self->log( 'dev', "UPSR", @_ ) if $self;
        },
#2008/12/14-13:30:50 [3] rcv: welcome UPSR FQ2DNFEXG72IK6IXALNSMBAGJ5JAYOQXJGCUZ4A NIsss2911 HI81.9.63.68:4111 U40 TRZ34KN23JX2BQC2USOTJLGZNEWGDFB327RRU3VUQ PC4 PI0,64,92,94,100,128,132,135 RI64,65,66,67,68,68,69,70,71,72
#UPSR CDARCZ6URO4RAZKK6NDFTVYUQNLMFHS6YAR3RKQ NIAspid HI81.9.63.68:411 U40 TRQ6SHQECTUXWJG5ZHG3L322N5B2IV7YN2FG4YXFI PC2 PI15,17,20,128 RI128,129,130,131
#$SR [Predator]Wolf DC++\Btyan Adams - Please Forgive Me.mp314217310 18/20TTH:G7DXSTGPHTXSD2ZZFQEUBWI7PORILSKD4EENOII (81.9.63.68:4111)
#2008/12/14-13:30:50 welcome UPSR FQ2DNFEXG72IK6IXALNSMBAGJ5JAYOQXJGCUZ4A NIsss2911 HI81.9.63.68:4111 U40 TRZ34KN23JX2BQC2USOTJLGZNEWGDFB327RRU3VUQ PC4 PI0,64,92,94,100,128,132,135 RI64,65,66,67,68,68,69,70,71,72
#UPSR CDARCZ6URO4RAZKK6NDFTVYUQNLMFHS6YAR3RKQ NIAspid HI81.9.63.68:411 U40 TRQ6SHQECTUXWJG5ZHG3L322N5B2IV7YN2FG4YXFI PC2 PI15,17,20,128 RI128,129,130,131
#$SR [Predator]Wolf DC++\Btyan Adams - Please Forgive Me.mp314217310 18/20TTH:G7DXSTGPHTXSD2ZZFQEUBWI7PORILSKD4EENOII (81.9.63.68:4111)
      },
      'auto_listen' => 1,
      'parent'      => $self,
    );
    $self->{'myport_udp'} = $self->{'clients'}{'listener_udp'}{'myport'};
    $self->log( 'err', "cant listen udp (search repiles)" ) unless $self->{'myport_udp'};
  }

=z
  $self->log( 'dev', "making listeners: http" );
    $self->{'clients'}{'listener_http'} = Net::DirectConnect::http->new(
      %$self, $self->clear(),
#'want'     => \%{ $self->{'want'} },
#'NickList' => \%{ $self->{'NickList'} },
#'IpList'   => \%{ $self->{'IpList'} },
##      'PortList' => \%{ $self->{'PortList'} },
      'handler'  => \%{ $self->{'handler'} },
#$self->{'clients'}{''} = $self->{'incomingclass'}->new( %$self, $self->clear(),
      #'LocalPort'=>$self->{'myport'},
      #'debug'=>1,
      'auto_listen' => 1,
    );
    $self->{'myport_http'}  = $self->{'clients'}{'listener_http'}{'myport'};
    $self->log( 'err', "cant listen http" )
      unless $self->{'myport_http'};
=cut

  $self->{'handler_int'}{'disconnect_bef'} = sub {
    #delete $self->{'sid'};
    #$self->log( 'dev', 'disconnect int' ) if $self and $self->{'log'};
  };
}
1;
