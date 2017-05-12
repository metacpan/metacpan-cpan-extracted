package Plugtools;

use warnings;
use strict;
use Config::IniHash;
use File::BaseDir qw/xdg_config_home/;
use Sys::User::UIDhelper;
use Sys::Group::GIDhelper;
use Net::LDAP;
use Net::LDAP::posixAccount;
use Net::LDAP::posixGroup;
use String::ShellQuote;
use Net::LDAP::Extension::SetPassword;

=head1 NAME

Plugtools - LDAP and Posix

=head1 VERSION

Version 1.3.0

=cut

our $VERSION = '1.3.0';


=head1 SYNOPSIS

    use Plugtools;

    my $pt = Plugtools->new();
    ...

=head1 METHODS

=head2 new

Initiate Plugtools.

Only one arguement is accepted and that is a hash.

=head3 args hash

At this time, none of these values are required.

=head4 config

This specifies a config file to read other than the default.

    #initilize it and read the default config
    my $pt=Plugtools->new();
    if($pt->{error}){
        print "Error!\n";
    }

    #initilize it and read '/some/config'
    my $pt=Plugtools->new({ config=>'/some/config' });
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self = {error=>undef, errorString=>"", module=>'Plugtools'};
	bless $self;

	if (!defined($args{config})) {
		$args{config}=xdg_config_home().'/plugtoolsrc';
	}

	$self->readConfig($args{config});

	return $self;
}

=head2 addGroup

=head3 args hash

=head4 group

This is the group name to add.

=head4 gid

This is the numeric ID of the group to add. If it is
not defined, it will automatically be added.

=head4 dump

If this is true, call the dump method on the create Net::LDAP::Entry object.

    #the most basic form
    $pt->addGroup({
                   group=>'someGroup',
                   })
    if($pt->{errpr}){
        print "Error!\n";
    }

    #do more
    $pt->addGroup({
                   group=>'someGroup',
                   gid=>'4444',
                   dump=>'1',
                   })
    if($pt->{errpr}){
        print "Error!\n";
    }

=cut

sub addGroup{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blanks any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{group})) {
		$self->{error}=6;
		$self->{errorString}='No group name specified';
		warn('Plugtools addGroup:6: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($gname,$gpasswd,$gid,$members) = getgrnam($args{group});
	if (defined($gname)) {
		$self->{error}=10;
		$self->{errorString}='The group "'.$args{group}.'" already exists';
		warn('Plugtools addUser:10: '.$self->{errorString});
		return undef;
	}

	#if we don't have a GID, find the first free one
	if (!defined($args{gid})) {
		my $gidhelper=Sys::Group::GIDhelper->new({min=>$self->{ini}->{''}->{GIDstart}});
		my $gid=$gidhelper->firstfree();
		if (!defined($gid)) {
			$self->{error}=4;
			$self->{errorString}='Could not locate a free GID';
			warn('Plugtools addUser:4: '.$self->{errorString});
			return undef;
		}
		$args{gid}=$gid;
	}

	($gname,$gpasswd,$gid,$members) = getgrnam($args{gid});
	if (defined($gid)) {
		$self->{error}=20;
		$self->{errorString}='The GID "'.$args{gid}.'" already exists.';
		warn('Plugtools addGroup:20: '.$self->{error});
		return undef;
	}

	#make sure the GID is complete numeric
	if (!($args{gid}=~/^[0123456789]*$/)) {
		$self->{error}=8;
		$self->{errorString}='The specified GID, "'.$args{gid}.'", is not numeric';
		warn('Plugtools addUser:8: '.$self->{errorString});
		return undef;
	}

	#initiates the Net::LDAP::posixAccount
	my $entrycreator=Net::LDAP::posixGroup->new({ baseDN=>$self->{ini}->{''}->{groupbase} });
	if ((!defined($entrycreator))||(defined($entrycreator->{error}))) {
		$self->{error}=12;
		if(!defined($entrycreator)){
			$self->{errorString}='Net::LDAP::posixGroup->create returned a undefined object';
		}else {
			$self->{errorString}='Net::LDAP::posixGroup->create errored. error="'.
			                     $entrycreator->{error}.'" errorString="'.
								 $entrycreator->{errorString}.'"';
		}
		warn('Plugtools addGroup:12: '.$self->{errorString});
		return undef;
	}
	my $entry=$entrycreator->create({
									 name=>$args{group},
									 gid=>$args{gid},
									 primary=>$self->{ini}->{''}->{groupPrimary},
									 });
	if (defined($entrycreator->{error})) {
		$self->{error}=12;
		$self->{errorString}='Net::LDAP::posixGroup->create errored. error="'.
		                      $entrycreator->{error}.'" errorString="'.
							  $entrycreator->{errorString}.'"';
		warn('Plugtools addGroup:12: '.$self->{errorString});
		return undef;
	}

	#dump it if asked
	if ($args{dump}) {
		$entry->dump;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools addGroup: Failed to connect to LDAP');
		return undef;
	}

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginAddGroup})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginAddGroup',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools addGroup: plugin errored');
			return undef;
		}
	}

	#add it
	my $mesg=$entry->update($ldap);
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=19;
		$self->{errorString}='$entry->update($ldap) failed. $mesg->{errorMessage}="'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools addGroup:19: '.$self->{errorString});
		return undef;
	}
	
	return 1;
}

=head2 addUser

=head3 args hash

=head4 user

The user to create.

=head4 uid

The numeric user ID for the new user. If this is note defined,
the first free one will be used.

=head4 group

The primary group of user. If this is not defined, the username is
used. If the user is this is not defined, it will be set to the same
as the user.

=head4 gid

If this is defined, the specified GID will be used instead of automatically
assigning one.

=head4 gecos

The gecos field for the user. If this is not defined, it is set to
the user name.

=head4 shell

This is the shell for the user. If this is not defined, the default
one is used.

=head4 home

This is the home directory for the user. If this is not defined, the
home prototype is used.

=head4 createHome

If this is specified, the default value for createHome will be overrode the
defaults or what is specified in the config.

If it exists, it assumes it does not need to be created, but it will still be
chowned.

=head4 skel

Use this instead of the default skeleton or the one specified in the config file.

This is skipped, if the home already exists.

=head4 chmodValue

Overrides the default value for this or the one specified in the config.

=head4 chmodHome

Overrides the default value for this or the one specified in the config.

=head4 chownHome

If home should be chowned. This overrides the value specified in the
config or the default one.

=head4 dump

If this is true, call the dump method on the create Net::LDAP::Entry object.

    #the most basic form
    $pt->addUser({
                  user=>'someUser',
                  })
    if($pt->{errpr}){
        print "Error!\n";
    }

    #do more
    $pt->addUser({
                  user=>'someUser',
                  uid=>'3333',
                  group=>'someGroup',
                  gid=>'4444',
                  dump=>'1',
                   })
    if($pt->{errpr}){
        print "Error!\n";
    }

=cut

