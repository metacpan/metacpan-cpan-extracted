#!perl -w
use strict;
use Test::More;
use MozRepl::RemoteObject;

my $repl = eval { MozRepl::RemoteObject->install_bridge( 
)};

if (! $repl) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
    exit
} else {
    plan tests => 1;
};

my $f = $repl->declare(<<'JS');
function(){return 1}
JS

my $destroyed = 0;
my $old = \&MozRepl::RemoteObject::Instance::DESTROY;
{
    no warnings 'redefine';
    *MozRepl::RemoteObject::Instance::DESTROY = sub {
        $destroyed++;
        goto &$old;
    };
};

undef $f;
undef $repl;

is $destroyed, 1, "Function object was destroyed";

