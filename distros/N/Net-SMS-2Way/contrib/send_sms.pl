#!/usr/bin/perl

# IMPORTANT!!!!!!!  INSTALLATION INSTRUCTIONS #
# Pre-installation check: Make sure you have installed Net::SMS::2Way and you have read the documentation.
# 1.) Copy this script to a suitable location (e.g: /usr/local/bin/) and make sure it has the appropriate permissions.
# 2.) Create a file called sms.cfg and place it in a suitable location (e.g. /usr/local/etc/) with appropriate permissions.
# 3.) Place the following entries in the sms.cfg file (without the #'s) Place your username/password in the file. 
#  verbose = 1
#  logfile = /usr/local/var/sms.log
#  username = jbloggs
#  password = tH3p@5sw0Rd
#  3.1) Read the Net::SMS::2Way docs for more information on the config file
# 4.) Edit line number 18 of this script and change it to reflect the focation of the config file e.g.: my $bulksms_config_file = '/usr/local/etc/sms.cfg';
# 5.) Test the script doing the following /usr/local/bin/send_sms.pl 123456789 "This is a test"    NOTE!!! Replace 123456789 with your cell number
# 6.) View the log file (that your specified in the config file) for any errors
#####################

my $bulksms_config_file = '/etc/sms.cfg';

die "FATAL: Your config file: $bulksms_config_file does not exist!" unless -e $bulksms_config_file;

use Net::SMS::2Way;

my $sms = Net::SMS::2Way->new({config => $bulksms_config_file}) || die "FATAL: Could not create Net::SMS::2Way object!\n";

my $recipient = shift @ARGV;
my $message = shift @ARGV;
my @recipients;
my $usage = "Usage: $0 [recipient[,recipient]] [message]\n";

die $usage unless $recipient;

if ($recipient =~/\d+,\d+/) {
	@recipients = split /,/, $recipient;
} else {
	$recipients[0] = $recipient;
}

my $retval = $sms->send_sms($message, @recipients);

print 'Error Message: ' . $sms->{error} . "\n" if $sms->{error};

