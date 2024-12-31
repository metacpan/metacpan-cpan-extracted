package SMS::Send::VoIP::MS;
use strict;
use warnings;
use URI;
use JSON::XS qw{decode_json};
use base qw{SMS::Send::Driver::WebService};

our $VERSION = '0.04';

=head1 NAME

SMS::Send::VoIP::MS - SMS::Send driver for VoIP.ms Web Services

=head1 SYNOPSIS

  Configure /etc/SMS-Send.ini
 
  [VoIP::MS]
  username=myuser
  password=mypass
  did=8005550123
 
  use SMS::Send;
  my $sms     = SMS::Send->new('VoIP::MS');
  my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035550123');
 
  use SMS::Send::VoIP::MS;
  my $sms     = SMS::Send::VoIP::MS->new;
  my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035550123');
  my $json    = $sms->{__content};
  my $href    = $sms->{__data};

=head1 DESCRIPTION

SMS::Send driver for VoIP.ms Web Services.

=head1 METHODS

=head2 send_sms

  my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035550123');

=cut

sub send_sms {
  my $self             = shift;
  my %argv             = @_;
  my $to               = $argv{'to'} or die('Error: to propoerty required');
  my $text             = defined($argv{'text'}) ? $argv{'text'} : '';
  my $url              = $self->url; #isa URI
  $url                 = URI->new($url) unless (ref($url) and $url->can('query_form'));
  my @form             = (
                          method       => 'sendSMS',
                          api_username => $self->username,
                          api_password => $self->password, 
                          did          => $self->did,
                          dst          => $argv{'to'},
                          message      => $argv{'text'},
                         );
  $url->query_form(\@form);
 
  #https://voip.ms/api/v1/rest.php?api_username={user}&api_password={pass}&method=sendSMS&did={from_phone}&dst={to_phone}&message=hello+world

  my $response         = $self->uat->get($url); #isa HASH from HTTP::Tiny
  die(sprintf('HTTP Error: %s %s', $response->{'status'}, $response->{'reason'})) unless $response->{'success'};
  $self->{'__content'} = $response->{'content'};
  #{"status":"success","sms":40702183}
  my $data             = decode_json($response->{'content'});
  $self->{'__data'}    = $data;
  return $data->{'status'} eq 'success' ? 1 : 0;
}

=head1 PROPERTIES

=head2 username

Sets and returns the username string value which is passed to the web service as "api_username"

  $sms->username("override");

=cut

#see SMS::Send::Driver::WebService->username

=head2 password

Sets and returns the password string value which is passed to the web service as "api_password"

  $sms->password("override");

=cut

#see SMS::Send::Driver::WebService->password

=head2 did

Sets and returns the "did" string value (Direct Inward Dialing Number aka the From Phone Number) which is passed to the web service as "did".

=cut

sub did {
  my $self       = shift;
  $self->{'did'} = shift if @_;
  $self->{'did'} = $self->cfg_property('did') unless defined $self->{'did'};
  die('Error: property did required (Direct Inward Dialing Phone Number)') unless defined $self->{'did'};
  return $self->{'did'};
}

=head2 url
 
Sets and returns the url for the web service.
 
Default: https://voip.ms/api/v1/rest.php
 
=cut
 
#see SMS::Send::Driver::WebService->url
 
sub _url_default {'https://voip.ms/api/v1/rest.php'};
sub _protocol_default {'https'};
sub _host_default {'voip.ms'};
sub _port_default {443};
sub _script_name_default {'/api/v1/rest.php'};

=head1 SEE ALSO

L<VoIPms>, L<https://www.voip.ms/m/apidocs.php>, L<https://voip.ms/m/api.php>

=head1 AUTHOR

Michael R. Davis, mrdvt92

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT

=cut

1;
