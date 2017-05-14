#$Id: adc.pm 594 2010-01-30 23:10:17Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/adc.pm $
#UNFINISHED
package    #hide from cpan
  Net::DirectConnect::nmdc;
use strict;
no strict qw(refs);
use warnings "NONFATAL" => "all";
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use utf8;
#use Time::HiRes qw(time sleep);
use Data::Dumper;    #dev only
$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
use Net::DirectConnect;
#use Net::DirectConnect::clicli;
#use Net::DirectConnect::http;
#use Net::DirectConnect::httpcli;
our $VERSION = ( split( ' ', '$Revision: 594 $' ) )[1];
use base 'Net::DirectConnect';

sub init {
  my $self = shift;
  #shift if $_[0] eq __PACKAGE__;
  #print "nmdcinit SELF=", $self, "REF=", ref $self, "  P=", @_, "package=", __PACKAGE__, "\n\n";
  #$self->SUPER::new();
  #%$self = (
  #%$self,
  local %_ = (
    'Nick'     => 'NetDCBot',
    'port'     => 411,
    'host'     => 'localhost',
    'protocol' => 'nmdc',
    'nmdc'     => 1,
    #'Pass' => '',
    #'key'  => 'zzz',
    #'auto_wait'        => 1,
    #'search_every' => 10, 'search_every_min' => 10, 'auto_connect' => 1,
    #ADC
    #'connect_protocol' => 'ADC/0.10', 'message_type' => 'H',
    #@_,
    'incomingclass' => 'Net::DirectConnect::clicli',
    #'incomingclass' => __PACKAGE__,    #'Net::DirectConnect::adc',
    #no_print => { 'INF' => 1, 'QUI' => 1, 'SCH' => 1, },
    #http://www.dcpp.net/wiki/index.php/%24MyINFO
    'description' => 'perl ' . __PACKAGE__ . ' bot',
    #====MOVE TO NMDC
    'connection' => 'LAN(T3)',
    #NMDC1: 28.8Kbps, 33.6Kbps, 56Kbps, Satellite, ISDN, DSL, Cable, LAN(T1), LAN(T3)
    #NMDC2: Modem, DSL, Cable, Satellite, LAN(T1), LAN(T3)
    'flag' => '1',    # User status as ascii char (byte)
                      #1 normal
                      #2, 3 away
                      #4, 5 server               The server icon is used when the client has
                      #6, 7 server away          uptime > 2 hours, > 2 GB shared, upload > 200 MB.
                      #8, 9 fireball             The fireball icon is used when the client
                      #10, 11 fireball away      has had an upload > 100 kB/s.
    'email' => 'billgates@microsoft.com', 'sharesize' => 10 * 1024 * 1024 * 1024 + int rand( 1024 * 1024 ),    #10GB
    'client' => 'perl',    #'dcp++',                                                              #++: indicates the client
                           #'protocol' => 'nmdc',    # or 'adc'
    'V' => $Net::DirectConnect::VERSION,   #. '_' . ( split( ' ', '$Revision: 656 $' ) )[1],    #V: tells you the version number
         #'M' => 'A',      #M: tells if the user is in active (A), passive (P), or SOCKS5 (5) mode
    'H' => '0/1/0'
    , #H: tells how many hubs the user is on and what is his status on the hubs. The first number means a normal user, second means VIP/registered hubs and the last one operator hubs (separated by the forward slash ['/']).
    'S' => '3',      #S: tells the number of slots user has opened
    'O' => undef,    #O: shows the value of the "Automatically open slot if speed is below xx KiB/s" setting, if non-zero
    'lock'         => 'EXTENDEDPROTOCOLABCABCABCABCABCABC Pk=DCPLUSPLUS0.668ABCABC',
    'cmd_bef'      => '$',
    'cmd_aft'      => '|',
    'auto_say_cmd' => [qw(welcome chatline To)],
  );
  #$self->{$_} ||= $_{$_} for keys %_;
  #$self->log('dev', 's0',$self->{'sharesize'});
  !exists $self->{$_} ? $self->{$_} ||= $_{$_} : () for keys %_;
  #$self->log('dev', 's1',$self->{'sharesize'});
  %_ = (
    #charset_chat => 'cp1251',
    #charset_nick => 'cp1251',
    charset_protocol => 'cp1251',
  );
  $self->{$_} = $_{$_} for keys %_;
#$self->log('dev', 'chPROTO:',$self->{'charset_protocol'});
#print 'adc init now=',Dumper $self;
#$self->{'periodic'}{ __FILE__ . __LINE__ } = sub {      my $self = shift if ref $_[0]; $self->cmd( 'search_buffer', ) if $self->{'socket'}; };
#http://www.dcpp.net/wiki/index.php/LockToKey :
  $self->{'lock2key'} ||= sub {
    my $self = shift if ref $_[0];
    #return $self->{lock};
    my ($lock) = @_;
    #$self->{'log'}->( 'dev', 'making lock from', $lock );
    $lock = Encode::encode $self->{charset_protocol}, $lock, Encode::FB_WARN if $self->{charset_protocol};
    #$self->{'log'}->( 'dev', 'making lock from2:', $lock );
    my @lock = split( //, $lock );
    my $i;
    my @key = ();
    foreach (@lock) { $_ = ord; }
    push( @key, $lock[0] ^ 5 );
    for ( $i = 1 ; $i < @lock ; $i++ ) { push( @key, ( $lock[$i] ^ $lock[ $i - 1 ] ) ); }
    for ( $i = 0 ; $i < @key ; $i++ ) { $key[$i] = ( ( ( $key[$i] << 4 ) & 240 ) | ( ( $key[$i] >> 4 ) & 15 ) ) & 0xff; }
    $key[0] = $key[0] ^ $key[ @key - 1 ];

    foreach (@key) {
      if ( $_ == 0 || $_ == 5 || $_ == 36 || $_ == 96 || $_ == 124 || $_ == 126 ) { $_ = sprintf( '/%%DCN%03i%%/', $_ ); }
      else                                                                        { $_ = chr; }
    }
    local $_ = join( '', @key );
    $_ = Encode::decode $self->{charset_protocol}, $_ if $self->{charset_protocol};
    return $_;
  };
  $self->{'tag'} ||= sub {
    my $self = shift;
    $self->{'client'} . ' ' . join( ',', map $_ . ':' . $self->{$_}, grep defined( $self->{$_} ), qw(V M H S O) );
  };
  $self->{'myinfo'} ||= sub {
    my $self = shift;
    return
        $self->{'Nick'} . ' '
      . $self->{'description'} . '<'
      . $self->tag() . '>' . '$' . ' ' . '$'
      . $self->{'connection'}
      . ( length( $self->{'flag'} ) ? chr( $self->{'flag'} ) : '' ) . '$'
      . $self->{'email'} . '$'
      . $self->{'sharesize'} . '$';
  };
  $self->{'supports'} ||= sub {
    my $self = shift;
    return join ' ', grep $self->{$_}, @{ $self->{'supports_avail'} };
  };
  $self->{'supports_parse'} ||= sub {
    my $self = shift;
    my ( $str, $save ) = @_;
    $save->{$_} = 1 for split /\s+/, $str;
    delete $save->{$_} for grep !length $save->{$_}, keys %$save;
    return wantarray ? %$save : $save;
  };
  $self->{'info_parse'} ||= sub {
    my $self = shift;
    my ( $info, $save ) = @_;
    $save->{'info'} = $info;
    $save->{'description'} = $1 if $info =~ s/^([^<\$]+)(<|\$)/$2/;
    ( $save->{'tag'}, $save->{'M'}, $save->{'connection'}, $save->{'email'}, $save->{'sharesize'} ) = split /\s*\$\s*/, $info;
    $save->{'flag'} = ord($1) if $save->{'connection'} =~ s/([\x00-\x1F])$//e;
    $self->tag_parse( $save->{'tag'}, $save );
    delete $save->{$_} for grep !length $save->{$_}, keys %$save;
    return wantarray ? %$save : $save;
  };
  $self->{'tag_parse'} ||= sub {
    my $self = shift;
    my ( $tag, $save ) = @_;
    $save->{'tag'} = $tag;
    $tag =~ s/(^\s*<\s*)|(\s*>\s*$)//g;
    $save->{'client'} = $1 if $tag =~ s/^(\S+)\s*//;
    /(.+):(.+)/, $save->{$1} = $2 for split /,/, $tag;
    return wantarray ? %$save : $save;
  };
  $self->{'make_hub'} ||= sub {
    my $self = shift if ref $_[0];
    $self->{'hub_name'} ||=
      $self->{'host'};    # . ( ( $self->{'port'} and $self->{'port'} != 411 ) ? ':' . $self->{'port'} : '' );
    $self->{'hub_name'} =~ s/:411$//;
    #$self->log('dev', $self->{'hub_name'});
  },;
}
1;
