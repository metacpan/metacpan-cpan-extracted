use strict;
use warnings;
use lib 'lib';
use Test::More tests => 3;

{
  package Class;
  use Moose;

  use MooseX::Storage;
  with Storage(format => 'JSONpm');

  has foo => (
    is  => 'rw',
    isa => 'Str',
  );
}

use utf8;

{
  my $obj  = Class->new(foo => "ascii string");
  my $pack = JSON->new->decode( $obj->freeze );
  is($pack->{foo}, $obj->foo, "foo roundtripped");
}

{
  my $obj  = Class->new(foo => "ascîî string");
  my $pack = JSON->new->decode( $obj->freeze );
  is($pack->{foo}, $obj->foo, "foo roundtripped");
  like($obj->freeze, qr{\A[\x01-\x7f]+\z}, "no 8-bit chars");
}
