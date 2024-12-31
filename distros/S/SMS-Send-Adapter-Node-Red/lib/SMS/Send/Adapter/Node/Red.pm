package SMS::Send::Adapter::Node::Red;
use strict;
use warnings;
use base qw{Package::New};
use JSON::XS qw{decode_json encode_json};
use SMS::Send;
use CGI;

our $VERSION = '0.10';
our $PACKAGE = __PACKAGE__;

=head1 NAME

SMS::Send::Adapter::Node::Red - SMS::Send Adapter to Node-RED JSON HTTP request

=head1 SYNOPSIS

CGI Application

  use SMS::Send::Adapter::Node::Red;
  my $service = SMS::Send::Adapter::Node::Red->new(content => join('', <>));
  $service->cgi_response;

PSGI Application

  use SMS::Send::Adapter::Node::Red;
  SMS::Send::Adapter::Node::Red->psgi_app

PSGI Plack Mount

  use SMS::Send::Adapter::Node::Red;
  use Plack::Builder qw{builder mount};
  builder {
    mount '/sms' => SMS::Send::Adapter::Node::Red->psgi_app;
    mount '/'    => sub {[404=> [], []]};
  }

=head1 DESCRIPTION

This Perl package provides an adapter from Node-RED HTTP request object with a JSON payload to the SMS::Send infrastructure using either a PSGI or a CGI script.  The architecture works easiest with SMS::Send drivers based on the L<SMS::Send::Driver::WebService> base object since common settings can be stored in the configuration file.

=head1 CONSTRUCTOR

=head2 new

  my $object = SMS::Send::Adapter::Node::Red->new(content=>$string_of_json_object);

=head1 PROPERTIES

=head2 content

JSON string payload of the HTTP post request.

Example Payload:

  {
    "to"      : "7035551212",
    "text"    : "My Text Message",
    "driver"  : "VoIP::MS",
    "options" : {}
  }

The Perl logic is based on this one-liner with lots of error trapping

  my $sent = SMS::Send->new($driver, %$options)->send_sms(to=>$to, text=>$text);

I use a Node-RED function like this to format the JSON payload.

  my_text     = msg.payload;
  msg.payload = {
                 "driver"  : "VoIP::MS",
                 "text"    : my_text,
                 "to"      : "7035551212",
                 "options" : {"key" : "value"},
                };
  return msg;

=cut

sub content {
  my $self = shift;
  die("Error: content not defined on construction") unless defined $self->{'content'};
  return $self->{'content'};
}

=head1 METHODS (STATE)

=head2 input

JSON Object from input that is passed to output.

=cut

sub input {
  my $self  = shift;
  if (not defined $self->{'input'}) {
    local $@;
    my $input = eval{decode_json($self->content)};
    my $error = $@;
    if ($error) {
      $self->set_status_error(400=>'Error: JSON decode failed');
    } elsif (ref($input) ne 'HASH') {
      $self->set_status_error(400=>'Error: JSON Object required');
    } else {
      $self->{'input'} = $input;
    }
  }
  return $self->{'input'};
}

=head2 status

HTTP Status Code returned to Node-RED is one of 200, 400, 500 or 502. Typically, a 200 means the SMS message was successfully sent to the provider, a 400 means the input is malformed, a 500 means the server is misconfigured (verify installation), and a 502 means that the remote service has issues or is unreachable.

=cut

sub status {
  my $self          = shift;
  $self->{'status'} = shift if @_;
  die("Error: status not set. sms_send method must be called first") unless $self->{'status'};
  return $self->{'status'};
}

=head2 status_string

Format HTTP Status Code as string for web response

=cut

our $STATUS_STRING = {
                      200 => 'OK',
                      400 => 'Bad Request',
                      500 => 'Internal Server Error',
                      502 => 'Bad Gateway',
                     };

sub status_string {
  my $self          = shift;
  my $status        = $self->status;
  my $status_string = $STATUS_STRING->{$status} or die("Error: STATUS_STRING not defined for $status");
  return "$status $status_string";
}

=head2 error

Error string passed in the JSON return object.

=cut

sub error {
  my $self = shift;
  $self->{'error'} = shift if @_;
  return $self->{'error'};
}

=head2 set_status_error

Method to set the HTTP status and error with one function call.

=cut

sub set_status_error {
  my $self   = shift;
  my $status = shift or die;
  my $error  = shift || '';
  $self->status($status);
  $self->error($error);
  return $self;
}

=head2 driver

Returns configured SMS driver from input, environment, or SMS-Send.ini.

=cut

