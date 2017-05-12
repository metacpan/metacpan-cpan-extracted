use Test::More;
use Net::DSLProvider::Murphx;
if (!exists $ENV{MURPHX_USERNAME}
    or !exists $ENV{MURPHX_PASSWORD}
    or !exists $ENV{MURPHX_CLIENTID}) {
     plan skip_all => "Can't do live testing without environment variables"; 
     exit;
}

my $account = Net::DSLProvider::Murphx->new({
    user => $ENV{MURPHX_USERNAME},
    pass => $ENV{MURPHX_PASSWORD},
    clientid => $ENV{MURPHX_CLIENTID},
});

my $self_test = $account->_make_request(selftest => { sysinfo => { type => "module" }});
is($self_test->{status}{no}, 0, "Self test passed");
is($self_test->{block}{a}{module}{content}, "XPS" , "Checking selftest returned content");
done_testing();