sub addUser{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if no user has been specified
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools addUser:5: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($args{user});
	if (defined($name)) {
		$self->{error}=9;
		$self->{errorString}='The user "'.$args{user}.'" already exists';
		warn('Plugtools addUser:9: '.$self->{errorString});
		return undef;
	}

	#make sure we have gecos
	if (!defined($args{gecos})) {
		$args{gecos}=$args{user};
	}

	#make sure we have a shell
	if (!defined($args{shell})) {
		$args{shell}=$self->{ini}->{''}->{defaultShell};
	}

	#make sure we have a group name
	if (!defined($args{group})) {
		$args{group}=$args{user};
	}

	#makes sure the UID is defined
	if (!defined($args{uid})) {
		#gets it if it not defined
		my $uidhelper=Sys::User::UIDhelper->new({
												 min=>$self->{ini}->{''}->{UIDstart}
												 });
		my $uid=$uidhelper->firstfree();
		if (!defined($uid)) {
			$self->{error}=3;
			$self->{errorString}='Could not locate a free UID';
			warn('Plugtools addUser:3: '.$self->{errorString});
			return undef;
		}
		$args{uid}=$uid;
	}

	#make sure the UID is complete numeric
	if (!($args{uid}=~/^[0123456789]*$/)) {
		$self->{error}=7;
		$self->{errorString}='The specified UID, "'.$args{uid}.'", is not numeric';
		warn('Plugtools addUser:7: '.$self->{errorString});
		return undef;
	}

	#check if the group exists or not
	my ($gname,$gpasswd,$ggid,$members) = getgrnam($args{group});
	if (!defined($gname)) {
		$self->addGroup({
						 group=>$args{group},
						 gid=>$args{gid},
						 dump=>$args{dump},
						 });
		if ($self->{error}) {
			warn('Plugtools addUser: addGroup failed');
			return undef;
		}
	}

	#gets the GID
	($gname,$gpasswd,$args{gid},$members) = getgrnam($args{group});

	#build the user
	$args{home}=$self->{ini}->{''}->{HOMEproto};
	$args{home}=~s/\%\%USERNAME\%\%/$args{user}/g;

	#initiates the Net::LDAP::posixAccount
	my $entrycreator=Net::LDAP::posixAccount->new({ baseDN=>$self->{ini}->{''}->{userbase} });
	my $entry=$entrycreator->create({
									 name=>$args{user},
									 uid=>$args{uid},
									 gid=>$args{gid},
									 home=>$args{home},
									 loginShell=>$args{shell},
									 primary=>$self->{ini}->{''}->{userPrimary},
									 });

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools addUser: Failed to connect to LDAP');
		return undef;
	}

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginAddUser})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginAddUser',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools addUser: plugin errored');
			return undef;
		}
	}

	#add it
	my $mesg=$entry->update($ldap);
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=19;
		$self->{errorString}='$entry->update($ldap) failed. $mesg->{errorMessage}="'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools addUser:19: '.$self->{errorString});
		return undef;
	}

	#dump it if needed
	if ($args{dump}) {
		$entry->dump;
	}

	#create the home directory if needed, after getting the required values
	if (!defined($args{createHome})) {
		$args{createHome}=$self->{ini}->{''}->{createHome};
	}
	if (!defined($args{skel})) {
		$args{skel}=$self->{ini}->{''}->{skeletonHome};
	}
	if (!defined($args{chownHome})) {
		$args{chownHome}=$self->{ini}->{''}->{chownHome};
	}
	if (!defined($args{chmodHome})) {
		$args{chmodHome}=$self->{ini}->{''}->{chmodHome};
	}
	if (!defined($args{chmodValue})) {
		$args{chmodValue}=$self->{ini}->{''}->{chmodValue};
	}
	if ($args{createHome}) {
		if (! -e $args{home}) {
			#copy it
			system( 'cp -r '.shell_quote($args{skel}).' '.shell_quote($args{home}) );
			if ($? ne '0') {
				$self->{error}=22;
				$self->{errorString}='Copying home from "'.$args{skel}.'" to "'.$args{home}.'" failed';
				warn('Plugtools addUser:22: '.$self->{errorString});
				return undef;
			}

			#chown it if needed
			if ($args{chownHome}) {
				system( 'chown -R '.shell_quote($args{user}).':'.shell_quote($args{group})
						.' '.shell_quote($args{home}) );
				if ($? ne '0') {
					$self->{error}=23;
					$self->{errorString}='Chowning "'.$args{home}.'" to "'.$args{chmodValue}.'" failed';
					warn('Plugtools addUser:22: '.$self->{errorString});
					return undef;
				}
			}

			#chmod it if needed
			if ($args{chmodHome}) {
				system( 'chmod -R '.shell_quote($args{chmodValue}).' '.shell_quote($args{home}) );
				if ($? ne '0') {
					$self->{error}=24;
					$self->{errorString}='Chmoding "'.$args{home}.'" to "'.$args{chmodValue}.'" failed';
					warn('Plugtools addUser:22: '.$self->{errorString});
					return undef;
				}
			}
		}
	}

	

	return 1;
}

=head2 connect

This forms a LDAP connection using the information in
config file.

    my $ldap=$pt->connect;
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub connect{
	my $self=$_[0];

	#blanks any previous errors
	$self->errorblank;

	#try to connect
	my $ldap = Net::LDAP->new($self->{ini}->{''}->{server}, port=>$self->{ini}->{''}->{port});

	#check if it connected or not
	if (!$ldap) {
		$self->{error}=11;
		$self->{errorString}='Failed to connect to LDAP';
		warn('Plugtools connect:11: '.$self->{errorString});
		return undef;
	}

	#start TLS if it is needed
	my $mesg;
	if ($self->{ini}->{''}->{starttls}) {
		$mesg=$ldap->start_tls(
							   verify=>$self->{ini}->{''}->{TLSverify},
							   sslversion=>$self->{ini}->{''}->{SSLversion},
							   ciphers=>$self->{ini}->{''}->{SSLciphers},
							   );

		if (!$mesg->{errorMessage} eq '') {
			$self->{error}=13;
			$self->{errorString}='$ldap->start_tls failed. $mesg->{errorMessage}="'.
			                     $mesg->{errorMessage}.'"';
			warn('Plugtools connect:13: '.$self->{errorString});
			return undef;
		}
	}

	#bind
	$mesg=$ldap->bind($self->{ini}->{''}->{bind},
					  password=>$self->{ini}->{''}->{pass},
					  );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=13;
		$self->{errorString}='Binding to the LDAP server failed. $mesg->{errorMessage}="'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools connect:13: '.$self->{errorString});
		return undef;
	}

	return $ldap;
}

=head2 deleteGroup

This removes a group.

    $pt->deleteGroup('someGroup');
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub deleteGroup{
	my $self=$_[0];
	my $group=$_[1];

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($group)) {
		$self->{error}=6;
		$self->{errorString}='No group name specified';
		warn('Plugtools deleteGroup:6: '.$self->{errorString});
		return undef;
	}

	#error if the user does not exists
	my ($gname,$gpasswd,$gid,$members) = getgrnam($group);
	if (!defined($gname)) {
		$self->{error}=10;
		$self->{errorString}='The group "'.$group.'" does not exist';
		warn('Plugtools deleteGroup:10: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools deleteGroup: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{groupbase},
						   filter=>'(&(cn='.$group.') (gidNumber='.$gid.'))'
						   );
	my $entry=$mesg->pop_entry;

	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=15;
		$self->{errorString}='The group "'.$group.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{groupbase}.'", ';
		warn('Plugtools findGroupDN:15: '.$self->{errorString});
		return undef;
	}

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginDeleteGroup})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginDeleteGroup',
					   },
					  {
					   group=>$group,
					   });
		if ($self->{error}) {
			warn('Plugtools deleteGroup: plugin errored');
			return undef;
		}
	}

	#delete the entry
	$entry->delete();
	$mesg=$entry->update($ldap);
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=13;
		$self->{errorString}='Deleting entry "'.$entry->dn.'" failed. $mesg->{errorMessage}="'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools connect:13: '.$self->{errorString});
		return undef;
	}
	
	return 1;
}

=head2 deleteUser

This removes a user.

Only LDAP is touched at this time, so if a user is a member of a group
setup in '/etc/groups', then it won't be removed from that group.

This does not remove the user's old home directory.

=head3 arge hash

'user' is the only required value.

=head4 user

This is the user to be removed.

=head4 removeHome

This removes the home directory of the user.

=head4 removeGroup

Remove the primary group if it is empty.

    #the most basic form
    $pt->deleteUser({
                  user=>'someUser',
                  })
    if($pt->{errpr}){
        print "Error!\n";
    }

    #do more
    $pt->deleteUser({
                     user=>'someUser',
                     removeHome=>'1',
                     removeGroup=>'0',
                     })
    if($pt->{errpr}){
        print "Error!\n";
    }

=cut

