package Foo;

use strict;
require Exporter;
require "t/lib/Foo.pm";
use vars qw(@ISA $VERSION);
$VERSION = 7.254;

@ISA = qw(This That What::Ever);

my $foo = 42;

{
    package Bar;

    my $bar = 23;
}

sub wibble {
    package Wibble;
    $foo = 42;
    return 66;
}

wibble('this is the function call');
{ no strict 'refs'; &{'wibble'}('this is a symref function call'); }
Foo->wibble(42);
{ local @ARGV = (bless {});  shift->wibble(42); }
my $obj = bless {};
$obj->wibble('bar');
my $method = 'wibble';
Foo->$method;
$obj->$method;
$obj->$method('bar');
Foo->$method('bar');
{
    no strict 'subs';
    $Foo::obj = bless {};
    $Foo::obj->wibble(main::STDOUT);
}
my $_private = sub {
    wibble('call inside anonymous subroutine');
};

require 5.004;
use 5.004;
require 5;
use 5;
use lib qw(blahbityblahblah);

eval "require Text::Soundex";

sub croak {
    require Carp;
    Carp::croak(@_);

    return sub {
        main::wibble('call insde anon sub inside sub');
        require 't/lib/NotHere.pm';
    }
}

BEGIN {
    require 't/lib/Bar.pm';
}

my $mod = 't/lib/Bar.pm';
require $mod;
