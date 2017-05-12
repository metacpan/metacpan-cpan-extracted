#!/usr/bin/perl

package SMS::Send::CZ::Neogate;

# ABSTRACT: SMS::Send driver for Neogate - Czech Republic 

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
use XML::Simple;

sub new {
	my $class  = shift;
	my %params = @_;

	my $LOG_FILE = "/var/log/neogate.log";
	my $ERROR_LOG_LEVEL = 6;

	open HANDLE, ">>$LOG_FILE";
	close HANDLE;

	# Create our LWP::UserAgent object
	my $ua = LWP::UserAgent->new;

	# Create the object, saving any private params for later
	my $dt = DateTime->now(time_zone  => 'Europe/Prague');
	my $self = bless {
		ua       => $ua,
		login    => $params{_login},
		password => $params{_password},
		private  => \%params,
		stamp    => $dt->strftime('%Y%m%dT%H%M%S'),
		log      => (-w $LOG_FILE) ? new Log::LogLite($LOG_FILE, $ERROR_LOG_LEVEL) : 0
	}, $class;

	$self->log("Driver Neogate created", 4);
	
	$self;
}

sub log {
	my ($self, $msg, $level) = @_;

	if ($self->{'log'}) {
		$self->{'log'}->write($msg, $level);
	}
}

sub get_salt {
	my $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:-';
	my $len = length($chars);
	my $salt = '';
	for (my $i = 1; $i < (30 + int(rand(20))); $i++) {	# 30-49 characters
		$salt .= substr($chars, int(rand($len)), 1);
	}
	
	return $salt;
}

sub send_sms {
	my ($self, %args) = @_;
    my $url = 'https://api.smsbrana.cz/smsconnect/http.php';
 	my $salt = get_salt();

	my $rawtext = $self->{'password'} . $self->{'stamp'} . $salt;
	#for debugging only
	#$self->log("TEXT: " . $rawtext . ", MD5: " . md5_hex($rawtext));

	my %params = (
	    'number'   => $args{'to'} || '', 
	    'message'  => $args{'text'}  || '', 
	    'login'    => $self->{'login'},
		'sul'	   => $salt,
		'time'	   => $self->{'stamp'},
		'hash'	   => md5_hex($rawtext), 
	    'action'   => 'send_sms'
	);

	# cleanup
	$params{'number'} =~ s{\D}{}g; # remove non-digits
	
	# send away
    my $uri = join( '&', map { $_ . '=' . uri_escape_utf8( $params{ $_ } ) } keys %params );
 
	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    $ua->protocols_allowed( ['https'] );

    my $x = $url . "?" . $uri;
    my $res = $ua->get($url . "?" . $uri);

    if( $res->is_success ) {
		$self->log("HTTP SUCCESS: " . $x, 4);
		my $parser = new XML::Simple;
		my $data = $parser->XMLin($res->decoded_content);
		if ($data->{'err'} == 0) {
			$self->log("SMS #" . $data->{'sms_id'} . " sent, remaining credit: " . $data->{'credit'}, 4);

			return 1;
		}
		else {
			$self->log("SMS processing error: " . $data->{'err'}, 4);
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

SMS::Send::CZ::Neogate - SMS::Send driver for Neogate - Czech Republic 

=head1 VERSION

version 1.000

=head1 SYNOPSIS

use SMS::Send;

  my $sender = SMS::Send->new('CZ::Neogate',
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

=head2 get_salt

Generates random salt made up from 30-49 characters

=head2 send_sms

Sends the message using prividers API at https://api.smsbrana.cz/smsconnect/http.php and takes additional arguments:
'text' containgin the message itself and 'to' with recipient's number.

Processing information is automatically logged to /var/log/neogate.log to allow tracking of possible problems.   

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
