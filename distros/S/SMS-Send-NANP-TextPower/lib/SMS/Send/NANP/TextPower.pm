package SMS::Send::NANP::TextPower;
use strict;
use warnings;
use SMS::Send::Driver::WebService 0.06; #uat function, keep_alive=0
use parent qw{SMS::Send::Driver::WebService};
use XML::Simple qw{XMLin};

our $VERSION = '0.06';
our $PACKAGE = __PACKAGE__;

=head1 NAME

SMS::Send::NANP::TextPower - SMS::Send driver for TextPower WebService

=head1 SYNOPSIS

Using L<SMS::Send> Driver API

  SMS-Send.ini
  [NANP::TextPower]
  username=myuser
  password=mypass
  campaign=MTMO
  queue=1

  use SMS::Send;
  my $service = SMS::Send->new('NANP::TextPower');
  my $success = $service->send_sms(
                                   to   => '+1-800-555-1212',
                                   text => 'Hello World!',
                                  );

=head1 DESCRIPTION

This package provides an L<SMS::Send> driver against the SMS web service at TextPower L<http://www.textpower.com/>.

=head1 USAGE

Direct Object Usage

  use SMS::Send::NANP::TextPower;
  my $service = SMS::Send::NANP::TextPower->new(
                                          username => $username,
                                          password => $password,
                                         );
  my $success = $service->send_sms(
                                   to   => '+18005551212',
                                   text => 'Hello World!',
                                  );

Subclass Usage

 package SMS::Send::My::Driver;
 use base qw{SMS::Send::NANP::TextPower};
 sub _username_default {return "myusername"};
 sub _password_default {return "mypassword"};
 sub _campaign_default {return "mycampaign"};
 sub _queue_default    {return "1"};

 use SMS::Send;
 my $service = SMS::Send->new('My::Driver');
 my $success = $service->send_sms(to => '+18005551212', text => 'Hello World!');

=head1 METHODS

=head2 send_sms

Sends the SMS message and returns 1 for success and 0 for failure or die on critical error.

=cut

sub send_sms {
  my $self = shift;
  my %argv = @_;
  my $to   = $argv{"to"} or die("Error: to address required");
  my $text = defined($argv{"text"}) ? $argv{"text"} : '';
  my @form = (
               UID        => $self->username,
               PWD        => $self->password,
               Campaign   => $self->campaign,
               CellNumber => $to,
               msg        => $text,
             );
  push @form, Queue => 'y' if $self->queue;
  my $url           = $self->url;
  my $response      = $self->uat->post_form($url, \@form); #isa HASH from HTTP::Tiny
  die(sprintf("HTTP Error: %s %s", $response->{'status'}, $response->{'reason'})) unless $response->{'success'};
  my $content       = $response->{'content'};
  my $data          = XMLin($content);
  $self->{"__data"} = $data;
  my $status        = $data->{"MessageStatus"}->{"SendResult"}->{"Status"} || '';
  return ($status eq 'Sent' or ($self->queue and $status eq 'Queued')) ? 1 : 0;
}

=head1 PROPERTIES

=head2 username

Sets and returns the username string value (passed to the web service as UID)

=cut

#see SMS::Send::Driver::WebService->username

=head2 password

Sets and returns the password string value (passed to the web service as PWD)

=cut

#see SMS::Send::Driver::WebService->password

=head2 campaign

Sets and returns the campaign string value (passed to the web service as Campaign)

Default: MTMO

=cut

sub campaign {
  my $self=shift;
  $self->{"campaign"}=shift if @_;
  $self->{"campaign"}=$self->cfg_property("campaign", $self->_campaign_default) unless defined $self->{"campaign"};
  return $self->{"campaign"};
}

sub _campaign_default {"MTMO"};

=head2 queue

Sets and returns the queue boolean value (passed to the web service as Queue=y when true omitted when false)

Default: "" (false)

=cut

sub queue {
  my $self=shift;
  $self->{"queue"}=shift if @_;
  $self->{"queue"}=$self->cfg_property("queue", $self->_queue_default) unless defined $self->{"queue"};
  return $self->{"queue"};
}

sub _queue_default {""};

=head2 url

Sets and returns the url for the web service.

Default: https://secure.textpower.com/TPIServices/Sender.aspx
Old Default: http://www.textpower.com/TPIServices/Sender.aspx

=cut

#see SMS::Send::Driver::WebService->url

sub _url_default {'https://secure.textpower.com/TPIServices/Sender.aspx'};

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  Satellite Tracking of People, LLC
  mdavis@stopllc.com
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<SMS::Send>

=cut

1;
