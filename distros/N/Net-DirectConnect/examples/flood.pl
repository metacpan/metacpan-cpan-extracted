#!/usr/bin/perl
#$Id: flood.pl 787 2011-05-25 21:41:28Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/examples/flood.pl $

=copyright

NOT SUPPORTED, OLD



flood tests

flood.pl config:
copy flooddef.pl floodmy.pl
edit floodmy.pl
run flood.pl dchub://1.4.5.6:4111


=cut
use strict;
eval { use Time::HiRes qw(time sleep); };
use Socket;
use lib::abs '../lib';
use Net::DirectConnect::clihub;
our (%config);

sub shuffle {
  my $deck = shift;
  $deck = [ $deck, @_ ] unless ref $deck eq 'ARRAY';
  my $i = @$deck;
  while ( $i-- ) {
    my $j = int rand( $i + 1 );
    @$deck[ $i, $j ] = @$deck[ $j, $i ];
  }
  return wantarray ? @$deck : $deck;
}

sub name_to_ip {
  my ($name) = @_;
  unless ( $name =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
    local $_ = ( gethostbyname($name) )[4];
    return ( $name, 1 ) unless length($_) == 4;
    $name = inet_ntoa($_);
  }
  return $name;
}

sub rand_int {
  my ( $from, $to ) = @_;
  return $from + int rand( $to - $from );
}

sub rand_char {
  my ( $from, $to ) = @_;
  #perl -e "print chr($_) for (32+65..32+65+25)"
  $from ||= 32 + 65;
  $to   ||= 32 + 65 + 25;
  return chr( rand_int( $from, $to ) );
}

sub rand_str {
  my ( $len, $from, $to ) = @_;
  $len ||= 10;
  my $ret;
  $ret .= rand_char( $from, $to ) for ( 0 .. $len );
  return $ret;
}

sub rand_str_ex {
  my ( $str, $chg ) = @_;
  $chg ||= int( length($str) / 10 );
  local @_ = split( //, $str );
  for ( 0 .. $chg ) { $_[ rand scalar @_ ] = rand_char(); }
  return join '', @_;
}

sub handler {
  my $name = shift;
  #print "handler($name) = [$config{'handler'}{$name}]\n";
  $config{'handler'}{ $name . $_ }->(@_) for grep { ref $config{'handler'}{ $name . $_ } eq 'CODE' } 0 .. 5;
  return $config{'handler'}{$name}->(@_) if ref $config{'handler'}{$name} eq 'CODE';
  return;
}
require 'flooddef.pl';
do 'floodmy.pl';
print("usage: $1 [dchub://]host[:port] [bot_nick]\n"), exit if !$ARGV[0];
handler( 'mail_loop_bef', @ARGV );

sub createbot {
  my ( $host, $port ) = @_;
  local $_ = Net::DirectConnect::clihub->new(
    'host' => $host,
    ( $port ? ( 'port' => $port ) : () ),
    'auto_connect' => 0, (
      $config{'log_filter'}
      ? ( 'log' => sub { local $_ = shift; return if $_ eq 'dcdmp'; print( join( ' ', $_, @_ ), "\n" ) } )
      : ()
    ),
    %{ ( ref $config{'dcbot_param'} eq 'CODE' ? $config{'dcbot_param'}->() : $config{'dcbot_param'} ) or {} },
    handler('param'),
  );
  handler( 'create_aft', $_ );
  $_->connect();
  return $_;
}
TRY: for ( 0 .. $config{'flood_tries'} ) {
  print("try $_\n"), handler( 'create_bef', $_ );
  $ARGV[0] =~ m|^(?:\w+\://)?(.+?)(?:\:(\d+))?$|i;
  #print("host=$1; port=$2;\n");
  my $dc = createbot( $1, $2 );
  #=c
  $SIG{'INFO'} = $SIG{'HUP'} = sub { $dc->info() };
  $SIG{'INT'} = sub {
    $dc->info();
    $dc->{'disconnect_recursive'} = 1;
    $dc->destroy();
    exit();
  };
  #=cut
  $dc->{'disconnect_recursive'} = 0;
  #print("prebot[$bn/$config{'bots'}]\n");
  $dc->{'clients'}{$_} = createbot( $1, $2 ), print("addbot[$_/$config{'bots'}] = $dc->{'clients'}{$_}{'number'}\n"),
    #handler( 'create_aft', $dc->{'clients'}{$_} ),
    #$dc->wait(),
    #sleep(0.1),
    $dc->recv(),
    #$dc->wait_sleep(),
    #$dc->info(),
    for ( 2 .. $config{'bots'} );
  #
  #print "added..\n";
  $dc->wait();
  $dc->info();
  #print("destroy1.\n"),
  handler( 'destroy', $dc ), next if !$dc->active();    #!$dc->{'socket'} and $dc->{'disconnect_recursive'};
  for ( 1 .. $config{'connect_wait'} ) {                #sleep(5); $dc->recv();
        #last if (!$dc->{'socket'} and $dc->{'disconnect_recursive'}) or $dc->{'status'} eq 'connected';
    last if ( !$dc->active() ) or $dc->{'status'} eq 'connected';
    $dc->wait_sleep(10);    #for 0 .. 10;
                            #sleep(1);
  }
  #print("destroy2.\n"),
  handler( 'destroy', $dc ), next if !$dc->active();    #!$dc->{'socket'} and $dc->{'disconnect_recursive'};
  $dc->wait(),
    #sleep(1)
    for ( 0 .. $config{'connect_aft_wait'} );
  #print("destroy3.\n"),
  handler( 'destroy', $dc ), next if !$dc->active();    #$dc->{'socket'} and $dc->{'disconnect_recursive'};
  handler( 'send_bef', $dc );
  for ( 0 .. $config{'send_tries'} ) {
    last if !$dc->active();    #!$dc->{'disconnect_recursive'} and ( !$dc->{'socket'} or $dc->{'status'} ne 'connected' );
    print( "send try $_ to ", join( ',', sort $dc->active() ), "\n" );
    last if !$dc->active();
    handler( 'send', $dc, $_ );
    $dc->wait_sleep( $config{'send_sleep'} );
    #$dc->recv(),;
  }
  handler( 'send_aft', $dc );
  $dc->recv();
  $dc->info();
  $dc->{'disconnect_recursive'} = 1;
  handler( 'destroy_bef', $dc );
  handler( 'destroy',     $dc );
  $dc->destroy() if !$config{'no_destroy'};
  #$dc->wait_finish();
  sleep( $config{'after_sleep'} );
  print "ok\n";
  handler( 'aft', $dc );
}
handler('end');
