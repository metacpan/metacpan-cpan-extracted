package TAM::Admin;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our $VERSION = '0.35';

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use TAM::Admin ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	IVADMINAPI_H
	IVADMIN_AUDIT_ADMIN
	IVADMIN_AUDIT_ALL
	IVADMIN_AUDIT_DENY
	IVADMIN_AUDIT_ERROR
	IVADMIN_AUDIT_NONE
	IVADMIN_AUDIT_PERMIT
	IVADMIN_CALLTYPE
	IVADMIN_CONTEXT_ADUSERREG
	IVADMIN_CONTEXT_DCEUSERREG
	IVADMIN_CONTEXT_DOMINOUSERREG
	IVADMIN_CONTEXT_LDAPUSERREG
	IVADMIN_CONTEXT_MULTIDOMAIN_ADUSERREG
	IVADMIN_DECLSPEC
	IVADMIN_FALSE
	IVADMIN_MAXRETURN
	IVADMIN_PROTOBJ_TYPE_UNKNOWN
	IVADMIN_PROTOBJ_TYPE__APP_CONTAINER
	IVADMIN_PROTOBJ_TYPE__APP_LEAF
	IVADMIN_PROTOBJ_TYPE__CONTAINER
	IVADMIN_PROTOBJ_TYPE__DIR
	IVADMIN_PROTOBJ_TYPE__DOMAIN
	IVADMIN_PROTOBJ_TYPE__EXTERN_AUTH_SVR
	IVADMIN_PROTOBJ_TYPE__FILE
	IVADMIN_PROTOBJ_TYPE__HTTP_SVR
	IVADMIN_PROTOBJ_TYPE__JNCT
	IVADMIN_PROTOBJ_TYPE__LEAF
	IVADMIN_PROTOBJ_TYPE__MGMT_OBJ
	IVADMIN_PROTOBJ_TYPE__NETSEAL_NET
	IVADMIN_PROTOBJ_TYPE__NETSEAL_SVR
	IVADMIN_PROTOBJ_TYPE__NON_EXIST_OBJ
	IVADMIN_PROTOBJ_TYPE__PORT
	IVADMIN_PROTOBJ_TYPE__PROGRAM
	IVADMIN_PROTOBJ_TYPE__WEBSEAL_SVR
	IVADMIN_REASON_ALREADY_EXISTS
	IVADMIN_RESPONSE_ERROR
	IVADMIN_RESPONSE_INFO
	IVADMIN_RESPONSE_WARNING
	IVADMIN_SSOCRED_SSOGROUP
	IVADMIN_SSOCRED_SSOWEB
	IVADMIN_TIME_LOCAL
	IVADMIN_TIME_UTC
	IVADMIN_TOD_ALL
	IVADMIN_TOD_ANY
	IVADMIN_TOD_FRI
	IVADMIN_TOD_MINUTES
	IVADMIN_TOD_MON
	IVADMIN_TOD_OCLOCK
	IVADMIN_TOD_SAT
	IVADMIN_TOD_SUN
	IVADMIN_TOD_THU
	IVADMIN_TOD_TUE
	IVADMIN_TOD_WED
	IVADMIN_TOD_WEEKDAY
	IVADMIN_TOD_WEEKEND
	IVADMIN_TRUE
) ],
'gso' => [ qw(
	IVADMIN_SSOCRED_SSOGROUP
	IVADMIN_SSOCRED_SSOWEB
) ]
	 );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	IVADMINAPI_H
	IVADMIN_AUDIT_ADMIN
	IVADMIN_AUDIT_ALL
	IVADMIN_AUDIT_DENY
	IVADMIN_AUDIT_ERROR
	IVADMIN_AUDIT_NONE
	IVADMIN_AUDIT_PERMIT
	IVADMIN_CALLTYPE
	IVADMIN_CONTEXT_ADUSERREG
	IVADMIN_CONTEXT_DCEUSERREG
	IVADMIN_CONTEXT_DOMINOUSERREG
	IVADMIN_CONTEXT_LDAPUSERREG
	IVADMIN_CONTEXT_MULTIDOMAIN_ADUSERREG
	IVADMIN_DECLSPEC
	IVADMIN_FALSE
	IVADMIN_MAXRETURN
	IVADMIN_PROTOBJ_TYPE_UNKNOWN
	IVADMIN_PROTOBJ_TYPE__APP_CONTAINER
	IVADMIN_PROTOBJ_TYPE__APP_LEAF
	IVADMIN_PROTOBJ_TYPE__CONTAINER
	IVADMIN_PROTOBJ_TYPE__DIR
	IVADMIN_PROTOBJ_TYPE__DOMAIN
	IVADMIN_PROTOBJ_TYPE__EXTERN_AUTH_SVR
	IVADMIN_PROTOBJ_TYPE__FILE
	IVADMIN_PROTOBJ_TYPE__HTTP_SVR
	IVADMIN_PROTOBJ_TYPE__JNCT
	IVADMIN_PROTOBJ_TYPE__LEAF
	IVADMIN_PROTOBJ_TYPE__MGMT_OBJ
	IVADMIN_PROTOBJ_TYPE__NETSEAL_NET
	IVADMIN_PROTOBJ_TYPE__NETSEAL_SVR
	IVADMIN_PROTOBJ_TYPE__NON_EXIST_OBJ
	IVADMIN_PROTOBJ_TYPE__PORT
	IVADMIN_PROTOBJ_TYPE__PROGRAM
	IVADMIN_PROTOBJ_TYPE__WEBSEAL_SVR
	IVADMIN_REASON_ALREADY_EXISTS
	IVADMIN_RESPONSE_ERROR
	IVADMIN_RESPONSE_INFO
	IVADMIN_RESPONSE_WARNING
	IVADMIN_SSOCRED_SSOGROUP
	IVADMIN_SSOCRED_SSOWEB
	IVADMIN_TIME_LOCAL
	IVADMIN_TIME_UTC
	IVADMIN_TOD_ALL
	IVADMIN_TOD_ANY
	IVADMIN_TOD_FRI
	IVADMIN_TOD_MINUTES
	IVADMIN_TOD_MON
	IVADMIN_TOD_OCLOCK
	IVADMIN_TOD_SAT
	IVADMIN_TOD_SUN
	IVADMIN_TOD_THU
	IVADMIN_TOD_TUE
	IVADMIN_TOD_WED
	IVADMIN_TOD_WEEKDAY
	IVADMIN_TOD_WEEKEND
	IVADMIN_TRUE
);

