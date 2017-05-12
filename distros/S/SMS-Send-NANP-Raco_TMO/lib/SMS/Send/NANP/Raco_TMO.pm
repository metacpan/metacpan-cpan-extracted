package SMS::Send::NANP::Raco_TMO;
use strict;
use warnings;
use base qw{SMS::Send::Driver::WebService};
use XML::Simple qw{XMLin};

our $VERSION = '0.03';
our $PACKAGE = __PACKAGE__;

=head1 NAME

SMS::Send::NANP::Raco_TMO - SMS::Send driver for RacoWireless T-Mobile Web Service

=head1 SYNOPSIS

Using L<SMS::Send> Driver API

  SMS-Send.ini
  [NANP::Raco_TMO]
  username=myuser
  password=mypass
  
  use SMS::Send;
  my $service = SMS::Send->new('NANP::Raco_TMO');
  my $success = $service->send_sms(
                                   to   => '+1-800-555-1212',
                                   text => 'Hello World!',
                                  );

=head1 DESCRIPTION

This package provides an SMS::Send driver against the SMS web service at RacoWireless https://t-mobile.racowireless.com/SMSRicochet2.0/

=head1 USAGE

  use SMS::Send::NANP::Raco_TMO;
  my $service = SMS::Send::NANP::Raco_TMO->new(
                                         username => $partnerID,
                                         password => $webServiceKey,
                                        );
  my $success = $service->send_sms(
                                   to   => '+18005551212',
                                   text => 'Hello World!',
                                  );

=head1 METHODS

This package is a trivial sub class of the package L<SMS::Send::Driver::WebService> all of the work is in that Driver base package.

=head2 send_sms

Sends the SMS message and returns 1 for success and 0 for failure or die on critical error.

=cut

sub send_sms {
  my $self = shift;
  my %argv = @_;
  my $to   = $argv{"to"} or die("Error: to address required");
  my $text = defined($argv{"text"}) ? $argv{"text"} : '';
  my @form = (
               partnerID     => $self->username,
               webServiceKey => $self->password,
               to            => $to,
               message       => $text,
             );
  my $response = $self->ua->post($self->url, \@form);
  die(sprintf("HTTP Error: %s", $response->status_line)) unless $response->is_success;
  my $content  = $response->decoded_content;
  my $data     = XMLin($content);
  $self->{"__data"}=$data;
  my $status   = $data->{"ServiceResult"} || '';
  return $status eq 'ACCEPTED' ? 1 : 0;
}

=head1 PROPERTIES

=head2 username

=cut

#see SMS::Send::Driver::WebService->username

=head2 password

=cut

#see SMS::Send::Driver::WebService->password

=head2 url

Default: https://t-mobile.racowireless.com/SMSRicochet2.0/Send.asmx/SendSMS

=cut

#see SMS::Send::Driver::WebService->url

sub _url_default {"https://t-mobile.racowireless.com/SMSRicochet2.0/Send.asmx/SendSMS"};

=head1 BUGS

=head1 SUPPORT

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

L<SMS::Send>, L<SMS::Send::Driver::WebService>, L<XML::Simple>

=cut

1;
