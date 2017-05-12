package SMS::Send::TW::ShareSMS;

use strict;
use Carp;
use LWP::UserAgent;
use base 'SMS::Send::Driver';

use vars qw{$VERSION};
BEGIN {
   $VERSION = '0.02';
}

# Preloaded methods go here.



sub new {
   my ($class, %params) = @_;

   foreach(qw/username password language region/) {
      Carp::croak("No $_ specified") unless(defined $params{"_$_"});
   }

   my $self = bless { %params }, $class;

   return $self;
}

sub send_sms {
   my $self   = shift;
   my %params = @_;

  # Get the message and destination
  my $message   = $self->_MESSAGE( delete $params{text} );
  my $recipient = $self->_TO( delete $params{to} );

#   foreach(qw/to text/) {
#      Carp::croak("No $_ specified") unless(defined $params{"$_"});
#   }

   my $ua = LWP::UserAgent->new(
      agent => __PACKAGE__." v. $VERSION",
   );
   
   
   my $response = $ua->post('http://www.sharesms.com/api/SendSMS.php',
   				[  CID => $self->{"_username"},
        	                   CPW => $self->{"_password"},
                	           L => $self->{"_language"},
                        	   N => $recipient,
                   		   M => $message,
                	           W => $self->{"_region"}, ]);
   return $response->content;
}

sub _MESSAGE {
  use bytes;
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

SMS::Send::TW::ShareSMS - SMS::Send driver for www.ShareSMS.com

=head1 SYNOPSIS

  use SMS::send;

  my $sender = SMS::Send->new('TW::ShareSMS',
                  _username   => 'UserName',
                  _password   => 'Password',
                  _language   => 'E',
                  _region     => 1

                );

  my $sent = $sender->send_sms(
                  text => 'My very urgent message',
                  to   => '0912345678',
             );

=head1 DESCRIPTION

SMS::Send::TW::ShareSMS is a SMS::Send driver which allows you to send messages through L<http://www.sharesms.com/>.

=head1 METHODS

=head2 new

The C<new> method takes a few parameters. C<_username> , C<_password> , C<_language> , and C<_region>
are mandatory. 

=head2 send_sms

Takes C<to> as recipient phonenumber, and C<text> as the text that's
supposed to be delivered.


=head1 SEE ALSO

=over 5

=item * L<Send::SMS>

=back

=head1 AUTHOR

Tsung-Han Yeh, E<lt>snowfly@yuntech.edu.twE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Tsung-Han Yeh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