sub deleteUser{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#make sure a group if specifed
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools deleteUser:5: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($args{user});
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$args{user}.'" does not exists';
		warn('Plugtools deleteUser:17: '.$self->{errorString});
		return undef;
	}

	#check if the group exists or not
	my ($gname,$gpasswd,$ggid,$members) = getgrgid($gid);
	my $removeGroup=0;
	#set the group to be removed if it exists
	if (defined($ggid)) {
		$removeGroup=1;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools deleteUser: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$args{user}.') (uidNumber='.$uid.'))'
						   );
	my $entry=$mesg->pop_entry;

	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=18;
		$self->{errorString}='The user "'.$args{user}.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{userbase}.'", ';
		warn('Plugtools deleteUser:18: '.$self->{errorString});
		return undef;
	}

	#we check this here as checking it after wards after deleting the user does not work
	my $onlyMember;
	if (!defined($args{removeGroup})) {
		$args{removeGroup}=$self->{ini}->{''}->{removeGroup};
	}
	if ($args{removeGroup}) {
		#check if it the only member of that group
		$onlyMember=$self->onlyMember({
										  user=>$args{user},
										  group=>$gname,
										  });
		if ($self->{error}) {
			warn('Plugtools deleteUser: onlyMember errored');
			return undef;
		}
	}

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginDeleteUser})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginDeleteUser',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools deleteUser: plugin errored');
			return undef;
		}
	}


	#delete the entry
	$entry->delete();
	$mesg=$entry->update($ldap);
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=13;
		$self->{errorString}='Deleting entry "'.$entry->dn.'" failed. $mesg->{errorMessage}="'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools deleteUser:13: '.$self->{errorString});
		return undef;
	}

	#remove the primary group if requested...
	if ($args{removeGroup}) {
		#proceede further if it is the only member
		if ($onlyMember) {
			#figure out if it is a LDAP group or not
			my $returned=$self->isLDAPgroup($gname);
			if ($self->{error}) {
				warn('Plugtools deleteUser: isLDAPgroup errored');
				return undef;
			}
			#if it is a LDAP group, remove it
			if ($returned) {
				$self->deleteGroup($gname);
				if ($self->{error}) {
					warn('Plugtools deleteUser: deleteGroup failed');
					return undef;
				}
			}
		}
	}

	#remove the user from what ever groups they are in, in LDAP
	$self->removeUserFromGroups($args{user});
	if ($self->{error}) {
		warn('Plugtools deleteUser: removeUserFromGroups failed');
		return undef;
	}

	#remove the primary group if requested...
	if (!defined($args{removeHome})) {
		$args{removeHome}=$self->{ini}->{''}->{removeHome};
	}
	if ($args{removeHome}) {
		system( 'rm -rf '.shell_quote($dir) );
		if ($? ne '0') {
			$self->{error}=26;
			$self->{errorString}='rm -rf '.shell_quote($dir).' has failed failed';
			warn('Plugtools deleteUser:26: '.$self->{errorString});
			return undef;
		}
	}
	
	return 1;
}

=head2 findGroupDN

This locates a DN for a already setup group.

    my $dn=$pt->findGroupDN('someGroup');
    if($pt->{error}){
        print "Error!";
    }

=cut

sub findGroupDN{
	my $self=$_[0];
	my $group=$_[1];

	#blank any previous errors
	$self->errorblank;

	#make sure a group if specifed
	if (!defined($group)) {
		$self->{error}=6;
		$self->{errorString}='No group name specified';
		warn('Plugtools findGroupDN:6: '.$self->{errorString});
		return undef;
	}

	#error if the user does not exists
	my ($gname,$gpasswd,$gid,$members) = getgrnam($group);
	if (!defined($gname)) {
		$self->{error}=14;
		$self->{errorString}='The group "'.$group.'" does not exist';
		warn('Plugtools findGroupDN:14: '.$self->{errorString});
		return undef;
	}
	
	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools findGroupDN: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{groupbase},
						   filter=>'(&(cn='.$group.') (gidNumber='.$gid.'))'
						   );
	my $entry=$mesg->pop_entry;

	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=15;
		$self->{errorString}='The group "'.$group.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{groupbase}.'", ';
		warn('Plugtools findGroupDN:15: '.$self->{errorString});
		return undef;
	}
	
	#if we get here, it means we have a entry... thus we have a DN
	return $entry->dn;
}

=head2 findUserDN

This locates a DN for a already setup group.

    my $dn=$pt->findUserDN('someUser');
    if($pt->{error}){
        print "Error!";
    }

=cut

sub findUserDN{
	my $self=$_[0];
	my $user=$_[1];

	#blank any previous errors
	$self->errorblank;

	#make sure a group if specifed
	if (!defined($user)) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools findUserDN:5: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($user);
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$user.'" does not exists';
		warn('Plugtools findUserDN:17: '.$self->{errorString});
		return undef;
	}
	
	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools findUserDN: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$user.') (uidNumber='.$uid.'))'
						   );
	my $entry=$mesg->pop_entry;

	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=18;
		$self->{errorString}='The user "'.$user.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{userbase}.'", ';
		warn('Plugtools findUserDN:18: '.$self->{errorString});
		return undef;
	}
	
	#if we get here, it means we have a entry... thus we have a DN
	return $entry->dn;
}

=head2 getUserEntry

Fetch a Net::LDAP::Entry object of a user.

=head3 args hash

=head4 user

This is the user to fetch a Net::LDAP::Entry
of.

    my $entry=$pt->getUserEntry({
                                 user=>'someUser',
                                 });
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub getUserEntry{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};


	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools getUserEntry:5: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gecos,$dir,$shell,$expire) = getpwnam($args{user});
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$args{user}.'" does not exists';
		warn('Plugtools getUserEntry:17: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools getUserEntry: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$args{user}.') (uidNumber='.$uid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=32;
		$self->{errorString}='Fetching the entry for the user failed under "'.
		                     $self->{ini}->{''}->{userbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools userGIDchange:32: '.$self->{errorString});
		return undef;
	}
	my $entry=$mesg->pop_entry;

	if (!defined($entry)) {
		$self->{error}=18;
		$self->{errorString}='The user "'.$args{user}.'" was not found under'.
		                     'the base "'.$self->{ini}->{''}->{userbase}.'"';
		warn('Plugtools getUserEntry:18: '.$self->{errorString});
		return undef;
	}

	return $entry;
}

=head2 groupAddUser

This adds a user from a group.

=head3 args hash

=head4 group

The group to act on.

=head4 user

The user to act remove from the group.

=head4 dump

Call the dump method on the entry afterwards.

    $pt->groupAddUser({
                       group=>'someGroup',
                       user=>'someUser',
                       })
    if($pt->{errpr}){
        print "Error!\n";
    }

=cut

sub groupAddUser{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{group})) {
		$self->{error}=6;
		$self->{errorString}='No group name specified';
		warn('Plugtools groupAddUser:6: '.$self->{errorString});
		return undef;
	}

	#error if no user has been specified
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools groupAddUser:5: '.$self->{errorString});
		return undef;
	}

	#error if the user does not exists
	my ($gname,$gpasswd,$gid,$members) = getgrnam($args{group});
	if (!defined($gname)) {
		$self->{error}=14;
		$self->{errorString}='The group "'.$args{group}.'" does not exist';
		warn('Plugtools groupAddUser:14: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools groupAddUser: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{groupbase},
						   filter=>'(&(cn='.$args{group}.') (gidNumber='.$gid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=27;
		$self->{errorString}='Fetching a list of posixGroup objects under "'.
		                     $self->{ini}->{''}->{groupbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools groupAddUser:27: '.$self->{errorString});
		return undef;
	}
	my $entry=$mesg->pop_entry;
	
	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=15;
		$self->{errorString}='The group "'.$args{group}.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{groupbase}.'", ';
		warn('Plugtools groupAddUser:15: '.$self->{errorString});
		return undef;
	}

	$entry->add(memberUid=>$args{user});

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginGroupAddUser})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginGroupAddUser',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools groupAddUser: plugin errored');
			return undef;
		}
	}

	#update the entry
	my $mesg2=$entry->update($ldap);
	if (!$mesg2->{errorMessage} eq '') {
		$self->{error}=13;
		$self->{errorString}='Adding the user, "'.$args{user}.'", to  "'.$entry->dn.'" failed. $mesg2->{errorMessage}="'.
		                     $mesg2->{errorMessage}.'"';
		warn('Plugtools groupAddUser:13: '.$self->{errorString});
		return undef;
	}

	#dump the entry if asked
	if ($args{dump}) {
		$entry->dump;
	}

	return 1;
}

=head2 groupGIDchange

This changes the GID for a group.

=head3 args hash

=head4 group

The group to act on.

=head4 gid

The GID to change this group to.

=head4 userUpdate

Update any user that has the old GID as their primary GID. This defaults to
true, '1'.

=head4 dump

Call the dump method on the group afterwards.

    $pt->groupGIDchange({
                         group=>'someGroup',
                         gid=>'2222',
                         })
    if($pt->{errpr}){
        print "Error!\n";
    }


=cut

