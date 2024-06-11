#!/usr/bin/perl

package SMS::Send::CZ::Smsmanager;

# ABSTRACT: SMS::Send driver for SMS Manager - Czech Republic 

use warnings;
use strict;
use Carp;

our $VERSION = "1.001";
$VERSION = eval $VERSION;

use LWP::UserAgent;
use URI::Escape;
use DateTime qw();
use base qw(SMS::Send::Driver);
use Log::LogLite;
use Text::Unidecode;
use Data::Dumper;

sub new {
	my $class  = shift;
	my %params = @_;

	my $LOG_FILE = "/var/log/smsmanager.log";
	my $ERROR_LOG_LEVEL = 6;

	open HANDLE, ">>$LOG_FILE";
	close HANDLE;

	# Create our LWP::UserAgent object
	my $ua = LWP::UserAgent->new;

	# Create the object, saving any private params for later
	my $dt = DateTime->now(time_zone  => 'Europe/Prague');
	my $self = bless {
		ua       => $ua,
		apikey   => $params{_password},
		private  => \%params,
		stamp    => $dt->strftime('%Y%m%dT%H%M%S'),
		log      => (-w $LOG_FILE) ? new Log::LogLite($LOG_FILE, $ERROR_LOG_LEVEL) : 0
	}, $class;

	$self->log("Driver Smsmanager created", 4);
	
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
    my $url = 'https://http-api.smsmanager.cz/Send';

    $args{'text'} = unidecode($args{'text'});
	my $params = {
	    'number'   => $args{'to'} || '', 
	    'message'  => $args{'text'}  || '', 
		'apikey'   => $self->{apikey}
	};

	# cleanup
	$params->{'number'} =~ s{\D}{}g; # remove non-digits
	
	# send away
	my $ua = LWP::UserAgent->new();
    my $res = $ua->post($url, $params );

    if( $res->is_success ) {
		$self->log("HTTP SUCCESS: " . $args{'to'} . " - " . $args{'text'}, 4);
		my $data = $res->decoded_content;
		if ( substr($data, 0, 2) eq 'OK' ) {
			$self->log("SMS sent: " . $data, 4);

			return 1;
		}
		else {
			$self->log("SMS processing error: " . $data, 4);
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

SMS::Send::CZ::Smsmanager - SMS::Send driver for SMS Manager - Czech Republic 

=head1 VERSION

version 1.001

=head1 SYNOPSIS

use SMS::Send;

  my $sender = SMS::Send->new('CZ::Smsmanager',
  	_login    => 'who',
  	_password => 'apikey',
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

=head1 NAME

SMS::Send::CZ::Smsmanager - SMS::Send driver for SMS Manager - Czech Republic 

=head1 VERSION

version 1.000

=head1 METHODS

=head2 send_sms

Sends the message using privider's API at https://http-api.smsmanager.cz/Send and takes additional arguments:
'text' containing the message itself and 'to' with recipient's number.

Processing information is automatically logged to /var/log/smsmanager.log to allow tracking of possible problems.   

Returns true if the msssage was successfully sent

Returns false if an error occured

=head1 AUTHOR

Radek Šiman <rbit@rbit.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by R-Bit Technology, s.r.o.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Radek Šiman <rbit@rbit.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by R-Bit Technology, s.r.o.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
