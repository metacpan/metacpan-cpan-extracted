package Net::Clickatell;

use strict;
use warnings;
#use diagnostics;

use LWP::UserAgent;
use URI::Escape qw(uri_escape);
use HTTP::Request::Common;

# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

# Copyright (c) 2010 Christopherus Goo.  All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module as you
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.

# The most recent version and complete docs are available at:
#   http://www.artofmobile.com/software/

# Clickatell is Copyright (c) 2010 Clickatell (Pty) Ltd: Bulk SMS Gateway

#This software or the author aren't related to Clickatell in any way.

# November 2010. Singapore.

$Net::Clickatell::VERSION=0.5;

=head1 NAME

Net::Clickatell - Access to Clickatell HTTP API

  This module support the API from Clickatell's HTTP API Specification v.2.4.1.
  The following is all the available API and not all are supported

  Basic Commands

  http://api.clickatell.com/http/auth			Yes (But session not support)
  http://api.clickatell.com/http/ping			Yes (But session not support)
  http://api.clickatell.com/http/querymsg		Yes
  http://api.clickatell.com/http/sendmsg		Yes

  Additional Commands

  http://api.clickatell.com/http/delmsg			No
  http://api.clickatell.com/http/getbalance		Yes
  http://api.clickatell.com/http/routeCoverage.php	Yes
  http://api.clickatell.com/mms/ind_push.php		Yes
  http://api.clickatell.com/mms/si_push.php		Yes
  http://api.clickatell.com/http/getmsgcharge		Yes
  http://api.clickatell.com/http/token_pay              No

  Batch Messaging

  http://api.clickatell.com/http_batch/startbatch	No
  http://api.clickatell.com/http_batch/senditem		No
  http://api.clickatell.com/http_batch/quicksend	No
  http://api.clickatell.com/http_batch/endbatch		No




=head1 SYNOPSIS

=head2 With SSL

  use Net::Clickatell;

  my $clickatell = Net::Clickatell->new( API_ID => $api_id, USERNAME =>$username, PASSWORD =>$password );
  my $bal=$clickatell->getBalance;

=head2 Without SSL

  use Net::Clickatell;

  my $clickatell = Net::Clickatell->new( UseSSL=>0, API_ID => $api_id, USERNAME =>$username, PASSWORD =>$password );
  my $bal=$clickatell->getBalance;

=head1 DESCRIPTION