sub new {
	my $self = {};
	bless $self, shift;
	$self->_init(@_);
	return $self;
}

sub _init {
	my $self = shift;
	my ($ctx, $rsp);	
	my $user = shift;
	my $password = shift;
	if ( @_ ) {
		my %attr = @_;
		TAM::Admin::ivadmin_context_create( $attr{'keyring'}, 
			(exists($attr{'stash'}) ? $attr{'stash'} : ''), 
			(exists($attr{'password'}) ? $attr{'password'} : ''), 
			$user, $password,
			(exists($attr{'dn'}) ? $attr{'dn'} : ''), 
			$attr{'server'}, 
			(exists($attr{'port'}) ? $attr{'port'} : 7135), 
			$ctx, $rsp);
	} else {
		TAM::Admin::ivadmin_context_createdefault(
			$user, $password, $ctx, $rsp);
	}
	$self->{'_rsp'} = $rsp;
	$self->{'_context'} = $ctx;
	return;
}

sub cred {
	my $self = shift;
	my $pac = shift;
	TAM::Admin::ivadmin_free($self->{'_rsp'});
	my $rv = TAM::Admin::ivadmin_context_setdelcred( $self->{'_context'},
		$pac, length($pac), $self->{'_rsp'});
	return $rv;
}

sub get_user {
	my $self = shift;
	use TAM::Admin::User;
	my $rv = TAM::Admin::User->new($self->{'_context'}, @_);
	$self->{'_rsp'} = $rv->{'_rsp'};
	return $rv
}

