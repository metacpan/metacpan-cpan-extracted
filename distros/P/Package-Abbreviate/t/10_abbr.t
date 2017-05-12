use strict;
use warnings;
use Test::More;
use Package::Abbreviate;

my $package = "Foo::Bar::TooLong::PackageName";

{ # default
  my @tests = (
    [ 30 => 'Foo::Bar::TooLong::PackageName' ],
    [ 28 => 'F::Bar::TooLong::PackageName' ],
    [ 26 => 'F::B::TooLong::PackageName' ],
    [ 24 => 'F::B::TL::PackageName' ],
    [ 20 => undef ], # too short
  );

  for my $test (@tests) {
    my $p = Package::Abbreviate->new($test->[0], {croak => 1});
    is $test->[1] => eval { $p->abbr($package) } => $test->[1] || "error: $test->[0]";
    note $@ if $test->[1] && $@;
  }
}

{ # eager
  my @tests = (
    [ 30 => 'Foo::Bar::TooLong::PackageName' ],
    [ 28 => 'F::Bar::TooLong::PackageName' ],
    [ 26 => 'F::B::TooLong::PackageName' ],
    [ 24 => 'F::B::TL::PackageName' ],
    [ 20 => 'FB::TL::PackageName' ],
    [ 18 => 'FBTL::PackageName' ],
    [ 16 => 'F::B::TL::PN' ],
    [ 10 => 'FBTLPN' ],
    [ 5 => undef ], # too short
  );

  for my $test (@tests) {
    my $p = Package::Abbreviate->new($test->[0], {eager => 1, croak => 1});
    is $test->[1] => eval { $p->abbr($package) } => $test->[1] || "error: $test->[0]";
    note $@ if $test->[1] && $@;
  }
}

done_testing;