sub groupGIDchange {
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{group})) {
		$self->{error}=6;
		$self->{errorString}='No group name specified';
		warn('Plugtools groupGIDchange:6: '.$self->{errorString});
		return undef;
	}

	#error if no user has been specified
	if (!defined($args{gid})){
		$self->{error}=28;
		$self->{errorString}='No GID specified';
		warn('Plugtools groupGIDchange:28: '.$self->{errorString});
		return undef;
	}

	#make sure the GID is complete numeric
	if (!($args{gid}=~/^[0123456789]*$/)) {
		$self->{error}=8;
		$self->{errorString}='The specified GID, "'.$args{gid}.'", is not numeric';
		warn('Plugtools groupGIDchange:8: '.$self->{errorString});
		return undef;
	}

	#error if the user does not exists
	my ($gname,$gpasswd,$gid,$members) = getgrnam($args{group});
	if (!defined($gname)) {
		$self->{error}=14;
		$self->{errorString}='The group "'.$args{group}.'" does not exist';
		warn('Plugtools groupGIDchange:14: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools groupGIDchange: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{groupbase},
						   filter=>'(&(cn='.$args{group}.') (gidNumber='.$gid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=27;
		$self->{errorString}='Fetching a list of posixGroup objects under "'.
		                     $self->{ini}->{''}->{groupbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools groupGIDchange:27: '.$self->{errorString});
		return undef;
	}
	my $entry=$mesg->pop_entry;
	
	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=15;
		$self->{errorString}='The group "'.$args{group}.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{groupbase}.'", ';
		warn('Plugtools groupGIDchange:15: '.$self->{errorString});
		return undef;
	}

	$entry->delete(gidNumber=>$gid);
	$entry->add(gidNumber=>$args{gid});

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginGroupGIDchange})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginGroupGIDchange',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools groupGIDchange: plugin errored');
			return undef;
		}
	}

	#update the entry
	my $mesg2=$entry->update($ldap);
	if (!$mesg2->{errorMessage} eq '') {
		$self->{error}=29;
		$self->{errorString}='Updating the GID from "'.$gid.'" to "'.$args{gid}.
		                     '" for "'.$entry->dn.'" failed. $mesg2->{errorMEssage}="'.
		                     $mesg2->{errorMessage}.'"';
		warn('Plugtools groupGIDchange:29: '.$self->{errorString});
		return undef;
	}

	#dump the entry if asked
	if ($args{dump}) {
		$entry->dump;
	}

	#return successfully now if don't have to update any possible users
	if (!defined($args{userUpdate})) {
		$args{userUpdate}=$self->{ini}->{''}->{userUpdate};
	}
	if (!$args{userUpdate}) {
		return 1;
	}

	#we now do another search for the purpose of updating any users with the old GID
	my $mesg3=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(objectClass=posixAccount) (gidNumber='.$gid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=37;
		$self->{errorString}='The search for posixAccounts entries that need updating failed. base="'.
		                     $self->{ini}->{''}->{userbase}.'" $mesg3->{errorMessage}="'.
		                     $mesg3->{errorMessage}.'"';
		warn('Plugtools groupGIDchange:37: '.$self->{errorString});
		return undef;
	}
	$entry=$mesg3->pop_entry;

	#if no entries are found, nothing needs updated
	if (!defined($entry)) {
		return 1;
	}

	#go through each one and update it
	my $loop=1;
	while ($loop) {
		$entry->delete('gidNumber'=>$gid);
		$entry->add(gidNumber=>$args{gid});

		#update the entry
		my $mesg4=$entry->update($ldap);
		if (!$mesg2->{errorMessage} eq '') {
			$self->{error}=29;
			$self->{errorString}='Changing the GID to "'.$args{gid}.'" from "'.$gid
			                     .'" for  "'.$entry->dn.'" failed. $mesg4->{errorMessage}="'.
								 $mesg4->{errorMessage}.'"';
			warn('Plugtools groupGIDchange:29: '.$self->{errorString});
			return undef;
		}		

		#dump the entry if asked
		if ($args{dump}) {
			$entry->dump;
		}
		
		#get the next entry and decide it it should continue or not
		$entry=$mesg3->pop_entry;
		if (!defined($entry)) {
			$loop=0;
		}
	}
	


	return 1;
}

=head2 groupRemoveUser

This removes a user from a group.

=head3 args hash

=head4 group

The group to act on.

=head4 user

The user to act remove from the group.

=head4 dump

Call the dump method on the group afterwards.

    $pt->groupRemoveUser({
                       group=>'someGroup',
                       user=>'someUser',
                       })
    if($pt->{errpr}){
        print "Error!\n";
    }

=cut

sub groupRemoveUser{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{group})) {
		$self->{error}=6;
		$self->{errorString}='No group name specified';
		warn('Plugtools groupRemoveUser:6: '.$self->{errorString});
		return undef;
	}

	#error if no user has been specified
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools groupRemoveUser:5: '.$self->{errorString});
		return undef;
	}

	#error if the user does not exists
	my ($gname,$gpasswd,$gid,$members) = getgrnam($args{group});
	if (!defined($gname)) {
		$self->{error}=14;
		$self->{errorString}='The group "'.$args{group}.'" does not exist';
		warn('Plugtools groupRemoveUser:14: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools groupRemoveUser: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{groupbase},
						   filter=>'(&(cn='.$args{group}.') (gidNumber='.$gid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=27;
		$self->{errorString}='Fetching a list of posixGroup objects under "'.
		                     $self->{ini}->{''}->{groupbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools groupRemoveUser:27: '.$self->{errorString});
		return undef;
	}
	my $entry=$mesg->pop_entry;
	
	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=15;
		$self->{errorString}='The group "'.$args{group}.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{groupbase}.'", ';
		warn('Plugtools groupRemoveUser:15: '.$self->{errorString});
		return undef;
	}

	$entry->delete(memberUid=>$args{user});

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginGroupRemoveUser})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginGroupRemoveUser',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools groupRemoveUser: plugin errored');
			return undef;
		}
	}

	#update the entry
	my $mesg2=$entry->update($ldap);
	if (!$mesg2->{errorMessage} eq '') {
		$self->{error}=13;
		$self->{errorString}='Removing the user, "'.$args{user}.'", from  "'.$entry->dn.'" failed. $mesg2->{errorMessage}="'.
		                     $mesg2->{errorMessage}.'"';
		warn('Plugtools deleteUser:13: '.$self->{errorString});
		return undef;
	}

	#dump the entry if asked
	if ($args{dump}) {
		$entry->dump;
	}

	return 1;
}

=head2 groupClean

This checks through the groups setup in LDAP and removes any group that does not exist.

=head3 args hash

=head4 dump

If this is specified, the dump method is called on any updated entry. If this is not
defined, it defaults to false.

    $pt->groupClean;
    if($pt->{error}){
        print "Error!\n";
    }

    #do the same thing as above, but do $entry->dump for any changed entry
    $pt->groupClean({dump=>'1'});
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub groupClean{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools groupClean: Failed to connect to LDAP');
		return undef;
	}	

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{groupbase},
						   filter=>'(objectClass=posixGroup)',
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=27;
		$self->{errorString}='Fetching a list of posixGroup objects under "'.
		                     $self->{ini}->{''}->{groupbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools groupClean:27: '.$self->{errorString});
		return undef;
	}

	#get the first entry
	my $entry=$mesg->pop_entry;
	
	#if the entry is not defined, there are no groups
	if (!defined($entry)) {
		return 1;
	}

	#process each one
	my $loop=1;
	while ($loop) {
		my @members=$entry->get_value('memberUid');
		#if there is no $members[0], it means the group
		#has no members listed
		if (defined($members[0])) {
			my $int=0;
			my $changed=0;#records if any changes have happened or not
			while (defined($members[$int])) {
				my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($members[$int]);	
				#if it is not defined, it means the user does not exist
				if (!defined($name)) {
					$entry->delete('memberUid'=>$members[$int]);
					$changed=1;
				}

				$int++;
			}

			#if it changed, update it
			if ($changed) {
				my $mesg2=$entry->update($ldap);
				if (!$mesg->{errorMessage} eq '') {
					$self->{error}=28;
					$self->{errorString}='Failed to update the entry, "'.$entry->dn.'". $mesg2->{errorMessage}="'.
				                          $mesg2->{errorMessage}.'"';
					warn('Plugtools groupClean:27: '.$self->{errorString});
					return undef;
				}
				if ($args{dump}) {
					$entry->dump;
				}
			}
		}

		#get the next entry
		$entry=$mesg->pop_entry;
		#exit this loop if it is not defined... meaning we reached the end
		if (!defined($entry)) {
			$loop=0;
		}
	}

	return 1;
}

=head2 isLDAPgroup

