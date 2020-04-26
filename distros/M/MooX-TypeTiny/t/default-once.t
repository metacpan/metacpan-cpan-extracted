use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Type::Tiny;
use Sub::Quote qw(quote_sub);

BEGIN {
  package MooClassMXTT;
  use Moo;
  use MooX::TypeTiny;
  use Types::Standard qw(Bool);

  has calls => (is => 'rwp', default => 0);

  has bool_coerce => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->_set_calls($_[0]->calls+1); 0 },
    isa => Bool,
    coerce => 1,
  );
}

my $o = MooClassMXTT->new;
$o->bool_coerce;
is $o->calls, 1;

done_testing;
