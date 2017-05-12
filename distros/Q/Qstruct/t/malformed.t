use strict;

use Test::More qw/no_plan/;
use Math::Int64;

use Qstruct;


sub LEU32 {
  return pack("V", $_[0]);
}

sub LEU64 {
  ## This hack is because pack("Q") won't work on 32 bit perls
  ## and Math::Int64 doesn't have uint64_to_little()
  return join("", split(//, reverse(Math::Int64::uint64_to_net($_[0]))));
}


run(
  name => "truncated header",

  data => "\x00"x15,

  sanity_should_fail => 1,
);


run(
  name => "body size longer than msg",

  schema => q{ a @0 uint64; },

  data => "\x00"x8 . LEU32(1) . LEU32(1),

  sanity_should_fail => 1,

  cb => sub {
    my ($obj, $name) = @_;
    is($obj->a, 0, "$name: a is default");
  },
);



run(
  name => "under-length string",

  schema => q{ a @0 string; },

  data => "\x00"x8 . LEU32(16 + 20) . LEU32(1) . LEU64(20 << 8) . LEU64(32) . "Q"x19,

  sanity_should_fail => 1,

  cb => sub {
    my ($obj, $name) = @_;

    eval { $obj->a };
    like($@, qr/malformed/i, "$name: accessor threw an exception");
  },
);


run(
  name => "string pointer points beyond message end",

  schema => q{ a @0 string; },

  data => "\x00"x8 . LEU32(16 + 20) . LEU32(1) . LEU64(20 << 8) . LEU64(33) . "Q"x20,

  cb => sub {
    my ($obj, $name) = @_;

    eval { $obj->a };
    like($@, qr/malformed/i, "$name: accessor threw an exception");
  },
);




sub run {
  my (%args) = @_;

  Qstruct::load_schema("qstruct TestSchema { $args{schema} }");

  my $sanity_check_result = Qstruct::Runtime::sanity_check($args{data});
  is(!$args{sanity_should_fail},
     !$sanity_check_result,
     "$args{name}: sanity check should " . ($args{sanity_should_fail} ? 'fail' : 'pass'));

  ## This encapsulation break is to test the accessors even if the sanity check is bypassed somehow
  my $obj = bless { e => \$args{data}, }, 'TestSchema::Loader';

  $args{cb}->($obj, $args{name})
    if $args{cb};
}
