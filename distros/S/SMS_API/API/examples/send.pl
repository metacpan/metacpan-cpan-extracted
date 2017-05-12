#!/usr/bin/perl

  use HTTP::Request::Common;
  use LWP::UserAgent;
  use SMS::API;
my $email = 'test@webbee.biz';
my $password= 'demo';
my $to = '919911111111'; #Substitute by a valid International format mobile number to whom you wanted to send SMS. eg. 919811111111 where 91 is indian isd code.
$message= 'Wow ! This site rocks.';
  my $sms = SMS::API->new(
    'email' => "$email",
    'password' => "$password",
    'to' =>  "$to",
    'message'=>"$message", #Max 160 characters Message.
      );
print $sms->send;

