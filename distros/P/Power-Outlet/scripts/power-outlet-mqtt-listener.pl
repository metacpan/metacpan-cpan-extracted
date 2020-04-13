#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std qw{getopts};
use YAML::XS qw{};
use DateTime;
use Net::MQTT::Simple;
use Power::Outlet;

local $|       = 1;
my $opt        = {};
getopts("c:", $opt);
my $yamlfile   = $opt->{"c"} || '/etc/power-outlet-mqtt-listener.yml';

printf "%s: Start\n", DateTime->now;
printf "%s: Yaml: %s\n", DateTime->now, $yamlfile;
die("Error: Cannot read file $yamlfile") unless -r $yamlfile;

my $config     = YAML::XS::LoadFile($yamlfile) or die("Error: cannot import Yaml file $yamlfile");
die("Error: Yaml configuration must be a dictionary") unless ref($config) eq "HASH";

my $version    = $config->{'version'} // 1.0;
printf "%s: Yaml: Version: $version\n", DateTime->now;

my $host       = $config->{'host'}      || '127.0.0.1';
my $LWT        = $config->{'last_will'} || 'tele/power-outlet-mqtt-listener/LWT';

my $mqtt       = Net::MQTT::Simple->new($host);
$mqtt->last_will($LWT => 'Offline');
$mqtt->retain($LWT => 'Online');

die("Error: Yaml configuration must provide directives entry") unless exists $config->{'directives'};
my $directives = $config->{'directives'};
die("Error: Yaml configuration directives entry must be an array") unless ref($directives) eq 'ARRAY';
printf "%s: Directives: %s\n", DateTime->now, scalar(@$directives);

my $topics     = {};
foreach my $directive (@$directives) {
  my $topic   = $directive->{'topic'};
  my $value   = $directive->{'value'};
  my $dirname = $directive->{'name'}    || "$topic => $value";
  printf qq{%s: Directive: "%s", Topic: %s, Value: %s\n}, DateTime->now, $dirname, $topic, $value;

  my $actions = $directive->{'actions'} || [];
  die("Error: Yaml configuration actions must be an array of dictionaries") unless ref($actions) eq 'ARRAY';

  printf qq{%s: Directive: "%s", Topic: %s, Value: %s, Actions: %s\n}, DateTime->now, $dirname, $topic, $value, scalar(@$actions);

  foreach my $action (@$actions) {
    die("Error: Yaml configuration action must be a dictionary") unless ref($action) eq 'HASH';
    my $driver  = $action->{'driver'}  or die("Error: Yaml configuration action must have a driver");

    my $command = $action->{'command'} or die("Error: Yaml configuration action must have a command");
    die("Error: Yaml configuration action command must be one of ON|OFF|SWITCH|CYCLE") unless $command =~ m/\A(ON|OFF|SWITCH|TOGGLE|CYCLE)\Z/i;

    my $actname   = $action->{'name'} ||= join(' => ', $action->{'driver'}, $action->{'command'});
   
    printf qq{%s: Directive: "%s", Topic: %s, Value: %s, Action: "%s", Driver: %s, Command: %s\n}, DateTime->now, $dirname, $topic, $value, $actname, $driver, $command;
    my $class = "Power::Outlet::$driver";
    local $@;
    eval "use $class";
    my $error = $@;
    die(qq{Error: Power::Outlet class "$class" not loaded}) if $error;
  }

  $topics->{$topic}->{$value} ||= [];
  push @{$topics->{$topic}->{$value}}, @$actions;
}

foreach my $topic (sort keys %$topics) {
  printf qq{%s: Subscription: Topic: %s, Values: [%s]\n}, DateTime->now, $topic, join(", ", map {qq{"$_"}} sort keys %{$topics->{$topic}});
}

#print Dumper({config=>$config, topics=>$topics});

$mqtt->run(map {$_, \&handler} keys %$topics);

printf "%s: Finish\n", DateTime->now;

sub handler {
  my $topic   = shift;
  my $message = shift;
  printf qq{%s: Topic: "%s", Message: "%s"\n}, DateTime->now, $topic, $message;
  my $actions = $topics->{$topic}->{$message} || [];
  if (@$actions) {
    foreach my $action (@$actions) {
      my $driver  = $action->{'driver'};
      my $command = $action->{'command'};
      my $actname = $action->{'name'};
      my $options = $action->{'options'} || {}; 
      my $outlet  = Power::Outlet->new(type=>$driver, %$options);
      my $return  = $command =~ m/\AON/i                ? $outlet->on
                  : $command =~ m/\AOFF/i               ? $outlet->off
                  : $command =~ m/\A(SWITCH|TOGGLE)\Z/i ? $outlet->switch
                  : $command =~ m/\ACYCLE\Z/i           ? $outlet->cycle
                  : die(sprintf(qq{%s: Topic: "%s", Message: "%s", Type: %s, Command: %s not found, Expected, "ON|OFF|SWITCH|CYCLE"\n}, DateTime->now, $topic, $message, $driver, $command));
      printf qq{%s: Topic: "%s", Message: "%s", Type: %s, Command: %s, Return: %s\n}, DateTime->now, $topic, $message, $driver, $command, $return;
    }
  } else {
    printf "%s: Topic: %s, Value: %S, No actions registered\n", DateTime->now, $topic, $message;
  }
}

__END__

=head1 NAME

power-outlet-mqtt-listener.pl - MQTT listener to control Power::Outlet devices

=head1 SYNOPSIS

  power-outlet-mqtt-listener.pl [-c /etc/power-outlet-mqtt-listener.yml]

=head1 DESCRIPTION

This script provides an MQTT listener to control Power::Outlet devices

=head1 CONFIGURATION

The YAML formatted file /etc/power-outlet-mqtt-listener.yml is a key-value hash.  

The "host" key value is a string representing the host name of the MQTT server.

The "directives" key value is a list of individual directives with "name", "topic", "value" (topic payload to match) and "actions".

The "actions" key value is a list of individual actions to run when "topic" and "value" match. Individual actions have keys "name", "driver", "command", and "options". "options" is a hash of options that is passed to the driver.

Example:

  ---
  host: mqtt

  directives:

  - name: Smart Outlet Top Button Press
    topic: cmnd/smartoutlet_button_topic/POWER1
    value: TOGGLE
    actions:
    - name: Outside Lights
      driver: iBootBarGroup
      command: 'ON'
      options:
        outlets: '1,2,6,7'
        host: bar

  - name: Smart Outlet Bottom Button Press
    topic: cmnd/smartoutlet_button_topic/POWER2
    value: TOGGLE
    actions:
    - name: Outside Lights
      driver: iBootBarGroup
      command: 'OFF'
      options:
        outlets: '1,2,6,7'
        host: bar

=head1 SYSTEMD

The included rpm spec file installs a systemd service file so you can run this process from systemd.

  systemctl power-outlet-mqtt-listener.service enable
  systemctl power-outlet-mqtt-listener.service start

=head1 BUILD

  rpmbuild -ta Power-Outlet-*.tar.gz

=head1 INSTALL

  sudo yum install perl-Power-Outlet-mqtt-listener 

=head1 COPYRIGHT

Copyright (c) 2020 Michael R. Davis <mrdvt92>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
