package RWDE::Mailing;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

=pod

=head1 RWDE::Mailing

Mailing interface for objects that can receive emails.

Throttling is also provided to keeping daily count of emails sent under control. 

To be clear this is meant to be used as a base class and derived classes are required to 
implement certain methods so the facility works correctly.

=cut
  
=head2 get_email()

Retrieve the class defined email address. This is specifically assigned within the RWDE
Object hash for the purpose of dispatching emails.

=cut

sub get_email {
  my ($self, $params) = @_;

  my $email_field = $self->{_email};

  throw RWDE::DevelException({ info => " $self does not have an email address" })
    unless defined $email_field;

  return $self->$email_field;
}

=head2 send_message()

This method is required to be implemented by your derived class. If you don't implement it
an DevelException will be thrown upon invocation.

The implementation for this method should include a call to _send_message in order for the interface
to work end to end.

=cut

sub send_message {
  my ($self, $params) = @_;

  my $class = ref $self || $self;
	
  throw RWDE::DevelException({ info =>"Class $class does not implement send_message" });
	
  return();
}

=head2 _send_message()

Verify that that record has no exceeded specified daily limits for messages.

If the number of messages has not been exceeded then the message is sent out
via RWDE::PostMaster

=cut

sub _send_message {
  my ($self, $params) = @_;

  if (defined $$params{user_initiated}){
    $self->check_limit();
    $self->mail_count($self->mail_count+1);
    $self->update_record();
  }
	
  my %loc_params = %{$params}; #copy the hash, to avoid side-effects

  RWDE::PostMaster->send_message($params);

  $self->syslog_msg('devel', 'Sent ' .  $loc_params{template} . ' to ' . $loc_params{smtp_recipient});

  return();	
}

=head2 check_limit()

Check to make sure that the mailing limit (default 5) has not been exceeded for today.

=cut

sub check_limit {
  my ($self, $params) = @_;
	
  if ($self->mail_count >= 5){
    throw RWDE::DataLimitException({ info => 'Max number of user inititiated emails reached for today.'});
  }
	
  return();
}

1;

