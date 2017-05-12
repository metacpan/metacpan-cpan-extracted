package TAM::Admin::User;

use strict;
use vars qw($AUTOLOAD);
our @ISA = qw(TAM::Admin);

sub new {
        my $self = {};
        bless $self, shift;
        $self->_init(@_);
        return $self;
}

sub _init {
        my $self = shift;
        $self->{'_context'} = shift;
	my($user,$rsp);
	if ( $#_ == 0 ) {
		TAM::Admin::ivadmin_user_get($self->{'_context'}, 
			shift, $user, $rsp);
	} elsif ( lc($_[0]) eq 'dn' ) {
		TAM::Admin::ivadmin_user_getbydn($self->{'_context'}, 
			$_[1], $user, $rsp);
	} elsif ( $#_ == 1 ) { 
		TAM::Admin::ivadmin_user_get($self->{'_context'}, 
			$_[1], $user, $rsp);
	}
		 
	$self->{'_rsp'} = $rsp;
        $self->{'_object'} = $user;
        return;
}

sub cn {
	my $self = shift;
	return TAM::Admin::ivadmin_user_getcn( $self->{'_object'});
}

sub sn {
	my $self = shift;
	return TAM::Admin::ivadmin_user_getsn( $self->{'_object'});
}

sub dn {
	my $self = shift;
	return TAM::Admin::ivadmin_user_getdn( $self->{'_object'});
}

sub id {
	my $self = shift;
	return TAM::Admin::ivadmin_user_getid(
		$self->{'_object'});
}

sub description {
	my $self = shift;
	if ( @_ ) {
		my $rsp;
		TAM::Admin::ivadmin_user_setdescription(
			$self->{'_context'}, $self->{'_id'}, shift, $rsp);
		$self->{'_rsp'} = $rsp;
	}
	return TAM::Admin::ivadmin_user_getdescription(
		$self->{'_object'});
}

sub valid {
	my $self = shift;
	if ( @_ ) {
		my $rsp;
		TAM::Admin::ivadmin_user_setaccountvalid(
			$self->{'_context'}, $self->{'_id'}, shift, $rsp);
		$self->{'_rsp'} = $rsp;
	}
	return TAM::Admin::ivadmin_user_getaccountvalid(
		$self->{'_object'});
}
	
sub gso {
	my $self = shift;
	if ( @_ ) {
		my $rsp;
		TAM::Admin::ivadmin_user_setssouser(
			$self->{'_context'}, $self->{'_id'}, shift, $rsp);
		$self->{'_rsp'} = $rsp;
	}
	return TAM::Admin::ivadmin_user_getssouser(
		$self->{'_object'});
}

sub delete {
	my $self = shift;
	return $self->delete_user($self->{'_id'});
}

sub remove {
	my $self = shift;
	return $self->remove_user($self->{'_id'});
}

sub groups {
	my $self = shift;
	my(@groups,$rsp); 
	TAM::Admin::ivadmin_user_getmemberships($self->{'_context'}, 
		$self->{'_id'}, \@groups, $rsp);
	$self->{'_rsp'} = $rsp;
	return @groups;
}

sub add_gso {
	my $self = shift;
	my $gso = shift;
	my $rv = $gso->add_cred( $self->id, @_);
	$self->{'_rsp'} = $gso->{'_rsp'};
	return $rv;
}

sub all_gso {
	my $self = shift;
	my(@list,$rsp);
	TAM::Admin::ivadmin_ssocred_list( $self->{'_context'}, $self->id,
		 \@list,$rsp);
	$self->{'_rsp'} = $rsp;	
	use TAM::Admin::GSO::Credential;
	foreach my $i (0..$#list) {
		$list[$i] = TAM::Admin::GSO::Credential->new($list[$i]);
	}
	return @list;
}

sub get_gso {
	my $self = shift;
	use TAM::Admin::GSO;
	my $gso = TAM::Admin::GSO->new($self->{'_context'}, @_);
	my $cred = $gso->get_cred($self->id);
	$self->{'_rsp'} = $gso->{'_rsp'};
	return $cred;
}

1;

__END__
# Below is stub documentation for the module.

=head1 NAME

TAM::Admin::User

=head1 SYNOPSIS

  use TAM::Admin;

  # Connect to the policy server as sec_master
  my $pdadmin = TAM::Admin->new('sec_master', 'password');

  # Get the user with the ID joe and print basic information
  my $user = $pdadmin->get_user('joe');
  print 'Login ID: ', $user->id, "\n";
  print 'Login CN: ', $user->cn, "\n";
  print 'Login DN: ', $user->dn, "\n";

  if ( $user->valid ) {
	print "User account valid.\n";
  } else {
  	# Make the user account valid
  	$user->valid(1);
  }

  # Make the user a Non-GSO user
  $user->gso(0);

=head1 DESCRIPTION

TAM::Admin::User is a support module for the TAM::Admin module.

=head1 METHODS

=head2 Basic Attributes

=head3 id

Return the TAM ID of the user.

=head3 cn

Return the LDAP CN of the user.

=head3 sn

Return the LDAP SN of the user.

=head3 dn

Returns the LDAP DN of the user.

=head3 description(<description>)

Return the current description of the user.  The method will set the description to the value of the first parameter, if passed.

=head3 valid(<valid>)

Returns true if the account is currently valid.  The method will also set the account validity of the user if 1 (valid) or 0 (invalid) is passed as an argument.

=head3 gso(<valid>)

Returns true if the account is a GSO user.  The method will also set the GSO state of the user if 1 (GSO user) or 0 (non-GSO user) is passed as an argument.

=head2 Account Removal

=head3 remove

Remove the user from TAM only.  This method is equivalent to the following pdadmin command.

   pdadmin> user delete <userid>

=head3 delete

Remove the user from TAM and LDAP.  This method is equivalent to the following pdadmin command.

   pdadmin> user delete -registry <userid>

=head2 GSO Methods

=head3 add_gso(<gso>, <username>, <password>)

Create a new GSO credential for this user. The first argument is a GSO object that corresponds to the GSO resource to add the credential. The next two (2) arguments specify the username/password pair to be added into the new credential.

=head3 all_gso

Returns an array of all GSO credential objects for the user.  The items in the array will be TAM::Admin::GSO::Credential objects.

=head3 get_gso(<type> => <id>)

Return the a specific GSO credential object for the user. Type is ether 'group' or resource and ID is the label of the GSO resource.  The returned object will be a TAM::Admin:GSO::Credential object.

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

