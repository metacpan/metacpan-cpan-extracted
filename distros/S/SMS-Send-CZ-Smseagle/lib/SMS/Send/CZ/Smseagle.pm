#!/usr/bin/perl

package SMS::Send::CZ::Smseagle;

# ABSTRACT: SMS::Send driver for SMSEagle - Czech Republic 

use warnings;
use strict;
use Carp;

our $VERSION = "1.001";
$VERSION = eval $VERSION;

use LWP::UserAgent;
use URI::Escape;
use DateTime qw();
use base 'SMS::Send::Driver';
use Log::LogLite;
use Data::Dumper;
use Text::Unidecode;
use XML::Simple;

sub new {
	my $class  = shift;
	my %params = @_;

	my $LOG_FILE = "/var/log/smseagle.log";
	my $ERROR_LOG_LEVEL = 6;

	open HANDLE, ">>$LOG_FILE";
	close HANDLE;

	# Create our LWP::UserAgent object
	my $ua = LWP::UserAgent->new;

	# Create the object, saving any private params for later
	my $self = bless {
		ua       => $ua,
		login    => $params{_login},
		password => $params{_password},
		api_url  => $params{_api_url}, 
		private  => \%params,
		log	     => (-w $LOG_FILE) ? new Log::LogLite($LOG_FILE, $ERROR_LOG_LEVEL) : 0
	}, $class;
	$self->log("Driver Smseagle created", 4);
	
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
    my $url = $self->{'api_url'};
 	
 	$args{'text'} = unidecode($args{'text'});
	$self->log("TEXT: " . $args{'text'} . ", TO: " . $args{'to'}, 4);

	my %params = (
	    'to'	  => $args{'to'} || '', 
	    'message' => $args{'text'}  || '', 
	    'login'	  => $self->{'login'},
	    'pass'	  => $self->{'password'},
	    'responsetype' => 'xml'
	);

	# cleanup
	$params{'to'} =~ s{\D}{}g; # remove non-digits
	if (length($params{'to'}) == 9) {
		$params{'to'} = '00420' . $params{'to'};
		$self->log("Auto-prefix: " . $args{'to'} . " => " . $params{'to'}, 4);
	}
	
	# send away
    my $uri = join( '&', map { $_ . '=' . uri_escape_utf8( $params{ $_ } ) } keys %params );
 
	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    $ua->protocols_allowed( ['https'] );

    my $res = $ua->get($url . "?" . $uri);

    if( $res->{'_rc'} == 200 ) {
    	$params{'password'} = "------";	# hide password in logs
	    my $successLog = $url . "?" . join( '&', map { $_ . '=' . uri_escape_utf8( $params{ $_ } ) } keys %params );
		$self->log("HTTP SUCCESS: " . $successLog, 4);
		
		my $parser = new XML::Simple;
		my $data = $parser->XMLin($res->decoded_content);
		
		if ($data) {
			my $logMsg;
			my $result = 0;
			
			if ($data->{'status'} eq 'ok' ) {
				$logMsg = "SMS #" . $data->{'message_id'} . " sent";
				$result = 1; 
			}
			elsif ($data->{'status'} eq 'error') {
				$logMsg = "SMS processing error: " . $data->{'error_text'};
			}
			
			$self->log($logMsg, 4);
			
			return $result;
		}
	}
	else {
		return 0;
	}
}

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::CZ::Smseagle - SMS::Send driver for SMSEagle - Czech Republic 

=head1 VERSION

version 1.001

=head1 SYNOPSIS

use SMS::Send;

  my $sender = SMS::Send->new('CZ::Smseagle',
  	_login    => 'who',
  	_password => 'secret',
  	_api_url => 'https://.../index.php/http_api/send_sms
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

Logs message to /var/log/smseagle.log if this file is accessible and writable

=head2 send_sms

Sends the message using SMSEagle API, see https://www.smseagle.eu
Parameter 'text' contains the message itself and 'to' provides recipient's number.
API URL is passed to the constructor as '_api_url'. 

Processing information is automatically logged to /var/log/smseagle.log to allow tracking of possible problems.   

Returns true if the msssage was successfully sent

Returns false if an error occured

=cut

=head1 AUTHOR

Radek Šiman <rbit@rbit.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by R-Bit Technology, s.r.o.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
