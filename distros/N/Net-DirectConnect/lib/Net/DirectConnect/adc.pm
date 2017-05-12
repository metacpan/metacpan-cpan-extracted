#$Id: adc.pm 794 2011-06-17 17:48:15Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/adc.pm $
package    #hide from cpan
  Net::DirectConnect::adc;
use strict;
use Time::HiRes qw(time sleep);
use Socket;
use Data::Dumper;    #dev only
$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
#eval "use MIME::Base32 qw( RFC ); 1;"        or print join ' ', ( 'err', 'cant use', $@ );
#use MIME::Base32 qw( RFC );
use Net::DirectConnect;
#use Net::DirectConnect::clicli;
use Net::DirectConnect::http;
#use Net::DirectConnect::httpcli;
use lib::abs('pslib');
use psmisc;          # REMOVE
no warnings qw(uninitialized);
our $VERSION = ( split( ' ', '$Revision: 794 $' ) )[1];
use base 'Net::DirectConnect';
our %codesSTA = (
  '00' => 'Generic, show description',
  'x0' => 'Same as 00, but categorized according to the rough structure set below',
  '10' => 'Generic hub error',
  '11' => 'Hub full',
  '12' => 'Hub disabled',
  '20' => 'Generic login/access error',
  '21' => 'Nick invalid',
  '22' => 'Nick taken',
  '23' => 'Invalid password',
  '24' => 'CID taken',
  '25' =>
'Access denied, flag "FC" is the FOURCC of the offending command. Sent when a user is not allowed to execute a particular command',
  '26' => 'Registered users only',
  '27' => 'Invalid PID supplied',
  '30' => 'Kicks/bans/disconnects generic',
  '31' => 'Permanently banned',
  '32' =>
'Temporarily banned, flag "TL" is an integer specifying the number of seconds left until it expires (This is used for kick as well…).',
  '40' => 'Protocol error',
  '41' =>
qq{Transfer protocol unsupported, flag "TO" the token, flag "PR" the protocol string. The client receiving a CTM or RCM should send this if it doesn't support the C-C protocol. },
  '42' =>
qq{Direct connection failed, flag "TO" the token, flag "PR" the protocol string. The client receiving a CTM or RCM should send this if it tried but couldn't connect. },
  '43' => 'Required INF field missing/bad, flag "FM" specifies missing field, "FB" specifies invalid field.',
  '44' => 'Invalid state, flag "FC" the FOURCC of the offending command.',
  '45' => 'Required feature missing, flag "FC" specifies the FOURCC of the missing feature.',
  '46' => 'Invalid IP supplied in INF, flag "I4" or "I6" specifies the correct IP.',
  '47' => 'No hash support overlap in SUP between client and hub.',
  '50' => 'Client-client / file transfer error',
  '51' => 'File not available',
  '52' => 'File part not available',
  '53' => 'Slots full',
  '54' => 'No hash support overlap in SUP between clients.',
);
#eval "use Net::DirectConnect::TigerHash; 1;" or print join ' ', ( 'err', 'cant use', $@ );
#eval q{use Net::DirectConnect::TigerHash;};

=no
sub base32 ($) {
  #eval {
  MIME::Base32::encode( $_[0] );
  #; } || @_;
}

sub tiger ($) {
  local ($_) = @_;
  #use Mhash qw( mhash mhash_hex MHASH_TIGER);
  #eval "use MIME::Base32 qw( RFC ); use Digest::Tiger;" or $self->log('err', 'cant use', $@);
  #$_.=("\x00"x(1024 - length $_));        print ( 'hlen', length $_);
  #Digest::Tiger::hash($_);
  eval { Net::DirectConnect::TigerHash::tthbin($_); }
    #mhash(Mhash::MHASH_TIGER, $_);
}
sub hash ($) { base32( tiger( $_[0] ) ); }
=cut

#sub init {  my $self = shift;

=cu
sub new {
#psmisc::printlog('adc::new', @_);
##  my $self = ref $_[0] ? shift() : bless {}, $_[0];
  my $self = ref $_[0] ? shift() : Net::DirectConnect->new(
  #@_
  adcinit(bless({},shift),@_)
  ); #

#shift if $_[0] eq __PACKAGE__;
return $self;

}
=cut
sub func {
  my $self = shift if ref $_[0];
#warn 'func call';
  $self->SUPER::func(@_);
  %_ = ( 'ID_file' => 'ID', );
  $self->{$_} //= $_{$_} for keys %_;
  if ( Net::DirectConnect::use_try( 'MIME::Base32', 'RFC' ) ) {
    $self->{base_encode} ||= sub {
      shift if ref $_[0];
      MIME::Base32::encode_rfc3548(@_);
    };
    $self->{base_decode} ||= sub {
      shift if ref $_[0];
      MIME::Base32::decode_rfc3548(@_);
    };
  } else {
    $self->log( 'err', 'cant use MIME::Base32' );
  }
  if ( Net::DirectConnect::use_try('Net::DirectConnect::TigerHash') ) {
    $self->{hash} ||= sub { shift if ref $_[0]; Net::DirectConnect::TigerHash::tthbin( $_[0] ); };
    $self->{base_encode} ||= sub {
      shift if ref $_[0];
      Net::DirectConnect::TigerHash::toBase32( $_[0] );
    };
    $self->{base_decode} ||= sub {
      shift if ref $_[0];
      Net::DirectConnect::TigerHash::fromBase32( $_[0] );
    };
  } else {
    $self->log( 'err', 'cant use Net::DirectConnect::TigerHash' );
  }
  $self->{hash_base} ||= sub { shift if ref $_[0]; $self->base_encode( $self->hash( $_[0] ) ) };
  #sub hash ($) { base32( tiger( $_[0] ) ); }
  $self->{cmd_direct} ||= sub {
    my $self = shift if ref $_[0];
    my $peerid = shift;
    local $self->{'host'} = $self->{'peers'}{$peerid}{'INF'}{I4}, local $self->{'port'} = $self->{'peers'}{$peerid}{'INF'}{U4}
      if $self->{'peers'}{$peerid}{'INF'}{I4} and $self->{'peers'}{$peerid}{'INF'}{U4};
    $self->cmd(@_);
  };
  $self->{ID_get} ||= sub {
    #sub ID_get {
    my $self = shift if ref $_[0];
    if ( -s $self->{'ID_file'} ) { $self->{'ID'} ||= psmisc::file_read( $self->{'ID_file'} ); }
    unless ( $self->{'ID'} ) {
      $self->{'ID'} ||= join ' ', 'perl', $self->{'myip'}, $VERSION, $0, $self->{'INF'}{'NI'}, time,
        '$Id: adc.pm 794 2011-06-17 17:48:15Z pro $';
      psmisc::file_rewrite( $self->{'ID_file'}, $self->{'ID'} );
    }
    $self->{'PID'}       ||= $self->hash( $self->{'ID'} );
    $self->{'CID'}       ||= $self->hash( $self->{'PID'} );
    $self->{'INF'}{'PD'} ||= $self->base_encode( $self->{'PID'} );
    $self->{'INF'}{'ID'} ||= $self->base_encode( $self->{'CID'} );
    return $self->{'ID'};
  };
  $self->{INF_generate} ||= sub {
    my $self = shift if ref $_[0];
    #$self->log( 'dev', 'ing_generate', $self->{'myport'},$self->{'myport_udp'}, $self->{'myip'});
    #$self->{'clients'}{'listener_udp'}
    $self->{'INF'}{'NI'} ||= $self->{'Nick'} || 'perlAdcDev';
    $self->{'PID'} ||= MIME::Base32::decode $self->{'INF'}{'PD'} if $self->{'INF'}{'PD'};
    $self->{'CID'} ||= MIME::Base32::decode $self->{'INF'}{'ID'} if $self->{'INF'}{'ID'};
    $self->ID_get();
    $self->{'INF'}{'SID'} ||= $self->{broadcast} ? $self->{'INF'}{'ID'} : substr $self->{'INF'}{'ID'}, 0, 4;
#sid
#$self->log( 'id gen',"iID=$self->{'INF'}{'ID'} iPD=$self->{'INF'}{'PD'} PID=$self->{'PID'} CID=$self->{'CID'} ID=$self->{'ID'}" );
    $self->{'INF'}{'SL'} ||= $self->{'S'}         || '2';
    $self->{'INF'}{'SS'} ||= $self->{'sharesize'} || 20025693588;
    $self->{'INF'}{'SF'} ||= 30999;
    $self->{'INF'}{'HN'} ||= $self->{'H'}         || 1;
    $self->{'INF'}{'HR'} ||= $self->{'R'}         || 0;
    $self->{'INF'}{'HO'} ||= $self->{'O'}         || 0;
    $self->{'INF'}{'VE'} ||= $self->{'client'} . $self->{'V'}
      || 'perl'
      . $Net::DirectConnect::VERSION . '_'
      . $VERSION;    #. '_' . ( split( ' ', '$Revision: 794 $' ) )[1];    #'++\s0.706';
    $self->{'INF'}{'US'} ||= 10000;
    $self->{'INF'}{'U4'} ||= $self->{'myport_udp'} || $self->{'myport'};    #maybe if broadcast only
    $self->{'INF'}{'I4'} ||= $self->{'myip'};
    $self->{'INF'}{'SU'} ||= 'ADC0,TCP4,UDP4';
    return $self->{'INF'};
  };
}

sub init {
  my $self = shift if ref $_[0];
  #shift if $_[0] eq __PACKAGE__;
  #print "adcinit SELF=", $self, "REF=", ref $self, "  P=", @_, "package=", __PACKAGE__, "\n\n";
  #$self->SUPER::new();
  #%$self = (
  #%$self,
  local %_ = (
    'Nick'     => 'NetDCBot',
    'port'     => 412,
    'host'     => 'localhost',
    'protocol' => 'adc',
    'adc'      => 1,
    #'Pass' => '',
    #'key'  => 'zzz',
    #'auto_wait'        => 1,
    'reconnects' => 5, 'search_every' => 10, 'search_every_min' => 10, 'auto_connect' => 1,
    #ADC
    'connect_protocol' => 'ADC/0.10', 'message_type' => 'H',
    #@_,
    'incomingclass' => __PACKAGE__,                               #'Net::DirectConnect::adc',
    no_print        => { 'INF' => 1, 'QUI' => 1, 'SCH' => 1, },
    'ID_file'       => 'ID',
    'cmd_bef'       => undef,
    'cmd_aft'       => "\x0A",
    'auto_say_cmd'  => [qw(MSG)],
  );
  $self->{$_} //= $_{$_} for keys %_;
  #!exists $self->{$_} ? $self->{$_} ||= $_{$_} : () for keys %_;
  #print 'adc init now=',Dumper $self;
  $self->{'periodic'}{ __FILE__ . __LINE__ } = sub { $self->cmd( 'search_buffer', ) if $self->{'socket'}; };
  #$self->log( $self, 'inited', "MT:$self->{'message_type'}", ' with', Dumper \@_ );
  #$self->baseinit();    #if ref $self eq __PACKAGE__;
  #$self->log( $self, 'inited3', "MT:$self->{'message_type'}", ' with' );
  $self->{SUPAD}{H}{$_} = $_ for qw(BAS0 BASE TIGR UCM0 BLO0 BZIP );
  $self->{SUPAD}{I}{$_} = $_ for qw(BASE TIGR BZIP);
  $self->{SUPAD}{C}{$_} = $_ for qw(BASE TIGR BZIP);
  if ( $self->{'broadcast'} ) { $self->{SUPAD}{B} = $self->{SUPAD}{C}; }
  if ( $self->{'hub'} ) {
    #$self->log( 'dev', 'hub settings apply');
    $self->{'auto_connect'}         = 0;
    $self->{'auto_listen'}          = 1;
    $self->{'status'}               = 'working';
    $self->{'disconnect_recursive'} = 1;
  }
  #if ($self->{'message_type'} eq 'H') {
  #  $self->{'disconnect_recursive'} = 1;
  #}
  #$self->{$_} ||= $self->{'parent'}{$_} ||= {} for qw(peers peers_sid peers_cid want share_full share_tth);
  $self->{$_} ||= $self->{'parent'}{$_} for qw(ID PID CID INF SUPAD myport);
# Proto
  $self->{message_type} = 'B' if $self->{'broadcast'};
  $self->func();
#warn "IG:$self->{INF_generate}";
  $self->INF_generate();
  $self->{'parse'} ||= {
#
#=================
#ADC dev
#
#'ISUP' => sub { }, 'ISID' => sub { $self->{'INF'}{'SID'} = $_[0] }, 'IINF' => sub { $self->cmd('BINF') },    'IQUI' => sub { },    'ISTA' => sub { $self->log( 'dcerr', @_ ) },
    'SUP' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid ) = @{ shift() };
      #for my $feature (split /\s+/, $_[0])
      #$self->log( 'adcdev', $dst, 'SUP:', @_ , "SID:n=$self->{'number'}; $peerid");
      #=z
      #if $self->{''}
      if ( $dst eq 'H' ) {
        $self->cmd( 'I', 'SUP' );
        #$peerid ||= join '', map {} 1..4
        $peerid ||= $self->base_encode(
          pack 'S', $self->{'number'}
            #+ int rand 100
        );
        $self->log( 'adcdevsid', "pack [$self->{'number'}] = [$peerid]" );
        $peerid = ( 'A' x ( 4 - length $peerid ) ) . $peerid;
        $self->{'peerid'} ||= $peerid;
        $self->log( 'adcdev', $dst, 'SUP:', @_, "SID:n=$self->{'number'}; $peerid=$self->{'peerid'}" );
        $self->cmd( 'I', 'SID', $peerid );
        $self->cmd( 'I', 'INF', );    #$self->{'peers'}{$_}{'INF'}
                                      #for keys %{$self->{'peers'}};
        $self->{'status'} = 'connected';
      } elsif ( $dst eq 'C' ) {
        $self->cmd( $dst, 'INF', ) unless $self->{count_sendcmd}{CINF};
      }
      $peerid ||= '';
      for ( $self->adc_strings_decode(@_) ) {
        if   ( (s/^(AD|RM)//)[0] eq 'RM' ) { delete $self->{'peers'}{$peerid}{'SUP'}{$_}; }
        else                               { $self->{'peers'}{$peerid}{'SUP'}{$_} = 1; }
      }
      #=cut

=z
      my $params = $self->adc_parse_named(@_);
      for ( keys %$params ) {
        delete $self->{'peers'}{$peerid}{'SUP'}{ $params->{$_} } if $_ eq 'RM';
        $self->{'peers'}{$peerid}{'SUP'}{ $params->{$_} } = 1 if $_ eq 'AD';
      }
=cut      

      #$self->log('adcdev', 'SUPans:', $peerid, $self->{'peers'}{$peerid}{'INF'}{I4}, $self->{'peers'}{$peerid}{'INF'}{U4});
      #local $self->{'host'} = $self->{'peers'}{$peerid}{'INF'}{I4}; #can answer direct
      #local $self->{'port'} = $self->{'peers'}{$peerid}{'INF'}{U4};
      #$self->cmd( 'D', 'INF', ) if $self->{'broadcast'} and $self->{'broadcast_INF'};
      #$self->cmd_direct( 'D', 'INF', ) if $self->{'broadcast'} and $self->{'broadcast_INF'};
      return $self->{'peers'}{$peerid}{'SUP'};
    },
    'SID' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid, $toid ) = @{ shift() };
      return $self->{'INF'}{'SID'} unless $dst eq 'I';
      $self->{'INF'}{'SID'} = $_[0];
      $self->log( 'adcdev', 'SID:', $self->{'INF'}{'SID'} );
      return $self->{'INF'}{'SID'};
    },
    'INF' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid, $toid ) = @{ shift() };
      #test $_[1] eq 'I'!
      #$self->log('adcdev', '0INF:', "[d=$dst,p=$peerid]", join ':', @_);
      #$self->log('adcdev', 'INF1', $peerid, @_);
      my $params = $self->adc_parse_named(@_);
      #$self->log('adcdev', 'INF2', $peerid, @_);
      #for (@_) {
      #s/^(\w\w)//;
      #my ($code)= $1;
      #$self->log('adcdev', 'INF:', $dst, $peerid, $toid, Dumper $params);
      #$self->{'peers'}{$peerid}{'INF'}{$code} = $_;
      #}
      my $peersid = $peerid;
      if ( $dst ne 'B' and $peerid ||= $params->{ID} ) {
        #$self->log('adcdev', 'INF:', "moving peer '' to $peerid");
        $self->{'peerid'} ||= $peerid;
        $self->{'peers'}{$peerid}{$_} = $self->{'peers'}{''}{$_} for keys %{ $self->{'peers'}{''} || {} };
        delete $self->{'peers'}{''};
      }
      my $sendbinf;
      if ( $self->{parent}{hub} and $dst eq 'B' ) {
        if ( !keys %{ $self->{'peers'}{$peerid}{'INF'} } ) {    #join
              #++$sendbinf;
              #$self->log( 'adcdev', 'FIRSTINF:', $peerid, Dumper $params, $self->{'peers'} );
          $self->cmd( 'B', 'INF', $_, $self->{'peers_sid'}{$_}{'INF'} ) for keys %{ $self->{'peers_sid'} };
        }
      }
      #$dst eq 'I' ?
      $self->log( 'adcdev', "ip change from [$params->{I4}] to [$self->{hostip}] " ), $params->{I4} = $self->{hostip}
        if $dst eq 'B' and $self->{parent}{hub} and $params->{I4} and $params->{I4} ne $self->{hostip};   #!$self->{parent}{hub}
      if (                                                                                                #$dst eq 'B' and
        $self->{broadcast}
        )
      {
        $self->log( 'adcdev',
          "ip change from [$params->{I4}] to [$self->{recv_hostip}:$self->{recv_port}] ($self->{recv_hostip}:$self->{port})" );
        #$params->{U4} = $self->{recv_port};
        $params->{U4} ||= $self->{port};
        $params->{I4} ||= $self->{recv_hostip};
      }
      if ( $peerid eq $self->{'INF'}{'SID'} and !$self->{myip} ) {
        $self->{myip} ||= $params->{I4};
        $self->{'INF'}{'I4'} ||= $params->{I4};
        $self->log( 'adcdev', "ip  detected: [$self->{myip}:$self->{myport}]" );
      }
      #my $first_seen;
      #$first_seen = 1 unless $self->{'peers'}{$peerid}{INF};
      #$self->log( 'adcdev',  "peer[$first_seen]: $peerid : $self->{'peers'}{$peerid}");
      $self->{'peers'}{$peerid}{'INF'}{$_} = $params->{$_} for keys %$params;
      $self->{'peers'}{$peerid}{'object'} = $self;
      $self->{'peers'}{ $params->{ID} }                              ||= $self->{'peers'}{$peerid};
      $self->{'peers'}{$peerid}{'SID'}                               ||= $peersid;
      $self->{'peers_sid'}{$peersid}                                 ||= $self->{'peers'}{$peerid};
      $self->{'peers_cid'}{ $self->{'peers'}{$peerid}{'INF'}{'ID'} } ||= $self->{'peers'}{$peerid};
      #$self->log( 'adcdev', 'INF:', $peerid, Dumper $params, $self->{'peers'} ) unless $peerid;
      #$self->log('adcdev', 'INF7', $peerid, @_);
      if ( $dst eq 'I' ) {
        $self->cmd( 'B', 'INF' );
        $self->{'status'} = 'connected';    #clihub
      } elsif ( $dst eq 'C' ) {
        $self->{'status'} = 'connected';    #clicli
        $self->cmd( $dst, 'INF' ) unless $self->{count_sendcmd}{CINF};
        if   ( $params->{TO} ) { }
        else                   { }
        $self->cmd('file_select');
        $self->cmd( $dst, 'GET' );
      }
      #$self->log('adcdev', 'INF8', $peerid, @_);
      #if ($sendbinf) { $self->cmd( 'B', 'INF', $_, $self->{'peers_sid'}{$_}{'INF'} ) for keys %{ $self->{'peers_sid'} }; }
      #$self->log('adcdev', 'INF9', $peerid, "H:$self->{parent}{hub}", @_);
      if ( $self->{parent}{hub} ) {
        my $params_send = \%$params;
        delete $params_send->{PD};
        $self->cmd_all( $dst, 'INF', $peerid, $self->adc_make_string($params_send) );
      }
      #$self->log('adcdev', "first_seen: $first_seen,$peerid ne $self->{'INF'}{'SID'} dst: $dst");
      if (    #$first_seen and
        $self->{'broadcast'} and $peerid ne $self->{'INF'}{'SID'} and $dst eq 'B'
        )
      {
        $self->cmd( 'D', 'INF', ) if $self->{'broadcast'};    # and $self->{'broadcast_INF'};
              #$self->cmd_direct( $peerid, 'D', 'INF', ) if $self->{'broadcast'} and $self->{'broadcast_INF'};
      }
      return $params;    #$self->{'peers'}{$peerid}{'INF'};
    },
    'QUI' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid ) = @{ shift() };
      #$peerid
      #$self->log( 'adcdev', 'QUI', $dst, $_[0], Dumper $self->{'peers'}{ $_[0] } );
      delete $self->{'peers_cid'}{ $self->{'peers'}{$peerid}{'INF'}{'ID'} };
      delete $self->{'peers_sid'}{$peerid};
      delete $self->{'peers'}{$peerid};    # or mark time
      undef;
    },
    'STA' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid ) = @{ shift() };
      #$self->log( 'dcerr', @_ );
      my $code = shift;
      $code =~ s/^(.)//;
      my $severity = $1;
