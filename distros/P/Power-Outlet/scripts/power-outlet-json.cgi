#!/usr/bin/perl
use strict;
use warnings;
use CGI qw{};
use Config::IniFiles qw{};
use Power::Outlet qw{};
use JSON qw{to_json};

my $cgi      = CGI->new;
my $ini      = "../conf/power-outlet.ini";
my $status   = "";
my $state  = "";
my $name     = $cgi->param("name");

if (defined($name)) {
  my $action = $cgi->param("action");
  if (defined($action)) {
    my $cfg    = Config::IniFiles->new(-file=>$ini);
    my @keys   = $cfg->Parameters($name);
    if (@keys) {
      my %config = map {$_ => $cfg->val($name=>$_)} @keys;
      my $outlet = Power::Outlet->new(%config);
      if ($action eq "on") {
        $state = $outlet->on;
        $status  = $state eq "ON" ? "OK" : "FAILED";
      } elsif ($action eq "off") {
        $state = $outlet->off;
        $status  = $state eq "OFF" ? "OK" : "FAILED";
      } elsif ($action eq "query") {
        $state = $outlet->query;
        $status  = ($state eq "OFF" or $state eq "ON") ? "OK" : "FAILED";
      } elsif ($action eq "switch") {
        $state = $outlet->switch;
        $status  = ($state eq "OFF" or $state eq "ON") ? "OK" : "FAILED";
      } else {
        $status  = "INVALID_ACTION";
      }
    } else {
      $status = "CONFIGURATION_MISSING_NAME";
    }
  } else {
    $status = "PARAMETER_MISSING_ACTION";
  }
} else {
  $status = "PARAMETER_MISSING_NAME";
}

my %return=(
             status  => $status,
             state => $state,
           );

print $cgi->header(-type=>"application/json"),
      to_json(\%return),
      "\n";

__END__

=head1 NAME

power-outlet-json.cgi - Control Power::Outlet device with web service

=head1 DESCRIPTION

power-outlet-json.cgi is a CGI application to control a Power::Outlet device with a web service.

=head1 API

The script is called over HTTP with name and action parameters.  The name is the Section Name from the INI file and the action is one of on, off, query, or switch.

  http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp&action=off
  http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp&action=on
  http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp&action=query
  http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp&action=switch

Return is a JSON hash with keys status and state.  status is OK if there are no errors, state is the state of the switch after command either ON or OFF.

  {"status":"OK","state":"ON"}

=head1 CONFIGURATION

To add an outlet for the web service, add a new INI section to the power-outlet.ini file.

  [Unique_Section_Name]
  type=iBoot
  host=Lamp

If you need to override the defaults

  [Unique_Section_Name]
  type=iBoot
  host=Lamp
  port=80
  pass=PASS
  name=My iBoot Description

WeMo device

  [WeMo]
  type=WeMo
  host=mywemo

Default Location: /usr/share/power-outlet/conf/power-outlet.ini

=head1 INSTALLATION

I recomend installation with the provided RPM package perl-Power-Outlet-application-cgi which installs to /usr/share/power-outlet.

=cut
