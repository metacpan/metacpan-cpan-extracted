package Net::SMS::PChome;

use strict;
use Carp;
use WWW::Mechanize;
use HTML::TagParser;
use Date::Calc qw(check_date check_time Today_and_Now This_Year);

our $VERSION = '0.11';
our (@ISA) = qw(Exporter);
our (@EXPORT) = qw(send_sms);

sub new {
    my ($class, %params) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(%params) or return undef;
    return $self;
}

sub send_sms {
   return __PACKAGE__->new(
               username  => $_[0], 
               password  => $_[1],
               authcode  => $_[2],
               recipients=> [$_[3]],
          )->smsSend($_[4]);
}

sub baseurl {
   my $self = shift;
   if (@_) { $self->{"_baseurl"} = shift }
   return $self->{"_baseurl"};
}

sub username {
   my $self = shift;
   if (@_) { $self->{"_username"} = shift }
   return $self->{"_username"};
}

sub password {
   my $self = shift;
   if (@_) { $self->{"_password"} = shift }
   return $self->{"_password"};
}

sub authcode {
   my $self = shift;
   if (@_) { $self->{"_authcode"} = shift }
   return $self->{"_authcode"};
}

sub login {
   my ($self, $user, $pass, $auth) = @_;
   $self->username($user) if($user);
   $self->password($pass) if($pass);
   $self->authcode($auth) if($auth);
   return ($self->username, $self->password, $self->authcode);
}

sub smsRecipient {
   my ($self, $recip) = @_;
   push @{$self->{"_recipients"}}, $recip if($recip);
   return $self->{"_recipients"};
}

sub smsMessage {
   my $self = shift;
   if (@_) { $self->{"_message"} = shift }
   return $self->{"_message"};
}

sub smsDeliverydate {
   my $self = shift;
   if (@_) { $self->{"_dlvdatetime"} = shift }
   return $self->{"_dlvdatetime"};
}

sub smsType {
   my $self = shift;
   if (@_) { $self->{"_sendType"} = shift }
   return $self->{"_sendType"};
}

sub smsEncode {
   my $self = shift;
   if (@_) { $self->{"_encodeType"} = shift }
   return $self->{"_encodeType"};
}

sub is_success {
   my $self = shift;
   return $self->{"_success"};
}

sub successcount {
   my $self = shift;
   return $self->{"_successcount"};
}

sub resultcode {
   my $self = shift;
   return $self->{"_resultcode"};
}

sub resultmessage {
   my $self = shift;
   return $self->{"_resultmessage"}; 
    
}

