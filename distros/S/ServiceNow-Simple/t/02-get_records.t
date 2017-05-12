#!perl -T
#
# 02-get_records
#

use strict;
use warnings FATAL => 'all';
use Test::More;
use ServiceNow::Simple;

sub BEGIN
{
    eval {require './t/config.cache'; };
    if ($@)
    {
        plan( skip_all => "Testing configuration was not set, test not possible" );
    }
}

my $tests = 3;
plan tests => $tests;

my $sn = ServiceNow::Simple->new({
    instance => CCACHE::instance(),
    user     => CCACHE::user(),
    password => CCACHE::password(),
    table    => 'sys_user_group',
    });
ok( defined $sn);

my $results;
eval {
    $results = $sn->get_keys({ name => 'CAB Approval' });
};

SKIP: {
    skip 'ServiceNow is unavailable',           $tests - 1 if ($@ =~ /Service Unavailable/);
    skip 'ServiceNow instance does not exist',  $tests - 1 if ($@ =~ /500 Can't connect to/);    #' <-- syntax correction comment
    skip 'Problem talking with ServiceNow',     $tests - 1 if ($@);
    #skip 'Connectivity issues',                 $tests - 1 unless ($sn);

    ok( defined $results);
    ok( defined($results) && defined($results->{sys_id}));
};
# End