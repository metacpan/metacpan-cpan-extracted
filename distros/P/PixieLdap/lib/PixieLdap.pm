package PixieLdap;

use 5.010000;
use strict;
use warnings;
use Net::LDAPS;
use Net::LDAP;
use Crypt::PasswdMD5;
use YAML;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(viewSearch deleteMember deleteEntry addMember addGroup getMaxUID getMaxGID getInput viewBind addUser getGIDNumber changeUserPasswd
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(viewSearch deleteMember deleteEntry addMember addGroup getMaxUID getMaxGID getInput viewBind addUser getGIDNumber changeUserPasswd
);

our $VERSION = '0.01';

my $scope = 'sub';


sub viewBind {
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $config = YAML::LoadFile($configfile);
	my $conn;
	
	if ($config->{secure} == '1'){
		$conn = Net::LDAPS->new($config->{server}, verify => 'none' ) or die "Unable to Connect: $@\n";
	}
	else {
		$conn = Net::LDAP->new($config->{server} ) or die "Unable to Connect: $@\n";
	}
	my $message = $conn->bind($config->{user}->[1]->{dn}, password => $config->{user}->[1]->{password});

	if ( $message->code){
		die 'Unable to bind: '. $message->error . "\n";
	}
	
	return ($conn, $config->{basedn});
}


sub rootBind {
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $config = YAML::LoadFile($configfile);
	my $conn;

	if ($config->{secure} == '1'){
		$conn = Net::LDAPS->new($config->{server}, verify => 'none' ) or die "Unable to Connect: $@\n";
	}
	else {
		$conn = Net::LDAP->new($config->{server}, verify => 'none' ) or die "Unable to Connect: $@\n";
	}
	my $message = $conn->bind($config->{user}->[0]->{dn}, password => $config->{user}->[0]->{password});

	if ( $message->code){
		die 'Unable to bind: '. $message->error . "\n";
	}
	
	return ($conn, $config->{basedn});
}

 
sub viewSearch {
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $filter = shift;
	unless (defined $filter) { die "No Filter Specified\n";}
	my $base = shift;
	unless (defined $base) { die "No Group/User Base Specified\n";}
	
	my ($vconn, $basedn) = viewBind($configfile);
	my $search = $vconn->search(base => $base.$basedn,
		scope => $scope,
		filter => $filter );
		die "Bad Search: " . $search->error() if $search->code();

	$vconn->unbind;
	return $search;
}


sub addMember{
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $group = shift;
	unless (defined $group) { die "No Group Specified\n";}
	my $uid = shift;
	unless (defined $uid) { die "No UserID Specified\n";}

	my ($rconn, $basedn) = rootBind($configfile);
	my $search = $rconn->search(base => "ou=group,".$basedn,
		scope => $scope,
		filter => "cn=".$group,
		attrs => [''],
		typesonly => 1 );
		die "Error in Search: " . $search->error() if $search->code();
	
	if ($search){
		my @entries = $search->entries;
		for (@entries){
			print "Adding " . $uid . " to " . $_->dn() ."\n";
			my $modify = $rconn->modify($_->dn(), add => {'memberUid'=> $uid});
			die 'Unable to modify, errorcode #' . $modify->error() if $modify->code();
		}
	}

        $rconn->unbind;
        return;
}


sub addGroup{
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $group = shift;
	unless (defined $group) { die "No Group Specified\n";}

	my $gidNumber = (&getMaxGID($configfile) + 1 );

	my ($rconn, $basedn) = rootBind($configfile);
	my $dn = "cn=" . $group . ",ou=group," . $basedn;

	my $add = $rconn->add(
		dn => $dn,
		attr => [	'cn'			=> $group,
					'gidNumber'		=> $gidNumber,
					'objectClass'	=> [qw( top posixGroup)]]
	);
		die 'Error in add: ' . $add->error()."\n" if $add->code();
	
	$rconn->unbind;
	
	my $answer='O';
	my $member;
	my $memberadd;
	while ( lc $answer ne 'n' ) {
		$answer = getInput("Would you like to add a user to the group Y/N? ");
		if ( lc $answer eq 'y' ) {
			$member = getInput("Enter Member UID :");
    		$memberadd = addMember($group, $member);
		}
	}

	return;
}


sub addUser {
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $uid = shift;
	unless (defined $uid) { die "No UserID Specified\n";}
	my $cli = shift;
	unless (defined $cli) { die "No CLI Specified, 1 eq cli, 0 eq non interactive\n";}
	my $cn = shift 							|| getAddUserInput("Enter Users First Name: ", $cli);
	my $sn = shift 							|| getAddUserInput("Enter Users Surname Name: ", $cli);
	my $shadowMax = shift 					|| getAddUserInput("Enter Max Password Valid Days [90]: ", $cli);
	my $loginShell = shift 					|| getAddUserInput("Enter Required Login Shell [/bin/bash]: ", $cli);
	my $homeDirectory = shift 				|| getAddUserInput("Enter Users Home Directory: ", $cli);
	my $group = shift 						|| getAddUserInput("Enter Users Primary Group: ", $cli);
	my $street = shift 						|| getAddUserInput("Enter Users Street: ", $cli);
	my $mail = shift 						|| getAddUserInput("Enter Users Email Address: ", $cli);
	my $o = shift	 						|| getAddUserInput("Enter Users Organisation: ", $cli);
	my $ou = shift	 						|| getAddUserInput("Enter Users Department: ", $cli);
	my $title = shift						|| getAddUserInput("Enter Users title: ", $cli);
	my $mobile = shift	 					|| getAddUserInput("Enter Users Mobile Number: ", $cli);
	my $telephoneNumber = shift 			|| getAddUserInput("Enter Users Telephone Number: ", $cli);
	my $facsimileTelephoneNumber = shift 	|| getAddUserInput("Enter Users Faxcimile Telephone Number: ", $cli);
	my $l = shift 							|| getAddUserInput("Enter Users City: ", $cli);
	my $st = shift 							|| getAddUserInput("Enter Users State: ", $cli);
	my $postalCode = shift 					|| getAddUserInput("Enter Users Post Code: ", $cli);
	my $givenName = $cn . " " . $sn; 
	my $gecos = $givenName . " " . $group;
	
	$shadowMax = '90' if ($shadowMax eq 'Unknown');
	$loginShell = '/bin/bash' if ($loginShell eq 'Unknown');

	my ($passwd, $cryptPasswd) = genPasswd();
	my $gidNumber = getGIDNumber($configfile, $group);
	
	unless (defined $gidNumber){
		die	"No Such Group\n";
	}

	my $uidNumber = (&getMaxUID($configfile) + 1 );

	my ($rconn, $basedn) = rootBind($configfile);
	my $dn = "uid=" . $uid . ",ou=people," . $basedn;

	my $add = $rconn->add(
		dn => $dn,
		attr => [	'uid'						=> $uid,
					'cn'						=> $cn,
					'sn'						=> $sn,
					'shadowMax'					=> $shadowMax,
					'shadowWarning' 			=> '7',
					'shadowInactive' 			=> '3',
					'shadowLastChange'			=> today(),
					'loginShell' 				=> $loginShell,
					'userPassword'				=> $cryptPasswd,
					'uidNumber'					=> $uidNumber,
					'homeDirectory'				=> $homeDirectory,
					'street' 					=> $street,
					'gecos' 					=> $gecos,
					'mail' 						=> $mail,
					'o' 						=> $o,
					'ou'						=> $ou,
					'title' 					=> $title,
					'mobile' 					=> $mobile,
					'telephoneNumber' 			=> $telephoneNumber,
					'facsimileTelephoneNumber'	=> $facsimileTelephoneNumber,
					'givenName' 				=> $cn,
					'l' 						=> $l,
					'st' 						=> $st,
					'postalCode'				=> $postalCode,
					'gidNumber'					=> $gidNumber,
					'objectClass'				=> [qw( top  posixAccount inetOrgPerson organizationalPerson shadowAccount)]]
	);
		die 'Error in add: ' . $add->error()."\n" if $add->code();
	
	$rconn->unbind;
	return ($givenName, $passwd);
}


sub deleteMember{
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $filter = shift;
	unless (defined $filter) { die "No Filter Specified\n";}
	my $base = shift;
	unless (defined $base) { die "No base Group or People Specified\n";}
	my $uid = shift;
	unless (defined $uid) { die "No UserID Specified\n";}

	my ($rconn, $basedn) = rootBind($configfile);
	my $search = $rconn->search(base => $base.$basedn,
		scope => $scope,
		filter => $filter,
		attrs => [''],
		typesonly => 1 );
		die "Error in Search: " . $search->error() if $search->code();
	
	if ($search){
		my @entries = $search->entries;
		for (@entries){
			print "Removing " . $uid . " from " . $_->dn() ."\n";
			my $delete = $rconn->modify($_->dn(), delete => {'memberUid'=> $uid});
			die 'Unable to modify, errorcode #' . $delete->error() if $delete->code();
		}
	}

        $rconn->unbind;
        return;
}


sub deleteEntry{
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $filter = shift;
	unless (defined $filter) { die "No Filter Specified\n";}
	my $base = shift;
	unless (defined $base) { die "No base Group or People Specified\n";}

	my ($rconn, $basedn) = rootBind($configfile);
	my $dn=$filter.",".$base.$basedn;
	print "Deleting ".$dn."\n";
	my $delete = $rconn->delete($dn);
		die 'Error in delete: ' . $delete->error() . "\n" if $delete->code();

	$rconn->unbind;
	return;
}


sub changeUserPasswd{
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $uid = shift;
	unless (defined $uid) { die "No UserID Specified\n";}

	my ($passwd, $cryptPasswd) = genPasswd();

	my ($rconn, $basedn) = rootBind($configfile);
	my $dn = "uid=" . $uid . ",ou=people," . $basedn;

	my $modify = $rconn->modify(
		dn => $dn,
		replace => [	'shadowLastChange'			=> today(),
						'userPassword'				=> $cryptPasswd,]
	);
		die 'Error in Password Change: ' . $modify->error()."\n" if $modify->code();

	$rconn->unbind;
	return $passwd;
}


sub getMaxUID {
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}

	my ($vconn, $basedn) = viewBind($configfile);
	my $uids = $vconn->search(base => "ou=people,".$basedn,
		scope => $scope,
		filter => "uidNumber=*",
		attrs  => [ 'uidNumber' ]
        );
		die "Bad Search: " . $uids->error() if $uids->code();

	return unless $uids->count;

	my ($highest) = sort {$b <=> $a} grep $_ ne 65534, map $_->get_value('uidNumber'), $uids->all_entries;
	die "Couldn't find new id" unless ($highest);

	return $highest;
}


