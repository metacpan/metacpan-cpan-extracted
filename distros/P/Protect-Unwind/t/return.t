use strict;
use Test::More;
use Protect::Unwind;

if (eval { require Scope::Upper }) {
  plan tests => 4;
} else {
  plan skip_all => 'Scope::Upper is required for this test';
}

my $i = 0;

is($i++, 0, 'start');

my $cb; $cb = sub {
  protect {
    is($i++, 1, 'inside protected');
    Scope::Upper::unwind(undef, Scope::Upper::UP(Scope::Upper::UP(Scope::Upper::HERE())));
    die "Scope::Upper::unwind didn't work?";
  } unwind {
    is($i++, 2, 'inside after');
  };
  die "shouldn't get here";
};

$cb->();

is($i++, 3, 'all done');
