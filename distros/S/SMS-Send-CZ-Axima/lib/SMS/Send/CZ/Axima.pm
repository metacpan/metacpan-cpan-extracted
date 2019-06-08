#!/usr/bin/perl

package SMS::Send::CZ::Axima;

# ABSTRACT: SMS::Send driver for Axima - Czech Republic 

use warnings;
use strict;
use Carp;

our $VERSION = "1.000";
$VERSION = eval $VERSION;

use LWP::UserAgent;
 
use base 'SMS::Send::Driver';
use Text::Unidecode;
use Digest::MD5 qw(md5 md5_hex);
use XML::Simple;
use Log::LogLite qw(logpath);

sub new {
	my $class  = shift;
	my %params = @_;

    # prepare logging
    my $LOG_FILE = "/tmp/axima.log";
    my $ERROR_LOG_LEVEL = 6;
    open(my $fh, ">", $LOG_FILE);
    close $fh;

    # Create our LWP::UserAgent object
    my $ua = LWP::UserAgent->new;

	# Create the object, saving any private params for later
	my $self = bless {
                          ua       => $ua,
                          login    => $params{_login},
                          password => $params{_password},
                          private  => \%params,
                          
                          # State variables
                          logged_in => '',
                          
                          # logging
                          log      => (-w $LOG_FILE) ? new Log::LogLite($LOG_FILE, $ERROR_LOG_LEVEL) : 0
                      }, $class;

    $self->log("Driver Axima created", 4);
    
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
    my $url = 'https://smsgateapi.sms-sluzba.cz/apipost30/sms';
    
    $args{'text'} = unidecode($args{'text'});
 
	my %params = (
	    'msisdn'   => $args{'to'} || '', 
	    'msg'     => $args{'text'}  || '', 
	    'act'      => 'send',
	    'login'    => $self->{'login'},
	    'auth' => md5_hex(md5_hex($self->{'password'}) . $self->{'login'} . 'send' . substr($args{'text'}, 0, 31)) 
	);

	# cleanup
	$params{'msisdn'} =~ s{\D}{}g; # remove non-digits
	
	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    $ua->protocols_allowed( ['https'] );
    my $res = $ua->post($url, \%params );

    if( $res->is_success ) {
    	if ( $res->decoded_content ) {
            my $parser = new XML::Simple;
            my $data = $parser->XMLin($res->decoded_content);
            if ($data->{'id'} == 200) {
            	return 1;
            }
            else {
            	$self->log("SMS processing error: " . $data->{'message'}, 4);
            	return 0;
            }
    	}
    	$self->log("Unexpected response from SMS provider: " . res->decoded_content, 4);
        return 0;
	}
	else {
		$self->log("Communication error", 4);
		return 0;
	}
}

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::CZ::Axima - SMS::Send driver for Axima - Czech Republic 

=head1 VERSION

version 1.000

=head1 SYNOPSIS

use SMS::Send;

  my $sender = SMS::Send->new('CZ::Axima',
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

=head2 send_sms

Sends the message using provider's API at https://smsgateapi.sms-sluzba.cz/apipost30/sms and takes additional arguments:
'text' containgin the message itself and 'to' with recipient's number.

Processing information is automatically logged to /tmp/axima.log to allow tracking of possible problems.   

Returns true if the msssage was successfully sent

Returns false if an error occured

=cut

=head1 AUTHOR

Radek Šiman <rbit@rbit.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by R-Bit Technology, s.r.o.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
