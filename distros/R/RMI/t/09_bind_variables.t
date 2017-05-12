#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 11;
use FindBin;
use lib $FindBin::Bin;
use RMI::TestClass2;

use_ok("RMI::Client::ForkedPipes");

my $c = RMI::Client::ForkedPipes->new();
ok($c, "created an RMI::Client::ForkedPipes using the default constructor (fored process with a pair of pipes connected to it)");

sub cklocal {
    my ($var) = @_;
    my ($local_value,$remote_value) = _ck($var);
    is($local_value,$remote_value," set remote value of $var to $remote_value and local value of $var of $local_value matches");
}

sub ckremote {
    my ($var) = @_;
    my ($local_value,$remote_value) = _ck($var);
    is($remote_value,$local_value,  " set local value of $var to $local_value and remote value of $var of $remote_value matches");
}

sub nomatch {
    my ($var) = @_;
    my ($local_value,$remote_value) = _ck($var);
    ok($local_value ne $remote_value, "values for unbound $var do not match, as expected");
}

sub _ck {
    my $var = shift;
    no warnings;
    my $local_value     = Data::Dumper->new([[eval "$var"]])->Useqq(1)->Terse(1)->Indent(0)->Dump;
    my $remote_value    = Data::Dumper->new([[$c->call_eval("$var")]])->Useqq(1)->Terse(1)->Indent(0)->Dump;
    for ($local_value,$remote_value) {
        s/^\[//;
        s/\]$//;
    }
    return ($local_value, $remote_value,);
}

# SCALAR
ok($c->bind_local_var_to_remote('$main::x'), 'bound $main::x');

$main::x = 5;
ckremote('$main::x');

$c->call_eval('$main::x = 6');
cklocal('$main::x');

$main::x = undef;
ckremote('$main::x');

# ARRAY
@main::a = (11,22,33);
nomatch('@main::a');

ok($c->bind_local_var_to_remote('@main::a'), 'bound @main::a');

$c->call_eval('@main::a = (111,222,333,444)');
cklocal('@main::a');

@main::a = (11);
ckremote('@main::a');

$c->call_eval('@main::a = ()');
cklocal('@main::a');

$c->close;
