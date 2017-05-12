package TAM::Admin::Group;

use strict;
use vars qw($AUTOLOAD);
our @ISA = qw(TAM::Admin);

sub _init {
        my $self = shift;
        $self->{'_context'} = shift;
	my($group,$rsp);
	if ( $#_ == 0 ) {
		TAM::Admin::ivadmin_group_get( $self->{'_context'}, shift, 
			$group, $rsp);
	} elsif ( lc($_[0]) eq 'dn' ) {
		TAM::Admin::ivadmin_group_getbydn( $self->{'_context'}, $_[1], 
			$group, $rsp);
	} elsif ( $#_ == 1 ) {
		TAM::Admin::ivadmin_group_get( $self->{'_context'}, $_[1], 
			$group, $rsp);
	}
	$self->{'_rsp'} = $rsp;
        $self->{'_object'} = $group;
        return;
}

sub cn {
	my $self = shift;
	return TAM::Admin::ivadmin_group_getcn( 
		$self->{'_object'});
}

sub dn {
	my $self = shift;
	return TAM::Admin::ivadmin_group_getdn( 
		$self->{'_object'});
}

sub id {
	my $self = shift;
	return TAM::Admin::ivadmin_group_getid(
		$self->{'_object'});
}

sub description {
	my $self = shift;
	if ( @_ ) {
		my $rsp;
		TAM::Admin::ivadmin_group_setdescription(
			$self->{'_context'}, $self->{'_id'}, shift, $rsp);
		$self->{'_rsp'} = $rsp;
	}
	return TAM::Admin::ivadmin_group_getdescription(
		$self->{'_object'});
}

sub delete {
	my $self = shift;
	return $self->delete_group($self->{'_id'});
}

sub remove {
	my $self = shift;
	return $self->remove_group($self->{'_id'});
}

sub members {
	my $self = shift;
	my($rsp,@users);
	TAM::Admin::ivadmin_group_getmembers($self->{'_context'},
		$self->{'_id'}, \@users, $rsp);	
	$self->{'_rsp'};	
	return @users;
}

1;

__END__
# Below is stub documentation for the module.

=head1 NAME

TAM::Admin::Group - Perl extension for TAM Admin API

=head1 SYNOPSIS

  use TAM::Admin;

  # Connect to the policy server as sec_master
  my $pdadmin = TAM::Admin->new('sec_master', 'password');

  # Get the iv-admin group and print basic information
  my $group = $pdadmin->get_group('iv-admin');
  print 'Group ID: ', $group->id, "\n";
  print 'Group CN: ', $group->cn, "\n";
  print 'Group DN: ', $group->dn, "\n";

=head1 DESCRIPTION

TAM::Admin::Group is a support module for the TAM::Admin module.

=head1 METHODS

=head2 id

Return the TAM ID of the group.

=head2 cn

Return the LDAP CN of the group.

=head2 dn

Returns the LDAP DN of the group.

=head2 description(<description>)

Return the current description of the group.  The method will set the description to the value of the first parameter, if passed.

=head2 remove

Remove the group from TAM only.  This method is equivalent to the following pdadmin command.

   pdadmin> group delete <userid>

=head2 delete

Remove the group from TAM and LDAP.  This method is equivalent to the following pdadmin command.

   pdadmin> group delete -registry <userid>

=head2 ok

Returns true if the last action was successful.

=head2 error

Returns true if the last action was unsuccessful.

=head2 message([<index>])

Returns the error message for the last action. The index will specify which error message to return if the last action resulted in more that one error condition. The index is 0 based.

=head2 code([<index>])

Returns the error code for the last action. The index will specify which error code to return if the last ction resulted in more that one error condition.  The index is 0 based.

=head1 msg_count 

Returns the number of errors generated for the last action.

=head1 AUTHOR

George Chlipala, george@walnutcs.com

=head1 SEE ALSO

perl(1).

=cut

