use strict;
use warnings;
use Test::More;

use Net::LDAP::SimpleServer::LDIFStore;
use Net::LDAP::SimpleServer::ProtocolHandler;

sub _check_param {
    eval { my $o = Net::LDAP::SimpleServer::ProtocolHandler->new(@_); };
    return $@;
}

sub check_param_success {
    ok( not _check_param(@_) );
}

sub check_param_failure {
    ok( _check_param(@_) );
}

my $store =
  Net::LDAP::SimpleServer::LDIFStore->new('examples/single-entry.ldif');
isa_ok( $store, 'Net::LDAP::SimpleServer::LDIFStore' );
my $in  = *STDIN{IO};
my $out = *STDOUT{IO};

my $obj = new_ok(
    'Net::LDAP::SimpleServer::ProtocolHandler',
    [
        {
            store   => $store,
            root_dn => 'cn=root',
            root_pw => 'somepw',
            'sock'  => $in
        }
    ],
);

check_param_failure();
check_param_failure( {} );
check_param_failure( $store, $in, $out );
check_param_failure( [$store], $in, $out );
check_param_failure( { bobstore => $store }, $in, $out );
check_param_failure(
    { store => $store, root_dn => 'root', root_pw => 'somepw' },
    $in, $out );
check_param_failure('non/existent/file.ldif');

done_testing();