sub getMaxGID {
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}

	my ($vconn, $basedn) = viewBind($configfile);
	my $gids = $vconn->search(base => "ou=group,".$basedn,
		scope => $scope,
		filter => "gidNumber=*",
		attrs  => [ 'gidNumber' ]
        );
		die "Bad Search: " . $gids->error() if $gids->code();

	return unless $gids->count;

	my ($highest) = sort {$b <=> $a} grep $_ ne 65534, map $_->get_value('gidNumber'), $gids->all_entries;
	die "Couldn't find new id" unless ($highest);

	return $highest;
}


sub getGIDNumber{
	my $configfile = shift;
	unless (defined $configfile) { die "No Config File Specified\n";}
	my $group = shift;
	unless (defined $group) { die "No Group Specified\n";}

	my $search = viewSearch( $configfile, "cn=".$group, 'ou=group,' );
	my $entry;
	return ($entry->get_value('gidNumber')) if defined ($entry = $search->entry('0'));

	return;
}


sub getInput {
	my $question = shift;
	print $question;
	my $answer = <STDIN>;
	chomp ($answer);
	return $answer;
}


sub getAddUserInput {
	my $question = shift;
	unless (defined $question) { die "No Question Specified\n";}
	my $cli = shift;
	unless (defined $cli) { die "No CLI Specified, 1 eq cli, 0 eq non interactive\n";}
	return 'Unknown' if ($cli != '1' );
	my $answer = getInput($question);
	$answer = 'Unknown' if (!$answer);
	return $answer;
}