sub smsSend {
   my ($self, $message) = @_;
   $self->smsMessage($message) if($message);
   my $parms = {};
   
   #### Check for mandatory input
   foreach(qw/username password authcode recipients message sendType encodeType/) {
      $self->_croak("$_ not specified.") unless(defined $self->{"_$_"});
      if($_ eq 'recipients') {
         $parms->{$_} = join(";", @{$self->{"_$_"}});
      } else {
         $parms->{$_} = $self->{"_$_"};
      }
   }

   # Type can be now/dlv
   $self->_croak("Invalid type") 
      unless($self->smsType =~ /^[12]$/);

   # delivery? We must have a Date that format: YYYYMMDDHHmm (example:200606130830)
   if($self->smsType eq '2') {
      $self->_croak("No delivery date specified.") unless($self->smsDlvtime);
   }

   # Encoding can be now/dlv
   $self->_croak("Invalid encoding") 
      unless($self->smsEncode =~ /^(BIG5|ASCII)$/);

   # Append the additional arguments
   if(defined $self->{"_dlvdatetime"}) {
   	 if (my ($year,$month,$day,$hour,$min) = $self->{"_dlvdatetime"} =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})$/) {
   	 	# Check Date
   	 	$self->_croak("Delivery date is incorrect.")
   	 	  unless(check_date($year,$month,$day));
   	 	# Check Time
   	 	$self->_croak("Delivery time is incorrect.")
   	 	  unless(check_time($hour,$min,undef));   	 	 
   	 	# Check least
   	 	my $now = sprintf("%04d%02d%02d%02d",Today_and_Now());
   	 	$self->_croak("Delivery time must earlier than now.")
   	 	  unless($self->{"_dlvdatetime"} > $now);
   	 	
   	 	foreach (qw/year month day hour minute/) {
			$parms->{$_} = ${"$_"} ;   	 		
   	 	}
         } else {
         	$self->_croak("Format of Delivery date is incorrect.");
         }
   }

   # Should be ok now, right? Let's send it!
   # Login
   $self->{"_ua"}->agent_alias('Windows IE 6');
   $self->{"_ua"}->get($self->baseurl);
   $self->{"_ua"}->form_number(1);
   $self->{"_ua"}->field('smsid', $parms->{username});
   $self->{"_ua"}->field('pwd', $parms->{password});
   $self->{"_ua"}->submit();   
   
   # Input SMS_Message, Recipients
   $self->{"_ua"}->form_number(2);
   $self->{"_ua"}->field('InputMsg', $parms->{message});
   $self->{"_ua"}->field('mobiles', $parms->{recipients});
   $self->{"_ua"}->field('sendType', $parms->{sendType});
   $self->{"_ua"}->field('longCount', scalar(@{$self->{"_recipients"}}));

   if($self->smsType eq '2') {
   	$self->{"_ua"}->select('year', ($parms->{year} - This_Year()));
   	$self->{"_ua"}->select('month', $parms->{month});
   	$self->{"_ua"}->select('day', $parms->{day});
   	$self->{"_ua"}->select('hour', $parms->{hour});
   	$self->{"_ua"}->select('minute', $parms->{minute});
   }
   $self->{"_ua"}->submit();

   # Input Authcode	
   $self->{"_ua"}->field('auth_code', $parms->{authcode});
   $self->{"_ua"}->current_form()->action('https://ezpay.pchome.com.tw/auth_form_do');
   $self->{"_ua"}->submit();

   if($self->{"_ua"}->success()) {
      my $item = _parse_output($self->{"_ua"}->content);

      # Set the return info
      $self->{"_resultcode"} 	= $item->{"resultcode"};
      $self->{"_resultmessage"} = $item->{"resultmessage"};

      # Successful?
      if($item->{"success"} eq 'false') {
         $self->{"_successcount"} = 0;
         $self->{"_success"} = 0;
      } else {
         $self->{"_successcount"} = scalar(@{$self->{"_recipients"}});
         $self->{"_success"} = 1;
      }
   } else {
      $self->{"_resultcode"} = -999;
      $self->{"_resultmessage"} = $self->{"_ua"}->status;
   }
   return $self->is_success;
}


####################################################################
sub _init {
   my $self   = shift;
   my %params = @_;

   my $ua = WWW::Mechanize->new(
      agent => __PACKAGE__." v. $VERSION",
   );

   # Set/override defaults
   my %options = (
      ua                => $ua,
      baseurl           => 'http://sms.pchome.com.tw/jsp/smslong.jsp',
      username          => undef,	#	帳號
      password          => undef,	#	密碼
      authcode		=> undef,	#       Auth Code
      recipients	=> [],		#	收訊者
      message           => undef,	#	簡訊內容

      dlvdatetime	=> undef,	#	預約時間 delivery date
      sendType          => '1',		#	1 =>立即發送, 2 => 預約發送
      encodeType	=> 'BIG5',	#	BIG5, ASCII

      success           => undef,	#
      successcount      => undef,	#
      resultcode        => undef,	#
      resultmessage     => undef,	#
      %params,
   );
   $self->{"_$_"} = $options{$_} foreach(keys %options);
   return $self;
}

sub _parse_output {
   my $input = shift;
   return unless($input);
   my $item = {};
   my $html = HTML::TagParser->new($input);
   my $list = [$html->getElementsByTagName( "td" )];
 
   if ($list->[12]->innerText =~ m/恭喜您扣點消費成功\/) {
 	# success  
   	$item->{"order_sn"} 		= $list->[17];#
   	$item->{"Consume_summary"} 	= $list->[19];#
   	$item->{"Trade_time"} 		= $list->[21];#
   	$item->{"Quota_originally"} 	= $list->[23];#
   	$item->{"Quota_consume"} 	= $list->[25];#
   	$item->{"Quota_surplus"} 	= $list->[27];#
   	$item->{"success"} 		= 'true';
   	$item->{"resultcode"}		= 1;
   	$item->{"resultmessage"} 	= 'Send SMS from PChome is success';
   } else {
   	$item->{"success"} 		= 'false';
   	$item->{"resultcode"}		= -1;
   	$item->{"resultmessage"} 	= 'Username or Password or Auth Code is incorrect.';	
   }  
   return $item;
}

