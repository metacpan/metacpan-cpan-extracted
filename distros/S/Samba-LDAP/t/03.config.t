#!perl -w

use warnings;
use strict;
use Test::More tests => 6;

BEGIN {
        use_ok( 'Samba::LDAP::Config');
}

my $config = Samba::LDAP::Config->new();
isa_ok ( $config, 'Samba::LDAP::Config' );
can_ok( $config, qw(find_smbldap find_smbldap_bind find_samba) );

SKIP: {

    skip 'smbldap tools installed, so not point in testing this', 
    1 if -e '/etc/smbldap-tools/smbldap.conf';
    
    is ( $config->find_smbldap(), 'smbldap.conf',
        'Should return smbldap.conf bundled in the scrips directory' );
}        

SKIP: {

    skip 'smbldap tools installed, so not point in testing this', 
    1 if -e '/etc/smbldap-tools/smbldap_bind.conf';
    
    is ( $config->find_smbldap_bind(), 'smbldap_bind.conf',
    'Should return smbldap_bind.conf bundled in the scripts directory' );
}

SKIP: {

    skip 'Samba installed, so not point in testing this', 
    1 if -e '/etc/samba/smb.conf';
    
    is ( $config->find_samba(), 'smb.conf',
    'Should return smb.conf bundled in the scripts directory' );
}

