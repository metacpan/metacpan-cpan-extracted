use strict;
use warnings;
use Test::More;
use Package::Abbreviate;

my @tests = (
  [10, [qw/Foo::Bar Foo::Baz/] => [qw/Foo::Bar Foo::Baz/]],
  [7, [qw/Foo::Bar Foo::Baz/] => [qw/F::Bar F::Baz/]],
  [5, [qw/Foo::Bar Foo::Baz/] => undef], # too short not to be duped
  [5, [qw/Foo::Bar Foo::Bar/] => [qw/F::B F::B/]], # packages are also duped
);

for my $test (@tests) {
  my $p = Package::Abbreviate->new($test->[0], {eager => 1, croak => 1});
  my @abbrs = eval { $p->abbr(@{$test->[1]}) };
  if ($test->[2]) {
    is_deeply \@abbrs => $test->[2], join ',', @{$test->[2]};
  } else {
    ok $@, "error: $test->[0]";
  }
}

done_testing;
