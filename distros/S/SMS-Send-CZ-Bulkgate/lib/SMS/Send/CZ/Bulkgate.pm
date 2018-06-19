#!/usr/bin/perl

package SMS::Send::CZ::Bulkgate;

# ABSTRACT: SMS::Send driver for Bulkgate - Czech Republic 

use warnings;
use strict;
use Carp;

our $VERSION = "1.001";
$VERSION = eval $VERSION;

use LWP::UserAgent;
use IO::Socket::SSL;
use URI::Escape;
use DateTime qw();
use base 'SMS::Send::Driver';
use Digest::MD5 qw(md5 md5_hex);
use Log::LogLite;
use Data::Dumper;
use Text::Unidecode;

sub new {
	my $class  = shift;
	my %params = @_;

	my $LOG_FILE = "/var/log/bulkgate.log";
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
	$self->log("Driver Bulkgate created", 4);
	
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
    my $url = 'https://api.bulkgate.com/http';
 	
 	$args{'text'} = unidecode($args{'text'});
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
 
	IO::Socket::SSL::set_ctx_defaults(
	     SSL_verifycn_scheme => 'www',
	     SSL_verify_mode => 0,
	);

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
        $self->log("Error " . $res->{'_rc'}, 4);
        $self->log($res->{'_content'}, 4);
		return 0;
	}
}

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::CZ::Bulkgate - SMS::Send driver for Bulkgate - Czech Republic 

=head1 VERSION

version 1.001

=head1 SYNOPSIS

use SMS::Send;

  my $sender = SMS::Send->new('CZ::Bulkgate',
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

Logs message to /var/log/bulkgate.log if this file is accessible and writable

=head2 send_sms

Sends the message using prividers API at https://api.bulkgate.com/http and takes additional arguments:
'text' containgin the message itself and 'to' with recipient's number.

Processing information is automatically logged to /var/log/bulkgate.log to allow tracking of possible problems.   

Returns true if the msssage was successfully sent

Returns false if an error occured

=cut

=head1 AUTHOR

Radek Šiman <rbit@rbit.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by R-Bit Technology, s.r.o.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
