use strict; use warnings FATAL => 'all';

my $location = shift @ARGV || die 'No location specified';
my $api_key  = shift @ARGV;
warn "No API key specified, trying anyway...\n"
  unless $api_key;

use POE;
use POEx::Weather::OpenWeatherMap;

POE::Session->create(
  heap => POEx::Weather::OpenWeatherMap->new(
    event_prefix => '',
    ( $api_key ? (api_key => $api_key) : () ),
  ),
  inline_states => +{
    _start => sub {
       $_[HEAP]->start;
       $_[HEAP]->get_weather( location => $location );
    },
    weather => sub {
      my $weather = $_[ARG0];
      my $place = $weather->name;
      my $tempf = $weather->temp_f;
      my $wind  = $weather->wind_speed_mph;
      my $direc = $weather->wind_direction;
      print "$place -> ${tempf}F, wind ${wind}mph $direc\n";
      $_[HEAP]->stop;
    },
  },
);

POE::Kernel->run
