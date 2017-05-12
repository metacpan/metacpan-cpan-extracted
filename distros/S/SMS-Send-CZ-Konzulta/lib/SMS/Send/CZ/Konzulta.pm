#!/usr/bin/perl

package SMS::Send::CZ::Konzulta;

# ABSTRACT: SMS::Send driver for Konzulta - Czech Republic 

use warnings;
use strict;
use Carp;

our $VERSION = "1.000";
$VERSION = eval $VERSION;

use base 'SMS::Send::Driver';
use Log::LogLite;
use XML::Simple;
use LWP::UserAgent;
use DateTime qw();

sub new {
    my $class  = shift;
    my %params = @_;

    my $LOG_FILE = "/var/log/konzulta.log";
    my $ERROR_LOG_LEVEL = 6;

    open HANDLE, ">>$LOG_FILE";
    close HANDLE;

    my $dt = DateTime->now(time_zone  => 'Europe/Prague');
    my $self = bless {
        login    => $params{_login},
        password => $params{_password},
        stamp    => $dt->strftime('%Y%m%dT%H%M%S'),
        log      => (-w $LOG_FILE) ? new Log::LogLite($LOG_FILE, $ERROR_LOG_LEVEL) : 0
    }, $class;

    $self->log("Driver Konzulta created", 4);
    
    $self;
}

sub log {
    my ($self, $msg, $level) = @_;

    if ($self->{'log'}) {
        $self->{'log'}->write($msg, $level);
    }
}

sub send_sms {
    my ($self, %args) = @_;
    my $url = 'https://www.sms-operator.cz/webservices/webservice.aspx';
    
    $self->log("TEXT: " . $args{'text'} . ", TO: " . $args{'to'}, 4);
    
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    my $message = "<SmsServices>
		  <DataHeader>
		    <DataType>SMS</DataType>
		    <UserName>$self->{'login'}</UserName>
		    <Password>$self->{'password'}</Password>
		  </DataHeader>
		  <DataArray>
		    <DataTemplate>
		      <Text>$args{'text'}</Text>
		      <DataItem>
		        <MobileTerminate>$args{'to'}</MobileTerminate>
		        <SmsId>$self->{'stamp'}</SmsId>
		      </DataItem>
		    </DataTemplate>
		  </DataArray>
		</SmsServices>
    ";
    
    my $res = $ua->post($url, Content_Type => 'text/xml', Content => $message);

    if( $res->is_success ) {
        $self->log("HTTP SUCCESS", 4);
        if ( $res->decoded_content ) {
	        my $parser = new XML::Simple;
	        my $data = $parser->XMLin($res->decoded_content);
	        if ($data->{'DataArray'}->{'DataItem'}->{'Status'} == 0) {
	            $self->log("SMS #" . $data->{'DataArray'}->{'DataItem'}->{'SmsId'} . " sent", 4);
	
	            return 1;
	        }
	        else {
	            $self->log("SMS processing error: " . $data->{'DataArray'}->{'DataItem'}->{'Status'}, 4);
	            return 0;
	        }
        }
        else {
                $self->log("SMS processing error: invalid credentials?", 4);
                return 0;
        }
    }
    else {
        $self->log("HTTP error #" . $res->code() . ": " . $res->message(), 4);
        return 0;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::CZ::Konzulta - SMS::Send driver for Konzulta - Czech Republic 

=head1 VERSION

version 1.000

=head1 SYNOPSIS

use SMS::Send;

  my $sender = SMS::Send->new('CZ::Konzulta',
    _login    => 'who',
    _password => 'secret',
    );
  
  my $sent = $sender->send_sms(
    text => 'Test SMS',
    to   => '604111111',
    );
  
  # Did it send?
  if ( $sent ) {
    print "Sent test message\n";
  } else {
    print "Test message failed\n";
  }

=head1 METHODS

=head2 log

Logs message to /var/log/konzulta.log if this file is accessible and writable

=head2 send_sms

Sends the message using provider's API at https://www.sms-operator.cz/webservices/webservice.aspx and takes additional arguments:
'text' containgin the message itself and 'to' with recipient's number.

Processing information is automatically logged to /var/log/konzulta.log to allow tracking of possible problems.   

Returns true if the msssage was successfully sent

Returns false if an error occured

=cut

=head1 AUTHOR

Radek Šiman <rbit@rbit.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by R-Bit Technology, s.r.o.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
