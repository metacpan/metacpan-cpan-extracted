use strict;
use Test::More;

use_ok 'Package::Prototype';

my %orig = (hello => 20, world => "codehex");
my @orig = (1..10);

my $proto = Package::Prototype->bless({
    foo => 10,
    bar => "Hello",
    baz => sub {
        my ($self, $arg) = @_;
        return "$arg, World";
    },
    hoge => \%orig,
    fuga => \@orig
});

is $proto->foo, 10;
is $proto->bar, "Hello";
is $proto->baz($proto->bar), "Hello, World"; # scalar wantarray

# reference
my $href = $proto->hoge;
my $aref = $proto->fuga;
is_deeply $href, \%orig;
is_deeply $aref, \@orig; 

# wantarray
my %h = $proto->hoge;
my @a = $proto->fuga;
is_deeply \%h, \%orig;
is_deeply \@a, \@orig;

done_testing;