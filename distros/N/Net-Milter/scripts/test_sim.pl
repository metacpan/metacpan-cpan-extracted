#!/usr/bin/perl 

# this program is an example of talking to a milter filter
# sending a very simple email, sent from the machine 'portland'
# IP address 127.0.0.1, sent from martin@localhost to 
# martin@localhost, with a single header 'Subject: hi there',
# and a message body 'this is the body'.

use Net::Milter;
use strict;
no strict 'refs';

my (@results);

# connect to the milter via tcp on port 5513
my $milter = new Net::Milter;
$milter->open('127.0.0.1',5513,'tcp');

my ($ret_version,$returned_actions_ref,$returned_protocol_ref) = $milter->protocol_negotiation();
print "returned milter protocol : $ret_version\n";

print "Requested actions :\n";
foreach (@{$returned_actions_ref}) {
    print "\t$_\n";
}

print "Undesired protocol content :\n";
foreach (@{$returned_protocol_ref}) {
    print "\t$_\n";
}


# send email information
#############
# send connection macro information

$milter->send_macros(
		     j => 'localhost.localdomain',
		     _ => 'portland [127.0.0.1]',
		     '{daemon_name}' => 'MTA',
		     '{if_name}'     => 'portland'
		     );

# send connection information
(@results) = $milter->send_connect('portland','tcp4','12345','127.0.0.1');

foreach (@results) {
    print "\n".'returned command : '.$$_{command}."\n";
    print 'explanation : '.$$_{explanation}."\n";
    print 'action : '.$$_{action}."\n";
    if ($$_{action} eq 'accept' || $$_{action} eq 'reject') {$milter->send_quit();exit;}
}

#############
# send HELO information

(@results) = $milter->send_helo('martin@localhost');
foreach (@results) {
    print "\n".'returned command : '.$$_{command}."\n";
    print 'explanation : '.$$_{explanation}."\n";
    print 'action : '.$$_{action}."\n";
    if ($$_{action} eq 'accept' || $$_{action} eq 'reject') {$milter->send_quit();exit;}
}


#############
# send mail macro information

$milter->send_macros(
		     'i' => 'h8A8sjOQ014446',
		     '{mail_mailer}'   => 'local',
		     '{mail_host}'   => '',
		     '{mail_addr}'   => 'martin',
		     );
# send MAIL FROM information

(@results) = $milter->send_mail_from('martin@localhost');
foreach (@results) {
    print "\n".'returned command : '.$$_{command}."\n";
    print 'explanation : '.$$_{explanation}."\n";
    print 'action : '.$$_{action}."\n";
    if ($$_{action} eq 'accept' || $$_{action} eq 'reject') {$milter->send_quit();exit;}
}


#############
# send RCPT macro information

$milter->send_macros(
		     '{rcpt_mailer}' => 'local',
		     '{rcpt_host}'   => '',
		     '{rcpt_addr}'   => 'martin',
		     );
# send RCPT TO information

(@results) = $milter->send_rcpt_to('<martin@localhost>');
foreach (@results) {
    print "\n".'returned command : '.$$_{command}."\n";
    print 'explanation : '.$$_{explanation}."\n";
    print 'action : '.$$_{action}."\n";
    if ($$_{action} eq 'accept' || $$_{action} eq 'reject') {$milter->send_quit();exit;}
}


#############
# send information about one header

(@results) = $milter->send_header('subject','hi there');
foreach (@results) {
    print "\n".'returned command : '.$$_{command}."\n";
    print 'explanation : '.$$_{explanation}."\n";
    print 'action : '.$$_{action}."\n";
    if ($$_{action} eq 'accept' || $$_{action} eq 'reject') {$milter->send_quit();exit;}
}

#############
# inform no more headers to be sent

(@results) = $milter->send_end_headers();
foreach (@results) {
    print "\n".'returned command : '.$$_{command}."\n";
    print 'explanation : '.$$_{explanation}."\n";
    print 'action : '.$$_{action}."\n";
    if ($$_{action} eq 'accept' || $$_{action} eq 'reject') {$milter->send_quit();exit;}
}


#############
# send the body

(@results) = $milter->send_body("\nthis is the body\n");
foreach (@results) {
    print "\n".'returned command : '.$$_{command}."\n";
    print 'explanation : '.$$_{explanation}."\n";
    print 'action : '.$$_{action}."\n";
    if ($$_{action} eq 'accept' || $$_{action} eq 'reject') {$milter->send_quit();exit;}
}


#########################
# send end of body

(@results) = $milter->send_end_body();
foreach (@results) {
    print "\n".'returned command : '.$$_{command}."\n";
    print 'explanation : '.$$_{explanation}."\n";
    print 'action : '.$$_{action}."\n";
    if ($$_{action} eq 'accept' || $$_{action} eq 'reject') {$milter->send_quit();exit;}
}


############
# nothing to do, send quit

$milter->send_quit();











