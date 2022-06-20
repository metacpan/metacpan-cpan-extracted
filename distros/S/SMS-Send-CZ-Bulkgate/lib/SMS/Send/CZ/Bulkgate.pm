#!/usr/bin/perl

package SMS::Send::CZ::Bulkgate;

# ABSTRACT: SMS::Send driver for Bulkgate - Czech Republic 

use warnings;
use strict;
use Carp;

our $VERSION = "2.004";
$VERSION = eval $VERSION;

use LWP::UserAgent;
use LWP::Protocol::https;
use DateTime qw();
use base 'SMS::Send::Driver';
use Log::LogLite;
use Text::Unidecode;
use JSON;

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
    my $url = 'https://portal.bulkgate.com/api/1.0/simple/transactional';
 	
 	$args{'text'} = unidecode($args{'text'});
	$self->log("TEXT: " . $args{'text'} . ", TO: " . $args{'to'}, 4);

    # example: 1111:gOwn:420111222333 
    my @id = split(':', $self->{'login'});  
    my $app_id = $id[0]; 
    my $sender_id = defined $id[1] ? $id[1] : 'gSystem';
    my $sender_id_value = defined $id[2] ? $id[2] : undef;

	my %params = (
	    'application_id'       => $id[0],
	    'application_token'    => $self->{'password'},
	    'number'	           => $args{'to'} || '', 
	    'text'  	           => $args{'text'}  || '', 
	    'unicode'	           => 0,
	    'sender_id'            => $sender_id,
	    'sender_id_value'      => $sender_id_value
	);

	# cleanup
	$params{'number'} =~ s{\D}{}g; # remove non-digits
	if (length($params{'number'}) == 9) {
		$params{'number'} = '420' . $params{'number'};
		$self->log("Auto-prefix: " . $args{'to'} . " => " . $params{'number'}, 4);
	}
	
	# send away
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    $ua->protocols_allowed( ['https'] );
    my $res = $ua->post($url, \%params );

    if( $res->{'_rc'} == 200 ) {
    	my $json = decode_json($res->{'_content'});
    	if (defined $json->{data}->{status} && $json->{data}->{status} eq 'accepted') {
            $self->log("SMS sent to : " . $args{'to'} . ", text: " . $args{'text'}, 4);
            return 1;
    	}
    	else {
            $self->log("Unexpected response from SMS provider: " . $res->{'_content'}, 4);
            return 0;
    	}
    }
    else {
        my $json = eval { decode_json($res->{'_content'}) };
        $self->log("Error " . $res->{'_rc'} . ": " . (defined $json ? $json->{error} : 'unexpected error'), 4);
        return 0;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::CZ::Bulkgate - SMS::Send driver for Bulkgate - Czech Republic 

=head1 VERSION

version 2.004

=head1 SYNOPSIS

use SMS::Send;

  # see https://help.bulkgate.com/docs/cs/http-simple-transactional.html
  my $sender = SMS::Send->new('CZ::Bulkgate',
  	_login    => '1111:gOwn:420111222333',
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

Sends the message using BulkGate Simple API at https://portal.bulkgate.com/api/1.0/simple/transactional and takes additional arguments:
'text' containing the message itself and 'to' providing recipient's number.

Processing information is automatically logged to /var/log/bulkgate.log to allow tracking of possible problems.   

Returns true if the msssage was successfully sent

Returns false if an error occured

=cut

=head1 AUTHOR

Radek Šiman <rbit@rbit.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by R-Bit Technology, s.r.o.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
