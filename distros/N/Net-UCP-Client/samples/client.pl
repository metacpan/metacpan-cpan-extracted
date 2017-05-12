#!/usr/bin/perl -w
use strict;
use warnings;
use Net::UCP::Client qw(NOTIFY NONOTIFY NOBYPASS BYPASS);
use Encode;
use Data::Dumper;

use vars qw($uclient);

my $user      = "username";
my $password  = "password";
my $smsc_host = "ucp.server.tld";
my $smsc_port = 6699;

### some UCP servers accept authentication based on soruce ip and source port / dest ip and dest port 
### if you need it fill those fields during Net::UCP::Client construction
### and set bypass_auth = to BYPASS. However if you don't need it... don't think about that!

$uclient = new Net::UCP::Client(user           => $user,
				password       => $password,
				smsc_host      => $smsc_host,
				smsc_port      => $smsc_port,
				bypass_auth    => NOBYPASS,
				timeout        => 10,                  ### time to wait during smsc connection
				debug          => 1,                   ### Debug enabled it will print out some debug messages
				alert_time     => 600,                 ### send an mt alert every 10 minutes [keep alive]
				send_hook_time => 2,                   ### client will call send_hook every 2 secs. (check the queue every 2 seconds)
				send_hook      => sub {
				    
				    ### ...
				    ### you will check your sms queue here
				    ### ...
				    
				    ### Encode text and oadc using gsm default alphabet
				    my $from = encode('gsm0338', 'ALPHA@NUM');       
				    my $text = encode('gsm0338', 'SMS test from nemux');
				    
				    ### set NOTIFY if you want to receive Delivery Notification for this message
				    $uclient->send_sms("00441111111111", $from, $text, NONOTIFY);  
				    
				    #$uclient->send_8bit("0031111111111", $udh, $from, $data, NONOTIFY);
				    #$uclient->send_multipart("003222222222", $from, $text_long, NONOTIFY);
				    #$uclient->send_wappush("0033333333333", $from, $text, $url, NONOTIFY);
				},
				op_01          => sub {
				    my $resp = shift;
				    
				    print "Operation 01 Response\n";
				    print Dumper ($resp);
				    
				    return;
				},
				op_02          => sub {
				    my $resp = shift;
				    
				    print "Operation 02 from SMSC [MO Message]\n";
				    print Dumper ($resp);
				       
				    #$uclient->send_02_response();
				    return;
				},
				op_31          => sub {
				    my $resp = shift;
				    
				    print "Operation 31 Response [Alert Response from SMSC]\n";
				    print Dumper ($resp);
				    
				    return;
				},
				op_51          => sub {
				    my $resp = shift;
				    
				    ### here you will manage your send_sms response 
				    ### parse response and update your history table with 
				    ### message timestamp 
				    
				    print "Operation 51 Response\n";
				    print Dumper ($resp);
				    
				    return;
				},
				op_52          => sub {
				    my $resp = shift;
				    
				    ### here you will manage your Mobile Originated Message
				    
				    print "Operation 52 from SMSC [MO message]\n";
				    print Dumper ($resp); 
				    
				    #$uclient->send_52_response();
				    return;
				},
				op_53          => sub {
				    my $resp = shift;
				    
				    ### here you will manage your delivery notification
				    ### parse response and update your data...
				    
				    print "Operation 53 from SMSC [Delivery Notification]\n";
				    print Dumper ($resp);
				    
				    #$uclient->send_53_response();
				    return;
				},
				);

### running client and its listener
$uclient->run();

