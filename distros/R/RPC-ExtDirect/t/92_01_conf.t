use strict;
use warnings;

use Test::More;

if ( $ENV{REGRESSION_TESTS} ) {
    plan tests => 8;
}
else {
    plan skip_all => 'Regression tests are not enabled.';
}

# We will test deprecated API and don't want the warnings
# cluttering STDERR
$SIG{__WARN__} = sub {};

use RPC::ExtDirect::Config;

my @methods = qw(router_path poll_path remoting_var polling_var);

my %expected_get_for = (
    router_path  => '/extdirectrouter',
    poll_path    => '/extdirectevents',
    remoting_var => 'Ext.app.REMOTING_API',
    polling_var  => 'Ext.app.POLLING_API',
);

for my $method ( @methods ) {
    my $get_sub  = 'get_'.$method;

    my $result   = eval { RPC::ExtDirect::Config->$get_sub() };
    my $expected = $expected_get_for{ $method };

    is $@,      '',        "$method get eval $@";
    is $result, $expected, "$method get result";
};

