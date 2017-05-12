use Test::More tests => 15;

use lib 't/lib';
use Helper qw(ldap_client test_requests);

our $DATA    = 'examples/single-entry.ldif';
our $ROOT_DN = 'cn=root';
our $ROOT_PW = 'testpw';

#sub diag { print STDERR @_; }

test_requests(
    server_opts => {
        data_file => $DATA,
        root_pw   => $ROOT_PW,
    },
    requests_sub => sub {
        my $mesg = undef;

        my $ldap = ldap_client();
        ok( $ldap, 'should be able to connect' );

        diag('Binding anonymously');
        $mesg = $ldap->bind;
        ok( !$mesg->code,
            'should be able to bind anonymously (' . $mesg->error_desc . ')' );

        $mesg = $ldap->unbind;
        ok( !$mesg->code,
            'should be able to unbind (' . $mesg->error_desc . ')' );

        diag('Binding with authentication');
        $ldap = ldap_client();
        $mesg = $ldap->bind( $ROOT_DN, password => $ROOT_PW );
        ok( !$mesg->code,
                'should be able to bind with authentication ('
              . $mesg->error_desc
              . ')' );

        $mesg = $ldap->unbind;
        ok( !$mesg->code,
            'should be able to unbind (' . $mesg->error_desc . ')' );

        diag('Upper case bind DN');
        $ldap = ldap_client();
        $mesg = $ldap->bind( uc($ROOT_DN), password => $ROOT_PW );
        ok( !$mesg->code,
                'should be able to bind with authentication in upper case('
              . $mesg->error_desc
              . ')' );

        $mesg = $ldap->unbind;
        ok( !$mesg->code,
            'should be able to unbind (' . $mesg->error_desc . ')' );

        diag('Wrong password -> no bind');
        $ldap = ldap_client();
        $mesg = $ldap->bind( $ROOT_DN, password => 'some-wrong-password' );
        ok( $mesg->code,
                'should not be able to bind with wrong password ('
              . $mesg->error_desc
              . ')' );

        $mesg = $ldap->unbind;
        ok( !$mesg->code,
            'should be able to unbind (' . $mesg->error_desc . ')' );

        diag('Unsupported auth mechanism');
        $ldap = ldap_client();
        {
            use Authen::SASL;
            my $sasl = Authen::SASL->new(
                mechanism => 'CRAM-MD5 PLAIN ANONYMOUS',
                callback  => {
                    pass => "blablabla",
                    user => "blablabla",
                }
            );
            $mesg = $ldap->bind( $ROOT_DN, sasl => $sasl );
            ok( $mesg->code,
                    'should not be able to bind with SASL authentication ('
                  . $mesg->error_desc
                  . ')' );

            $mesg = $ldap->unbind;
            ok( !$mesg->code,
                'should be able to unbind (' . $mesg->error_desc . ')' );
        }
    },
);

test_requests(
    server_opts => {
        data_file  => $DATA,
        root_pw    => $ROOT_PW,
        allow_anon => 0,
    },
    requests_sub => sub {
        my $ldap = ldap_client();
        my $mesg = undef;

        diag('Binding anonymously');
        $mesg = $ldap->bind;
        ok( $mesg->code, $mesg->error_desc );

        $mesg = $ldap->unbind;
        ok( !$mesg->code, $mesg->error_desc );

        diag('Binding with authentication');
        $ldap = ldap_client();
        $mesg = $ldap->bind( $ROOT_DN, password => $ROOT_PW );
        ok( !$mesg->code,
                'should be able to bind with authentication ('
              . $mesg->error_desc
              . ')' );

        $mesg = $ldap->unbind;
        ok( !$mesg->code, $mesg->error_desc );
    },
);
