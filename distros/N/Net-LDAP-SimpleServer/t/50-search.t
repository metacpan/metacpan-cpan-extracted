use strict;
use warnings;
use Test::More tests => 8;

use lib 't/lib';
use Helper qw(ldap_client test_requests);

use Net::LDAP::Constant qw/LDAP_SUCCESS LDAP_NO_SUCH_OBJECT/;

my $DATA    = 'examples/single-entry.ldif';
my $ROOT_PW = 'testpw';

test_requests(
    server_opts => {
        data_file => $DATA,
        root_pw   => $ROOT_PW,
    },
    requests_sub => sub {
        my $mesg = undef;

        my $ldap = ldap_client();
        $mesg = $ldap->bind;
        ok( !$mesg->code, $mesg->error_desc );

        # no results for this one
        $mesg = $ldap->search( base => 'DC=org', filter => '(dn=*)' );
        is( $mesg->code, LDAP_NO_SUCH_OBJECT, $mesg->error_desc );
        is( scalar( $mesg->entries ), 0 );

        my $dn1 = 'CN=Alexei Znamensky,DC=SnakeOil,DC=com';
        $mesg = $ldap->search(
            base   => 'DC=com',
            filter => '(distinguishedname=' . $dn1 . ')'
        );

        is( $mesg->code, LDAP_SUCCESS, 'check status code' )
          || diag explain $mesg;
        my @entries = $mesg->entries;
        is( scalar(@entries), 1 );
        my $e = shift @entries;

        is( $e->dn,              $dn1 );
        is( $e->get_value('sn'), 'Znamensky' );

        $mesg = $ldap->unbind;
        ok( !$mesg->code, $mesg->error_desc );
    }
);