#TODO: $severity :
#0 	Success (used for confirming commands), error code must be "00", and an additional flag "FC" contains the FOURCC of the command being confirmed if applicable.
#1 	Recoverable (error but no disconnect)
#2 	Fatal (disconnect)
#my $desc = $self->{'codesSTA'}{$code};
      @_ = $self->adc_strings_decode(@_);
      $self->log( 'adcdev', 'STA', $peerid, $severity, $code, @_, "=[$Net::DirectConnect::adc::codesSTA{$code}]" );
      return $severity, $code, $Net::DirectConnect::adc::codesSTA{$code}, @_;
    },
    'SCH' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid, @feature ) = @{ shift() };
      #$self->log( 'adcdev', 'SCH', ( $dst, $peerid, 'F=>', @feature ), 'S=>', @_ );
      $self->cmd_all( $dst, 'SCH', $peerid, @feature, @_ );
      my $params = $self->adc_parse_named(@_);
      #DRES J3F4 KULX SI0 SL57 FN/Joculete/logs/stderr.txt TRLWPNACQDBZRYXW3VHJVCJ64QBZNGHOHHHZWCLNQ TOauto
      my $found = $self->{'share_full'}{ $params->{TR} } || $self->{'share_full'}{ $params->{AN} };
      my $tth = $self->{'share_tth'}{$found};
      if (
#$self->{'share_full'}        and $params->{TR}        and exists $self->{'share_full'}{ $params->{TR} }        and -s $self->{'share_full'}{ $params->{TR} }
        $found
        )
      {
        my $foundshow = ( $found =~ m{^/} ? () : '/' ) . (
          #$self->{chrarset_fs}          ?
          #$self->{charset_fs} ne $self->{charset_protocol} ?
          Encode::encode $self->{charset_protocol}, Encode::decode $self->{charset_fs}, $found
            #: $found
        );
        $self->log( 'adcdev', 'SCH', ( $dst, $peerid, 'F=>', @feature ),
          $found, -s $found, -e $found, 'c=', $self->{chrarset_fs}, );
        local @_ = ( {
            SI => ( -s $found ) || -1,
            SL => $self->{INF}{SL},
            FN => $self->adc_path_encode($foundshow),
            TO => $params->{TO} || $self->make_token($peerid),
            TR => $params->{TR} || $tth,
          }
        );
        if ( $self->{'peers'}{$peerid}{INF}{I4} and $self->{'peers'}{$peerid}{INF}{U4} ) {
          $self->log(
            'dcdev', 'SCH', 'i=', $self->{'peers'}{$peerid}{INF}{I4},
            'u=', $self->{'peers'}{$peerid}{INF}{U4},
            'T==>', 'U' . 'RES ' . $self->adc_make_string( $self->{'INF'}{'ID'}, @_ )
          );
          $self->send_udp(
            $self->{'peers'}{$peerid}{INF}{I4}, $self->{'peers'}{$peerid}{INF}{U4},
            'U' . 'RES ' . $self->adc_make_string( $self->{'INF'}{'ID'}, @_ )    #. $self->{'cmd_aft'}
          );
        } else {
          $self->cmd( 'D', 'RES', $self->adc_make_string( $peerid, @_ ) );
        }
      }
      #$self->adc_make_string(@_);
      #TODO active send udp
      return $params;
      #TRKU2OUBVHC3VXUNOHO2BS2G4ECHYB6ESJUQPYFSY TO626120869 ]
      #TRQYKHJIZEPSISFF3T25DIGKEYI645Y7PGMSI7QII TOauto ]
      #ANthe ANhossboss TO3951841973 ]
      #FSCH ABWN +TCP4 TRKX55JDOFEBX32GLBSITTSY6KUCK4NMPU2R4XUII TOauto
    },
    'RES' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid, $toid ) = @{ shift() };
      #test $_[1] eq 'I'!
      $self->log( 'adcdev', '0RES:', "[d=$dst,p=$peerid,t=$toid]", join ':', @_ );
      my $params = $self->adc_parse_named(@_);
      #$self->log('adcdev', 'RES:',"[d=$dst,p=$peerid]",Dumper $params);
      if ( $dst eq 'D' and $self->{'parent'}{'hub'} and ref $self->{'peers'}{$toid}{'object'} ) {
        $self->{'peers'}{$toid}{'object'}->cmd( 'D', 'RES', $peerid, $toid, @_ );
      } else {
        #= $1 if
        #$params->{'FN'} =~ m{([^/\\]+)$};
        $params->{CID} = $peerid;
        ( $params->{'filename'} ) = $params->{FN} =~ m{([^\\/]+)$};
        my $wdl = $self->{'want_download'}{ $params->{'TR'} } || $self->{'want_download'}{ $params->{'filename'} };
        if ($wdl) {    #exists $self->{'want_download'}{ $params->{'TR'} } ) {
                       #$self->{'want_download'}{ $params->{'TR'} }
          $wdl->{$peerid} = $params;    #maybe not all
          if ( $params->{'filename'} ) { ++$self->{'want_download_filename'}{ $params->{TR} }{ $params->{'filename'} }; }
          $self->{'want_download'}{ $params->{TR} }{$peerid} = $params;    # _tth_from
        }
      }
      $params;
    },
    'MSG' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid ) = @{ shift() };
      #@_ = map {adc_string_decode} @_;
      $self->cmd_all( $dst, 'MSG', $peerid, @_ );
      @_ = $self->adc_strings_decode(@_);
      $self->log( 'adcdev', $dst, 'MSG', $peerid, "<" . $self->{'peers'}{$peerid}{'INF'}{'NI'} . '>', @_ );
      @_;
    },
    'RCM' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid, $toid ) = @{ shift() };
      $toid ||= shift;
      $self->log( 'dcdev', "( $dst, RCM, $peerid, $toid  me=[$self->{'INF'}{'SID'}] )", @_ );
      $self->cmd( $dst, 'CTM', $peerid, $_[0], $self->{'myport'}, $_[1], ) if $toid eq $self->{'INF'}{'SID'};
      if ( $dst eq 'D' and $self->{'parent'}{'hub'} and ref $self->{'peers'}{$toid}{'object'} ) {
        $self->{'peers'}{$toid}{'object'}->cmd( 'D', 'RCM', $peerid, $toid, @_ );
      }

