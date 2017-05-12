#!perl-wT

use strict;
use lib 't/lib';
use Test::More tests => 3;



my $t = InnerTest->new();

my %plugins = map { $_ => 1 } $t->plugins;

ok(keys %plugins, "Got some plugins");
ok($plugins{'InnerTest::Plugin::Foo'}, "Got Foo");
ok(!$plugins{'InnerTest::Plugin::Bar'}, "Didn't get Bar - the inner package");



package InnerTest;
use strict;
use Module::Pluggable::Fast require => 1, inner => 0;
use base qw(Module::Pluggable::Fast);


sub new {
    my $class = shift;
    return bless {}, $class;

}


1;

