package SMS::Send::NANP::Twilio;
use strict;
use warnings;
use URI;
use JSON::XS qw{decode_json};
use base qw{SMS::Send::Driver::WebService};

our $VERSION = '0.04';

=head1 NAME

SMS::Send::NANP::Twilio - SMS::Send driver for Twilio

=head1 SYNOPSIS

  Configure /etc/SMS-Send.ini

  [NANP::Twilio]
  username=accountSid
  password=authToken
  MessagingServiceSid=String
  ;From=+12025551212
  ;StatusCallback=URL
  ;ApplicationSid=String
  ;MaxPrice=USD
  ;ProvideFeedback=true|false
  ;ValidityPeriod=14400

  use SMS::Send;
  my $sms     = SMS::Send->new('NANP::Twilio');
  my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035551212');

  use SMS::Send::NANP::Twilio;
  my $sms     = SMS::Send::NANP::Twilio->new;
  my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035551212');
  my $json    = $sms->{__content};
  my $href    = $sms->{__data};

=head1 DESCRIPTION

SMS::Send driver for Twilio

=head1 METHODS

=head2 send_sms

Sends SMS Message via Twilio web service and returns 1 or 0. Method dies on critical error.

  my $status = $sms->send_sms(to =>'+17035551212', text=> 'Hello World!');
  my $status = $sms->send_sms(to =>'+17035551212', text=> 'Image Attached', MediaUrl=>'https://...');

=over

=item to

Passed as "To" in the posted form data. The destination phone number for SMS/MMS or a Channel user address for other 3rd party channels. Destination phone numbers should be formatted with a '+' and country code e.g., +16175551212 (E.164 format).

  to => "+17035551212"

=item text

Passed as "Body" in the posted form data. The text of the message you want to send, limited to 1600 characters.

  text => "My Message Body"

=item MediaUrl

The URL of the media you wish to send out with the message. gif, png, and jpeg content is currently supported and will be formatted correctly on the recipient's device. Other types are also accepted by the API. The media size limit is 5MB. If you wish to send more than one image in the message body, please provide multiple MediaUrls values in an array reference. You may include up to 10 MediaUrls per message.

  MediaUrl => "https://...."
  MediaUrl => [$url1, $url2, ...]

=back

=cut

sub send_sms {
  my $self                = shift;
  my %argv                = @_;

  my $to                  = $argv{'to'} or die('Error: to propoerty required');
  my $text                = defined($argv{'text'}) ? $argv{'text'} : '';
  my @form                = (To => $to, Body => $text);

  my $MediaUrl            = $argv{'MediaUrl'} || [];
  $MediaUrl               = [$MediaUrl] unless ref($MediaUrl) eq 'ARRAY';
  die("Error: MediaUrl - You may include up to 10 MediaUrls per message.") if @$MediaUrl > 10;
  push @form, MediaUrl => $_ foreach @$MediaUrl;

  my $status_response;
  if ($self->From) {
    push @form, From                => $self->From;
    $status_response = 'queued'; #When you only specify the From parameter, Twilio will validate the phone
                                 #numbers synchronously and return either a queued status or an error.
  }
  if ($self->MessagingServiceSid) {
    push @form, MessagingServiceSid => $self->MessagingServiceSid;
    $status_response = 'accepted'; #When specifying the MessagingServiceSid parameter, Twilio will first
                                   #return an accepted status.
  }
  die('Error: Property "From" or "MessagingServiceSid" must be configured.') unless $status_response;

  push @form, StatusCallback  => $self->StatusCallback  if $self->StatusCallback;
  push @form, ApplicationSid  => $self->ApplicationSid  if $self->ApplicationSid;
  push @form, MaxPrice        => $self->MaxPrice        if $self->MaxPrice;
  push @form, ProvideFeedback => $self->ProvideFeedback if $self->ProvideFeedback;
  push @form, ValidityPeriod  => $self->ValidityPeriod  if $self->ValidityPeriod;

  my $response            = $self->uat->post_form($self->_url, \@form); #isa HASH from HTTP::Tiny
  die(sprintf("HTTP Error: %s %s", $response->{'status'}, $response->{'reason'})) unless $response->{'success'};
  $self->{'__content'}    = $response->{'content'};
  my $data                = decode_json($response->{'content'});
  $self->{'__data'}       = $data;
  return $data->{'status'} eq $status_response ? 1 : 0;
}

sub _url {
  my $self = shift;
  my $url  = URI->new(join '/', 'https://api.twilio.com/2010-04-01/Accounts', $self->username, 'Messages.json');
  $url->userinfo(join ':', $self->username, $self->password);
  return $url;
}

=head1 PROPERTIES

Properties may be stored in Current Directory, /etc/SMS-Send.ini or C:\Windows\SMS-Send.ini. See L<SMS::Send::Driver::WebService>->cfg_path

=head2 username

The "Account SID" is passed on the URL and sent as the username for basic authentication credentials

=cut

#see SMS::Send::Driver::WebService->username

=head2 password

The "Auth Token" sent as password for basic authentication credentials

=cut

#see SMS::Send::Driver::WebService->password

=head2 From

The "From" parameter passed in the posted form

