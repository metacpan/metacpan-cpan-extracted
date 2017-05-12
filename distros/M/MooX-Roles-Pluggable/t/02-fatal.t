#!perl

use 5.008003;
use strict;
use warnings FATAL => 'all';

use Test::More;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname($0), "inc");

package #
    MyTest;

sub info {{}}

use MooX::Roles::Pluggable;

package #
    main;

my $info = MyTest->info();

ok(!defined $info->{Foo}, "Foo role not consumed");
ok(!defined $info->{Bar}, "Bar role not consumed");

done_testing();