sub import_user {
	my $self = shift;
	my %attr = @_;
	my $rsp;
	TAM::Admin::ivadmin_user_import2($self->{'_context'},
		$attr{'id'}, $attr{'dn'}, $attr{'group'} || '', 
		$attr{'gso'} || 0, $rsp);
	$self->{'_rsp'} = $rsp;
	return $self->get_user($attr{'id'});
}

sub remove_user {
	my $self = shift;
	my $id = shift;
	my $rsp;
	my $rv = TAM::Admin::ivadmin_user_delete2(
		$self->{'_context'}, $id, 0, $rsp);
	$self->{'_rsp'} = $rsp;
	return $rv;
}

sub delete_user {
	my $self = shift;
	my $id = shift;
	my $rsp;
	my $rv = TAM::Admin::ivadmin_user_delete2( $self->{'_context'}, $id, 1, 
		$rsp);
	$self->{'_rsp'} = $rsp;
	return $rv;
}

sub get_group {
	my $self = shift;
	use TAM::Admin::Group;
	my $rv =  TAM::Admin::Group->new( $self->{'_context'}, @_);
	$self->{'_rsp'} = $rv->{'_rsp'};
	return $rv
}

sub import_group {
	my $self = shift;
	my %attr = @_;
	my $rsp;
	TAM::Admin::ivadmin_group_import2(
		$self->{'_context'}, $attr{'id'}, $attr{'dn'}, 
		$attr{'container'}, $rsp);
	$self->{'_rsp'} = $rsp;
	return $self->get_group($attr{'id'});
}

sub remove_group {
	my $self = shift;
	my $id = shift;
	my $rsp;
	my $rv = TAM::Admin::ivadmin_group_delete2(
		$self->{'_context'}, $id, 0, $rsp);
	$self->{'_rsp'} = $rsp;
	return $rv;
}

sub delete_group {
	my $self = shift;
	my $id = shift;
	my $rsp;
	my $rv = TAM::Admin::ivadmin_group_delete2(
		$self->{'_context'}, $id, 1, $rsp);
	$self->{'_rsp'} = $rsp;
	return $rv;
}

sub get_gso {
	my $self = shift;
	use TAM::Admin::GSO;
	my $rv = TAM::Admin::GSO->new($self->{'_context'}, @_);
	$self->{'_rsp'} = $rv->{'_rsp'};
	return $rv;
}

sub all_gso {
	my $self = shift;
	my @gso;
	foreach my $type ( 'group', 'resource') {
		foreach my $res ( $self->list_gso($type) ) {
			push @gso, $self->get_gso( $type => $res );
		}
	}	
	return @gso;	
}

sub list_gso {
	my $self = shift;
	my $type = shift;
	my(@list,$rsp);
	if ( $type eq 'group' ) {
		TAM::Admin::ivadmin_ssogroup_list( $self->{'_context'},
			\@list, $rsp);
	} elsif ( $type eq 'resource' ) {
		TAM::Admin::ivadmin_ssoweb_list( $self->{'_context'},
			\@list, $rsp);
	} 
	$self->{'_rsp'} = $rsp;
	return @list;
}
	
sub list_objects {
        my $self = shift;
        my $parent = shift;
        my(@list,$rsp);
        TAM::Admin::ivadmin_protobj_list3( $self->{'_context'}, $parent,
                        \@list, $rsp);
        $self->{'_rsp'} = $rsp;
        return @list;
}

sub msg_count {
	my $self = shift;
	return TAM::Admin::ivadmin_response_getcount( 
		$self->{'_rsp'});
}	

sub code {
	my $self = shift;
	my $index = shift || 0;
	return TAM::Admin::ivadmin_response_getcode( 
		$self->{'_rsp'}, $index);
}

sub message {
	my $self = shift;
	my $index = shift || 0;
	return TAM::Admin::ivadmin_response_getmessage( 
		$self->{'_rsp'}, $index);
}

sub ok {
	my $self = shift;
	return TAM::Admin::ivadmin_response_getok(
		$self->{'_rsp'});
}

sub error {
	my $self = shift;
	return 0 if $self->ok;
	return 1;
}

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined TAM::Admin macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap TAM::Admin $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

