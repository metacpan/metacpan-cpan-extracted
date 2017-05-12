package SMS::Send::TW::emome;

use strict;
use Carp;
use WWW::Mechanize;
use Text::Iconv;
use base 'SMS::Send::Driver';


use vars qw{$VERSION};
BEGIN {
   $VERSION = '0.04';
}

# Preloaded methods go here.

sub new {
   my ($class, %params) = @_;

   foreach(qw/username password language/) {
      Carp::croak("No $_ specified") unless(defined $params{"_$_"});
   }

   my $self = bless { %params }, $class;

   return $self;
}

sub send_sms {
   my $self   = shift;
   my %params = @_;
   my $baseurl = 'http://websms1.emome.net/sms/sendsms/new.jsp?msg=';
   my $posturl = 'http://websms1.emome.net/sms/sendsms/send.jsp';

   # Get the message and destination
   my $message   = $self->_MESSAGE( $params{text} );
   my $recipient = $self->_TO( delete $params{to} );

   my $ua = WWW::Mechanize->new(
      agent => __PACKAGE__." v. $VERSION",
   );

   $ua->agent_alias('Windows IE 6');
   $ua->get($baseurl);
   $ua->submit();
   $ua->submit();
   $ua->submit_form(
        form_name => 'form1',
        fields    => {
                        uid  => $self->{"_username"},
                        pw   => $self->{"_password"},
                     },
   );

   $ua->content() =~ /window.location.href='(.+)'/i;
   $ua->get($1);
   $ua->post($posturl,
		[
		  'nextURL' 	  => '0',
		  'resend'	  => '1',			# 0:不重送　1:重送
		  'language'	  => $self->{"_language"},	# 1:中文　  2:英文
		  'phonelist'	  => $recipient,
		  'data'	  => $message,
		  'rad'		  => '0', 			# 0:立即傳送  1:預約傳送
		]);

   return $ua->content;
}

sub _MESSAGE {

  my $class = ref $_[0] ? ref shift : shift;
  my $message = shift;
  my $converter = Text::Iconv->new("big5", "utf-8");
  unless ( length($message) <= 160 ) {
    Carp::croak("Message length limit is 160 characters");
  }
  
  
  return $converter->convert($message);
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

SMS::Send::TW::emome - SMS::Send driver for www.emome.net

=head1 SYNOPSIS

  use SMS::send;

  my $sender = SMS::Send->new('TW::emome',
                  _username   => 'UserName',
                  _password   => 'Password',
                  _language   => '1',		# 1:Chinese  2:English
                );

  my $sent = $sender->send_sms(
                  text => 'My very urgent message',
                  to   => '0912345678',
             );

=head1 DESCRIPTION

SMS::Send::TW::emome is a SMS::Send driver which allows you to send messages through L<http://www.emome.net/>.

=head1 METHODS

=head2 new

The C<new> method takes a few parameters. C<_username> , C<_password> , and C<_language> >
are mandatory. 

=head2 send_sms

Takes C<to> as recipient phonenumber, and C<text> as the text that's
supposed to be delivered.

=head1 SEE ALSO

=over 5

=item * L<Send::SMS>

=item * L<WWW::Mechanize>

=head1 AUTHOR

Tsung-Han Yeh, E<lt>snowfly@yuntech.edu.twE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Tsung-Han Yeh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
