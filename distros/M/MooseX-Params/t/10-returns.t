use strict;
use warnings;

use Test::Most;
use MooseX::Params;
use Carp::Always;

sub foo      :Args(bar) :Returns(Str) { 'baz' }
sub crash    :Returns(Str)            { ['boom'] }
sub stuff    :Returns(Array[Str])     { qw(foo bar baz) }
sub stuffref :Returns(ArrayRef[Str])  { [qw(foo bar baz)] }
sub dict     :Returns(Hash[Str])      { foo => 'bar', baz => 'quz' }
sub dictref  :Returns(HashRef[Str])   { { foo => 'bar', baz => 'quz' } }

is foo('bar'), 'baz',  "returns with signature";
throws_ok ( sub { crash('bar') }, qr/Validation failed/, "returns without signature" );

my $foo_array = [qw(foo bar baz)];
my $foo_hash  = { foo => 'bar', baz => 'quz' };

my @stuff = stuff();
my $stuffref = stuffref();
my %dict = dict();
my $dictref = dictref();

is_deeply \@stuff, $foo_array, "returns array";
is_deeply $stuffref, $foo_array, "returns arrayref";
is_deeply \%dict, $foo_hash, "returns hash";
is_deeply $dictref, $foo_hash, "returns hashref";

done_testing;
