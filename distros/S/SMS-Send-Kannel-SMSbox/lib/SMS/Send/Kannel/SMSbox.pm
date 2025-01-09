package SMS::Send::Kannel::SMSbox;
use strict;
use warnings;
use base qw{SMS::Send::Driver::WebService};

our $VERSION = '0.08';
our $PACKAGE = __PACKAGE__;

=head1 NAME

SMS::Send::Kannel::SMSbox - SMS::Send driver for Kannel SMSbox Web Service

=head1 SYNOPSIS

Using L<SMS::Send> Driver API

  SMS-Send.ini
  [Kannel::SMSbox]
  host=mykannelserver
  username=myuser
  password=mypass

  use SMS::Send;
  my $service = SMS::Send->new('Kannel::SMSbox');
  my $success = $service->send_sms(
                                   to   => '+1-800-555-0000',
                                   text => 'Hello World!',
                                  );

=head1 DESCRIPTION

SMS::Send driver for Kannel SMSbox Web Service

=head1 USAGE

  use SMS::Send::Kannel::SMSbox;
  my $service = SMS::Send::Kannel::SMSbox->new(
                                       username => $username,
                                       password => $password,
                                       host     => $host,
                                      );
  my $success = $service->send_sms(
                                   to   => '+18005550000',
                                   text => 'Hello World!',
                                  );

=head1 METHODS

=head2 send_sms

Sends the SMS message and returns 1 for success and 0 for failure or die on critical error.

=cut

sub send_sms {
  my $self = shift;
  my %argv = @_;
  my $to   = $argv{"to"} or die("Error: to address required");
  print "Package: $PACKAGE, Method: send_sms, to: $to\n" if $self->debug >= 3;
  my $text = defined($argv{"text"}) ? $argv{"text"} : '';
  print "Package: $PACKAGE, Method: send_sms, text: $text\n" if $self->debug >= 3;
  my $url  = $self->url; #isa URI
  my @form = (
               username   => $self->username,
               password   => $self->password,
               to         => $to,
               text       => $text,
             );
  $url->query_form(\@form);
  print "Package: $PACKAGE, Method: send_sms, URL: $url\n" if $self->debug >= 2;
  my $response = $self->ua->get($url);
  die(sprintf("HTTP Error: %s", $response->status_line)) unless $response->is_success;
  if ($self->debug >= 6) {
    require Data::Dumper;
    print Data::Dumper::Dumper($response);
  }
  my $content          = $response->decoded_content;
  print "Package: $PACKAGE, Method: send_sms, content: $content\n" if $self->debug >= 1;
  $self->{"__data"}    = $self->{"__content"} = $content;
  my $status           = $content =~ m/^0:/ ? 1 : 0;
  warn("Package: $PACKAGE, Method: send_sms, Status: $status, Content: $content\n") if ($status != 1 and $self->warnings);
  return $status;
}

=head1 PROPERTIES

=head2 username

Sets and returns the username string value

Override in sub class

  sub _username_default {"myusername"};

Override in configuration

  [Kannel::SMSbox]
  username=myusername

=cut

#see SMS::Send::Driver::WebService->userame

=head2 password

Sets and returns the password string value

Override in sub class

  sub _password_default {"mypassword"};

Override in configuration

  [Kannel::SMSbox]
  password=mypassword

=cut

#see SMS::Send::Driver::WebService->password

=head2 host

Default: 127.0.0.1

Override in sub class

  sub _host_default {"myhost.domain.tld"};

Override in configuration

  [Kannel::SMSbox]
  host=myhost.domain.tld

=cut

#see SMS::Send::Driver::WebService->host

sub _host_default {"127.0.0.1"};

=head2 protocol

Default: http

Override in sub class

  sub _protocol_default {"https"};

Override in configuration

  [Kannel::SMSbox]
  protocol=https

=cut

#see SMS::Send::Driver::WebService->protocol

sub _protocol_default {"http"};

=head2 port

Default: 13013

Override in sub class

  sub _port_default {443};

Override in configuration

  [Kannel::SMSbox]
  port=443

=cut

#see SMS::Send::Driver::WebService->port

sub _port_default {13013};

=head2 script_name

Default: /cgi-bin/sendsms

Override in sub class

  sub _script_name_default {"/path/file"};

Override in configuration

  [Kannel::SMSbox]
  script_name=/path/file

=cut

#see SMS::Send::Driver::WebService->script_name

sub _script_name_default {'/cgi-bin/sendsms'};

=head2 url

Returns a L<URI> object based on above properties

=cut

#see SMS::Send::Driver::WebService->url

=head2 warnings

Default: 0

Override in sub class

  sub _warnings_default {1};

Override in configuration

  [Kannel::SMSbox]
  warnings=1

=cut

#see SMS::Send::Driver::WebService->warnings

=head2 debug

Default: 0

Override in sub class

  sub _debug_default {5};

Override in configuration

  [Kannel::SMSbox]
  debug=5

=cut

#see SMS::Send::Driver::WebService->debug

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT and LICENSE

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<SMS::Send>, L<SMS::Send::Driver::WebService>

=cut

1;
