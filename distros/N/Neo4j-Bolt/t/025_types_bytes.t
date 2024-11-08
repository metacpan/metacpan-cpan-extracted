use v5.12;
use warnings;
use Test::More;
use Test::Neo4j::Types;
use Neo4j::Bolt::NeoValue;
use Encode ();

plan tests => 5;

sub new_bytearray {
  my $class = shift // 'Neo4j::Bolt::Bytes';
  my $bytes = shift->{as_string};
  Encode::_utf8_off $bytes;
  return bless \$bytes, $class;
}

neo4j_bytearray_ok 'Neo4j::Bolt::Bytes', \&new_bytearray;

my $ba = new_bytearray(undef, {as_string => "\x{80}qbSD5&"});
my $v = Neo4j::Bolt::NeoValue->_new_from_perl($ba);
is $v->_neotype, "Bytes", "Neo4j type Bytes";

my $vv = $v->_as_perl;
ok ref($vv), "roundtrip procudes blessed ref";
SKIP: {
  skip "no blessed ref", 1 unless ref($vv);
  is $$vv, $$ba, "Bytes roundtrip";
}

{
no warnings 'deprecated';
is "$vv", $$ba, "qq overloaded for Bytes";
}

done_testing;
