use Test::More tests => 9;

use Net::LDAP::SimpleServer::LDIFStore;
use Net::LDAP::SimpleServer::ProtocolHandler;

sub _check_param {
    my @p = @_;
    eval { my $o = Net::LDAP::SimpleServer::ProtocolHandler->new(@p); };
    return $@;
}

sub check_param_success {
    my $p = _check_param(@_);
    ok( not $p );
}

sub check_param_failure {
    my $p = _check_param(@_);
    ok($p);
}

diag("Testing the constructor params for ProtocolHandler\n");

my $store =
  Net::LDAP::SimpleServer::LDIFStore->new('examples/single-entry.ldif');
isa_ok( $store, 'Net::LDAP::SimpleServer::LDIFStore' );
my $in  = *STDIN{IO};
my $out = *STDOUT{IO};

my $obj = new_ok(
    'Net::LDAP::SimpleServer::ProtocolHandler',
    [
        { store => $store, root_dn => 'cn=root', root_pw => 'somepw', },
        $in, $out
    ]
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