=z      
	my $host= $self->{'peers'}{$toid}{I4};
	my $port= $self->{'peers'}{$toid}{U4}
       $self->{'clients'}{ $host . ':' . $port } = __PACKAGE__->new(
        #%$self, $self->clear(),
        'parent' => $self,
        'host'         => $host,
        'port'         => $port,
#'want'         => \%{ $self->{'want'} },
#'NickList'     => \%{ $self->{'NickList'} },
#'IpList'       => \%{ $self->{'IpList'} },
#'PortList'     => \%{ $self->{'PortList'} },
#'handler'      => \%{ $self->{'handler'} },
        'auto_connect' => 1,
      );
=cut

    },
    'CTM' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid, $toid ) = @{ shift() };
      $toid ||= shift;
      my ( $proto, $port, $token ) = @_;
      my $host = $self->{'peers'}{$peerid}{'INF'}{'I4'};
      $self->log( 'dcdev', "( $dst, CTM, $peerid, $toid ) - ($proto, $port, $token) me=$self->{'INF'}{'SID'}", );
      $self->log( 'dcerr', 'CTM: unknown host', "( $dst, CTM, $peerid, $toid ) - ($proto, $port, $token)" ) unless $host;
      $self->{'clients'}{ $self->{'peers'}{$peerid}{'INF'}{ID} or $host . ':' . $port } = __PACKAGE__->new(
        #%$self, $self->clear(),
        parent => $self, 'host' => $host, 'port' => $port,
        #'parse' => $self->{'parse'},
        #'cmd'   => $self->{'cmd'},
        #'want'  => $self->{'want'},
        #'want'         => \%{ $self->{'want'} },
        #'NickList'     => \%{ $self->{'NickList'} },
        #'IpList'       => \%{ $self->{'IpList'} },
        #'PortList'     => \%{ $self->{'PortList'} },
        #'handler'      => \%{ $self->{'handler'} },
        #'TO' => $token,
        'INF'          => { %{ $self->{'INF'} }, 'TO' => $token },
        'message_type' => 'C',
        'auto_connect' => 1,
        'reconnects'   => 0,
        no_listen      => 1,
      ) if $toid eq $self->{'INF'}{'SID'};
      if ( $dst eq 'D' and $self->{'parent'}{'hub'} and ref $self->{'peers'}{$toid}{'object'} ) {
        $self->{'peers'}{$toid}{'object'}->cmd( 'D', 'CTM', $peerid, $toid, @_ );
      }
    },
    'SND' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid, $toid ) = @{ shift() };
      #CSND file files.xml.bz2 0 6117
      $self->{'filetotal'} //= $_[2] + $_[3];
      return $self->file_open();
    },
    #CGET file TTH/YDIXOH7A3W233WTOQUET3JUGMHNBYNFZ4UBXGNY 637534208 6291456
    'GET' => sub {
      my $self = shift if ref $_[0];
      my ( $dst, $peerid, $toid ) = @{ shift() };
      $self->file_send_parse(@_);

=z
      if ( $_[0] eq 'file' ) {
        my $file = $_[1];
        if ( $file =~ s{^TTH/}{} ) { $self->file_send_tth( $file, $_[2], $_[3] ); }
        else {
          #$self->file_send($file, $_[2], $_[3]);
        }
      } else {
        $self->log( 'dcerr', 'SND', "unknown type", @_ );
      }
=cut

    },
  };

