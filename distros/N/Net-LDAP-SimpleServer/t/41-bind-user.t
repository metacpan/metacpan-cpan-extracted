use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Helper qw(ldap_client test_requests);

use Net::LDAP::Constant
  qw/LDAP_SUCCESS LDAP_INVALID_DN_SYNTAX LDAP_INVALID_CREDENTIALS/;

our $DATA    = 'examples/single-entry.ldif';
our $ROOT_DN = 'cn=root';
our $ROOT_PW = 'testpw';

test_requests(
    server_opts => {
        data_file => $DATA,
        root_pw   => $ROOT_PW,
    },
    requests_sub => sub {
        my $mesg = undef;

        my $ldap = ldap_client();
        $mesg = $ldap->bind( 'CN=Alexei Znamensky,DC=SnakeOil,DC=com',
            password => 'potatoes' );
        is( $mesg->code, LDAP_SUCCESS, 'result: ' . $mesg->error_desc )
          || diag explain $mesg;
        $mesg = $ldap->unbind;
        is( $mesg->code, LDAP_SUCCESS,
            'should be able to unbind (' . $mesg->error_desc . ')' );

      SKIP: {
            skip( 'Net::LDAP::FilterMatch compares case-sensitively', 2 );
            $ldap = ldap_client();
            $mesg = $ldap->bind( uc('CN=Alexei Znamensky,DC=SnakeOil,DC=com'),
                password => 'potatoes' );
            is( $mesg->code, LDAP_SUCCESS, 'result: ' . $mesg->error_desc )
              || diag explain $mesg;
            $mesg = $ldap->unbind;
            is( $mesg->code, LDAP_SUCCESS,
                'should be able to unbind (' . $mesg->error_desc . ')' );
        }

        $ldap = ldap_client();
        $mesg = $ldap->bind( 'russoz', password => 'potatoes' );
        is( $mesg->code, LDAP_SUCCESS, 'result: ' . $mesg->error_desc )
          || diag explain $mesg;
        $mesg = $ldap->unbind;
        is( $mesg->code, LDAP_SUCCESS,
            'should be able to unbind (' . $mesg->error_desc . ')' );

        $ldap = ldap_client();
        $mesg = $ldap->bind( 'russoz', password => 'some-wrong-password' );
        is( $mesg->code, LDAP_INVALID_CREDENTIALS,
            'result: ' . $mesg->error_desc )
          || diag explain $mesg;
        $mesg = $ldap->unbind;
        is( $mesg->code, LDAP_SUCCESS,
            'should be able to unbind (' . $mesg->error_desc . ')' );

        $ldap = ldap_client();
        $mesg =
          $ldap->bind( 'caspertheghost', password => 'dontneednopassword' );
        is( $mesg->code, LDAP_INVALID_DN_SYNTAX,
            'result: ' . $mesg->error_desc )
          || diag explain $mesg;
        $mesg = $ldap->unbind;
        is( $mesg->code, LDAP_SUCCESS,
            'should be able to unbind (' . $mesg->error_desc . ')' );

    },
);

done_testing();
