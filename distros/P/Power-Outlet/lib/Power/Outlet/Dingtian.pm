package Power::Outlet::Dingtian;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP};

our $VERSION = '0.46';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Power::Outlet::Dingtian - Control and query Dingtian Relay Boards via the HTTP API

=head1 SYNOPSIS

  my $outlet = Power::Outlet::Dingtian->new(host => "my_host", relay => "1");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::Dingtian is a package for controlling and querying a relay on Dingtian hardware via the HTTP API.

Example commands can be executed via web (HTTP) GET requests, for example:

Relay Status URL Example

  http://192.168.1.100/relay_cgi_load.cgi

Relay 1 on example (relays are named one-based but the api uses a zero-based index)

  http://192.168.1.100/relay_cgi.cgi?type=0&relay=0&on=1&time=0&pwd=0&

Relay 2 off example

  http://192.168.1.100/relay_cgi.cgi?type=0&relay=1&on=0&time=0&pwd=0&

Relay 2 cycle off-on-off example (note: time in 100ms increments)

  http://192.168.1.100/relay_cgi.cgi?type=1&relay=1&on=1&time=100&pwd=0&

I have tested this package against the Dingtian DT-R002 V3.6A with V3.1.276A firmware configured for both HTTP and HTTPS.

=head1 USAGE

  use Power::Outlet::Dingtian;
  my $relay = Power::Outlet::Dingtian->new(host=>"my_host", relay=>"1");
  print $relay->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"Dingtian", host=>"my_host", relay=>"1");
  my $outlet = Power::Outlet::Dingtian->new(host=>"my_host", relay=>"1");

=head1 PROPERTIES

=head2 relay

Dingtian API supports up to 32 relays numbered 1 to 32.

Default: 1

Note: The relays are numbered 1-32 but the api uses a zero based index.

=cut

sub relay {
  my $self         = shift;
  $self->{'relay'} = shift if @_;
  $self->{'relay'} = $self->_relay_default unless defined $self->{'relay'};
  die("Error: $PACKAGE relay must be between 1 and 32") unless $self->{'relay'} =~ m/\A([1-9]|[12][0-9]|3[012])\Z/;
  return $self->{'relay'};
}

sub _relay_default {'1'};

=head2 pwd

Sets and returns the ID token used for authentication with the Dingtian hardware

Default: "0"

Can be set in the Relay Password property in the Other section on the Relay Connect screen.

=cut

sub pwd {
  my $self            = shift;
  $self->{'pwd'} = shift if @_;
  $self->{'pwd'} = $self->_pwd_default unless defined $self->{'pwd'};
  return $self->{'pwd'};
}

sub _pwd_default {'0'};

=head2 host

Sets and returns the hostname or IP address.

Default: 192.168.1.100

=cut

sub _host_default {'192.168.1.100'};

=head2 port

Sets and returns the port number.

Default: 80

Can be set in the HTTP Server Port property on the Setting screen.

=cut

sub _port_default {'80'};

=head2 http_scheme

Sets and returns the http scheme (i.e. protocol) (e.g. http or https).

Default: http

Can be set in the HTTP or HTTPS property on the Setting screen

=cut

sub _http_scheme_default {'http'};                         #see Power::Outlet::Common::IP::HTTP
sub _http_path_default {'/'};                              #see Power::Outlet::Common::IP::HTTP
sub _http_path_script_name_set {'relay_cgi.cgi'};          #custom
sub _http_path_script_name_status {'relay_cgi_load.cgi'};  #custom

=head1 METHODS

=head2 name

Sets and returns the friendly name for this relay.

=cut

#see Power::Outlet::Common

sub _name_default {sprintf("Relay %s", shift->relay)};

=head2 query

Sends an HTTP message to the device to query the current state

=cut

sub query {
  my $self = shift;
  return $self->_call(); #zero params is query but content is different format
}

=head2 on

Sends a message to the device to Turn Power ON

=cut

sub on {
  my $self = shift;
  return $self->_call(1);
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  return $self->_call(0);
}

