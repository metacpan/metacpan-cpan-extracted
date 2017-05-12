#!/usr/bin/env perl

use v5.10;
use strictures 1;

use List::Objects::WithUtils;
use List::Objects::Types -all;

use POE;
use POEx::Weather::OpenWeatherMap;
use POEx::IRC::Client::Lite;


use Getopt::Long;
my $Opts = +{
  nickname => 'Aurae',
  username => 'aurae',
  server   => undef,
  api_key  => undef,
  channels => '',
  cmd      => '.wx',

  help => sub {
    say $_ for (
      "Usage:",
      "",
      "  --api_key=KEY",
      "",
      "  --nickname=NICKNAME",
      "  --username=USERNAME",
      "  --server=ADDR",
      "  --channels=CHAN[,CHAN ..]",
      "  --cmd=CMD",
    );
    exit 0
  },
};
GetOptions( $Opts,
  'nickname=s',
  'username=s',
  'server=s',
  'api_key=s',
  'channels=s',
  'cmd=s',

  'help',
);

sub getopts { 
  unless (is_ArrayObj $Opts->{channels}) {
    $Opts->{channels} = array(split /,/, $Opts->{channels})
  }
  state $argv = hash(%$Opts)->inflate 
}


POE::Session->create(
  package_states => [
    main => [qw/
      _start

      pxi_irc_001
      pxi_irc_public_msg
      pxi_irc_disconnected
      
      pwx_error
      pwx_weather
      pwx_forecast
    /],
  ],
);

sub _start {
  $_[HEAP]->{irc} = POEx::IRC::Client::Lite->new(
    event_prefix => 'pxi_',
    server   => getopts->server,
    nick     => getopts->nickname,
    username => getopts->username,
  );
  $_[HEAP]->{irc}->connect;

  $_[HEAP]->{wx} = POEx::Weather::OpenWeatherMap->new(
    event_prefix => 'pwx_',
    api_key => getopts->api_key,
  );
  $_[HEAP]->{wx}->start;

  $_[HEAP] = hash(%{ $_[HEAP] })->inflate;
}

sub pxi_irc_disconnected {
  $_[HEAP]->irc->connect
}

sub pxi_irc_001 {
  $_[HEAP]->irc->join( getopts->channels->all )
}

sub pxi_irc_public_msg {
  my $event = $_[ARG0];
  my ($target, $string) = @{ $event->params };
  
  my $cmd = getopts->cmd;
  if ( index($string, "$cmd ") == 0 ) {
    my ($location, $fcast);
    if (index($string, 'forecast') == length($cmd)+1) {
      $location = substr $string, length($cmd) + length('forecast') + 2;
      $fcast++
    }

    $location ||= substr $string, length("$cmd ");

    $_[HEAP]->wx->get_weather(
      location => $location,
      tag      => $target,
      ( $fcast ? (forecast => 1, days => 3) : () ),
    );
  }
}


sub pwx_error {
  my $err = $_[ARG0];

  my $status = $err->status;
  my $req    = $err->request;

  if ($req->tag) {
    my $chan = $req->tag;
    $_[HEAP]->irc->privmsg($chan => "Error: $err");
  }
  warn "Error: $err";
}

sub pwx_weather {
  my $res = $_[ARG0];

  my $place = $res->name;

  my $tempf = $res->temp_f;
  my $tempc = $res->temp_c;
  my $humid = $res->humidity;

  my $wind    = $res->wind_speed_mph;
  my $gust    = $res->wind_gust_mph;
  my $winddir = $res->wind_direction;
  
  my $terse   = $res->conditions_terse;
  my $verbose = $res->conditions_verbose;

  my $hms = $res->dt->hms;

  my $str = "$place at ${hms}UTC: ${tempf}F/${tempc}C";
  $str .= " and ${humid}% humidity;";
  $str .= " wind is ${wind}mph $winddir";
  $str .= " gusting to ${gust}mph" if $gust;
  $str .= ". Current conditions: ${terse}: $verbose";

  my $chan = $res->request->tag;
  $_[HEAP]->irc->privmsg($chan => $str);
}


sub pwx_forecast {
  my $res = $_[ARG0];

  my $place = $res->name;

  my $chan = $res->request->tag;

  $_[HEAP]->irc->privmsg($chan =>
    "Forecast for $place ->"
  );

  my $itr = $res->iter;
  while (my $day = $itr->()) {
    my $date = $day->dt->day_name;
    
    my $temp_hi_f = $day->temp_max_f;
    my $temp_lo_f = $day->temp_min_f;
    my $temp_hi_c = $day->temp_max_c;
    my $temp_lo_c = $day->temp_min_c;

    my $terse   = $day->conditions_terse;
    my $verbose = $day->conditions_verbose;

    my $wind    = $day->wind_speed_mph;
    my $winddir = $day->wind_direction;
    
    my $str = "${date}: High of ${temp_hi_f}F/${temp_hi_c}C";
    $str .= ", low of ${temp_lo_f}F/${temp_lo_c}C";
    $str .= ", wind $winddir at ${wind}mph";
    $str .= "; $terse: $verbose";
    
    $_[HEAP]->irc->privmsg($chan => $str);
  }
}

POE::Kernel->run

