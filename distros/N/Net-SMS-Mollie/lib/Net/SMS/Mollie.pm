package Net::SMS::Mollie;

use strict;
use Carp;
use LWP::UserAgent;
use XML::Simple;

our $VERSION = '0.04';
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
               recipients=> [$_[2]],
               originator=> $_[4] || 'Mollie',
          )->send($_[3]);
}

sub baseurl {
   my $self = shift;
   if (@_) { $self->{"_baseurl"} = shift }
   return $self->{"_baseurl"};
}

sub ua {
   my $self = shift;
   if (@_) { $self->{"_ua"} = shift }
   return $self->{"_ua"};
}

sub gateway {
   my $self = shift;
   if (@_) { $self->{"_gateway"} = shift }
   return $self->{"_gateway"};
}

sub originator {
   my $self = shift;
   if (@_) { $self->{"_originator"} = shift }
   return $self->{"_originator"};
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

sub login {
   my ($self, $user, $pass) = @_;
   $self->username($user) if($user);
   $self->password($pass) if($pass);
   return ($self->username, $self->password);
}

sub recipient {
   my ($self, $recip) = @_;
   push @{$self->{"_recipients"}}, $recip if($recip);
   return $self->{"_recipients"};
}

sub message {
   my $self = shift;
   if (@_) { $self->{"_message"} = shift }
   return $self->{"_message"};
}

sub deliverydate {
   my $self = shift;
   if (@_) { $self->{"_deliverydate"} = shift }
   return $self->{"_deliverydate"};
}

sub type {
   my $self = shift;
   if (@_) { $self->{"_type"} = shift }
   return $self->{"_type"};
}

sub url {
   my $self = shift;
   if (@_) { $self->{"_url"} = shift }
   return $self->{"_url"};
}

sub udh {
   my $self = shift;
   if (@_) { $self->{"_udh"} = shift }
   return $self->{"_udh"};
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

sub send {
   my ($self, $message) = @_;
   $self->message($message) if($message);
   my $parms = {};

   # Wappush? We must have gateway 1 and an URL
   if($self->type eq 'wappush') {
      $self->gateway(1) ;
      $self->_croak("No url specified.") unless($self->url);
   }
   
   #### Check for mandatory input
   foreach(qw/username password gateway originator recipients message type/) {
      $self->_croak("$_ not specified.") unless(defined $self->{"_$_"});
      if($_ eq 'recipients') {
         $parms->{$_} = join(",", @{$self->{"_$_"}});
      } else {
         $parms->{$_} = $self->{"_$_"};
      }
   }

   #### Check for some specific input
   # Gateway is either 1, or 2
   $self->_croak("Gateway should be either '1' or '2'") 
      unless($self->gateway == 1 || $self->gateway == 2);

   # Type can be normaal/wappush/vcard/flash/binary/long
   $self->_croak("Invalid type") 
      unless($self->type =~ /^(normaal|wappush|vcard|flash|binary|long)$/);

   # Append the additional arguments
   foreach(qw/deliverydate url udh/) {
         $parms->{$_} = $self->{"_$_"} if(defined $self->{"_$_"});
   }

   # Should be ok now, right? Let's send it!
   my $res = $self->{"_ua"}->post($self->baseurl, $parms);

   if($res->is_success) {
      my $item = _parse_output($res->decoded_content)->{'item'};

      # Set the return info
      $self->{"_resultcode"} = $item->{"resultcode"};
      $self->{"_resultmessage"} = $item->{"resultmessage"};

      # Successful?
      if($item->{"success"} eq 'false') {
         $self->{"_successcount"} = 0;
         $self->{"_success"} = 0;
      } else {
         $self->{"_successcount"} = $item->{'recipients'};
         $self->{"_success"} = 1;
      }
   } else {
      $self->{"_resultcode"} = -1;
      $self->{"_resultmessage"} = $res->status_line;
   }
   return $self->is_success;
}

sub credits {
   my $self  = shift;
   my $parms = {};

   foreach(qw/username password/) {
      $self->_croak("$_ must be defined!") unless(defined $self->{"_$_"});
   }

   $parms->{'gebruikersnaam'} = $self->{"_username"};
   $parms->{'wachtwoord'}     = $self->{"_password"};

   my $res = $self->{"_ua"}->post($self->{"_creditsurl"}, $parms);

   if($res->is_success) {
      if($res->decoded_content eq 'ERROR') {
         $self->{"_resultcode"} = -2;
         $self->{"_resultmessage"} = "Username or password incorrect";
      } else {
         return $res->decoded_content;
      }
   } else {
      $self->{"_resultcode"} = -1;
      $self->{"_resultmessage"} = $res->status_line;
   }
   return undef;
}

####################################################################
sub _init {
   my $self   = shift;
   my %params = @_;

   my $ua = LWP::UserAgent->new(
      agent => __PACKAGE__." v. $VERSION",
   );

   # Set/override defaults
   my %options = (
      ua                => $ua,
      baseurl           => 'https://secure.mollie.nl/xml/sms/',
      creditsurl        => 'http://www.mollie.nl/partners/api/smscredits/',
      gateway           => 1,
      originator        => 'Mollie',
      username          => undef,
      password          => undef,
      recipients        => [],
      message           => undef,

      deliverydate      => undef,
      type              => 'normaal',
      url               => undef,
      udh               => undef,

      success           => undef,
      successcount      => undef,
      resultcode        => undef,
      resultmessage     => undef,
      %params,
   );
   $self->{"_$_"} = $options{$_} foreach(keys %options);
   return $self;
}

sub _parse_output {
   my $input = shift;
   return unless($input);
   my $xso = new XML::Simple();
   return $xso->XMLin($input);
}

sub _croak {
   my ($self, @error) = @_;
   Carp::croak(@error);
}
#################### main pod documentation begin ###################

=head1 NAME

Net::SMS::Mollie - Send SMS messages via the mollie.nl service

=head1 SYNOPSIS

  use strict;
  use Net::SMS::Mollie;

  my $mollie = new Net::SMS::Mollie;
     $mollie->login('username', 'p4ssw0rd');
     $mollie->recipient('0612345678');
     $mollie->send("I can send SMS!");

  if($mollie->is_success) {
     print "Successfully sent message to ".$mollie->successcount." number(s)!";
  } else {
     print "Something went horribly wrong!\n".
           "Error: ".$mollie->resultmessage." (".$mollie->resultcode.")";
  }

or, if you like one liners:

  perl -MNet::SMS::Mollie -e 'send_sms("username", "password", "recipient", "text", "originator")'

=head1 DESCRIPTION

C<Net::SMS::Mollie> allows sending SMS messages via L<http://www.mollie.nl/>

=head1 METHODS

=head2 new

C<new> creates a new C<Net::SMS::Mollie> object.

=head3 options

=over 5

=item baseurl

Defaults to L<https://secure.mollie.nl/xml/sms/>, but could be set to,
for example, the non SSL URL L<http://www.mollie.nl/xml/sms/>.

=item ua

Configure your own L<LWP::UserAgent> object, or use our default one.

=item gateway

Defaults to gateway "1". For more information on the mollie.nl gateways,
please read L<http://www.mollie.nl/docs/help/?id=1>

=item originator

The sender of the SMS. Could be 14 digits or 11 characters. Defaults to
"Mollie", so you most likely do want to override this default.

=item username

Your mollie.nl username

=item password

Your mollie.nl password

=item recipients

Takes an array of phonenumbers to send the message to.

=item message

The actual SMS text

=item type

Defaults to I<normaal>, but could be set to I<normaal, wappush, vcard, flash, 
binary, or long>

=item deliverydate

C<optional> When do you want to send the SMS? Format: I<yyyymmddhhmmss>

=item url

C<optional> Only useful for the I<wappush> type. Specify the URL of the
wappush content.

=item udh

C<optional> Only useful for the I<binary> type. Specify the I<header> of
the SMS message.

=back

All these options can be set at creation time, or be set later, like this:

  $mollie->username('my_username');
  $mollie->password('my_password');
  $mollie->type('wappush');
  $mollie->url('some_url');

Without an argument, the method will return its current value:

  my $username = $mollie->username;
  my $baseurl  = $mollie->baseurl;

=head2 login

Set the I<username> and I<password> in one go. 

  $mollie->login('my_username', 'my_p4ssw0rd');

  # is basically a shortcut for

  $mollie->username('my_username');
  $mollie->password('my_p4ssw0rd');

Without arguments, it will return the array containing I<username>,
and I<password>.

   my ($user, $pass) = $mollie->login;

=head2 recipient

Push numbers in the I<recipients> array

  foreach(qw/1234567890 0987654321 1292054283/) {
     $mollie->recipient($_);
  }

=head2 send

Send the actual message. If this method is called with an argument,
it's considered the I<message>. Returns true if the sending was successful,
and false when the sending failed (see I<resultcode> and I<resultmessage>).

=head2 is_success

Returns true when the last sending was successful and false when it failed.

=head2 successcount

Returns the amount of messages actually sent (could be useful with multiple
recipients).

=head2 resultcode

Returns the resulting code, as provided by mollie.nl. See
L<http://www.mollie.nl/geavanceerd/sms/http/> for all possible codes.

When L<LWP::UserAgent> reports an error, the I<resultcode> will be
set to C<-1>.

=head2 resultmessage

Returns the result message, as provided by mollie.nl, or L<LWP::UserAgent>.

=head2 credits

Requires both I<username> and I<password> to be set, and returns the 
amount of remaining credits (with 4 decimals) or I<undef>:

  if(my $credits = $mollie->credits) {
     print $credits." credits left!\n";
  } else {
     print $mollie->resultmessage." (".
           $mollie->resultcode.")\n";
  }

=head1 SEE ALSO

=over 5

=item * L<http://www.mollie.nl/geavanceerd/sms/http/>

=item * L<http://www.mollie.nl/docs/help/?id=1>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Net-SMS-Mollie>

=head1 AUTHOR

M. Blom,
E<lt>blom@cpan.orgE<gt>,
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
#################### main pod documentation end ###################

1;