=head2 switch

Sends a message to the device to toggle the power

=cut

#see Power::Outlet::Common

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

sub cycle {
  my $self  = shift;
  my $query = $self->query;
  $self->_call(($query eq 'OFF' ? 1 : 0) => $self->cycle_duration);
  return 'CYCLE';
}

#head2 _call
#
#  Returns "ON" or "OFF" for both query and set http calls
#
#  $self->_call(); #query
#  $self->_call(1); #on
#  $self->_call(0); #off
#  $self->_call(1, 10); #when off then does on  10 seconds wait then off
#  $self->_call(0, 10); #when on  then does off 10 seconds wait then on
#
#  When time is 0 or undef the type is set to 0 which is a simple on/off capability
#  When time is greater than 0 the the type is set to 1 which is cycle (jogging) capability
#  This package does not support type 2 which is a relay delay switching capability
#  The api does no support a toggle capability natively
#  
#cut

sub _call {
  my $self   = shift;
  my $set    = scalar(@_) ? 1 : 0;
  my $url    = $self->url;        #isa URI from Power::Outlet::Common::IP::HTTP
  my $relay  = $self->relay;      #e.g. 1 .. 32
  my $relay0 = $relay - 1;        #e.g. 0 .. 31
  if ($set) {
    my $on      = shift;             #e.g. "1" | "0"
    my $time    = shift || 0;        #time seconds
    my $time_ds = int($time * 10);   #time in 100ms increments (deciseconds) for the api
    my $type    = $time > 0 ? 1 : 0; #0:relay on/off, 1:relay jogging, 2:relay delay
    my $pwd     = $self->pwd;        #password id token 0 .. 9999
    $url->path($self->http_path . $self->_http_path_script_name_set);
    $url->query_form(type => $type, relay => $relay0, on => $on, time => $time_ds, pwd => $pwd);
  } else {
    $url->path($self->http_path . $self->_http_path_script_name_status);
  }
  #print "$url\n";
  my $response = $self->http_client->request(GET => $url);
  if ($response->{"status"} eq "599") {
    die(sprintf(qq{HTTP Error: "%s %s", URL: "$url", Content: %s}, $response->{"status"}, $response->{"reason"}, $response->{"content"}));
  } elsif ($response->{"status"} ne "200") {
    die(sprintf(qq{HTTP Error: "%s %s", URL: "$url"}, $response->{"status"}, $response->{"reason"}));
  }

  my $return  = '';
  my $content = $response->{"content"};
  #print "$content\n";
  die(qq{Error: content malformed, url: "$url", content: "$content"}) unless $content =~ m/\A\&[0-9].*\&\Z/;
  my @values  = split(/\&/, $content, -1); #LIMIT=-1 since split filters trailing values by default
  shift @values; #API has empty string as first array element
  pop   @values; #API has empty string as last array element
  my $ok      = shift @values; #0 => OK, 302 => NAK
  die(qq{Error: API returned error code "$ok". url: "$url", content: "$content"}) unless $ok eq '0';
  if ($set) {
    #&0&0&0&1&0& #$ok, $type, $relay, $on, $time
    my ($type, $relay, $on, $time) = @values;
    $return   = _state($on);
  } else {
    #&0&2&0&0& #$ok, $count, $relay[0], $relay[1]
    my $count = shift @values;
    my $on    = $values[$relay0]; #relay is zero-based index
    $return   = _state($on);
  }
  return $return;

  sub _state {
    my $state = shift;
    die("Error: API returned undefined relay state.") unless defined $state;
    return $state eq '1' ? 'ON'
         : $state eq '0' ? 'OFF'
         : die(qq{Error: API returned invalid relay state. state: "$state"});
  }
}

=head1 BUGS

Please open an issue on GitHub.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT

=head1 COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<https://www.dingtian-tech.com/sdk/relay_sdk.zip> => programming_manual_en.pdf page 12 "Protocol: HTTP GET CGI"

=cut

1;
