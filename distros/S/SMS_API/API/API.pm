package SMS::API;

#################################################################################
#
#
#             SMS1.in Goyali.com webbee.biz eMailOnMove.com
#
#################################################################################
#NOTE: Distributing this script is permitted but requires a licence. Visit www.sms1.in/contact.html for requesting
#that . Provide the reason for distributing the script ie. for which application do you want to use the cript. You will be responded within hours.
#Disclaimer: This program is distributed as it is and the author or sms1.in does not claim any responsibilities for the successful operation of this program or that we are not sure that it will or can cause any abnormality in your computer. However during our testing no such problem occured.
#For a detailed policy visit www.sms1.in/policy.htm
#
#
#This script is Prepared by ,
#Abhsihek jain
#Chief Programmer
#SMS1.in
#
use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);


our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();
our $VERSION = '4.01.1';


# Preloaded methods go here.
use HTTP::Request::Common qw(GET);
use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
sub new {
    my ($self);
    my $class = shift;
    my (%hash) = @_;
    $self = bless {
        'email' => $hash{email},
        'password' => $hash{password},
        'message' => $hash{message},
        'from' =>$hash{from},
        'to' =>$hash{to},
         }, $class;
    return $self;
}

sub send{
  my $self = shift;
  if(!$self->{email}||!$self->{password}||!$self->{to}||!$self->{message}){return 0;}
    if(!$self->{from}){
      $self->{from}='SMS1';
    }
 $self->{message}=substr $self->{message},0,159;
# $self->{messageText}=~ s/\&/\&amp;/gi;
# $self->{messageText}=~ s/\</\&lt;/gi;
# $self->{messageText}=~ s/\'/\&apos;/gi;

  use HTTP::Request::Common qw(POST);
  use LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(GET => "http://sms1.in/cgi-bin/send.sms?email=".$self->{email}."&password=".$self->{password}."&to=".$self->{to}."&from=".$self->{from}."&message=".$self->{message});
  my $res=$ua->request($req);
  unless ($res->is_success) {
      return '0';
  }
  return $res->content;
}

1;
__END__

=head1 NAME

SMS::API - A module to send SMS using the sms1.in servers

=head1 SYNOPSIS

  use HTTP::Request::Common;
  use LWP::UserAgent;
  use SMS::API;
                        #To send SMS Replace with email and password and message text. You can get Email/Username by visiting http://www.sms1.in
  my $sms = SMS::API->new(
    'email' => "$email",
    'password' => "$password",
    'to' =>  "$to",      #Substitute by a valid International format mobile number to whom you wanted to send SMS. eg. 919811111111
    '$from' => "$from",  #Optional
    'message'=>"$message", #Max 160 characters Message.
      );
  my $send = $sms->send;

=head1 DESCRIPTION

This is a module for sending the SMS by integrating with the servers of http://www.sms1.in

For a solution of directly sending the SMS via internet or through SMS visit http://www.sms1.in
In case of any problem whatsoever please do not hesitate to contact http://www.sms1.in/ .We have an excellent team of customer support and you will be responded in hours.

NOTE: You first need to register at http://www.sms1.in/ (visit the URL and request a sms gateway account. You will given one within seconds and it is free)for using this module. On registering you will be given a user id and password and some free test credits. You can use the credits to send the SMS.

NOTE: We are very serious about this module and any errors performed are requested to be reported at http://www.sms1.in/

NOTE: This module has a dependency over LWP::UserAgent and HTTP::Request::Common and that must be installed to properly send the SMSes . It can be obtained easily from cpan.

At the moment these methods are implemented:

=over 4

=item C<new>

A constructor

The parameters sent are :
email , password = The user name and Password given to you at the time of signup.
message = The message you wish to send.
from = If your account supports dynamic sender id then this parameter will tell what will be the from id as seen by the mobile.
to = The mobile number whom you wish to send SMS to in international  format eg. 919811111111 .

=item C<send>

This method send an SMS.
On successful sending the SMS the function returns the error text / success text.

You can also visit the SMS1.in to check the status by logging on to your account.

=item C<status>

This function is to be implemented and will be included if the need increases the coding time :) to get this method implemented pl. visit and place a query at http://www.sms1.in

And do not forget to inform the author of any bugs you encountered or the features you want into that.

=back

=head1 NOTE:

This module was initially made for the indian audience and so was the site http://sms1.in , international customers were also brought in later but you need to place a special request for that.
As alread mentioned sms1.in prouds to have a good support and you will be replied faster than expected.

Virus free , Spam Free , Spyware Free Software and hopefully Money free software .

=head1 AUTHOR

<Abhishek jain>
goyali at cpan.org

=head1 SEE ALSO

http://www.sms1.in

=cut
