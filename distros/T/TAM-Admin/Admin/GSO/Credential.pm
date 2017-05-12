package TAM::Admin::GSO::Credential;

use strict;
use vars qw($AUTOLOAD);
our @ISA = qw(TAM::Admin);
use TAM::Admin qw/:gso/;

sub _init {
	my $self = shift;
	$self->{'_context'} = shift;
	$self->{'_object'} = shift;
	return;
}

sub id {
	my $self = shift;
	return TAM::Admin::ivadmin_ssocred_getid($self->{'_object'});
}

sub type {
	my $self = shift;
	my $type = TAM::Admin::ivadmin_ssocred_gettype($self->{'_object'});
	return $type if $_[0] eq 'long';
	if ( $type == &IVADMIN_SSOCRED_SSOGROUP ) {
		return 'group';
	} elsif ( $type == return &IVADMIN_SSOCRED_SSOWEB ) {
		return 'resource';
	}
	return;

}

sub owner {
	my $self = shift;
	return TAM::Admin::ivadmin_ssocred_getuser($self->{'_object'});
}

sub user {
	my $self = shift;
	return TAM::Admin::ivadmin_ssocred_getssouser($self->{'_object'});
}

sub password {
	my $self = shift;
	return TAM::Admin::ivadmin_ssocred_getssopassword($self->{'_object'});
}
	
sub delete {
	my $self = shift;
	my $rsp;
	TAM::Admin::ivadmin_ssocred_delete(
		$self->{'_context'}, $self->id, $self->type('long'),
		$self->owner, $rsp);
	$self->{'_rsp'} = $rsp;
	return;
}

1;

__END__
# Below is stub documentation for the module.

=head1 NAME

TAM::Admin::GSO::Credential

=head1 SYNOPSIS

  use TAM::Admin;

  # Connect to the policy server as sec_master
  my $pdadmin = TAM::Admin->new('sec_master', 'password');

  # Get the GSO resource 'winnt'
  my $gso = $pdadmin->get_gso(resource => 'winnt');

  # Get the credential for 'bob'
  my $cred = $gso->get_cred('bob');

  # Print basic information for this credential
  print 'GSO Label: ', $cred->id, "\n";
  print 'GSO type: ', $cred->type, "\n";
  print 'TAM ID: ', $cred->owner, "\n";
  print 'Credential username: ', $cred->user, "\n";

=head1 DESCRIPTION

TAM::Admin::GSO::Credential is a support module for the TAM::Admin module.

=head1 METHODS

=head2 Basic Attributes

=head3 id

Return the GSO label of the credential.

=head3 owner

Return the TAM ID of the user tied to the credential.

=head3 user

Returns the username of the credential.

=head3 password

Returns the password of the credential.

=head3 type

Returns the credential type, i.e. 'group' or 'resource'.

=head2 Credential Management

=head3 delete 

Deletes the credential.  Besure to undef the object, since it will no longer be valid.

=head2 Response Methods

=head3 ok

Returns true if the last action was successful.

=head3 error

Returns true if the last action was unsuccessful.

=head3 message([<index>])

Returns the error message for the last action. The index will specify which error message to return if the last action resulted in more that one error condition. The index is 0 based.

=head3 code([<index>])

Returns the error code for the last action. The index will specify which error code to return if the last ction resulted in more that one error condition.  The index is 0 based.

=head1 msg_count 

Returns the number of errors generated for the last action.

=head1 AUTHOR

George Chlipala, george@walnutcs.com

=head1 SEE ALSO

perl(1).

=cut
