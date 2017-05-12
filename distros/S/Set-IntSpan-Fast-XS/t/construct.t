use strict;
use warnings;
use Test::More;
use Set::IntSpan::Fast::XS;

my @schedule;

BEGIN {
  @schedule = (
    {
      name   => 'No args',
      args   => [],
      expect => [],
    },
    {
      name   => 'String arg',
      args   => ['1-10, 20, 30'],
      expect => [ 1 .. 10, 20, 30 ],
    },
    {
      name   => 'Numeric args',
      args   => [ 1, 3, 5, 7, 9 ],
      expect => [ 1, 3, 5, 7, 9 ],
    },
  );

  plan tests => scalar( @schedule ) * 3;
}

for my $test ( @schedule ) {
  my $name = $test->{name};
  my $args = $test->{args};
  ok my $set = Set::IntSpan::Fast::XS->new( @$args ),
   "$name: set created OK";
  isa_ok $set, 'Set::IntSpan::Fast::XS';
  my @got = $set->as_array();
  is_deeply \@got, $test->{expect}, "$name: contents OK";
}
