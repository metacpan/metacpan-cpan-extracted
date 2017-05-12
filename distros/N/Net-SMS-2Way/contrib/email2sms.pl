#!/usr/bin/perl
# Author: Lee Engel, <lee@kode.co.za>
# Copyright (C) 2009 by Lee S. Engel
# A very simple email-to-sms gateway.

# INSTALLATION INSTRUCTIONS:
# Create a user which will handle all the email-to-sms stuff. Example: adduser -m -d /home/sms sms
# Install Net::SMS::2Way and create a config file for it at /home/sms/sms.cfg
# Install the MailTool Perl module. (See http://search.cpan.org/~markov/MailTools-2.04/)  Try this: perl -MCPAN -e " install( 'MailTool' ); "
# Create a .forward file in the sms user's home directory:  echo '|/home/sms/email2sms.pl' > /home/sms/.forward
# Change your alias_maps config option in /etc/postfix/main.cf  to look like this: alias_maps = hash:/etc/aliases pcre:/etc/aliases-regexp
# Create /etc/aliases-regexp with a line which looks likes this: /^\d+$/ sms
# Copy this script to /home/sms/email2sms.pl and make it executable by all.

# USAGE INSTRUCTIONS
# Once you have done the above you can send en email to 27812345678@yourdomain.com
# where 27812345678 is the mobile number you want send a message to and yourdomain.com is your domain.
# Check the postfix logs for errors.

############ CONFIG OPTIONS START ############
my $sms_config_file = '/home/sms/sms.cfg';
my $email_from_address = 'sms-system-noreply@domain-goes-here.tld';
############ CONFIG OPTIONS END  #############

use Net::SMS::2Way;
use Mail::Header;
use Mail::Internet;
use Mail::Send;

die "FATAL: Config file ($sms_config_file) does not exist!\n" unless -e $sms_config_file;

my $mail = Mail::Internet->new(\*STDIN);
my $mail_headers = $mail->head();

my $mail_body = $mail->body();
$mail->tidy_body( $mail_body );

my $body_text = join( "\n",  @$mail_body );
chomp( $body_text );

if( length( $body_text ) > 160 )
{
	$body_text = substr( $body_text, 0, (160 - length($body_text)) );
}

my $headers = $mail_headers->header_hashref();
my $sender_address = $headers->{From}->[0];
$sender_address =~ s/^(\S+)\s+.*/$1/;
chomp( $sender_address);
my $recipient;

my @to_headers = qw( To X-Original-To Delivered-To );

foreach my $to_header ( @to_headers )
{
	if( $headers->{$to_header}->[0] =~ /^(\d+)\@/ )
	{
		$recipient = $1;
		last;
	}
}

if( !$recipient )
{
	# This bit of code below is optional. This is an example of how to reply to the sender.
	#send_email( $email_from_address, $sender_address, "Email-to-SMS System Error", 
	#			"Hi,\n\nThe email-to-sms gateway could not extract a valid recipient number from your email.\n\n"
	#			. "No SMS message has been sent.\n\nRegards,\nThe Email-to-SMS Gateway :-)\n" );

	die "EMAIL-TO-SMS FAILURE: A valid recipient could not be extracted!\n";
}

my $sms = Net::SMS::2Way->new( {config => $sms_config_file} ) || die "EMAIL-TO-SMS FAILURE: Could not create Net::SMS::2Way object!\n";

$sms->send_sms( $body_text, $recipient );

warn( "EMAIL-TO-SMS WARNING: " . $sms->{error} . "\n" ) if $sms->{error} ne '';

sub send_email
{
	my $from = shift;
	my $to = shift;
	my $subject = shift;
	my $message = shift;
	
	return unless $from;
	return unless $to;
	return unless $subject;
	return unless $message;
	
	my $email = Mail::Send->new;
	
	$email->to( $to );
	$email->set( 'From', $from );
	$email->set( 'Reply-to', $from );
	$email->set( 'Return-Path', $from );
	$email->subject( $subject );
	
	my $FH = $email->open( 'sendmail' );
	
	print $FH $message;
	
	$FH->close() || return -1;
}