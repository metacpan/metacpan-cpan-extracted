package TAM::Admin::GSO;

use strict;
use vars qw($AUTOLOAD);
our @ISA = qw(TAM::Admin);
use TAM::Admin qw/:gso/;

sub _init {
	my $self = shift;
	$self->{'_context'} = shift;
	my %hash = @_;
	my($type, $id) = each(%hash);
	my($rsp,$object);
	$self->{'_id'} = $id;
	if ( $type eq 'group' ) {
		$self->{'_type'} = 'group';
		TAM::Admin::ivadmin_ssogroup_get($self->{'_context'}, $id, 
			$object, $rsp);
	} elsif ( $type eq 'resource' ) {
		$self->{'_type'} = 'resource';
		TAM::Admin::ivadmin_ssoweb_get($self->{'_context'}, $id, 
			$object, $rsp);
	}
	$self->{'_object'} = $object;
	$self->{'_rsp'} = $rsp;
	return;
}

sub id {
	my $self = shift;
	if ( $self->{'_type'} eq 'group' ) {
		return TAM::Admin::ivadmin_ssogroup_getid($self->{'_object'});
	} elsif ( $self->{'_type'} eq 'resource' ) {
		return TAM::Admin::ivadmin_ssoweb_getid($self->{'_object'});
	}
	return;
}

sub description {
	my $self = shift;
	if ( $self->{'_type'} eq 'group' ) {
		return TAM::Admin::ivadmin_ssogroup_getdescription(
			$self->{'_object'});
	} elsif ( $self->{'_type'} eq 'resource' ) {
		return TAM::Admin::ivadmin_ssoweb_getdescription(
			$self->{'_object'});
	}
	return;
}

sub list {
	my $self = shift;
	if ( $self->{'_type'} eq 'group' ) {
		my @sso;
		TAM::Admin::ivadmin_ssogroup_getresources(
			$self->{'_object'}, \@sso);
		return @sso;
	}
	return;
}	

sub resources {
	my $self = shift;
	if ( $self->{'_type'} eq 'group' ) {
		my @sso;
		foreach my $id ( $self->list ) {
			push(@sso, $self->get_gso('resource' => $id));
		}
		return @sso;
	}
	return;
}	
	
sub type {
	my $self = shift;
	if ( $self->{'_type'} eq 'group' ) {
		return &IVADMIN_SSOCRED_SSOGROUP;
	} elsif ( $self->{'_type'} eq 'resource' ) {
		return &IVADMIN_SSOCRED_SSOWEB;
	}
	return;

}

sub add_cred {
	my $self = shift;
	my $tamid = shift;
	my $ssouser = shift;
	my $ssopwd = ( shift || 'NULL' );
	my $rsp;
	my $rv = TAM::Admin::ivadmin_ssocred_create($self->{'_context'},
		$self->id, $self->type, $tamid, $ssouser, $ssopwd, $rsp);
	$self->{'_rsp'} = $rsp;
	return $rv;
}

sub get_cred {
	use TAM::Admin::GSO::Credential;
	my $self = shift;
	my $id = shift;
	my($cred,$rsp);
	TAM::Admin::ivadmin_ssocred_get($self->{'_context'}, $self->id,
		$self->type, $id, $cred, $rsp);
	$self->{'_rsp'} = $rsp;
	return unless $cred;
	return TAM::Admin::GSO::Credential->new($self->{'_context'},$cred);
}
1;

__END__
# Below is stub documentation for the module.

=head1 NAME

TAM::Admin::GSO

=head1 SYNOPSIS

  use TAM::Admin;

  # Connect to the policy server as sec_master
  my $pdadmin = TAM::Admin->new('sec_master', 'password');

  # Get the GSO resource with the ID winnt and print basic information
  my $gso = $pdadmin->get_gso('resource' => 'winnt');
  print 'GSO ID: ', $gso->id, "\n";
  print 'GSO Description: ', $gso->description, "\n";

  # Get the credential for bob
  my $cred = $gso->get_cred('bob')

  # Add a credential for alice
  $gso->add_cred('alice', 'WORKGROUP\ALICE', 'mypassword');

=head1 DESCRIPTION

TAM::Admin::GSO is a support module for the TAM::Admin module.

=head1 METHODS

=head2 Basic Methods

=head3 id

Return the label of the GSO object.

=head3 description(<description>)

Return the current description of the GSO object.  The method will set the description to the value of the first parameter, if passed.

=head3 add_cred(<userid>, <username>, <password>)

Add a credential for the user designated by the first argument.  The second and third argument specify the username/password pair information to be contained in the new credential

=head3 get_cred(<userid>)

Retrieve the credential information for the specified user.  The resulting object will be a TAM::Admin::GSO::Credential object.

=head2 Resource Group Methods

These methods only apply if the GSO object is a GSO resource group.

=head3 list

List all GSO resources in this resource group.

=head3 resources

Return an array of the GSO resources in this group.  Each entry in the array will be a TAM::Admin::GSO object.

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