sub driver {
  my $self     = shift;
  my $driver   = undef;
  my $ini_file = '/etc/SMS-Send.ini';
  my $input    = $self->input; #undef on error
  if (defined $input) {
    #Set driver from input
    $driver    = $input->{'driver'} if $input->{'driver'};
  }
  if (!$driver) {
    #Set driver from environment
    my $DRIVER = $ENV{'SMS_SEND_ADAPTER_NODE_RED_DRIVER'};
    $driver    = $DRIVER if $DRIVER;
  }
  if (!$driver and -r $ini_file) {
    #Set driver from INI file
    require Config::IniFiles;
    my $cfg     = Config::IniFiles->new(-file=>$ini_file);
    my @drivers = grep {$cfg->val($_, 'active', '1')} $cfg->Sections;
    $driver     = $drivers[0] if @drivers;
  }
  return $driver;
}

=head1 METHODS (ACTIONS)

=head2 send_sms

Wrapper around the SMS::Send->send_sms call.

=cut

sub send_sms {
  my $self = shift;
  my $sent = 0;
  my $SMS  = $self->SMS;
  if ($SMS) {
    my $to   = $self->input->{'to'};
    my $text = $self->input->{'text'};
    if ($to and $text) {
      local $@;
      $sent     = eval{$SMS->send_sms(to=>$to, text=>$text)};
      my $error = $@;
      if ($error) {
        $self->set_status_error(502=>"Error: Failed call SMS::Send->send_sms. $error");
      } elsif (!$sent) {
        $self->set_status_error(502=>'Error: Unknown. SMS::Send->send_sms returned unsuccessful');
      } else {
        $self->set_status_error(200=>'');
      }
    } elsif (!$to and $text) {
      $self->set_status_error(400=>'Error: JSON input missing "to"');
    } elsif ($to and !$text) {
      $self->set_status_error(400=>'Error: JSON input missing "text"');
    } else {
      $self->set_status_error(400=>'Error: JSON input missing "to" and "text"');
    }
  }
  return $sent;
}

=head2 cgi_response

Formatted CGI response

=cut

sub cgi_response {
  my $self   = shift;
  my $sent   = $self->send_sms ? \1 : \0; #sets object properties
  my %response = (sent  => $sent);
  $response{'error'} = $self->error if $self->error;
  $response{'input'} = $self->input if $self->input;
  print $self->CGI->header(
                           -status => $self->status_string,
                           -type   => 'application/json',
                          ),
        encode_json(\%response),
        "\n";
}

=head2 psgi_app

Returns a PSGI application

=cut

sub psgi_app {
  return sub {
    my $env            = shift;
    my $length         = $env->{'CONTENT_LENGTH'} || 0;
    my $content        = '';
    if ($length > 0) {
      my $fh           = $env->{'psgi.input'};
      $fh->read($content, $length, 0);
    }
    my $service        = $PACKAGE->new(content => $content);
    my $sent           = $service->send_sms ? \1 : \0; #sets object properties
    my %response       = (sent  => $sent);
    $response{'error'} = $service->error if $service->error;
    $response{'input'} = $service->input if $service->input;

    return [
      $service->status,
      [ 'Content-Type' => 'application/json' ],
      [ encode_json(\%response), "\n" ],
    ];
  };
}

=head1 OBJECT ACCESSORS

=head2 CGI

Returns a L<CGI> object for use in this package.

=cut

sub CGI {
  my $self       = shift;
  $self->{'CGI'} = CGI->new('') unless $self->{'CGI'};
  return $self->{'CGI'};
}

=head2 SMS

Returns a L<SMS::Send> object for use in this package.

=cut

sub SMS {
  my $self  = shift;
  my $input = $self->input; #undef on error
  if (defined $input) {
    my $driver   = $self->driver;
    if ($driver) {
      my $options = $input->{'options'} || {};
      if (ref($options) eq 'HASH') {
        local $@;
        $self->{'SMS'} =  eval{SMS::Send->new($driver, %$options)};
        my $error      = $@;
        if ($error) {
          my $text = qq{Failed to load Perl package SMS::Send with driver "$driver". Ensure SMS::Send::$driver is installed. $error};
          $self->set_status_error(500=>$text);
        }
      } else {
        $self->set_status_error(400=>'Error: JSON input "options" not an object.');
      }
    } else {
      $self->set_status_error(400=>'Error: "driver" not defined in JSON payload, environment variable SMS_SEND_ADAPTER_NODE_RED_DRIVER, or in SMS-Send.ini.');
    }
  }
  return $self->{'SMS'};
}

=head1 SEE ALSO

L<SMS::Send>, L<CGI>, L<JSON::XS>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2020 Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