This tests if a group is in LDAP or not.

    my $returned=$pt->isLDAPgroup('someGroup');
    if($pt->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "Yes!\n";
        }else{
            print "No!\n";
        }
    }

=cut

sub isLDAPgroup{
	my $self=$_[0];
	my $group=$_[1];

	#blank any previous errors
	$self->errorblank;

	#make sure a group if specifed
	if (!defined($group)) {
		$self->{error}=6;
		$self->{errorString}='No group name specified';
		warn('Plugtools isLDAPgroup:6: '.$self->{errorString});
		return undef;
	}

	#error if the user does not exists
	my ($gname,$gpasswd,$gid,$members) = getgrnam($group);
	if (!defined($gname)) {
		$self->{error}=10;
		$self->{errorString}='The group "'.$group.'" does not exist';
		warn('Plugtools isLDAPgroup:10: '.$self->{errorString});
		return undef;
	}
	
	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools isLDAPgroup: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{groupbase},
						   filter=>'(&(cn='.$group.') (gidNumber='.$gid.'))'
						   );
	my $entry=$mesg->pop_entry;

	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		return undef;
	}
	
	return 1;
}

=head2 isLDAPuser

This tests if a group is in LDAP or not.

    my $returned=$pt->isLDAPuser('someUser');
    if($pt->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "Yes!\n";
        }else{
            print "No!\n";
        }
    }

=cut

sub isLDAPuser{
	my $self=$_[0];
	my $user=$_[1];

	#blank any previous errors
	$self->errorblank;

	#make sure a group if specifed
	if (!defined($user)) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools isLDAPuser:5: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($user);
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$user.'" does not exists';
		warn('Plugtools isLDAPuser:17: '.$self->{errorString});
		return undef;
	}
	
	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools isLDAPuser: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$user.') (uidNumber='.$uid.'))'
						   );
	my $entry=$mesg->pop_entry;

	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		return undef;
	}

	return 1;
}

=head2 onlyMember

This figures out if a user is the only member of a group.

This returns true if the user is the only member of that group. A value
of false means that user is not in that group and there are no members or
that it that there are other members.

=head3 args hash

Both 'user' and 'group' are required.

=head4 user

This is the user it is checking to see if it is the only member of a
group.

=head4 group

This is the group to check.

    my $returned=$pt->onlyMember({
                       user=>'someUser',
                       group=>'someGroup',
                       });
    if($pt->{error}){
        print "Error!\n";
    }


=cut