sub today {
	my $sdt = time();
	return int($sdt / (60 * 60 * 24));
}


sub genPasswd {
	no strict "subs";
	my $passwd = join '',map{((A..Z),(0..9))[int(rand(36))]}(0..7);
    my $salt = join '', (qw#. /#,(0..9),('A'..'Z'),('a'..'z'))[map rand(64), (1..8)];
    my $cryptPasswd = "{crypt}".unix_md5_crypt($passwd, $salt);
	return ($passwd, $cryptPasswd);
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

PixieLdap - Perl extension for simple ldap functions using Net::LDAP and Net::LDAPS

=head1 SYNOPSIS

	use PixieLdap;
	
	my $config = 'ldap.yml';

=head2 Sample Search Operation.

    my $filter = getInput("Enter Filter i.e uid=* : ");
    unless (defined $filter) { die "No Filter Specified\n"};
    my $base = &GroupOrPeople;
    my $search = viewSearch($config, $filter, $base);
    if ($search){
        my $answer = getInput("Dump full ldif results to /tmp/dump.ldif Y/N ? ");
        if ( lc $answer eq 'y'){
            my $ldif = Net::LDAP::LDIF->new('/tmp/dump.ldif', 'w');
            $ldif->write_entry($search->entries());
            $ldif->done();
        }
        else {
            my $searchstruct = $search->as_struct;
            foreach my $dn (keys %$searchstruct){
                print $dn."    ";
                print $searchstruct->{$dn}{cn}[0],"\n";
            }
        }
    }


=head2 Add Member to Group.

    my $group = getInput( "Enter Group: ");
    unless (defined $group) { die "No Group Specified\n"};
    my $uid = getInput( "Enter UserID for adding to group: ");
    unless (defined $uid) { die "No User ID Specified\n"};
    my $add = addMember($config, $group, $uid);


=head2 Add User (interactive)

    my $uid = getInput("Enter UserID: ");
    unless (defined $uid) { die "No User ID Specified\n"};
    my ($givenName, $passwd) = addUser($config, $uid, '1');
    print "New User: " . $uid . "  " .  $givenName . " with password: " . $passwd . "\n";
You can also call the funcion and supply all the variables to use in non interactive mode if $cli=0.


=head2 Group ID Search

    my $group = getInput("Enter Group: ");
    unless (defined $group) { die "No Group Specified\n"};
    my $gidNumber;
    $gidNumber = getGIDNumber($config, $group);
    if (defined $gidNumber){
        print "Group: " . $group . " has group ID number: ". $gidNumber . "\n";
    }
    else {
        print "No Such Group Found\n";
    }


=head2 Delete User from Group

    my $filter = getInput("Enter Filter: ");
    unless (defined $filter) { die "No Filter Specified\n"};
    my $uid = getInput("Enter UserID: ");
    unless (defined $uid) { die "No User ID Specified\n"};
    my $base = &GroupOrPeople;
    my $delete = deleteMember($config, $filter, $base, $uid);


=head2 Delete Entry from Ldap server

    my $entry = getInput("Enter User or Group for Removal: ");
    my ($filter, $delete);
    my $base = &GroupOrPeople;
    if ($base !~ m/ou=group/){
        $filter = "uid=".$entry;
        $delete = deleteEntry($config, $filter, $base);
    }
    else {
        $filter = "cn=".$entry;
        $delete = deleteEntry($config, $filter, $base);
    }


=head2 Change a Users Password to an auto generated one

    my $uid = getInput("Enter UserID of User whos password needs to be changed: ");
    unless (defined $uid) { die "No User ID Specified\n"};
    my $passwd = changeUserPasswd( $config, $uid );
    if (defined $passwd) {
        print "New Password for User: " . $uid . " is: " . $passwd . "\n";
    }
    else {
        print "User: " . $uid . " not found!\n";
    }


=head1 DESCRIPTION

Exports routines to make the use of Net::LDAP and NET::LDAPS easier for certain repeated functions using a common configuration file to source the connection details from.

It requires a config file in yml format an example is below.

 ---
 server: ldap.test.com
 basedn: dc=test,dc=com
 secure: 1
 user: 
  - name: root
    dn: cn=root,dc=test,dc=com
    password: rootpwd 
  - name: view
    dn: cn=view,dc=test,dc=com
    password: teddies


=head2 EXPORT

The following properties are exported by this module:

 viewSearch - Searchs the ldap server as a view only user
 deleteMember - Deletes a user from a group
 deleteEntry - Deletes an entry from the ldap server
 addMember - Adds a user to a current group
 addGroup - Adds a group to the system
 getMaxUID - Gets the current max user id used in the system
 getMaxGID - Gets the current max group id used in the system
 getInput - A function to get user input.
 viewBind - Connect to the ldap server with view only privileges
 addUser - Add a user to the ldap server
 getGIDNumber - Get a groups gidNumber
 changeUserPasswd - Change and LDAP users password to a new random 8 character string

=head1 SEE ALSO

http://search.cpan.org/perldoc?Net::LDAP

My website for a use case script on this module is https://www.pixie79.org.uk/sysadmin/perl/Pixie-Ldap

=head1 AUTHOR

Mark Olliver, E<lt>mark@pixie79.org.uk<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Mark Olliver - Pixie79

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
