#
# $Id: 01_use.t 161 2004-12-31 04:00:52Z james $
#

use strict;
use warnings;

use File::Find;

# find the number of .pm files in the lib directory
my $pms = 0;
File::Find::find( sub { /\.pm$/ && $pms++ }, 'lib');

my %expected;
BEGIN {

    %expected = (
        'Net::TCPwrappers' => '1.11',
    );

    use Test::More;
    our $tests = ((keys %expected) * 2);
    $tests += 1;            # number of .pm files tested
    $tests += (14*2);        # symbols defined / exported
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

# make sure that we are testing the number of .pm files in lib
is keys %expected, $pms, "$pms version tests planned";

# check each package
for my $package( keys %expected ) {

    # pull in the package
    use_ok($package);

    # make sure the package version is correct
    my $version_var;
    {
        no strict 'refs';
        $version_var = ${$package . '::VERSION'};
    }
    is($version_var, $expected{$package},
        "$package is at version $expected{$package}");
}

for my $symbol( qw|
    RQ_CLIENT_ADDR
    RQ_CLIENT_NAME
    RQ_CLIENT_SIN
    RQ_DAEMON
    RQ_FILE
    RQ_SERVER_ADDR
    RQ_SERVER_NAME
    RQ_SERVER_SIN
    RQ_USER
    request_init
    request_set
    fromhost
    hosts_access
    hosts_ctl
| ) {

    no strict 'refs';
    ok defined \&{ "Net::TCPwrappers::$symbol" }, "Net::TCPwrappers::symbol" .
        " is defined";
    ok defined \&{ "::$symbol" }, "$symbol is exported to main";

}

#
# EOF