sub onlyMember{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error is no group is specified
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified.';
		warn('Plugtools onlyMember:5: '.$self->{errorString});
		return undef;
	}


	#error is no group is specified
	if (!defined($args{group})) {
		$self->{error}=6;
		$self->{errorString}='No group name specified.';
		warn('Plugtools onlyMember:6: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($gname,$gpasswd,$ggid,$members) = getgrnam($args{group});
	if (!defined($gname)) {
		$self->{error}=14;
		$self->{errorString}='The group "'.$args{group}.'" does not exist';
		warn('Plugtools onlyMember:14: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($args{user});
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$args{user}.'" does not exists';
		warn('Plugtools onlyMember:17: '.$self->{errorString});
		return undef;
	}

	#break the list of members apart
	my @membersA=split(/,/, $members);

	#handle it if there are no group members
	if (!defined($membersA[0])) {
		#if the group's GID and the user's primary GID are the same
		#here then it means the user is not explicityly as a member of that group
		if ($ggid eq $gid) {
			return 1;
		}

		#if we get here, the group has no explicityly listed members
		#and the user is not a member of the group
		return undef;
	}
	
	#check each member to see if it is not the user in question
	#while this may seem stupid, there is a possibiltiy that the user
	#has been listed in a group more than once...
	my $int=0;
	while (defined($membersA[$int])) {
		if ($membersA[$int] ne $args{user}) {
			return undef;
		}

		$int++;
	}

	return 1;
}

=head2 plugin

This processes series plugins.

=head3 opts hash

This is the first required hash.

=head4 ldap

This is the current LDAP connect.

=head4 do

This contains the variable it should reference for what plugins to run.

=head4 entry

This is the LDAP entry to work on.

=head3 args hash

This is the hash that was passed to the function calling the plugin.

=cut

sub plugin{
	my $self=$_[0];
	my $opts;
	my %opts;
	if(defined($_[1])){
		%opts= %{$_[1]};
	};
	my %args;
	if(defined($_[2])){
		%args= %{$_[2]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if no LDAP connection is present
	if (!defined($opts{ldap})) {
		$self->{error}=38;
		$self->{errorString}='No LDAP connection passed';
		warn('Plugtools plugin:38: '.$self->{errorString});
		return undef;
	}

	#error if no LDAP connection is present
	if (!defined($opts{do})) {
		$self->{error}=39;
		$self->{errorString}='What selection of plugins to process has not been specified. $opts{do} is undefined';
		warn('Plugtools plugin:39: '.$self->{errorString});
		return undef;
	}

	#error if no LDAP connection is present
	if (!defined($opts{entry})) {
		$self->{error}=42;
		$self->{errorString}='No Net::LDAP::Entry passed. $opts{entry} is undefined';
		warn('Plugtools plugin:42: '.$self->{errorString});
		return undef;
	}

	#error if the LDAP entry that is specified is not a Net::LDAP::Entry object
	if (ref($opts{entry}) ne 'Net::LDAP::Entry') {
		$self->{error}=43;
		$self->{errorString}='$opts{entry} is not a Net::LDAP::Entry object';
		warn('Plugtools plugin:43: '.$self->{errorString});
		return undef;
	}

	#error if no entry connection is present
	if (ref($opts{ldap}) ne 'Net::LDAP') {
		$self->{error}=44;
		$self->{errorString}='$opts{ldap} is not a Net::LDAP object';
		warn('Plugtools plugin:44: '.$self->{errorString});
		return undef;
	}

	#
	$opts{self}=$self;

	#make sure the specified config exists
	if (!defined( $self->{ini}->{''}->{$opts{do}} )) {
		$self->{error}=40;
		$self->{errorString}='The variable "'.$opts{do}.'" does not exist in the config';
		warn('Plugtools plugin:40: '.$self->{errorString});
		return undef;
	}

	#split the plugin apart
	my @plugins=split(/,/ , $self->{ini}->{''}->{$opts{do}});

	#process each one
	my $int=0;
	while (defined($plugins[$int])) {
		my %returned;
		my $run='use '.$plugins[$int].';'."\n".
		        'my %returned='.$plugins[$int].'->plugin(\%opts, \%args);';
		
		#run it
		my $ran=eval($run);
		
		#If we did not get a boolean true, then it failed
		if (!$ran) {
			$self->{error}=41;
			$self->{errorString}='Executing the plugin "'.$plugins[$int].'" failed. $run="'.$run.'"';
			warn('Plugtools plugins:41: '.$self->{errorString});
			return undef;
		}
		
		#it errored...
		if ($returned{error}) {
			$self->{error}=45;
			$self->{errorString}='The plugin returned a error. $returned{error}="'.$returned{error}.'" '.
		 	                     '$returned{errorString}="'.$returned{errorString}.'"';
			warn('Plugtools plugins:45: '.$self->{errorString});
			return undef;
		}
		
		$int++;
	}

	return 1;
}

=head2 removeUserFromGroups

This removes a user from any group in LDAP they are a member of.

No checks are made to see if the user exists or not.

    $pt->removeUserFromGroups('someUser');
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub removeUserFromGroups{
	my $self=$_[0];
	my $user=$_[1];

	#blank any previous errors
	$self->errorblank;

	#make sure a group if specifed
	if (!defined($user)) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools removeUserFromGroups:5: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools findGroupDN: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{groupbase},
						   filter=>'(&(objectClass=posixGroup) (memberUid='.$user.'))'
						   );
	my $entry=$mesg->pop_entry;

	#no groups with this user in them were found
	if (!defined($entry)) {
		return 1;
	}
	
	#exit it
	my $loop=1;
	while ($loop) {
		#remove the memberUid attribute that is equal to the user in question and update it
		$entry->delete('memberUid'=>$user);
		my $mesg2=$entry->update($ldap);
		#handles any errors
		if (!$mesg2->{errorMessage} eq '') {
			$self->{error}=25;
			$self->{errorString}='Deleting memberUid='.$user.' from the entry "'.$entry->dn.'" failed. $mesg2->{errorMessage}="'.
			                      $mesg2->{errorMessage}.'"';
			warn('Plugtools removeUserFromGroups:25: '.$self->{errorString});
			return undef;
		}
		
		#get the next entry
		$entry=$mesg->pop_entry;
		#if the next entry is not defined, there are no more so we exit the loop
		if (!defined($entry)) {
			$loop=0;
		}
	}

	return 1;
}

=head2 readConfig

This reads the specified config.

    #reads the default config
    $pt->readConfig();
    if($pt->{error}){
        print "Error!";
    }

    #reads the config '/some/config'
    $pt->readConfig('/some/config');
    if($pt->{error}){
        print "Error!";
    }

=cut

sub readConfig{
	my $self=$_[0];
	my $config=$_[1];

	#blanks any previous errors
	$self->errorblank;

	#if it is not defined, use the default one
	if (!defined($config)) {
		$config=xdg_config_home().'/plugtoolsrc';
	}

	#reads the config
	my $ini=ReadINI($config);

	#errors if it is not defined... meaning it errored
	if (!defined($ini)) {
		$self->{error}=1;
		$self->{errorString}='Failed to read the config';
		warn('Plugtools readConfig:1: '.$self->{errorString});
		return undef;
	}

	#puts together a array to check for the required ones
	my @required;
	push(@required, 'bind');
	push(@required, 'pass');
	push(@required, 'userbase');
	push(@required, 'groupbase');
	

	#make sure they are all defined
	my $int=0;
	while (defined($required[$int])) {
		#error if it is not defined
		if (!defined($ini->{''}->{$required[$int]})) {
			$self->{error}=2;
			$self->{errorString}='The required variable "'.$required[$int].'" is not defined in the config, "'.$config.'",';
			warn('Plugtools readConfig:2: '.$self->{errorString});
			return undef;
		}

		$int++;
	}

	#define the defaults if they are not defined
	if (!defined($ini->{''}->{UIDstart})) {
		$ini->{''}->{UIDstart}='1001';
	}
	if (!defined($ini->{''}->{GIDstart})) {
		$ini->{''}->{GIDstart}='1001';
	}
	if (!defined($ini->{''}->{defaultShell})) {
		$ini->{''}->{defaultShell}='/bin/tcsh';
	}
	if (!defined($ini->{''}->{HOMEproto})) {
		$ini->{''}->{HOMEproto}='/home/%%USERNAME%%/';
	}
	if (!defined($ini->{''}->{skeletonHome})) {
		$ini->{''}->{skeletonHome}='/etc/skel/';
	}
	if (!defined($ini->{''}->{chmodValue})) {
		$ini->{''}->{chmodValue}='640';
	}
	if (!defined($ini->{''}->{chmodHome})) {
		$ini->{''}->{chmodHome}='1';
	}
	if (!defined($ini->{''}->{chownHome})) {
		$ini->{''}->{chownHome}='1';
	}
	if (!defined($ini->{''}->{createHome})) {
		$ini->{''}->{createHome}='1';
	}
	if (!defined($ini->{''}->{groupPrimary})) {
		$ini->{''}->{groupPrimary}='cn';
	}
	if (!defined($ini->{''}->{userPrimary})) {
		$ini->{''}->{userPrimary}='uid';
	}
	if (!defined($ini->{''}->{server})) {
		$ini->{''}->{server}='127.0.0.1';
	}
	if (!defined($ini->{''}->{port})) {
		$ini->{''}->{port}='389';
	}
	if (!defined($ini->{''}->{TLSverify})) {
		$ini->{''}->{TLSverify}='none';
	}
	if (!defined($ini->{''}->{SSLversion})) {
		$ini->{''}->{SSLversion}='tlsv1';
	}
	if (!defined($ini->{''}->{SSLciphers})) {
		$ini->{''}->{SSLciphers}='ALL';
	}
	if (!defined($ini->{''}->{removeHome})) {
		$ini->{''}->{removeHome}='0';
	}
	if (!defined($ini->{''}->{removeGroup})) {
		$ini->{''}->{removeGroup}='1';
	}
	if (!defined($ini->{''}->{userUpdate})) {
		$ini->{''}->{userUpdate}='1';
	}

	#if we get here, the ini is good... so we save it
	$self->{ini}=$ini;

	return 1;
}

=head2 userGECOSchange

This changes the UID for a user.

=head3 args hash

=head4 user

The user to act on.

=head4 gecos

The GECOS to change this user to.

=head4 dump

Call the dump method on the group afterwards.

    $pt->userGECOSchange({
                          user=>'someUser',
                          gecos=>'whatever',
                          });
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub userGECOSchange{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools userGECOSchange:5: '.$self->{errorString});
		return undef;
	}

	#error if no user has been specified
	if (!defined($args{gecos})){
		$self->{error}=33;
		$self->{errorString}='No GECOS specified';
		warn('Plugtools userGECOSchange:33: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gecos,$dir,$shell,$expire) = getpwnam($args{user});
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$args{user}.'" does not exists';
		warn('Plugtools userGECOSchange:17: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools userGECOSchange: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$args{user}.') (uidNumber='.$uid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=32;
		$self->{errorString}='Fetching the entry for the user failed under "'.
		                     $self->{ini}->{''}->{groupbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools userGECOSchange:32: '.$self->{errorString});
		return undef;
	}
	my $entry=$mesg->pop_entry;
	
	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=18;
		$self->{errorString}='The user "'.$args{user}.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{userbase}.'", ';
		warn('Plugtools userGECOSchange:18: '.$self->{errorString});
		return undef;
	}

	$entry->delete(gecos=>$gecos);
	$entry->add(gecos=>$args{gecos});

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginUserGECOSchange})) {
		$entry=$self->plugin({
							  ldap=>$ldap,
							  entry=>$entry,
							  do=>'pluginUserGECOSchange',
							  },
							 \%args);
		if ($self->{error}) {
			warn('Plugtools userGECOSchange: plugin errored');
			return undef;
		}
	}

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginUserGECOSchange})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginUserGECOSchange',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools userGECOSchange: plugin errored');
			return undef;
		}
	}

	#update the entry
	my $mesg2=$entry->update($ldap);
	if (!$mesg2->{errorMessage} eq '') {
		$self->{error}=34;
		$self->{errorString}='Changing the GECOS to "'.$args{gecos}.'" from "'.$gecos
		                     .'" for  "'.$entry->dn.'" failed. $mesg2->{errorMessage}="'.
		                     $mesg2->{errorMessage}.'"';
		warn('Plugtools userGECOSchange:34: '.$self->{errorString});
		return undef;
	}

	#dump the entry if asked
	if ($args{dump}) {
		$entry->dump;
	}

	return 1;
}

=head2 userShellChange

This changes the UID for a user.

=head3 args hash

=head4 user

The user to act on.

=head4 shell

The shell to change this user to.

=head4 dump

Call the dump method on the group afterwards.

    $pt->userShellChange({
                          user=>'someUser',
                          shell=>'/bin/tcsh',
                          });
    if($pt->error){
        print "Error!\n";
    }

=cut

sub userShellChange{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='userShellChange';

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#error if no user has been specified
	if (!defined($args{shell})){
		$self->{error}=47;
		$self->{errorString}='No shell specified';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gecos,$dir,$shell,$expire) = getpwnam($args{user});
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$args{user}.'" does not exists';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools userGECOSchange: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$args{user}.') (uidNumber='.$uid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=32;
		$self->{errorString}='Fetching the entry for the user failed under "'.
		                     $self->{ini}->{''}->{groupbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}
	my $entry=$mesg->pop_entry;
	
	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=18;
		$self->{errorString}='The user "'.$args{user}.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{userbase}.'", ';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	$entry->delete(loginShell=>$shell);
	$entry->add(loginShell=>$args{shell});

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginUserShellChange})) {
		$entry=$self->plugin({
							  ldap=>$ldap,
							  entry=>$entry,
							  do=>'pluginUserShellChange',
							  },
							 \%args);
		if ($self->{error}) {
			warn('Plugtools userShellChange: plugin errored');
			return undef;
		}
	}

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginUserShellChange})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginUserShellChange',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools userShellChange: plugin errored');
			return undef;
		}
	}

	#update the entry
	my $mesg2=$entry->update($ldap);
	if (!$mesg2->{errorMessage} eq '') {
		$self->{error}=34;
		$self->{errorString}='Changing the Shell to "'.$args{shell}.'" from "'.$shell
		                     .'" for  "'.$entry->dn.'" failed. $mesg2->{errorMessage}="'.
		                     $mesg2->{errorMessage}.'"';
		warn($self->{module}.' '.$method.':'.$self->error.': '.$self->errorString);
		return undef;
	}

	#dump the entry if asked
	if ($args{dump}) {
		$entry->dump;
	}

	return 1;
}