Clickatell (http://www.clickatell.com) is a commercial service that allows its users to send
SMS messages to anyone in the world. This perl module allow users to send SMS, WAP push and
MMS through Clickatell HTTP API.

Please take note that neither this software nor the author are related to Clickatell in any way.

=head1 METHODS

=over 4

=cut
my %status= (
"001", "Message unknown. The delivering network did not recognise the message type or content.",
"002", "Message queued. The message could not be delivered and has been queued for attempted redelivery.",
"003", "Delivered. Delivered to the network or gateway (delivered to the recipient).",
"004", "Received by recipient. Confirmation of receipt on the handset of the recipient.",
"005", "Error with message. There was an error with the message, probably caused by the content of the message itself.",
"006", "User cancelled message delivery. Client cancelled the message by setting the validity period, or the message was terminated by an internal mechanism.",
"007", "Error delivering message An error occurred delivering the message to the handset.",
"008", " OK. Message received by gateway.",
"009", "Routing error. The routing gateway or network has had an error routing the message.",
"010", "Message expired. Message has expired at the network due to the handset being off, or out of reach.",
"011", "Message queued for later delivery. Message has been queued at the Clickatell gateway for delivery at a later time (delayed delivery).",
"012", "Out of credit. The message cannot be delivered due to a lack of funds in your account. Please re-purchase credits."
);

sub getStatusDetail {
   my $class = shift || undef;
   return undef if( !defined $class);

   my $ret = shift;

   my @allret=split ": ",$ret;
   my $sc=$allret[@allret-1];
   $sc=~s/\D//g;
   return $class->getStatus($sc);
}

sub getStatus {
   my $class = shift || undef;
   return undef if( !defined $class);

   my $scode = shift;
   my $ret=$status{$scode};
   return $scode,$ret if ($ret);
   return -1,"Unknown Status";
}

sub authentication {
   my $class = shift || undef;
   return undef if( !defined $class);

   return $class->connect('http/auth');
}

sub ping {
   my $class = shift || undef;
   return undef if( !defined $class);

   my ($sid)=@_;
   return $class->connect('http/ping','session_id',$sid);
}

=item new

This method is used to create the Clickatell object.

Usage:

  my $clickatell = Net::Clickatell->new( API_ID => $api_id, USERNAME= $user, PASSWORD =>$passwd );

The complete list of arguments is:

  API_ID    : Unique number received from Clickatell when an account is created.
  UseSSL    : Tell Clickatell module whether to use SSL or not (0 or 1).
  BaseURL   : Default URL used to connect with Clickatell service.
  UserAgent : Name of the user agent you want to display to Clickatell service.

=cut

sub new {
   my $class = shift || undef;
   return undef if( !defined $class);

   # Get arguments
   my %args = ( UseSSL => 1,
                UserAgent => 'Clickatell.pm/'. $Net::Clickatell::VERSION,
                @_ );

   # Check arguments
   if (!exists $args{API_ID}) {
      # There isn't an API identification number. We can't continue
      return undef;
   }

   if (!exists $args{USERNAME}) {
      # There isn't a USERNAME. We can't continue
      return undef;
   }

   if (!exists $args{PASSWORD}) {
      # There isn't a PASSWORD. We can't continue
      return undef;
   }

   if ($args{UseSSL} =~ /\D/) {
      # UseSSL argument wasn't valid. Set it to 1
      $args{UseSSL} = 1;
   }

  if (!exists $args{BaseURL}) {
      # BaseURL argument wasn't passed. Set it to default.
      # Check if we have to use SSL.
      if (exists $args{UseSSL} && $args{UseSSL}==1) {
         $args{BaseURL} = 'https://api.clickatell.com/';
      } else {
         $args{BaseURL} = 'http://api.clickatell.com/';
      }
   } else {
      # Set BaseURL property value.
      # Check if we have to use SSL.
      if (exists $args{UseSSL} && $args{UseSSL}==1) {
         $args{BaseURL} = 'https://'.$args{BaseURL};
      } else {
         $args{BaseURL} = 'http://'.$args{BaseURL};
      }
   }

   return bless { BASE_URL  => $args{BaseURL},
                  API_ID     => uri_escape($args{API_ID}),
                  USERNAME   => uri_escape($args{USERNAME}),
                  PASSWORD   => uri_escape($args{PASSWORD}),
                  USE_SSL    => $args{UseSSL},
                  USER_AGENT => $args{UserAgent},
                  }, $class;
}

sub connect {
   my $class = shift || undef;
   return undef if( !defined $class);

   my $url= shift;
   my (@entry)=@_;

   my $ua = LWP::UserAgent->new(agent => $class->{USER_AGENT} );

   my %tags = @entry;
   $tags{'api_id'} = $class->{API_ID};
   $tags{'user'} = $class->{USERNAME};
   $tags{'password'} = $class->{PASSWORD};

   my $res = $ua->request(
      POST $class->{BASE_URL}.$url,
      Content_Type  => 'application/x-www-form-urlencoded',
      Content       => [ %tags ]
   );
   return $res->content;
}

=item getBalance

This method will return the Balance of the account.

Usage:

  $clickatell->getBalance;

Succesful example of the return is as followed:
 OK: Credit: 100.3

Failed example of the return is as followed:
 ERR: 001, Authentication failed

=cut

sub getBalance {
   my $class = shift || undef;
   return undef if( !defined $class);

   my $ret= $class->connect('http/getbalance');
   return "OK: $ret" unless $ret=~/^ERR: /;
   return $ret;
}

=item checkCoverage 

This method will return the Balance of the account.

Usage:

  $clickatell->checkCoverage($msisdn);

Succesful example of the return is as followed:
 OK: This prefix is currently supported. Messages sent to this prefix will be routed. Charge: 1

Failed example of the return is as followed:
 ERR: This prefix is not currently supported. Messages sent to this prefix will fail. Please contact support for assistance.

=cut

sub checkCoverage {
   my $class = shift || undef;
   return undef if( !defined $class);

   my ($msisdn)=@_;
   return $class->connect('utils/routeCoverage.php','msisdn',$msisdn);
}

=item getQuery

This method will return the Message Charge Status.

Usage:

  my ($code,$querymessage)=$clickatell->getQuery($apimsgid);

 This method will return 2 values in a array which is as followed:
   001
   ID: add8f5556c0d3d54bc94a4cd8800f01b4 Status: 001, Message unknown. The delivering network did not recognise the message type or content.

=cut

sub getQuery {
   my $class = shift || undef;
   return undef if( !defined $class);

   my $apimsgid=shift;
   my $ret= $class->connect('http/querymsg','apimsgid',$apimsgid);
   my $code=-1;
   my $scode='Error in the return status';
   ($code,$scode)=$class->getStatusDetail($ret) if ($ret=~/status:/i);
   return $code, ($ret.', '.$scode);
}

=item getMessageCharge

This method will return the Message Charge Status.

Usage:

  my ($code,$messagecharge)=$clickatell->getMessageCharge($apimsgid);

 This method will return 2 values in a array which is as followed:
   001
   apiMsgId: add8f5556c0d3d54bc94a4cd8800f01b4 charge: 0 status: 001, Message unknown. The delivering network did not recognise the message type or content.

=cut

sub getMessageCharge {
   my $class = shift || undef;
   return undef if( !defined $class);

   my $apimsgid=shift;
   my $ret= $class->connect('http/getmsgcharge','apimsgid',$apimsgid);
   my $code=-1;
   my $scode='Error in the return status';
   ($code,$scode)=$class->getStatusDetail($ret) if ($ret=~/status:/i);
   return $code, ($ret.', '.$scode);
}

=item sendBasicSMSMessage

This method is used to send a text SMS Message.

Usage:

  my $smsResult=$clickatell->sendBasicSMSMessage($from,$to,$msg);

Succesful example of the return is as followed:
 OK: ID: dd8f5556c0d3d54bc94a4cd8800f01b4

Failed example of the return is as followed:
 ERR: 105, Invalid Destination Address

=cut

sub sendBasicSMSMessage {
   my $class = shift || undef;
   return undef if( !defined $class);

   my ($from,$to,$msg)=@_;
   my $ret= $class->connect('http/sendmsg',"to",$to,'from',$from,'text',$msg);
   return "OK: $ret" unless $ret=~/^ERR: /;
   return $ret;
}

=item sendAdvanceSMSMessage

This method is used to send a customised SMS Message. The following are the accepted parameter format:
  to
  text
  from
  callback
  deliv_time
  concat
  max_credits
  req_feat
  queue
  escalate
  mo
  cliMsgId
  Unicode
  msg_type
  udh
  data
  validity
  binary
  schedule_time

Usage:

  my $smsResult=$clickatell->sendAdvanceSMSMessage(to=>'6591234567',from=>'6591234568',text=>'testing');

Succesful example of the return is as followed:
 OK: ID: dd8f5556c0d3d54bc94a4cd8800f01b4

Failed example of the return is as followed:
 ERR: 105, Invalid Destination Address

=cut

sub sendAdvanceSMSMessage {
   my $class = shift || undef;
   return undef if( !defined $class);
   # Get arguments
   my %args = @_;

   # Check arguments
   if (!exists $args{to}) {
      return "ERR: To field not found";
   } else {
      if (ref($args{to})) {
         return "ERR: To field must be arrayref" unless ref($args{to}) eq "ARRAY";
         my $tos=$args{to};
         return "ERR: To field must be contain at least 1 number" unless (@$tos);
         $args{to}=join ',',@$tos;
print $args{to}."\n";
      }
   }

   if (!exists $args{from}) {
      return "ERR: From field not found";
   }

   if (!exists $args{text} && !exists $args{data}){
      return "ERR: Text field not found";
   }

   my $ret= $class->connect('http/sendmsg',%args);
   return "OK: $ret" unless $ret=~/^ERR: /;
   return $ret;
}

=item sendMMNotification

This method is used to send a MMS Notification Push Message.

Usage:

  my $mmsResult=$clickatell->sendMMNotification($from,$to,$subject,$expiry,$url);

Succesful example of the return is as followed:
 OK: ID: dd8f5556c0d3d54bc94a4cd8800f01b4

Failed example of the return is as followed:
 ERR: 105, Invalid Destination Address

=cut

sub sendMMNotification {
   my $class = shift || undef;
   return undef if( !defined $class);

   my ($from,$to,$subject,$expiry,$url)=@_;

   # mms_subject: subject
   # mms_class: class (e.g. 80,81,82,83)
   # mms_expire: seconds - different to the standard expire parameter
   # mms_from: from text
   # mms_url: the url with the mms content. The URL must be urlencoded.
   # print "($from,$to,$subject,$expiry,$url)\n";

   my $loc=uri_escape($url);
   my $ret=  $class->connect('mms/ind_push.php',"to",$to,'from',$from,'mms_from',$from,
      'mms_expire',$expiry,'mms_url',$loc,'mms_class','80','mms_subject',$subject);
   return "OK: $ret" unless $ret=~/^ERR: /;
   return $ret;

}

=item sendWAPPush

This method is used to send a WAP Push. Currently, only SI WAP Push message is supported.

Usage:

  my $wapResult=$clickatell->sendWAPPush($from,$to,$msg,$url);

Succesful example of the return is as followed:
 OK: ID: dd8f5556c0d3d54bc94a4cd8800f01b4

Failed example of the return is as followed:
 ERR: 105, Invalid Destination Address

=cut

sub sendWAPPush {
   my $class = shift || undef;
   return undef if( !defined $class);

   my ($from,$to,$message,$url)=@_;
   my $rr=$to.rand(100);
   $rr=~s/\D//g;
   return $class->sendSIWAPPush($from,$to,$rr,'delete',$message,$url);
}

sub sendSIWAPPush {
   my $class = shift || undef;
   return undef if( !defined $class);

   my ($from,$to,$si_id,$si_action,$message,$url)=@_;
   #si_id: unique id for msg - must be used with a 'delete' action
   #si_url: the url to be fetched (url encoded)
   #si_text: notification text
   #si_created: date in UTC
   #si_expires: data in UTC
   #si_action: one of (signal-none, signal-low, signal-medium, signal-high, delete)
   my $nowt=&getTime(0);
   my $nowx=&getTime(7);

   my $loc=uri_escape($url);
   my $ret= $class->connect('mms/si_push','si_id',$si_id,'si_action',$si_action,
      'si_created',$nowt,'si_expires',$nowx,
      'to',$to,'from',$from,'si_text',$message,'si_url',$loc);
   return "OK: $ret" unless $ret=~/^ERR: /;
   return $ret;
}

sub getTime {
   my $day=shift;
   $day=0 unless ($day);

   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time+($day*86400));
   return sprintf("%04d%02d%02d%02d%02d%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
}


=back 4

=head1 AUTHOR

Christopherus Goo <software@artofmobile.com>

=head1 COPYRIGHT

Copyright (c) 2010 Christopherus Goo.  All rights reserved.
This software may be used and modified freely, but I do request that this
copyright notice remain attached to the file.  You may modify this module
as you wish, but if you redistribute a modified version, please attach a
note listing the modifications you have made.

Clickatell is Copyright (c) 2010 Clickatell (Pty) Ltd: Bulk SMS Gateway

This software or the author aren't related to Clickatell in any way.

=cut

1;