=COMMANDS








=cut  

  $self->{'cmd'} = {
    #move to main
    'search_send' => sub {
      my $self = shift if ref $_[0];
      $self->cmd_adc( 'B', 'SCH', @{ $_[0] || $self->{'search_last'} } );
#$self->send_udp(inet_ntoa(INADDR_BROADCAST), $self->{'dev_broadcast'}, $self->adc_make_string( 'BSCH', @{ $_[0] || $self->{'search_last'} })) if $self->{'dev_broadcast'};
    },
    'search_tth' => sub {
      my $self = shift if ref $_[0];
      $self->{'search_last_string'} = undef;
      $self->log( 'search_tth', @_ );
      local $_ = shift;
      if ( $self->{'adc'} ) { $self->search_buffer( { TO => $self->make_token(), TR => $_, @_ } ); }    #toauto
      else {
        #$self->cmd( 'search_buffer', 'F', 'T', '0', '9', 'TTH:' . $_[0] );
      }
    },
    'search_string' => sub {
      my $self = shift if ref $_[0];
      my $string = shift;
      if ( $self->{'adc'} ) {
        #$self->cmd( 'search_buffer', { TO => 'auto', map AN => $_, split /\s+/, $string } );
        $self->cmd( 'search_buffer', ( map { 'AN' . $_ } split /\s+/, $string ), { TO => $self->make_token(), @_ } );    #TOauto
      } else {
        #$self->{'search_last_string'} = $string;
        #$string =~ tr/ /$/;
        #$self->cmd( 'search_buffer', 'F', 'T', '0', '1', $string );
      }
    },
    #'make_hub' => sub {
    #my $self = shift if ref $_[0];
    #$self->{'hub'} ||= $self->{'host'} . ( ( $self->{'port'} and $self->{'port'} != 411 ) ? ':' . $self->{'port'} : '' );
    #},
    'nick_generate' => sub {
      my $self = shift if ref $_[0];
      $self->{'nick_base'} ||= $self->{'Nick'};
      $self->{'Nick'} = $self->{'nick_base'} . int( rand( $self->{'nick_random'} || 100 ) );
    },
    #
    #=================
    #ADC dev
    #
    'connect_aft' => sub {
      #print "RUNADC![$self->{'protocol'}:$self->{'adc'}]";
      my $self = shift if ref $_[0];
      #$self->log($self, 'connect_aft inited',"MT:$self->{'message_type'}", ' ');
      #{
      $self->cmd( $self->{'message_type'}, 'SUP' );
      #}
      if ( $self->{'broadcast'} ) { $self->cmd( $self->{'message_type'}, 'INF' ); }
      #else
    },
    'cmd_all' => sub {
      my $self = shift if ref $_[0];
      return if    #( $_[0] ne 'B' and $_[0] ne 'F' and $_[0] ne 'I' ) or
        !$self->{'parent'}{'hub'};
      $self->{'parent'}->sendcmd_all(@_);    #for keys %{ $self->{'peers_sid'} };
    },
    'SUP' => sub {
      my $self = shift if ref $_[0];
      my $dst = shift;
#$self->log($self, 'SUP inited',"MT:$self->{'message_type'}", "=== $dst");
#$self->{SUPADS} ||= [qw(BASE TIGR)] if $dst eq 'I'; #PING
#$self->{SUPADS} ||= [qw(BAS0 BASE TIGR UCM0 BLO0 BZIP )];    #PING ZLIG
#$self->{SUPRMS} ||= [qw()];
#$self->{SUP} ||= { ( map { $_ => 1 } @{ $self->{'SUPADS'} } ), ( map { $_ => 0 } @{ $self->{'SUPRMS'} } ) };
#$self->{'SUPAD'} ||= { map { $_ => 1 } @{ $self->{'SUPADS'} } };
#$self->cmd_adc( $dst, 'SUP', ( map { 'AD' . $_ } @{ $self->{'SUPADS'} } ), ( map { 'RM' . $_ } keys %{ $self->{'SUPRM'} } ), );
#$self->log( 'SUP', "sidp=[$self->{'INF'}{'SID'}]");
      {
        local $self->{'INF'}{'SID'} = undef unless $self->{'broadcast'};
        $self->cmd_adc(
          $dst, 'SUP',
          ( map { 'AD' . $_ } sort keys %{ $self->{SUPAD}{$dst} } ),
          ( map { 'RM' . $_ } sort keys %{ $self->{SUPRM}{$dst} } ),
        );
      }
      #$self->log( 'SUP', "sida=[$self->{'INF'}{'SID'}]");
      #ADBAS0 ADBASE ADTIGR ADUCM0 ADBLO0
    },
    'INF' => sub {
      my $self = shift if ref $_[0];
      my $dst = shift;
      #$self->{'BINFS'} ||= [qw(ID PD I4 I6 U4 U6 SS SF VE US DS SL AS AM EM NI DE HN HR HO TO CT AW SU RF)];
      if ( $self->{parent}{hub} ) {
        if ( $dst eq 'I' ) {
          $self->{'INF'} = { CT => 32, VE => 'perl' . $VERSION, NI => 'devhub', DE => 'hubdev', };
#IINF CT32 VEuHub/0.3.0-rc4\s(git:\sd2da49d...) NI"??????????\s?3\\14?" DE?????,\s??????,\s?????????.\s???\s????????\s-\s???\s????????.
        } elsif ( $dst eq 'B' ) {
          $self->cmd_adc    #sendcmd
            (
            $dst, 'INF',    #$self->{'INF'}{'SID'},
            @_,
            #map { $_ . $self->{'INF'}{$_} } $dst eq 'C' ? qw(ID TO) : sort keys %{ $self->{'INF'} }
            );
          return;
        }
      } else {
#$self->INF_generate();
#$self->{''} ||= $self->{''} || '';
#$self->sendcmd( $dst, 'INF', $self->{'INF'}{'SID'}, map { $_ . $self->{$_} } grep { length $self->{$_} } @{ $self->{'BINFS'} } );
      }
      #$self->log(Dumper $self);
      $self->cmd_adc        #sendcmd
        (
        $dst, 'INF',        #$self->{'INF'}{'SID'},
        map { $_ . $self->{'INF'}{$_} } grep { length $self->{'INF'}{$_} } $dst eq 'C' ? qw(ID TO)
        : @_ ? @_
        : (
          qw(ID I4 I6 U6 SS SF VE US DS SL AS AM EM NI HN HR HO TO CT SU RF), ( $self->{'message_type'} eq 'H' ? 'PD' : () )
          )                 #sort keys %{ $self->{'INF'} }
        );
     #grep { length $self->{$_} } @{ $self->{'BINFS'} } );
     #$self->cmd_adc( $dst, 'INF', $self->{'INF'}{'SID'}, map { $_ . $self->{$_} } grep { $self->{$_} } @{ $self->{'BINFS'} } );
     #BINF UUXX IDFXC3WTTDXHP7PLCCGZ6ZKBHRVAKBQ4KUINROXXI PDP26YAWX3HUNSTEXXYRGOIAAM2ZPMLD44HCWQEDY NIïûðûî SL2 SS20025693588
     #SF30999 HN2 HR0 HO0 VE++\s0.706 US5242 SUADC0
    },
    'GET' => sub {
      my $self = shift if ref $_[0];
      my $dst = shift;
      #$self->sendcmd( $dst, 'CTM', $self->{'connect_protocol'},@_);
      local @_ = @_;
      if ( !@_ ) {
        @_ = ( 'file', $self->{'filename'}, $self->{'file_recv_from'} || '0', $self->{'file_recv_to'} || '-1' )
          if $self->{'filename'};
        $self->log( 'err', "Nothing to get" ), return unless @_;
      }
      $self->cmd_adc( $dst, 'GET', @_ );
    },
    'stat_hub' => sub {
      my $self = shift if ref $_[0];
      local %_;
      for my $w (qw(SS SF)) {
        #$self->log( 'dev', 'calc', $_, $w),
        $_{$w} += $self->{'peers'}{$_}{INF}{$w} for grep { $_ and $_ ne $self->{'INF'}{'SID'} } keys %{ $self->{'peers_sid'} };
      }
      $_{UC} = keys %{ $self->{'peers'} };
      return \%_;
    },
  };