=head2 userSetPass

This changes the password for a user.

=head3 args hash

=head4 user

This is the user to act on.

=head4 pass

This is the new password to set.

    $pt->userSetPass({
                      user=>'someUser',
                      pass=>'whatever',
                      });
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub userSetPass{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools userGIDchange:5: '.$self->{errorString});
		return undef;
	}

	#error if we don't have a group name
	if (!defined($args{user})) {
		$self->{error}=35;
		$self->{errorString}='No password specified.';
		warn('Plugtools userSetPass:35: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($args{user});
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$args{user}.'" does not exists';
		warn('Plugtools userSetPass:17: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools userSetPass: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$args{user}.') (uidNumber='.$uid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=32;
		$self->{errorString}='Fetching the entry for the user under "'.
		                     $self->{ini}->{''}->{userbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools userSetPass:32: '.$self->{errorString});
		return undef;
	}
	my $entry=$mesg->pop_entry;

	#get the DN of the entry we will be changing
	my $dn=$entry->dn;

	my $mesg2=$ldap->set_password(user=>$dn, newpasswd=>$args{pass});
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=36;
		$self->{errorString}='Fetching the entry for the user under "'.
		                     $self->{ini}->{''}->{userbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools userSetPass:36: '.$self->{errorString});
		return undef;
	}

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginUserSetPass})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginUserSetPass',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools userSetPass: plugin errored');
			return undef;
		}
	}else {
		return 1;
	}

	#update the entry
	my $mesg3=$entry->update($ldap);
	if (!$mesg3->{errorMessage} eq '') {
		$self->{error}=34;
		$self->{errorString}='Calling the update method on the entry, "'.$entry->dn.'", failed. $mesg3->{errorMessage}="'.
		                     $mesg3->{errorMessage}.'"';
		warn('Plugtools userSetPass:34: '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 userGIDchange

This changes the UID for a user.

=head3 args hash

=head4 user

The user to act on.

=head4 gid

The GID to change this user to. This GID must already exist.

=head4 dump

Call the dump method on the group afterwards.

    $pt->userGIDchange({
                        user=>'someUser',
                        gid=>'1234',
                        });
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub userGIDchange{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools userGIDchange:5: '.$self->{errorString});
		return undef;
	}

	#error if no user has been specified
	if (!defined($args{gid})){
		$self->{error}=28;
		$self->{errorString}='No GID specified';
		warn('Plugtools userGIDchange:30: '.$self->{errorString});
		return undef;
	}

	#make sure the GID is complete numeric
	if (!($args{gid}=~/^[0123456789]*$/)) {
		$self->{error}=8;
		$self->{errorString}='The specified GID, "'.$args{gid}.'", is not numeric';
		warn('Plugtools groupGIDchange:8: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($args{user});
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$args{user}.'" does not exists';
		warn('Plugtools userGIDchange:17: '.$self->{errorString});
		return undef;
	}

	#error if the user does not exists
	my ($gname,$gpasswd,$ggid,$members) = getgrgid($args{gid});
	if (!defined($gname)) {
		$self->{error}=14;
		$self->{errorString}='The group specified by GID "'.$args{gid}.'" does not exist';
		warn('Plugtools userGIDchange:14: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools userGIDchange: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$args{user}.') (uidNumber='.$uid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=32;
		$self->{errorString}='Fetching the entry for the user failed under "'.
		                     $self->{ini}->{''}->{userbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools userGIDchange:32: '.$self->{errorString});
		return undef;
	}
	my $entry=$mesg->pop_entry;
	
	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=18;
		$self->{errorString}='The user "'.$args{user}.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{userbase}.'", ';
		warn('Plugtools userGIDchange:18: '.$self->{errorString});
		return undef;
	}

	$entry->delete(gidNumber=>$gid);
	$entry->add(gidNumber=>$args{gid});

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginUserGIDchange})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginUserGIDchange',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools userGIDchange: plugin errored');
			return undef;
		}
	}

	#update the entry
	my $mesg2=$entry->update($ldap);
	if (!$mesg2->{errorMessage} eq '') {
		$self->{error}=29;
		$self->{errorString}='Changing the GID to "'.$args{gid}.'" from "'.$gid
		                     .'" for  "'.$entry->dn.'" failed. $mesg2->{errorMessage}="'.
		                     $mesg2->{errorMessage}.'"';
		warn('Plugtools userGIDchange:29: '.$self->{errorString});
		return undef;
	}

	#dump the entry if asked
	if ($args{dump}) {
		$entry->dump;
	}

	return 1;
}

=head2 userUIDchange

This changes the UID for a user.

=head3 args hash

=head4 user

The user to act on.

=head4 uid

The UID to change this user to.

=head4 dump

Call the dump method on the group afterwards.

    $pt->userUIDchange({
                        user=>'someUser',
                        uid=>'1234',
                        });
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub userUIDchange{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#blank any previous errors
	$self->errorblank;

	#error if we don't have a group name
	if (!defined($args{user})) {
		$self->{error}=5;
		$self->{errorString}='No user name specified';
		warn('Plugtools userUIDchange:5: '.$self->{errorString});
		return undef;
	}

	#error if no user has been specified
	if (!defined($args{uid})){
		$self->{error}=30;
		$self->{errorString}='No GID specified';
		warn('Plugtools userUIDchange:30: '.$self->{errorString});
		return undef;
	}

	#make sure the UID is complete numeric
	if (!($args{uid}=~/^[0123456789]*$/)) {
		$self->{error}=7;
		$self->{errorString}='The specified UID, "'.$args{uid}.'", is not numeric';
		warn('Plugtools userUIDchange:7: '.$self->{errorString});
		return undef;
	}

	#error if the user already exists
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($args{user});
	if (!defined($name)) {
		$self->{error}=17;
		$self->{errorString}='The user "'.$args{user}.'" does not exists';
		warn('Plugtools userUIDchange:17: '.$self->{errorString});
		return undef;
	}

	#connect to the LDAP server
	my $ldap=$self->connect();
	if ($self->{error}) {
		warn('Plugtools userUIDchange: Failed to connect to LDAP');
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{userbase},
						   filter=>'(&(uid='.$args{user}.') (uidNumber='.$uid.'))'
						   );
	if (!$mesg->{errorMessage} eq '') {
		$self->{error}=32;
		$self->{errorString}='Fetching the entry for the user under "'.
		                     $self->{ini}->{''}->{userbase}.'"'.
		                     $mesg->{errorMessage}.'"';
		warn('Plugtools userUIDchange:32: '.$self->{errorString});
		return undef;
	}
	my $entry=$mesg->pop_entry;
	
	#if $entry is not defined or does not exist under the specified base
	if (!defined($entry)) {
		$self->{error}=18;
		$self->{errorString}='The user "'.$args{user}.'" does not exist in specified group base, "'.
		                     $self->{ini}->{''}->{userbase}.'", ';
		warn('Plugtools userUIDchange:18: '.$self->{errorString});
		return undef;
	}

	$entry->delete(uidNumber=>$uid);
	$entry->add(uidNumber=>$args{uid});

	#call a plugin if needed
	if (defined($self->{ini}->{''}->{pluginUserUIDchange})) {
		$self->plugin({
					   ldap=>$ldap,
					   entry=>$entry,
					   do=>'pluginUserGIDchange',
					   },
					  \%args);
		if ($self->{error}) {
			warn('Plugtools userUIDchange: plugin errored');
			return undef;
		}
	}

	#update the entry
	my $mesg2=$entry->update($ldap);
	if (!$mesg2->{errorMessage} eq '') {
		$self->{error}=31;
		$self->{errorString}='Changing the UID to "'.$args{uid}.'" from "'.$uid
		                     .'" for  "'.$entry->dn.'" failed. $mesg2->{errorMessage}="'.
		                     $mesg2->{errorMessage}.'"';
		warn('Plugtools userUIDchange:31: '.$self->{errorString});
		return undef;
	}

	#dump the entry if asked
	if ($args{dump}) {
		$entry->dump;
	}

	return 1;
}

=head2 error

Returns the current error code and true if there is an error.

If there is no error, undef is returned.

    my $error=$foo->error;
    if($error){
        print 'error code: '.$error."\n";
    }

