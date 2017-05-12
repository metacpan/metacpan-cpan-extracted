#!/usr/bin/perl -w

use strict;
use warnings;
use Carp;
use Data::Dumper;
use DateTime;
use Samba::LDAP;
use Samba::LDAP::Config;
use Samba::LDAP::User;
use Samba::LDAP::Group;
use Storable qw( nstore );

my $config = Samba::LDAP::Config->new()
   or croak "Can't create object\n";

my $smbldap = Samba::LDAP->new()
   or croak "Can't create object\n";

my $smbuser = Samba::LDAP::User->new()
   or croak "Can't create object\n";

my $smbgroup = Samba::LDAP::Group->new()
   or croak "Can't create object\n";

#print Dumper( $smbgroup );
#print Dumper( $smbldap );

#nstore $smbgroup, './test';

# Returns where smbldap.conf, smbldap_bind.conf and
# smb.conf are located
#print Dumper( $config->find_smbldap() );
#print Dumper( $config->find_smbldap_bind() );
#print Dumper( $config->find_samba() );
#print Dumper( $config );

#print "Finding SID\n";
#print Dumper( $smbldap->get_local_sid() );

#$config = $config->read_conf();
#print Dumper( $config );

#print Dumper( $smbldap->connect_ldap_master() );
#print Dumper( $smbldap->connect_ldap_slave() );

#print "Searching for Samba User: ('1' means found)\n";
#print Dumper( $smbuser->is_samba_user( 'ghenry' ) );

#print "Searching for Valid User: ('1' means found)\n";
#print Dumper( $smbuser->is_valid_user(
#'ou=Users,ou=OxObjects,dc=suretecsystems,dc=com', 'testing' ) );

#print "Getting group DN:\n";
#print Dumper( $smbgroup->_get_group_dn( 'testing' ) );

#print "Reading Group Entry:\n";
#print Dumper( $smbgroup->read_group_entry( 'testing' ) );

#print "Searching for valid Unix User: ('1' means found)\n";
#print Dumper( $smbuser->is_unix_user( 'ghenry' ) );


#my $groups_ref = [ 'staff', 'directors', 'contractors', ];
#my $groups_ref = { 
#            admin => [ 'staff', 'directors', 'contractors', ], 
#            normal => [ 'web_team', 'finance', 'cleaners', ],           
#          };
#$smbgroup->add_to_groups( $groups_ref, 'gavin' );

#print $group;

#print Dumper( $smbuser->make_hash(  clear_pass => 'testing', 
#                                    hash_encrypt_format => 'SSHA',
#                                  ) );

#print Dumper( $smbuser->_make_salt( '4' ) );

#print Dumper( $smbuser->get_next_id(
#'ou=Users,ou=OxObjects,dc=suretecsystems,dc=com', 'uidNumber' ) );

#print "Disabling User ghenry\n";
#print Dumper( $smbuser->disable_user ( 'ghenry' ) );

#print "Getting homedir for 'test'\n";
#print Dumper( $smbuser->get_homedir('test') );

#print "Disabling user 'test'\n";
#print Dumper( $smbuser->disable_user('test') ); 

#print "Deleting user 'ghenry'\n";
#print Dumper( $smbuser->delete_user( user => 'andrew6' ) ); 
#print "Waiting for 5 secs\n";
#sleep 5;


#print "Checking for user 'ghenry' - 1 means they are a Samba User\n";
#print Dumper( $smbuser->is_samba_user( 'ghenry' ) ); 

my @groups = $smbgroup->find_groups( 'andrew6' );
print "@groups\n";

#print "Adding user 'test'\n";
#print Dumper( $smbuser->add_user( 
#                                    user => 'ghenry', 
#                                    newpass => 'testing', 
#                                    windows_user => '1',
#                                    ox => '1',
#                                   
#                                ) );

#print Dumper( $smbuser->change_password ( 
#                                    user => 'ghenry',
#                                    oldpass => '{crypt}x',
#                                    newpass => 'testing',
#                                    ) );