=auto    
      'CTM' => sub {
      my $self = shift if ref $_[0];
      my $dst = shift;
      #$self->sendcmd( $dst, 'CTM', $self->{'connect_protocol'},@_);
      $self->cmd_adc( $dst, 'CTM', @_ );
    },
     'RCM' => sub {
      my $self = shift if ref $_[0];
      my $dst = shift;
      #$self->sendcmd( $dst, 'CTM', $self->{'connect_protocol'},@_);
      $self->cmd_adc( $dst, 'RCM', @_ );
    },
    'SND' => sub {
      my $self = shift if ref $_[0];
      my $dst = shift;
      #$self->sendcmd( $dst, 'CTM', $self->{'connect_protocol'},@_);
      $self->cmd_adc( $dst, 'SND', @_ );
    },
=cut    

  $self->log( 'dev', "0making listeners [$self->{'M'}]:$self->{'no_listen'}; auto=$self->{'auto_listen'}" );
  unless ( $self->{'no_listen'} ) {
#$self->log( 'dev', 'nyportgen',"$self->{'M'} eq 'A' or !$self->{'M'} ) and !$self->{'auto_listen'} and !$self->{'incoming'}" );
    if (
      #( $self->{'M'} eq 'A' or !$self->{'M'} )  and
      !$self->{'incoming'}
        and !$self->{'auto_listen'}
      )
    {
      #$self->log( 'dev', __FILE__, __LINE__, "  myptr", $self->{'auto_listen'}, $self->{broadcast});
      if (
        #!$self->{'auto_listen'} or    #$self->{'Proto'} ne 'tcp'
        
        $self->{broadcast}
        )
      {
        #$self->log( 'dev', __FILE__, __LINE__, "  myptr");
        $self->log( 'dev', "making listeners: tcp; class=", $self->{'incomingclass'} );
        $self->{'clients'}{'listener_tcp'} = $self->{'incomingclass'}->new(
          'parent' => $self, 'auto_listen' => 1,    
        );
        #$self->log( 'dev', __FILE__, __LINE__, "  myptr");
        $self->{'myport'} = $self->{'myport_tcp'} = $self->{'clients'}{'listener_tcp'}{'myport'};
        $self->log( 'err', "cant listen tcp (file transfers)" ) unless $self->{'myport_tcp'};
      }
      if (
        !$self->{'auto_listen'}
        #and $self->{'Proto'} ne 'udp'
        )
      {
        $self->log( 'dev', "making listeners: udp ($self->{'auto_listen'})" );
        $self->{'clients'}{'listener_udp'} = $self->{'incomingclass'}->new(
          'parent' => $self, 'Proto' => 'udp', 'auto_listen' => 1,
#$self->{'clients'}{''} = $self->{'incomingclass'}->new( %$self, $self->clear(),
#'LocalPort'=>$self->{'myport'},
#'debug'=>1,
#'nonblocking' => 0,
#'NONONOparse' => {
#'SR'  => $self->{'parse'}{'SR'},
#'PSR' => sub {                     #U
# #$self->log( 'dev', "UPSR", @_ );
#},
#2008/12/14-13:30:50 [3] rcv: welcome UPSR FQ2DNFEXG72IK6IXALNSMBAGJ5JAYOQXJGCUZ4A NIsss2911 HI81.9.63.68:4111 U40 TRZ34KN23JX2BQC2USOTJLGZNEWGDFB327RRU3VUQ PC4 PI0,64,92,94,100,128,132,135 RI64,65,66,67,68,68,69,70,71,72
#UPSR CDARCZ6URO4RAZKK6NDFTVYUQNLMFHS6YAR3RKQ NIAspid HI81.9.63.68:411 U40 TRQ6SHQECTUXWJG5ZHG3L322N5B2IV7YN2FG4YXFI PC2 PI15,17,20,128 RI128,129,130,131
#$SR [Predator]Wolf DC++\Btyan Adams - Please Forgive Me.mp314217310 18/20TTH:G7DXSTGPHTXSD2ZZFQEUBWI7PORILSKD4EENOII (81.9.63.68:4111)
#2008/12/14-13:30:50 welcome UPSR FQ2DNFEXG72IK6IXALNSMBAGJ5JAYOQXJGCUZ4A NIsss2911 HI81.9.63.68:4111 U40 TRZ34KN23JX2BQC2USOTJLGZNEWGDFB327RRU3VUQ PC4 PI0,64,92,94,100,128,132,135 RI64,65,66,67,68,68,69,70,71,72
#UPSR CDARCZ6URO4RAZKK6NDFTVYUQNLMFHS6YAR3RKQ NIAspid HI81.9.63.68:411 U40 TRQ6SHQECTUXWJG5ZHG3L322N5B2IV7YN2FG4YXFI PC2 PI15,17,20,128 RI128,129,130,131
#$SR [Predator]Wolf DC++\Btyan Adams - Please Forgive Me.mp314217310 18/20TTH:G7DXSTGPHTXSD2ZZFQEUBWI7PORILSKD4EENOII (81.9.63.68:4111)
#},
        );
        $self->{'myport_udp'} = $self->{'clients'}{'listener_udp'}{'myport'};
        $self->log( 'dev', 'nyportgen', $self->{'myport_udp'} );
        $self->log( 'err', "cant listen udp (search repiles)" ) unless $self->{'myport_udp'};
      }




      if ( 
        #!$self->{'auto_listen'} and 
        $self->{'dev_sctp'}
        )
      {
        $self->log( 'dev', "making listeners: sctp" );
        $self->{'clients'}{'listener_sctp'} = $self->{'incomingclass'}->new(
          'parent' => $self, 'Proto' => 'sctp', 'auto_listen' => 1,
        );
        $self->{'myport_sctp'} = $self->{'clients'}{'listener_sctp'}{'myport'};
        $self->log( 'dev', 'nyportgen', $self->{'myport_sctp'} );
        $self->log( 'err', "cant listen sctp" ) unless $self->{'myport_sctp'};
      }
























    }
    #DEV=z

=no
    if ( $self->{'dev_broadcast'} ) {
$self->log( 'info', 'listening broadcast ', $self->{'dev_broadcast'} || $self->{'port'});
      $self->{'clients'}{'listener_udp_broadcast'} = $self->{'incomingclass'}->new(
        #%$self, $self->clear(),
        'parent' => $self, 'Proto' => 'udp', 'auto_listen' => 1,
      'sockopts' => {%{$self->{'sockopts'}||{}}, 'Broadcast'=>1},
      myport => $self->{'dev_broadcast'} || $self->{'port'},
      );
      $self->log( 'err', "cant listen broadcast (hubless)" ) unless $self->{'clients'}{'listener_udp_broadcast'}{'myport'};
    }
=cut

    if ( $self->{'dev_http'} ) {
      $self->log( 'dev', "making listeners: http" );
      #$self->{'clients'}{'listener_http'} = Net::DirectConnect::http->new(
      $self->{'clients'}{'listener_http'} = Net::DirectConnect->new(
        #%$self, $self->clear(),
        #'want'     => \%{ $self->{'want'} },
        #'NickList' => \%{ $self->{'NickList'} },
        #'IpList'   => \%{ $self->{'IpList'} },
##      'PortList' => \%{ $self->{'PortList'} },
        #'handler'  => \%{ $self->{'handler'} },
        #$self->{'clients'}{''} = $self->{'incomingclass'}->new( %$self, $self->clear(),
        #'LocalPort'=>$self->{'myport'},
        #'debug'=>1,
        #@_,
        'incomingclass' => 'Net::DirectConnect::http', 'auto_connect' => 0, 'auto_listen' => 1,
        #'auto_listen' => 1,
        #'HubName'       => 'Net::DirectConnect test hub',
        #'myport'        => 80,
        'myport'        => 8000,
        'myport_base'   => 8000,
        'myport_random' => 99,
        'myport_tries'  => 5,
        'parent'        => $self,
        'allow'         => ( $self->{http_allow} || '127.0.0.1' ),
        #'auto_listen' => 0,
      );
      $self->{'myport_http'} = $self->{'clients'}{'listener_http'}{'myport'};
      $self->log( 'err', "cant listen http" ) unless $self->{'myport_http'};
    }
  }
  #=cut
  $self->{'handler_int'}{'disconnect_aft'} = sub {
    delete $self->{'peers'}{ $self->{'peerid'} };
    delete $self->{'peers_sid'}{ $self->{'peerid'} };
    $self->cmd_all( 'I', 'QUI', $self->{'peerid'}, ) if $self->{'parent'}{'hub'};
    delete $self->{'INF'}{'SID'} unless $self->{'parent'};
    $self->log(
      'dev',  'disconnect int',           #psmisc::caller_trace(30)
      'hub=', $self->{'parent'}{'hub'},
      )
      if $self
        and $self->{'log'};
    #psmisc::caller_trace 15;
  };
  $self->get_peer_addr() if $self->{'socket'};
  $self->log( 'err', 'cant load TigerHash module' ) unless $INC{'Net/DirectConnect/TigerHash.pm'};
  return $self;
}
1;
