#!perl -T
#
# 04-get_instance_url
#

use strict;
use warnings FATAL => 'all';
use Test::More;
use ServiceNow::Simple;
my $tests = 5;
plan tests => $tests;

sub BEGIN
{
    eval {require './t/config.cache'; };
    if ($@)
    {
        plan( skip_all => "Testing configuration was not set, test not possible" );
    }
}

my $url = 'https://' . CCACHE::instance() . '.service-now.com/';
my $sn = ServiceNow::Simple->new({
        instance_url => $url,
        user         => CCACHE::user(),
        password     => CCACHE::password(),
        table        => 'sys_user_group',
        });

diag( 'Testing against instance_url: ' . $url);
ok( defined($sn), 'connected, table sys_user_group');

my $results;
eval {
    $results = $sn->get_keys({ name => 'CAB Approval' });
};

SKIP: {
    skip 'ServiceNow is unavailable',           $tests - 1 if ($@ =~ /Service Unavailable/);
    skip 'ServiceNow instance does not exist',  $tests - 1 if ($@ =~ /500 Can't connect to/);    #' <-- syntax correction comment
    skip 'Problem talking with ServiceNow',     $tests - 1 if ($@);
    #skip 'Connectivity issues',                 $tests - 1 unless ($sn);

    ok( defined($results), "defined get_keys for 'CAB Approval'");
    ok( defined($results) && defined($results->{sys_id}), "get_keys for 'CAB Approval' got sys_id");
    print STDERR " 'CAB Approval' sys_id is " . $results->{sys_id} . "\n";

    my $r = $sn->get({ sys_id => $results->{sys_id} });  # Administration group, which should always be defined
    ok( defined($r), 'get call defined result');
    ok( defined($r) && defined($r->{sys_id}), 'get call with sys_id');
}

# End