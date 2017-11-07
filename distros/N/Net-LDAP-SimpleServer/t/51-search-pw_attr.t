use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use Helper qw(ldap_client test_requests);

use Net::LDAP::Constant qw/LDAP_SUCCESS LDAP_NO_SUCH_OBJECT/;
use Net::LDAP::SimpleServer::Constant;

my $DATA    = 'examples/single-entry.ldif';
my $ROOT_PW = 'testpw';

test_requests(
    server_opts => {
        data_file      => $DATA,
        root_pw        => $ROOT_PW,
        user_passwords => USER_PW_ALL,
    },
    requests_sub => sub {
        my $mesg = undef;

        my $ldap = ldap_client();
        $ldap->bind();

        my $dn = 'CN=Alexei Znamensky,DC=SnakeOil,DC=com';
        $mesg = $ldap->search(
            base   => 'DC=com',
            filter => '(distinguishedname=' . $dn . ')'
        );
        my $entry = ( $mesg->entries )[0];

        is( $entry->get_value('userPassword'), 'potatoes' )
          || diag explain $entry;
    }
);

test_requests(
    server_opts => {
        data_file      => $DATA,
        root_pw        => $ROOT_PW,
        user_passwords => USER_PW_NONE,
    },
    requests_sub => sub {
        my $mesg = undef;

        my $ldap = ldap_client();
        $ldap->bind();

        my $dn = 'CN=Alexei Znamensky,DC=SnakeOil,DC=com';
        $mesg = $ldap->search(
            base   => 'DC=com',
            filter => '(distinguishedname=' . $dn . ')'
        );
        my $entry = ( $mesg->entries )[0];

        is( defined( $entry->get_value('userpassword') ), '' )
          || diag explain $entry;
    }
);

test_requests(
    server_opts => {
        data_file      => $DATA,
        root_pw        => $ROOT_PW,
        user_passwords => USER_PW_MD5,
    },
    requests_sub => sub {
        my $meo_deos_5_batatas = '{md5}4aHwvjDO/H2FfqZAjNAKEg==';
        my $mesg               = undef;

        my $ldap = ldap_client();
        $ldap->bind();

        my $dn = 'CN=Alexei Znamensky,DC=SnakeOil,DC=com';
        $mesg = $ldap->search(
            base   => 'DC=com',
            filter => '(distinguishedname=' . $dn . ')'
        );
        my $entry = ( $mesg->entries )[0];

        is( $entry->get_value('userpassword'), $meo_deos_5_batatas )
          || diag explain $entry;
    }
);

# default should be USER_PW_NONE
test_requests(
    server_opts => {
        data_file => $DATA,
        root_pw   => $ROOT_PW,
    },
    requests_sub => sub {
        my $mesg = undef;

        my $ldap = ldap_client();
        $ldap->bind();

        my $dn = 'CN=Alexei Znamensky,DC=SnakeOil,DC=com';
        $mesg = $ldap->search(
            base   => 'DC=com',
            filter => '(distinguishedname=' . $dn . ')'
        );
        my $entry = ( $mesg->entries )[0];

        is( defined( $entry->get_value('userpassword') ), '' )
          || diag explain $entry;
    }
);

