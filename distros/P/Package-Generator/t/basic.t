#!perl -T
use strict;
use warnings;

use Test::More tests => 33;

my $has_params_util = eval {
  eval "use Params::Util 0.11; 1" or die $@;
  Params::Util->import('_CLASS');
  1;
};

sub pkg_ok {
  my ($name) = @_;
  SKIP: {
    skip "test can't be run without Params::Util 0.11 or newer", 1
      unless $has_params_util;

    ok(_CLASS($name), qq{"$name" is a valid package name});
  }
}

BEGIN { use_ok('Package::Generator'); }

{
  my $pkg = Package::Generator->new_package;

  pkg_ok($pkg);
  like(
    $pkg,
    qr/\APackage::Generator::__GENERATED__::\d+\z/,
    "got a standard name"
  );

  my $pkg2 = Package::Generator->new_package;

  pkg_ok($pkg2);
  like(
    $pkg2,
    qr/\APackage::Generator::__GENERATED__::\d+\z/,
    "got another standard name"
  );

  isnt($pkg, $pkg2, "and the two packages are distinct");
}

{
  my $pkg = Package::Generator->new_package({ base => 'XYZZY' });

  pkg_ok($pkg);
  like(
    $pkg,
    qr/\AXYZZY::\d+\z/,
    "got a name in our given base",
  );
}

{
  my $i = 1;
  my $make_unique = sub { sprintf "%s::%u", $_[0], $i *= 2; };

  for my $j (2, 4, 8, 16) {
    my $pkg = Package::Generator->new_package({
      base => 'y2',
      make_unique => $make_unique,
    });

    pkg_ok($pkg);
    is($pkg, "y2::$j", "got expected name with our base/unique-er");
  }
}

{
  my $pkg = Package::Generator->new_package({ isa => 'Foo::Bar' });

  pkg_ok($pkg);
  #isa_ok($pkg, 'Foo::Bar'); # doesn't work on classes.  LAME!
  ok(eval { $pkg->isa('Foo::Bar') }, 'package has requested @ISA');
}

{
  my $pkg = Package::Generator->new_package({
    isa => [ 'Foo::Bar', 'Bar::Foo' ]
  });

  pkg_ok($pkg);
  #isa_ok($pkg, 'Foo::Bar'); # doesn't work on classes.  LAME!
  ok(eval { $pkg->isa('Foo::Bar') }, 'package has requested @ISA (part 1/2)');
  ok(eval { $pkg->isa('Bar::Foo') }, 'package has requested @ISA (part 2/2)');
}

{
  my $pkg = Package::Generator->new_package({
    version => 10,
  });

  pkg_ok($pkg);

  eval { $pkg->VERSION(9) };
  is($@, '', "we built a package at version 10, so we can demand 9");

  eval { $pkg->VERSION(11) };
  like($@, qr/only version 10/, "...but demanding 11 throws an exception");
}

{
  no warnings 'once';

  my $pkg;
  BEGIN {
    $pkg = Package::Generator->new_package({
      make_unique => sub { return 'Totally::Not::Unique' }, # cheating!
      data => [ 
        foo => 10,
        bar => 12,
        foo => [ qw(a b c d) ],
        foo => { birth => 1978, death => 2862 },
        foo => sub { return "Give me foo or give me death!" },
        obj => bless({} => 'Foo::Bar'),
        qux => 14,    # you could take advantage of multiple assignment to
        qux => undef, # assign a tied scalar, then reassign for evil! yow!
      ],
    });
  }

  pkg_ok($pkg);

  is($Totally::Not::Unique::foo, 10, "scalar assigned via data");
  is($Totally::Not::Unique::bar, 12, "another scalar assigned via data");
  isa_ok(
    $Totally::Not::Unique::obj,
    'Foo::Bar',
    "assignment of blessed ref via data went to scalar",
  );

  is(
    $Totally::Not::Unique::qux,
    undef,
    "of multiple assignments, the later sticks"
  );

  is(
    Totally::Not::Unique->foo,
    "Give me foo or give me death!",
    "sub assigned via data"
  );

  is_deeply(
    \@Totally::Not::Unique::foo,
    [ qw(a b c d) ],
    "array assigned via data"
  );

  is_deeply(
    \%Totally::Not::Unique::foo,
    { birth => 1978, death => 2862 },
    "hash assigned via array",
  );
}

{
  no warnings 'once';

  eval { Package::Generator->new_package({ data => [ "foo" ] }); };
  like($@, qr/must be even/, "you can't pass an list of non-pairs as data");
}

package Foo::Bar;
package Bar::Foo;
# if we don't declare these packages, we get a warning I'd never seen before:
# Can't locate package Foo::Bar for @Package::Generator::__GENERATED__::3::ISA
# ...pretty cool!
