#!perl -T
use strict;
use warnings;

use Test::More tests => 24;

BEGIN {
  use_ok('Package::Generator');
  use_ok('Package::Reaper');
}

{ # test reaping a coded package
  {
    package Test::Package::Reaper;
    sub foo { return 1 }
  }

  is(
    Test::Package::Reaper->foo,
    1,
    "our method responds correctly",
  );

  {
    my $reaper = Package::Reaper->new('Test::Package::Reaper');

    is($reaper->package, 'Test::Package::Reaper', "package is set");

    eval { $reaper->package('New::Package'); };
    like($@, qr/may not be altered/, "->package isn't a mutator");
  }

  my $x = eval { Test::Package::Reaper->foo };
  ok($@, "we can no longer call our method, after reaping");
  is($x, undef, "so the result of eval was undef");

  ok(
    ! Package::Generator->package_exists('Test::Package::Reaper'),
    "P::G says package no longer exists",
  );
}

{ # test reaping a coded package -- with one-part name
  {
    package TestPackageReaper;
    sub bar { return 1 }
  }

  is(
    TestPackageReaper->bar,
    1,
    "our method responds correctly",
  );

  {
    my $reaper = Package::Reaper->new('TestPackageReaper');
  }

  my $x = eval { TestPackageReaper->bar };
  ok($@, "we can no longer call our method, after reaping");
  is($x, undef, "so the result of eval was undef");

  ok(
    ! Package::Generator->package_exists('TestPackageReaper'),
    "P::G says package no longer exists",
  );
}

{ # test reaping a generated package
  my $pkg = Package::Generator->new_package;

  ok(
    Package::Generator->package_exists($pkg),
    "a newly generated package exists: $pkg",
  );

  {
    my $reaper = Package::Reaper->new($pkg);
    isa_ok($reaper, 'Package::Reaper', "the reaper");

    ok(
      Package::Generator->package_exists($pkg),
      "package to reap still exists",
    );
  }

  ok(
    ! Package::Generator->package_exists($pkg),
    "after reaper is gone, the package is reaped; RIP",
  );
}

{ # disarmed reaper
  my $pkg = Package::Generator->new_package;

  ok(
    Package::Generator->package_exists($pkg),
    "a newly generated package exists: $pkg",
  );

  {
    my $reaper = Package::Reaper->new($pkg);
    isa_ok($reaper, 'Package::Reaper', "the reaper");

    $reaper->disarm;

    ok(
      Package::Generator->package_exists($pkg),
      "package to reap still exists",
    );
  }

  ok(
    Package::Generator->package_exists($pkg),
    "after reaper is gone, the package is not reaped; we disarmed!",
  );
}

{ # disarm, rearm
  my $pkg = Package::Generator->new_package;

  ok(
    Package::Generator->package_exists($pkg),
    "a newly generated package exists: $pkg",
  );

  {
    my $reaper = Package::Reaper->new($pkg);
    isa_ok($reaper, 'Package::Reaper', "the reaper");

    ok(
      Package::Generator->package_exists($pkg),
      "package to reap still exists",
    );

    $reaper->disarm;
    $reaper->arm;
  }

  ok(
    ! Package::Generator->package_exists($pkg),
    "after reaper is gone, the package is reaped; RIP",
  );
}
