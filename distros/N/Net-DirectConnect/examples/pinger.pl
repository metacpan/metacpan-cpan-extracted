#!/usr/bin/perl
#$Id: pinger.pl 793 2011-06-17 16:51:17Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/examples/pinger.pl $

=head1 NAME

get info about hubs

=head1 SYNOPSIS

 ./pinger.pl hub hub ...

 ./pinger.pl adc://dc.hub.com:412  dc.hub.com 

=head1 CONFIGURE 

 create config.pl:
 $config{dc}{host} = 'myhub.net';

=cut
use 5.10.0;
use strict;
use Data::Dumper;
$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
use Time::HiRes qw(time sleep);
#use Encode;
use lib::abs '../lib';
#use lib '../TigerHash/lib';
#use lib './stat/pslib';
our (%config);
use Net::DirectConnect::pslib::psmisc;
psmisc->import qw(:log);
#use psmisc;
#use pssql;
use Net::DirectConnect;
$config{disconnect_after}     //= 10;
$config{disconnect_after_inf} //= 0;
$config{ 'log_' . $_ } //= 0 for qw (dmp dcdmp dcdbg);
psmisc::configure();    #psmisc::lib_init();
printlog("usage: $1 [adc|dchub://]host[:port] [hub..]\n"), exit if !$ARGV[0] and !$config{dc}{host} and !$config{dc}{hosts};
printlog( 'info', 'started:', $^X, $0, join ' ', @ARGV );
#$SIG{INT} = $SIG{KILL} = sub { printlog 'exiting', exit; };
#use Net::DirectConnect::adc;
#my $dc =
Net::DirectConnect->new(
  #modules  => ['filelist'],
  SUPAD => { H => { PING => 1 } },
  #botinfo      => 'devperlpinger',
  auto_GetINFO => 1,
  auto_connect => 1,
  auto_say     => 1,
  dev_http     => 1,
  'log'        => sub (@) {
    my $dc = ref $_[0] ? shift : {};
    psmisc::printlog shift(), "[$dc->{'number'}]", @_,;
  },
  'handler' => { 
    
    INF => sub {
      my $dc  = shift;
      my $dst = shift @{ $_[0] };
      return if $dst ne 'I';
      my $info = pop;
      printlog( "getted adc info: $info->{UC} $info->{SS} $info->{SF}, full=", Dumper $info);
      $dc->destroy() if $config{disconnect_after_inf};    #no manual calc, disconnect
    },
  },
  auto_work => sub {
    my $dc = shift;
    #our $starttime ||= time if $dc->{status} eq 'connected';
    #$BotINFO <bot description>|
    if ( time - $dc->{time_start} > $config{disconnect_after} ) {    # works only 10 seconds (for users inf getting)
      my $info = $dc->stat_hub();
      printlog( "calced info: $info->{UC} $info->{SS} $info->{SF}, full=", Dumper($info) );
      $dc->destroy();
    }
    psmisc::schedule(
      [ 20, 100 ],
      our $dump_sub__ ||= sub {
        printlog("Writing dump");
        psmisc::file_rewrite( $0 . '.dump', Dumper $dc);
      }
    ) if $config{debug};
  },
  %{ $config{dc} || {} },
  ( $_ ? ( 'host' => $_ ) : () ),
) for ( @ARGV, @{ $config{dc}{hosts} || [] } );
