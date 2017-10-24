use Test::More;
use strict;
use warnings;

use Object::HashBase;
use Object::HashBase::Inline;
use File::Temp qw/tempdir/;

my $tmp = tempdir(CLEANUP => 0);
chdir($tmp);

Object::HashBase::Inline::inline('My::Prefix', '123');

ok(-f 'lib/My/Prefix/HashBase.pm', "Wrote HashBase.pm");
ok(-f 't/HashBase.t', "Wrote HashBase.t");

unshift @INC => "$tmp/lib";

require My::Prefix::HashBase;

is($My::Prefix::HashBase::VERSION, '123', "Set a custom inline module version number");
ok($My::Prefix::HashBase::HB_VERSION, "Set the HB_VERSION");
is($My::Prefix::HashBase::HB_VERSION, $Object::HashBase::VERSION, "The HB_VERSION is correct");

{
    no warnings 'once';
    is(
        \%Object::HashBase::ATTR_SUBS,
        \%My::Prefix::HashBase::ATTR_SUBS,
        "Aliased ATTR_SUBS"
    );
}

{
    package Test::A;
    My::Prefix::HashBase->import('foo');

    main::is(FOO(), 'foo', "Added foo");
}

{
    package Test::B;
    push @Test::B::ISA => 'Test::A';
    My::Prefix::HashBase->import('bar');

    main::is(FOO(), 'foo', "Added foo");
    main::is(BAR(), 'bar', "Added bar");
}

{
    package Test::C;
    push @Test::C::ISA => 'Test::B';
    Object::HashBase->import('baz');

    main::is(FOO(), 'foo', "Added foo from copy");
    main::is(BAR(), 'bar', "Added bar from copy");
    main::is(BAZ(), 'baz', "Added baz");
}

done_testing;
