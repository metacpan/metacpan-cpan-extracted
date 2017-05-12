package SMS::Send::NL::Mollie;

use strict;
use base 'SMS::Send::Driver';
use Net::SMS::Mollie;

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

   my $mollie = Net::SMS::Mollie->new(
      username  => $self->{"_username"},
      password  => $self->{"_password"},
   );
   $mollie->originator($self->{"_originator"}) 
      if(defined $self->{"_originator"});
   $mollie->originator($self->{"_gateway"}) 
      if(defined $self->{"_gateway"});

   $mollie->recipient($params{"to"});
   return $mollie->send($params{"text"});
}

#################### main pod documentation begin ###################

=head1 NAME

SMS::Send::NL::Mollie - SMS::Send driver for www.mollie.nl

=head1 SYNOPSIS

  use SMS::Send;

  my $sender = SMS::Send->new('NL::Mollie',
                  _username   => 'MyUserName',
                  _password   => 'P4ssw0rd!',
                  _originator => '0612345678',
                  _gateway    => 2,
               );

  my $sent = $sender->send_sms(
                  text => 'My very urgent message',
                  to   => '0687654321',
             ); 

=head1 DESCRIPTION

SMS::Send::NL::Mollie is a L<SMS::Send> driver which allows you to send
messages through L<http://www.mollie.nl/>.

=head1 METHODS

=head2 new

The C<new> method takes a few parameters. C<_username> and C<_password>
are mandatory, C<_originator>, and C<_gateway> are optional. 
See L<Net::SMS::Mollie> for details on these parameters. 

This driver is a very simplified wrapper around L<Net::SMS::Mollie> 
and provides a lot less functionality than L<Net::SMS::Mollie>.

=head2 send_sms

Takes C<to> as recipient phonenumber, and C<text> as the text that's
supposed to be delivered.

=head1 SEE ALSO

=over 5

=item * L<Send::SMS>

=item * L<Net::SMS::Mollie>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Send-SMS-NL-Mollie>

=head1 AUTHOR

M. Blom
E<lt>blom@cpan.orgE<gt>
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
