use Test::More tests => 6;

use Net::LDAP::SimpleServer::LDIFStore;

sub _check_param {
    my @p = @_;
    eval { my $o = Net::LDAP::SimpleServer::LDIFStore->new(@p); };
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

diag("Testing the constructor params for LDIFStore\n");

my $obj = undef;

#$obj = new_ok( 'Net::LDAP::SimpleServer::LDIFStore', [ 'name/of/a/file/that/will/never/ever/exist.ldif' ] );
check_param_failure('');
check_param_failure('name/of/a/file/that/will/never/ever/exist.ldif');
$obj =
  new_ok( 'Net::LDAP::SimpleServer::LDIFStore',
    ['examples/single-entry.ldif'] );

my $list = $obj->list;
ok( $list, 'Returns a list' );
is( ref($list), 'ARRAY', 'The list is an array-reference' );
my @list = @{$list};
is( scalar(@list), 1, 'the list contains one element' );

