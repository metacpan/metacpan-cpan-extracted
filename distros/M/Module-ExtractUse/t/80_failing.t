#!/usr/bin/perl -w
use strict;
#use Test::More skip_all=>'parser is known to not catch those';
use Test::More;
use Module::ExtractUse;

my @tests=
  (
   ['use base (Class::DBI,FooBar);','Class::DBI Foo::Bar'],
   ['use constant lib_ext => $Config{lib_ext};','constant'],
   [q[use Foo;say "Failed to load the release-testing modules we require Bar;";],'Foo','"require" in some string'],
   [q[eval { { use Test::Pod } use Test::Pod::Coverage }],'Test::Pod Test::Pod::Coverage','without semicolon at the end of the BLOCK'],
  );

plan tests => scalar @tests;

foreach my $t (@tests) {
    my ($code,$expected,$testname)=@$t;
    $testname ||=$code;
    my $p=Module::ExtractUse->new;
    my $used=$p->extract_use(\$code)->string;
    TODO: {
        local $TODO='known to not work';
        if ($used) {
            is($used,$expected,$testname);
        } else {
            is(undef,$expected,$testname);
        }
    }
}