A Twilio phone number (in E.164 format), alphanumeric sender ID or a Channel Endpoint address enabled for the type of message you wish to send. Phone numbers or short codes purchased from Twilio work here. You cannot (for example) spoof messages from your own cell phone number.

=cut

sub From {
  my $self=shift;
  $self->{'From'}=shift if @_;
  $self->{'From'}=$self->cfg_property('From', $self->_From_default) unless defined $self->{'From'};
  return $self->{'From'};
}

sub _From_default {undef};

=head2 MessagingServiceSid

The "MessagingServiceSid" parameter passed in the posted form

The 34 character unique id of the Messaging Service you want to associate with this Message. Set this parameter to use the Messaging Service Settings and Copilot Features you have configured. When only this parameter is set, Twilio will use your enabled Copilot Features to select the from phone number for delivery.

=cut

sub MessagingServiceSid {
  my $self=shift;
  $self->{'MessagingServiceSid'}=shift if @_;
  $self->{'MessagingServiceSid'}=$self->cfg_property('MessagingServiceSid', $self->_MessagingServiceSid_default) unless defined $self->{'MessagingServiceSid'};
  return $self->{'MessagingServiceSid'};
}

sub _MessagingServiceSid_default {undef};

=head2 StatusCallback

The "StatusCallback" parameter passed in the posted form

A URL where Twilio will POST each time your message status changes to one of the following: queued, failed, sent, delivered, or undelivered. Twilio will POST the MessageSid along with the other standard request parameters as well as MessageStatus and ErrorCode. If this parameter passed in addition to a MessagingServiceSid, Twilio will override the Status Callback URL of the Messaging Service. URLs must contain a valid hostname (underscores are not allowed).

=cut

sub StatusCallback {
  my $self=shift;
  $self->{'StatusCallback'}=shift if @_;
  $self->{'StatusCallback'}=$self->cfg_property('StatusCallback', $self->_StatusCallback_default) unless defined $self->{'StatusCallback'};
  return $self->{'StatusCallback'};
}

sub _StatusCallback_default {undef};

=head2 ApplicationSid

The "ApplicationSid" parameter passed in the posted form

Twilio will POST MessageSid as well as MessageStatus=sent or MessageStatus=failed to the URL in the MessageStatusCallback property of this Application. If the StatusCallback parameter above is also passed, the Application's MessageStatusCallback parameter will take precedence.

=cut

sub ApplicationSid {
  my $self=shift;
  $self->{'ApplicationSid'}=shift if @_;
  $self->{'ApplicationSid'}=$self->cfg_property('ApplicationSid', $self->_ApplicationSid_default) unless defined $self->{'ApplicationSid'};
  return $self->{'ApplicationSid'};
}

sub _ApplicationSid_default {undef};

=head2 MaxPrice

The "MaxPrice" parameter passed in the posted form

The total maximum price up to the fourth decimal (0.0001) in US dollars acceptable for the message to be delivered. All messages regardless of the price point will be queued for delivery. A POST request will later be made to your Status Callback URL with a status change of 'Sent' or 'Failed'. When the price of the message is above this value the message will fail and not be sent. When MaxPrice is not set, all prices for the message is accepted.

=cut

sub MaxPrice {
  my $self=shift;
  $self->{'MaxPrice'}=shift if @_;
  $self->{'MaxPrice'}=$self->cfg_property('MaxPrice', $self->_MaxPrice_default) unless defined $self->{'MaxPrice'};
  return $self->{'MaxPrice'};
}

sub _MaxPrice_default {undef};

=head2 ProvideFeedback

The "ProvideFeedback" parameter passed in the posted form

Set this value to true if you are sending messages that have a trackable user action and you intend to confirm delivery of the message using the Message Feedback API. This parameter is set to false by default.

=cut

sub ProvideFeedback {
  my $self=shift;
  $self->{'ProvideFeedback'}=shift if @_;
  $self->{'ProvideFeedback'}=$self->cfg_property('ProvideFeedback', $self->_ProvideFeedback_default) unless defined $self->{'ProvideFeedback'};
  return $self->{'ProvideFeedback'};
}

sub _ProvideFeedback_default {undef};

=head2 ValidityPeriod

The "ValidityPeriod" parameter passed in the posted form

The number of seconds that the message can remain in a Twilio queue. After exceeding this time limit, the message will fail and a POST request will later be made to your Status Callback URL. Valid values are between 1 and 14400 seconds (the default). Please note that Twilio cannot guarantee that a message will not be queued by the carrier after they accept the message. We do not recommend setting validity periods of less than 5 seconds.

=cut

sub ValidityPeriod {
  my $self=shift;
  $self->{'ValidityPeriod'}=shift if @_;
  $self->{'ValidityPeriod'}=$self->cfg_property('ValidityPeriod', $self->_ValidityPeriod_default) unless defined $self->{'ValidityPeriod'};
  return $self->{'ValidityPeriod'};
}

sub _ValidityPeriod_default {undef};

=head1 SEE ALSO

L<SMS::Send::Driver::WebService>, L<SMS::Send>, L<https://www.twilio.com/docs/api/messaging/send-messages>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Michael R. Davis

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.10.1 or, at your option, any later version of Perl 5 you may have available.

=cut

1;
