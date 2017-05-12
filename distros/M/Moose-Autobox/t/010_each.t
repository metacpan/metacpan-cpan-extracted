use strict;
use warnings;

use Test::More tests => 11;

require_ok('Moose::Autobox');

use Moose::Autobox;

{
  my %hash = (
    a => 1,
    b => 2,
    c => 3,
  );

  my $href = { %hash };

  is_deeply($href, \%hash, "sanity check to start");

  my @keys;
  $href->each_key(sub { push @keys, $_ });
  is_deeply([ sort @keys ], [ sort keys %hash ], "keys found via each_key");

  my @values;
  $href->each_value(sub { push @values, $_ });
  is_deeply([ sort @values ], [ sort values %hash ], "values via each_values");

  $href->each_value(sub { $_++ });
  is($href->{a}, 2, "we can ++ values directly");

  $href->each_key(sub { $_ = "$_$_" });
  ok(! exists $href->{aa}, "we cannot alter keys directly");
}

{
  my @array = qw(foo bar baz);

  my $aref = [ @array ];

  is_deeply($aref, \@array, "sanity check to start");

  my @keys;
  $aref->each_key(sub { push @keys, $_ });
  is_deeply([ @keys ], [ 0, 1, 2 ], "keys found via each_key");

  my @values;
  $aref->each_value(sub { push @values, $_ });
  is_deeply([ @values ], [ @array ], "values via each_values");

  $aref->each_value(sub { $_ = uc });
  is($aref->[0], 'FOO', "we can alter values directly");

  $aref->each_key(sub { $_ = $_ + 1 });
  ok(! $aref->[3], "we cannot alter keys directly");
}
