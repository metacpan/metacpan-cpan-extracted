#!perl -w
use strict;
use Test::More;
use MozRepl::RemoteObject;

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => ['debug'] 
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 1;
};

diag "JS JSON encoder: $repl->{ js_JSON }";

my $appinfo = $repl->appinfo;

isa_ok $appinfo, 'MozRepl::RemoteObject::Instance',
    'We got the application info';

diag 'ID      : ', $appinfo->{ID};
diag 'name    : ', $appinfo->{name};
diag 'version : ', $appinfo->{version};