=cut

sub error{
    return $_[0]->{error};
}

=head2 errorblank

This is a internal function and should not be called.

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head2 errorString

Returns the error string if there is one. If there is not,
it will return ''.

    my $error=$foo->error;
    if($error){
        print 'error code:'.$error.': '.$foo->errorString."\n";
    }

=cut

sub errorString{
    return $_[0]->{errorString};
}

=head1 ERROR CODES

=head2 1

Could not read config.

=head2 2

Missing required variable.

=head2 3

Can't find a free UID.

=head2 4

Can't find a free GID.

=head2 5

No user name specified.

=head2 6

No group name specified.

=head2 7

UID is not numeric.

=head2 8

GID is not numeric.

=head2 9

User already exists.

=head2 10

Group already exists.

=head2 11

Connecting to LDAP failed.

=head2 12

Net::LDAP::posixGroup failed.

=head2 13

Failed to bind to the LDAP server.

=head2 14

The group does not exist.

=head2 15

The group does not exist in LDAP or under specified group base.

=head2 16

Failed to delete the group's entry.

=head2 17

The user does not exist.

=head2 18

The user does not exist in LDAP or under specified user base.

=head2 19

Adding the new entry failed.

=head2 20

The GID already exists.

=head2 21

Failed to create home.

=head2 22

Copying the skeleton to the home location failed.

=head2 23

Failed to chown the new home directory.

=head2 24

Failed to chmod the new home directory.

=head2 25

Failed to update a entry when removing a memberUid.

=head2 26

Failed to remove the users home directory.

=head2 27

Faild to fetch a list posixGroup objects.

=head2 28

No GID specified.

=head2 29

Failed to update the entry when changing the GID.

=head2 30

No UID specified.

=head2 31

Failed to update the entry when changing the UID.

=head2 32

Failed to fetch the user entry.

=head2 33

No GECOS specified.

=head2 34

Failed to update the entry when changing the GECOS.

=head2 35

No password specified.

=head2 36

Updating the password for the user failed.

=head2 37

Errored when fetching a list of users that may possibly need updated.

=head2 38

No LDAP object given.

=head2 39

$opts{do} has not been specified.

=head2 40

The specified selection of plugins to run does not exist.

=head2 41

Exectuting a plugin failed.

=head2 42

$opts{entry} is not defined.

=head2 43

$opts{entry} is not a Net::LDAP::Entry object.

=head2 44

$opts{ldap} is not a Net::LDAP object.

=head2 45

$returned{error} is set to true.

=head2 46

Calling the LDAP update function on the entry modified by the userSetPass
plugin failed. The unix password has been set though.

=head2 47

No shell specified.

=head1 CONFIG FILE

The default is xdg_config_home().'/plugtoolsrc', which wraps
around to "~/.config/plugtoolsrc". The file format is ini.

The only required ones are 'bind', 'pass', 'groupbase', and
'userbase'.

    bind=cn=admin,dc=foo,dc=bar
    pass=somebl00dyp@ssw0rd
    userbase=ou=users,dc=foo,dc=bar
    groupbase=ou=groups,dc=foo,dc=bar

=head2 bind

This is the DN to bind as.

=head2 pass

This is the password for the bind DN.

=head2 userbase

This is the base for where the users are located.

=head2 groupbase

This is the base where the groups are located.

=head2 server

This is the LDAP server to connect to. If the server is not
specified, '127.0.0.1' is used.

=head2 port

This is the LDAP port to use. If the port is not specified, '389'
is used.

=head2 UIDstart

This is the first UID to start checking for existing users at. The default is '1001'.

=head2 GIDstart

This is the first GID to start checking for existing groups at. The default is '1001'.

=head2 defaultShell

This is the default shell for a user. The default is '/bin/tcsh'.

=head2 HOMEproto

The prototype for the home directory. %%USERNAME%% is replaced with
the username. The default is '/home/%%USERNAME%%/'.

=head2 skeletonHome

This is the location that will be copied for when creating a new home directory. If this is not defined,
a blanked one will be created. The default is '/etc/skel'.

=head2 chmodValue

This is the numeric value the newly created home directory will be chmoded to. The default is '640'.

=head2 chmodHome

If home should be chmoded. The default value is '1', true.

=head2 chownHome

If home should be chowned. The default value is '1', true.

=head2 createHome

If this is true, it the home directory for the user will be created. The default is '1'.

=head2 groupPrimary

This is the attribute to use for when creating the DN for the group entry. Either 'cn' or
'gidNumber' are currently accepted. The default is 'cn'.

=head2 userPrimary

This is the attribute to use for when creating the DN for the user entry. Either
'cn', 'uid', or 'uidNumber' are currently accepted. The default is 'uid'.

=head2 starttls

Wether or not it should try to do start_tls.

=head2 TLSverify

The verify mode for TLS. The default is 'none'.

=head3 none

The server may provide a certificate but it will not be
checked - this may mean you are be connected to the wrong
server.

=head3 optional

Verify only when the server offers a certificate.

=head3 require

The server must provide a certificate, and it must be valid.

=head2 SSLversion

This is the SSL versions accepted.

'sslv2', 'sslv3', 'sslv2/3', or 'tlsv1' are the possible values. The default
is 'tlsv1'.

=head2 SSLciphers

This is a list of ciphers to accept. The string is in the standard OpenSSL
format. The default value is 'ALL'.

=head2 removeGroup

This determines if it should try to remove the user's primary group after removing the
user.

The default value is '1', true.

=head2 removeHome

This determines if it should try to remove a user's home directory when deleting the
user.

The default value is '0', false.

=head2 userUpdate

This determines if it should update the primary GIDs for users after groupGIDchange
has been called.

The default value is '1', true.

=head2 pluginAddGroup

A comma seperated list of plugins to run when addGroup is called.

=head2 pluginAddUser

A comma seperated list of plugins to run when addUser is called.

=head2 pluginGroupAddUser

A comma seperated list of plugins to run when groupAddUser is called.

=head2 pluginGroupGIDchange

A comma seperated list of plugins to run when groupGIDchange is called.

=head2 pluginGroupRemoveUser

A comma seperated list of plugins to run when groupRemoveUser is called.

=head2 pluginUserGECOSchange

A comma seperated list of plugins to run when userGECOSchange is called.

=head2 pluginUserSetPass

A comma seperated list of plugins to run when userSetPass is called.

=head2 pluginUserGIDchange

A comma seperated list of plugins to run when userGIDchange is called.

=head2 pluginUserShellChange

A comma seperated list of plugins to run when userShellChange is called.

=head2 pluginUserUIDchange

A comma seperated list of plugins to run when userUIDchange is called.

=head2 pluginDeleteUser

A comma seperated list of plugins to run when deleteUser is called.

=head2 pluginDeleteGroup

A comma seperated list of plugins to run when deleteGroup is called.

=head1 PLUGINS

Plugins are supported by the functions specified in the config section.

A plugin may be specified for any of those by setting that value to a comma seperated
list of plugins. For example if you wanted to call 'Plugtools::Plugins::Dump' and then
'Foo::Bar' for a userSetPass, you would set the value 'pluginsUserSetPass' equal to
'Plugtools::Plugins::Dump,Foo::Bar'.

Both hashes specified in the section covering the plugin function. The key 'self' is added
to %opts before it is passed to the plugin. That key contains a copy of the Plugtools object.

A plugin is a Perl module that is used via eval and then the function 'plugin' is called on
it. The expected return is 

The plugin is called before the update method is called on a Net::LDAP::Entry object, except for
the function 'userSetPass'. It is called after the password is updated.

=head2 example

What is shown below is copied from Plugtools::Plugins::Dump. This is a simple plugin
that calls Data::Dumper->Dumper on what is passed to it.

    package Plugtools::Plugins::Dump;
    use warnings;
    use strict;
    use Data::Dumper;
    our $VERSION = '0.0.0';
    sub plugin{
        my %opts;
        if(defined($_[1])){
            %opts= %{$_[1]};
        };
        my %args;
        if(defined($_[2])){
                %args= %{$_[2]};
        };
        print '%opts=...'."\n".Dumper(\%opts)."\n\n".'%args=...'."\n".Dumper(\%args);
        my %returned;
        $returned{error}=undef;
        return %returned;
    }
	1;


=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plugtools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plugtools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plugtools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plugtools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plugtools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plugtools>

=item * Search CPAN

L<http://search.cpan.org/dist/Plugtools/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Plugtools
