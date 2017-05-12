#!/usr/bin/perl

package SMS::Send::CZ::Smsmidlet;

# ABSTRACT: SMS::Send driver for SMSMidlet - Czech Republic 

use warnings;
use strict;
use Carp;

our $VERSION = "1.000";
$VERSION = eval $VERSION;

use LWP::UserAgent;
use URI::Escape;
use DateTime qw();
use base 'SMS::Send::Driver';
use Digest::MD5 qw(md5 md5_hex);
use Log::LogLite;
use Data::Dumper;

sub new {
	my $class  = shift;
	my %params = @_;

	my $LOG_FILE = "/var/log/smsmidlet.log";
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
		private  => \%params,
		log	     => (-w $LOG_FILE) ? new Log::LogLite($LOG_FILE, $ERROR_LOG_LEVEL) : 0
	}, $class;
	$self->log("Driver Smsmidlet created", 4);
	
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
    my $url = 'https://smsmidlet.com/http';
 	
	$self->log("TEXT: " . $args{'text'} . ", TO: " . $args{'to'}, 4);

	my %params = (
	    'number'	=> $args{'to'} || '', 
	    'data'  	=> $args{'text'}  || '', 
	    'username'	=> $self->{'login'},
	    'password'	=> $self->{'password'},
	    'action'	=> 'sendsmsall'
	);

	# cleanup
	$params{'number'} =~ s{\D}{}g; # remove non-digits
	if (length($params{'number'}) == 9) {
		$params{'number'} = '420' . $params{'number'};
		$self->log("Auto-prefix: " . $args{'to'} . " => " . $params{'number'}, 4);
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

		if ($res->{'_content'} =~ /<stat>(\d+)<\/stat><info>([^<]+)<\/info>/) {
			my $stat = $1;
			my $info = $2;
			my $logMsg;
			my $result = 0;
			
			SWITCH: {
				if ($stat == 1) { $logMsg = "SMS #" . $info . " sent"; $result = 1; last SWITCH; }
				if ($stat == 11) { $logMsg = "SMS #" . $info . " deferred, re-sending in 1 minute"; $result = 1; last SWITCH; } 
				$logMsg = "SMS processing error #" . $stat . ": " . $info;
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

SMS::Send::CZ::Smsmidlet - SMS::Send driver for SMSMidlet - Czech Republic 

=head1 VERSION

version 1.000

=head1 SYNOPSIS

use SMS::Send;

  my $sender = SMS::Send->new('CZ::Smsmidlet',
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

Logs message to /var/log/smsmidlet.log if this file is accessible and writable

=head2 send_sms

Sends the message using prividers API at https://smsmidlet.com/http and takes additional arguments:
'text' containgin the message itself and 'to' with recipient's number.

Processing information is automatically logged to /var/log/smsmidlet.log to allow tracking of possible problems.   

Returns true if the msssage was successfully sent

Returns false if an error occured

=cut

=head1 AUTHOR

Radek Šiman <rbit@rbit.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by R-Bit Technology, s.r.o.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
