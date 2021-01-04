#!/usr/bin/perl
use strict;
use warnings;
use Mojolicious::Lite;

#I do not yet have a Shelly device but this emulator is based on the documention at https://shelly-api-docs.shelly.cloud/#shelly2-relay-index

#To test the Shelly program
#start test service
# $ plackup t/003_Shelly_live.psgi
#
# set envrionemnt
#
# $ export NET_SHELLY_HOST=127.0.0.1
# $ export NET_SHELLY_PORT=5000
# $ perl Makefile.PL
# $ make
# $ prove -bv t/003_Shelly_live.t

our $NAME  = 'my name';
our $STATE = 0;

get '/settings/:style/0' => sub  {
  my $c     = shift;
  my $style = $c->param('style') or die;
  my $name  = $c->param('name');
  if (defined($name)) {
    $NAME = $name;
  }
  printf qq{Style: %s\n}, $style;
  $c->render(json => 
    {
     "name"           => $NAME,
     "appliance_type" => "General",
     "ison"           => ($STATE ? \1 : \0),
     "has_timer"      => \0,
     "overpower"      => \0,
     "default_state"  => "off",
     "btn_type"       => "toggle",
     "btn_reverse"    => 0,
     "auto_on"        => 0,
     "auto_off"       => 0,
     "schedule"       => \0,
     "schedule_rules" => []
    }
  );
};

get '/:style/0' => sub  {
  my $c     = shift;
  my $style = $c->param('style') or die;
  my $turn  = $c->param('turn')  // '';
  my $timer = $c->param('timer') // 0;
  if ($turn eq 'on') {
    $STATE = 1;
  } elsif ($turn eq 'off') {
    $STATE = 0;
  } elsif ($turn eq 'toggle') {
    $STATE = !$STATE;
  } elsif ($timer > 0) {
    $STATE = !$STATE;
    sleep $timer;
    $STATE = !$STATE;
  }
  printf qq{Style: %s, Turn: "%s", Timer: "%s"\n}, $style, $turn, $timer;
  $c->render(json => 
    {
     "ison"            => ($STATE ? \1 : \0),
     "has_timer"       => \0,
     "timer_started"   => 0,
     "timer_duration"  => 0,
     "timer_remaining" => 0,
     "overpower"       => \0,
     "is_valid"        => \0,
     "source"          => "http"
    }
  );
};

app->start;