TAM::Admin - Perl extension for Tivoli Access Manager (TAM) Admin API

=head1 SYNOPSIS

  use TAM::Admin;

  # Connect to the policy server as sec_master
  my $pdadmin = TAM::Admin->new('sec_master', 'password');

  # Get the user with the ID joe and print basic information
  my $user = $pdadmin->get_user('joe');
  print 'Login ID: ', $user->id, "\n";
  print 'Login CN: ', $user->cn, "\n";
  print 'Login DN: ', $user->dn, "\n";

  # Make the user account valid
  $user->valid(1);
  # Make the user a Non-GSO user
  $user->gso(0);

=head1 DESCRIPTION

TAM::Admin is a set of modules that utilize to TAM Admin C API to perform management functions within a Tivoli Access Manager environment.

=head1 METHODS

=head2 Constructor Method

=head3 new(<user>, <password>, [<options>])

Creates a new TAM::Admin object and connects to the policy server. The first two arguments specifies the user ID of the administration and the password. If no other options are specified, the API will utilize the configuration information of the local TAM runtime. Additional options are:

=over 4

=item keyring => FILENAME

Specifies the filename for a CMS keyring database for SSL operations.

=item stash => FILENAME

Specifies the filename of the stash file for the keyring.

=item password => PASSWORD

Specifies the password for the keyring.  This parameter will take precedence over the stash file.

=item dn => CERTIFICATE DN

Specifies the DN of a certificate to be utilized for authentication.

=item server => HOSTNAME

Specifies the location of the policy server.

=item port => PORT

Specifies the TCP port of the policy server process.  Default port is 7135.

B<Examples>

	# Create a default context
	$pdadmin = TAM::Admin->new('sec_master', 'password'); 

	# Connect to policy server tam2.foobar.com
	$pdadmin = TAM::Admin->new('sec_master', 'password', 
		keyfile => '/var/PolicyDirector/keytab/pd2.kdb',
		password => 'cmsopen',
		server => 'tam2.foobar.com'); 

=head2 User Management

These methods are used for basic user management, i.e. get, import, create, remove, and delete.  Management of the individual user, e.g. set account valid, is done via the TAM::Admin::User module.

=head3 get_user(<userid>)

Retrieve a user object for the specified ID.  This function will return a TAM::Admin::User object.  A user object can also be retrieved by LDAP DN.  To get a user by DN call the method in the following fashion...

  $pdadmin->get_user(dn => <ldap dn>)

=head3 import_user(<userid>, <dn>)

Import a LDAP account into TAM. The first argument will used as the TAM logon ID and the second argument designates the LDAP of the existing account.  This function will return a TAM::Admin::User object relating to the imported user.

=head3 remove_user(<userid>)

Remove a user from TAM only.  This method is equivalent to the following pdadmin command.

   pdadmin> user delete <userid>

=head3 delete_user(<userid>)

Remove a user from TAM and LDAP.  This method is equivalent to the following pdadmin command.

   pdadmin> user delete -registry <userid>

=head2 Group Methods

These methods are used for basic group management, i.e. get, import, create, remove, and delete.  Management of the individual group, e.g. add users, is done via the TAM::Admin::Group module.

=head3 get_group(<groupid>)

Retrieve a group object for the specified ID.  This function will return a TAM::Admin::Group object.  A group object can also be retrieved by LDAP DN.  To get a user by DN call the method in the following fashion...

  $pdadmin->get_group(dn => <ldap dn>)
=head3 import_group(<groupid>, <dn>)

Import a LDAP group into TAM. The first argument will used as the TAM group ID and the second argument designates the LDAP object of the existing group.  This function will return a TAM::Admin::Group object relating to the imported group.

=head3 remove_group(<groupid>)

Remove a group from TAM only.  This method is equivalent to the following pdadmin command.

   pdadmin> group delete <userid>

=head3 delete_group(<groupid>)

Remove a group from TAM and LDAP.  This method is equivalent to the following pdadmin command.

   pdadmin> group delete -registry <groupid>

=head2 GSO Methods 

These methods are used for basic GSO management, i.e. get, create, and delete.  Management of individual GSO objects is done via the TAM::Admin::GSO module.

