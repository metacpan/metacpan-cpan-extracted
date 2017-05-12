# -*- Mode: Perl; -*-

=head1 NAME

00_base.t - Test the basic functionality of the base Net::YAR

=cut

use constant N_TESTS => 43;
use strict;
use Test::More tests => N_TESTS;
use Data::Dumper qw(Dumper);

use_ok('Net::YAR');

my $yar;
ok(($yar = Net::YAR->new), "Was able to create a Net::YAR object");

###----------------------------------------------------------------###

ok($yar->can('api_user'),           "Can call api_user");
ok($yar->can('api_pass'),           "Can call api_pass");
ok($yar->can('api_host'),           "Can call api_host");
ok($yar->can('serialize_type'), "Can call serialize_type");

###----------------------------------------------------------------###

ok($yar->serialize_type, "Got a type");
ok(! eval { $yar->api_user }, "Cannot get uninitialized api_user");
ok(! eval { $yar->api_pass }, "Cannot get uninitialized api_pass");
ok(! eval { $yar->api_host }, "Cannot get uninitialized api_host");

###----------------------------------------------------------------###

if (! $ENV{'TEST_NET_YAR_CONNECT'}) {
    SKIP: {
        skip('Set TEST_NET_YAR_CONNECT to "user/pass/host" to run tests requiring connection', N_TESTS - 10);
    };
    exit;
}
my ($user, $pass, $host) = split /\//, $ENV{'TEST_NET_YAR_CONNECT'};

###----------------------------------------------------------------###

ok(($yar = Net::YAR->new({
    api_user => $user,
    api_pass => $pass,
    api_host => $host,
})), "Got new object");

ok(eval { $yar->api_user }, "Can get initialized api_user");
ok(eval { $yar->api_pass }, "Can get initialized api_pass");
ok(eval { $yar->api_host }, "Can get initialized api_host");

my $r = $yar->noop;
if (! $r) {
    SKIP: {
        diag Dumper($r->data);
        my $s = Dumper($r);
        $s =~ s/^/\#/gm;
        print $s;
        skip("TEST_NET_YAR_CONNECT could not connect: ".(eval { $r->code } || 'unknown'), N_TESTS - 14);
    };
    exit;
}

local $Net::YAR::DEFAULT_RETRY_MAX = 0;

ok($r, "Ran noop");
ok($r->{'type'} eq 'success', "Got noop success");

ok($r = $yar->balance, "Ran balance");
my $b = eval { $r->data->{'balance'} };
ok($b =~ /^-?(\d+|\d*\.\d*)$/, "Found a balance ($b)");

###----------------------------------------------------------------###

$r = $yar->util->noop;
ok($r, "Ran util->noop with chained calling syntax");
ok($r->{'type'} eq 'success', "Got util->noop success");

$r = eval { $yar->util_noop };
ok($r, "Ran util_noop with single name calling syntax");
ok($r->{'type'} eq 'success', "Got util_noop success");

###----------------------------------------------------------------###
### test various errors

$r = $yar->util_method_doesnot_exist;
ok(! $r, "Ran non_existant method ($@)");

$r = $yar->util->method_doesnot_exist;
ok(! $r, "Ran non_existant method ($@)");

$r = $yar->util->noop({serialize_type => 'blah'});
ok(! $r, "Ran with bad serialize_type ($@)");

ok(($yar = Net::YAR->new({
    api_user => $user,
    api_pass => $pass,
    api_host => $host,
    api_port => "--garbageport--",
})), "Got new object");

$r = $yar->util->noop;
#diag Dumper $r;
ok(! $r, "Ran with intentional connect error ($@)");

###----------------------------------------------------------------###
### test intentionally bad info

ok(($yar = Net::YAR->new({
    api_user => '---',
    api_pass => '123qwe',
    api_host => $host,
})), "Got new object");

ok(! ($r = $yar->noop), "Ran noop");
ok(eval { $r->type } eq 'error', "Got noop error");
ok(eval { $r->code } eq 'failed_auth', "Got noop error");

###----------------------------------------------------------------###
### test logging

{
    package MyLogger;
    sub new { my $str; bless \$str, __PACKAGE__ }
    sub print { my $self = shift; $$self .= join("", @_) }
    sub as_string { my $self = shift; $$self }
}

ok(($yar = Net::YAR->new({
    api_user => $user,
    api_pass => $pass,
    api_host => $host,
    log_obj  => MyLogger->new,
})), "Got new object");

ok(! $yar->log_obj->as_string, "No log yet");
ok(($r = $yar->noop), "Ran noop");
#print $yar->logobj->as_string;
ok($yar->log_obj->as_string, "Got log info");

###----------------------------------------------------------------###
### test serialization types

foreach my $type (qw(json xml yaml uri)) {
    local $yar->{'serialize_type'} = $type;
    my $r = $yar->util->noop({foo => 'bar'});
    if ($r) {
        ok(1, "Ran noop with type $type");
        is($r->type, 'success', "Got the right type");
    } else {
        SKIP: {
            skip("Module for type $type doesn't appear to be installed", 1) for 1 .. 2;
        };
    }
}

###----------------------------------------------------------------###
