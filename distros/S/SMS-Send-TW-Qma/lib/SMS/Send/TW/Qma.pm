package SMS::Send::TW::Qma;

use strict;
use base 'SMS::Send::Driver';
use WWW::Mechanize;

use vars qw{$VERSION};
BEGIN {
   $VERSION = '0.01';
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

   my $baseurl = 'http://www.qma.com/cdp/jsp/websms';
   my $posturl = 'http://www.qma.com/cdp/jsp/websms/SMS_Action.jsp';

   # Get the message and destination
   my $message   = $self->_MESSAGE( $params{text} );
   my $recipient = $self->_TO( delete $params{to} );

   my $ua = WWW::Mechanize->new(
      agent => __PACKAGE__." v. $VERSION",
   );

   $ua->agent_alias('Windows IE 6');
   $ua->get("$baseurl/SMS_send.jsp");
   $ua->submit_form(
	form_name => 'form1',
	fields    => {
			'j_username'	=> $self->{"_username"},
			'j_password'	=> $self->{"_password"},
                     },
   );

   # Should be ok now, right? Let's send it!
   # Input SMS_Message, Recipients

   $ua->post($posturl,
		[
			'receivers'     => $recipient,
			'sendContent'   => $message,
			'iscurrentsend' => 'Y',
			'func'          => 'addSmsMessageInfo',
			'targetURL'     => 'SMS_send_result.jsp',
#			'sender'        => "0953858839",
#			'contractid'    => 'sf093',
		]);


   $ua->content() =~ /document.location="(.+)"/i;
   $ua->get("$baseurl/$1&iscurrentsend=Y");

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

SMS::Send::TW::Qma - SMS::Send driver for www.qma.com

=head1 SYNOPSIS

  use SMS::Send;

  my $sender = SMS::Send->new('TW::Qma',
                  _username   => 'UserName',
                  _password   => 'Password',
                );

  my $sent = $sender->send_sms(
                  text => 'My very urgent message',
                  to   => '0912345678',
             );

=head1 DESCRIPTION

SMS::Send::TW::Qma is a SMS::Send driver which allows you to send messages through L<http://www.qma.com/>.

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

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Send-SMS-TW-Qma>

=head1 AUTHOR

Tsung-Han Yeh, E<lt>snowfly@yuntech.edu.twE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tsung-Han Yeh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