sub _croak {
   my ($self, @error) = @_;
   Carp::croak(@error);
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::SMS::PChome - Send SMS messages via the sms.pchome.com.tw service.

=head1 SYNOPSIS

  use strict;
  use Net::SMS::PChome;

  my $sms = new Net::SMS::PChome;
     $sms->login('username', 'password', 'auth_code');
     $sms->smsRecipient('0912345678');
     $sms->smsSend("The SMS be send by PChome SMS Service!");

  if($sms->is_success) {
     print "Successfully sent message to ".$sms->successcount." number!\n";
  } else {
     print "Something went horribly wrong!\n".
           "Error: ".$sms->resultmessage." (".$sms->resultcode.")".
  }

or, if you like one liners:

  perl -MNet::SMS::PChome -e 'send_sms("pchome_username", "pchome_password", "auth_code", "recipient", "messages text")'


=head1 DESCRIPTION

Net::SMS::PChome allows sending SMS messages via L<http://sms.pchome.com.tw/>

=head1 METHODS

=head2 new

new creates a new Net::SMS::PChome object.

=head2 Options

=over 4

=item baseurl

Defaults to L<http://sms.pchome.com.tw/jsp/smslong.jsp>

=item ua

Configure your own L<WWW::Mechanize> object, or use our default value.

=item username

Your pchome.com.tw username

=item password

Your pchome.com.tw password

=item authcode

Your PChome Micro Payment System authcode

=item smsMessage

The actual SMS text

=item smsType

Defaults to I<1>, but could be set to I<2>

I<1> mean send SMS now. 
I<2> mean send SMS at a delivery date.

=item smsEncode

Defaults to I<BIG5>, but could be set to I<ASCII> 

I<BIG5>:    the SMS context in Chinese or Engilsh, the max of SMS context length is 70 character.
I<ASCII>:   the SMS context in Engilsh, the max of SMS context length is 140 character.

=item smsDeliverydate

smsDeliverydate mean send SMS at a reserved time.

Its format is YYYYMMDDHHII.

Example: 200607291730  (mean 2006/07/29 17:30)

=back

All these options can be set at creation time, or be set later, like this:

  $sms->username('my_username');
  $sms->password('my_password');
  $sms->smsType('2');
  $sms->smsDeliverydate('200608141803');  # Send SMS at 2006/08/14 PM 06:03.


=head2 login

Set the I<username>, I<password> and I<authcode>  in one go. 

  $sms->login('my_pchome_username', 'my_pchome_password', 'my_pchome_authcode');

  # is basically a shortcut for

  $sms->username('my_pchome_username');
  $sms->password('my_pchome_password');
  $sms->authcode('my_pchome_authcode');

Without arguments, it will return the array containing I<username>, I<password>
and I<authcode>.

   my ($username, $password, $authcode) = $sms->login();

=head2 smsRecipient

Push numbers in the I<recipients> array

  foreach(qw/0912345678 0987654321 0912920542/) {
     $sms->smsRecipient($_);
  }

=head2 smsSend

Send the actual message. If this method is called with an argument,
it's considered the I<message>. Returns true if the sending was successful,
and false when the sending failed (see I<resultcode> and I<resultmessage>).

=head2 is_success

Returns true when the last sending was successful and false when it failed.

=head2 resultcode

Returns the resulting code.

When L<LWP::UserAgent> reports an error, the I<resultcode> will be
set to C<-999>.

=head2 resultmessage

Returns the result message, as provided by sms.pchome.com.tw, or L<LWP::UserAgent>.


=head2 EXPORT

    send_sms


=head1 SEE ALSO


=head1 WEBSITE

You can find information about PChome SMS Service at :

   http://sms.pchome.com.tw/

=head1 AUTHOR

Tsung-Han Yeh, E<lt>snowfly@yuntech.edu.twE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Tsung-Han Yeh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut



