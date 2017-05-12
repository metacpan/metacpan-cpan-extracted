#!perl

use 5.008003;
use strict;
use warnings FATAL => 'all';

use Test::More;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname($0), "inc");

{ package #
    MyTest;

use Moo;

sub info {{}}

use MooX::Roles::Pluggable;
}

{ package #
    MyTest2;

use Moo;

sub info {{}}

use MooX::Roles::Pluggable search_path => 'MyTest::Role';
}

package #
    main;

my $mytest = MyTest->new();
my $info = $mytest->info();

ok($info->{Foo}, "Foo role consumed");
ok($info->{Bar}, "Bar role consumed");

my $mytest2 = MyTest2->new();
my $info2 = $mytest2->info();

ok($info2->{Foo}, "Foo role consumed");
ok($info2->{Bar}, "Bar role consumed");

done_testing();
