package SMS::Send::TW::HiAir;

use strict;
use base 'SMS::Send::Driver';
use WWW::Mechanize;

use vars qw{$VERSION};
BEGIN {
   $VERSION = '0.02';
}

sub new {
   my ($class, %params) = @_;

   foreach(qw/username password/) {
      Carp::croak("No $_ specified") unless(defined $params{"_$_"});
   }

   my $self = bless { %params }, $class;

   return $self;
}

sub send_sms {
   my $self   = shift;
   my %params = @_;
   my $baseurl = 'http://hiair.hinet.net/hweb/hiairpost_new.jsp';
   my $posturl = 'http://hiair.hinet.net/jweb/send_check2.jsp';
   my $number = 0;

   # Get the message and destination
   my $message   = $self->_MESSAGE( $params{text} );
   my $recipient = $self->_TO( delete $params{to} );
   
   my $ua = WWW::Mechanize->new(
      agent => __PACKAGE__." v. $VERSION",
   );

   $ua->agent_alias('Windows IE 6');
   
   # Should be ok now, right? Let's send it!
   # Input SMS_Message, Recipients

   $ua->post($posturl,
		[ 'add_name' 	  => "0",
		  'message'	  => $message,
		  'tel'	  	  => $recipient,
		  'tran_type'	  => 'now',
		  'can'		  => "0",
		  'can1'	  => "0"]);


   # Auth Login
   $ua->form_name("loginform");
   $ua->submit();

   $ua->form_name("AuthScreen");
   $ua->field("aa-uid", $self->{"_username"});
   $ua->field("aa-passwd", $self->{"_password"});
   $ua->submit();

   # Send SMS
   foreach (split(/\r|\n/, $ua->content()))
   {
     next unless (/window.location.replace\('/i);
 
     $_ =~ /window.location.replace\('(.+)'\)/i;
     my $newurl = $1;
     $ua->get($newurl);
     last;
   }
   
   return $ua->content();
}

sub _MESSAGE {

  my $class = ref $_[0] ? ref shift : shift;
  my $message = shift;
  unless ( length($message) <= 160 ) {
    Carp::croak("Message length limit is 160 characters");
  }
  
  return $message;
}

sub _TO {
  my $class = ref $_[0] ? ref shift : shift;
  my $to = shift;

  # International numbers need their + removed
  $to =~ y/0123456789//cd;

  return $to;
}
  

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SMS::Send::TW::HiAir - SMS::Send driver for hiair.hinet.net

=head1 SYNOPSIS

  use SMS::Send;

  my $sender = SMS::Send->new('TW::HiAir',
                  _username   => 'UserName',
                  _password   => 'Password',
                );

  my $sent = $sender->send_sms(
                  text => 'My very urgent message',
                  to   => '0912345678',
             );

=head1 DESCRIPTION

SMS::Send::TW::HiAir is a SMS::Send driver which allows you to send messages through L<http://hiair.hinet.net/>.

=head1 METHODS

=head2 new

The C<new> method takes a few parameters. C<_username> and C<_password> are mandatory. 
See L<WWW::Mechanize> for details on these parameters. 

=head2 send_sms

Takes C<to> as recipient phonenumber, and C<text> as the text that's
supposed to be delivered.


=head1 SEE ALSO

=over 5

=item * L<Send::SMS>

=item * L<WWW::Mechanize>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Send-SMS-TW-HiAir>

=head1 AUTHOR

Tsung-Han Yeh, E<lt>snowfly@yuntech.edu.twE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Tsung-Han Yeh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
