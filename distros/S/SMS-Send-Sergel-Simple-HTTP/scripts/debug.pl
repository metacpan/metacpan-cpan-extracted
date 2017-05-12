#!/usr/bin/perl

use YAML;
use HTTP::Tiny;
use SMS::Send;
use lib '../lib';
use SMS::SEND::Sergel::Simple::HTTP;
use Data::Dumper;
use strict;
use warnings;

sub usage {
  print << "eof";
Prepare the conf.yaml and debug.yaml files with credentials etc.
Then run perl debug.pl.
eof
}

unless (-f 'conf.yaml') {
  usage();
  die "No conf.yaml found";
}

unless (-f 'debug.yaml') {
  usage();
  die "No debug.yaml found";
}

my $conf1 = YAML::LoadFile('conf.yaml');
my $conf2 = YAML::LoadFile('debug.yaml');
my $tmp = {%$conf1, %$conf2};
my $conf = {};
for my $key (keys %$tmp) {
  $conf->{"_$key"} = $tmp->{$key};
}
print "Loaded configuration:\n";
print Dumper($conf);

my $installed_drivers = join "\n", SMS::Send->installed_drivers;
print << "eof";
Installed SMS::Send drivers:
$installed_drivers

eof

my $sender = SMS::Send->new('Sergel::Simple::HTTP',
  _debug => 1,
  %$conf,
);

my $response = $sender->send_sms(
  text => $conf->{_userdata},
  to => $conf->{_destination}
);

use Data::Dumper;
print Dumper($response);
