use strict;
use warnings;

use Test::More tests => 7;
use FindBin;

use lib $FindBin::Bin. '/lib';

use_ok 'TestRole';

my $o = TestRole->new();
is $o->name, 'default-name';
is $o->age, 42, 'default age';
is $o->date, '20210102', 'default date';

# test that with() rejects invalid module names
{
    package SafeTest;
    use Simple::Accessor qw{x};

    eval { with('Foo; system("echo pwned")') };
    ::like $@, qr/Invalid module name/, 'with() rejects module names containing semicolons';

    eval { with('Foo::Bar') };
    ::like $@, qr/Can't locate/, 'with() accepts valid module names (fails on require, not validation)';

    eval { with('') };
    ::like $@, qr/Invalid module name/, 'with() rejects empty module name';
}

1;