=head3 get_gso(<type> => <id>)

Returns a TAM::Admin:GSO object for the specified resource.  Type is either 'group' or 'resource' and the ID is the label of the GSO resource.

=head3 all_gso

Returns an array of all TAM::Admin:GSO objects.

=head3 list_gso(<type>)

Returns an array of IDs for all GSO resources of a given type.  Type is either 'group' or 'resource'.

=head2 Protected Object Methods

These methods are used for basic management of TAM protected objects. 

=head3 list_objects(<path>)

Returns an array of objects that are contained in the path given. This method is equivalent to the following pdadmin command

   pdadmin> object list <path>

=head2 Response Methods

These methods help manage and retrive messages from actions performed.  These mehoted are inherited by all TAM::Admin objects.

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

=head1 EXPORT

None by default.

=head2 Exportable constants

  IVADMINAPI_H
  IVADMIN_AUDIT_ADMIN
  IVADMIN_AUDIT_ALL
  IVADMIN_AUDIT_DENY
  IVADMIN_AUDIT_ERROR
  IVADMIN_AUDIT_NONE
  IVADMIN_AUDIT_PERMIT
  IVADMIN_CALLTYPE
  IVADMIN_CONTEXT_ADUSERREG
  IVADMIN_CONTEXT_DCEUSERREG
  IVADMIN_CONTEXT_DOMINOUSERREG
  IVADMIN_CONTEXT_LDAPUSERREG
  IVADMIN_CONTEXT_MULTIDOMAIN_ADUSERREG
  IVADMIN_DECLSPEC
  IVADMIN_FALSE
  IVADMIN_MAXRETURN
  IVADMIN_PROTOBJ_TYPE_UNKNOWN
  IVADMIN_PROTOBJ_TYPE__APP_CONTAINER
  IVADMIN_PROTOBJ_TYPE__APP_LEAF
  IVADMIN_PROTOBJ_TYPE__CONTAINER
  IVADMIN_PROTOBJ_TYPE__DIR
  IVADMIN_PROTOBJ_TYPE__DOMAIN
  IVADMIN_PROTOBJ_TYPE__EXTERN_AUTH_SVR
  IVADMIN_PROTOBJ_TYPE__FILE
  IVADMIN_PROTOBJ_TYPE__HTTP_SVR
  IVADMIN_PROTOBJ_TYPE__JNCT
  IVADMIN_PROTOBJ_TYPE__LEAF
  IVADMIN_PROTOBJ_TYPE__MGMT_OBJ
  IVADMIN_PROTOBJ_TYPE__NETSEAL_NET
  IVADMIN_PROTOBJ_TYPE__NETSEAL_SVR
  IVADMIN_PROTOBJ_TYPE__NON_EXIST_OBJ
  IVADMIN_PROTOBJ_TYPE__PORT
  IVADMIN_PROTOBJ_TYPE__PROGRAM
  IVADMIN_PROTOBJ_TYPE__WEBSEAL_SVR
  IVADMIN_REASON_ALREADY_EXISTS
  IVADMIN_RESPONSE_ERROR
  IVADMIN_RESPONSE_INFO
  IVADMIN_RESPONSE_WARNING
  IVADMIN_SSOCRED_SSOGROUP
  IVADMIN_SSOCRED_SSOWEB
  IVADMIN_TIME_LOCAL
  IVADMIN_TIME_UTC
  IVADMIN_TOD_ALL
  IVADMIN_TOD_ANY
  IVADMIN_TOD_FRI
  IVADMIN_TOD_MINUTES
  IVADMIN_TOD_MON
  IVADMIN_TOD_OCLOCK
  IVADMIN_TOD_SAT
  IVADMIN_TOD_SUN
  IVADMIN_TOD_THU
  IVADMIN_TOD_TUE
  IVADMIN_TOD_WED
  IVADMIN_TOD_WEEKDAY
  IVADMIN_TOD_WEEKEND
  IVADMIN_TRUE


=head1 AUTHOR

George Chlipala, george@walnutcs.com

=head1 SEE ALSO

perl(1).

=cut
