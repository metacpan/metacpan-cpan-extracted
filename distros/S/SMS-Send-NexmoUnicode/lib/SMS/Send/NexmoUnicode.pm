package SMS::Send::NexmoUnicode;

use strict;
use base 'SMS::Send::Driver';
use Nexmo::SMS;

use vars qw{$VERSION};
BEGIN {
   $VERSION = '0.02';
}

sub new {
   my ($class, %params) = @_;

   foreach(qw/username password type from/) {
      Carp::croak("No $_ specified") unless(defined $params{"_$_"});
   }

   my $self = bless { %params }, $class;

   return $self;
}

sub send_sms {
   my $self   = shift;
   my %params = @_;
   my %options;

   # Get the message and destination
   my $message   = $self->_MESSAGE( $params{text} );
   my $recipient = $self->_TO( delete $params{to} );

   my $nexmo = Nexmo::SMS->new(
	   server => 'https://rest.nexmo.com/sms/json',
	   username => $self->{"_username"},
	   password => $self->{"_password"},
	   );

   my $sms = $nexmo->sms(
	   text => $message,
	   to => $recipient,
	   type => $self->{"_type"},
	   from => $self->{"_from"},
	   ) or die $nexmo->errstr;

   if ('http' eq $self->{'_proxy_type'}) {
       $sms->user_agent->proxy(['http'], 'http://' . $self->{'_proxy_host'} . ':' . $self->{'_proxy_port'});
   }
   
   my $res = $sms->send;

   return $res->is_success;
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

SMS::Send::NexmoUnicode - SMS::Send driver for www.nexmo.com

=head1 SYNOPSIS

  use SMS::Send;

  my $sender = SMS::Send->new('NexmoUnicode',
                  _username   => 'UserName',
                  _password   => 'Password',
		  _type	      => 'unicode',
		  _from	      => 'author',
                );

  my $sent = $sender->send_sms(
                  text => 'My very urgent message',
                  to   => '0912345678',
             );

=head1 DESCRIPTION

SMS::Send::NexmoUnicode is a SMS::Send driver which allows you to send unicode messages through L<http://www.nexmo.com/>.

=head1 METHODS

=head2 new

The C<new> method takes a few parameters. C<_username> , C<_password>, C<_type>, and C<_from> 
are mandatory. 

=head2 send_sms

Takes C<to> as recipient phonenumber, and C<text> as the text that's
supposed to be delivered.


=head1 SEE ALSO

=over 5

=item * L<Send::SMS>

=item * L<SMS::Nexmo>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Send-SMS-NexmoUnicode>


=head1 AUTHOR

Jui-Nan Lin, E<lt>jnlin@csie.nctu.edu.twE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Jui-Nan Lin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

