use strict;

use Test::More qw/no_plan/;
use Math::Int64 qw/int64 uint64/;
use List::Util qw/shuffle/;

use Qstruct;

my $type_specs = {
  string => {
    vals => ["", "asdf", "QQQQQQQQQQQQQQQ", "ZZZZZZZZZZZZZZZ", "roflcopter"x1000],
    no_array_fixed => 1,
  },
  blob => {
    vals => ["", "asdf", "roflcopter"x1000],
    no_array_fixed => 0,
  },
  bool => {
    vals => [0, 1],
    no_array_dyn => 0,
    no_array_fixed => 0,
  },
  int8 => {
    vals => [0, 1, -1, 127],
  },
  uint8 => {
    vals => [0, 198, 255],
  },
  int16 => {
    vals => [0, -10, -32767],
  },
  uint16 => {
    vals => [0, 12345, 65535],
  },
  int32 => {
    vals => [0, -100, 2147483647],
  },
  uint32 => {
    vals => [0, 2713640343, 4294967295],
  },
  int64 => {
    vals => [int64('0'), int64('-1000'), int64('9223372036854775807')],
  },
  uint64 => {
    vals => [uint64('0'), uint64('9876543210'), uint64('18446744073709551616')],
  },
  float => {
    vals => [0, -1.2339999744e+10],
  },
  double => {
    vals => [0, 1.28089993101642e-31],
  },
};


my $curr_test = 0;

sub run_test {
  my @args = @_;

  my $schema = "qstruct TestSchema {\n";

  for my $i (0..$#args) {
    $args[$i] =~ s/\[x\]$/'['.int(rand(20)).']'/e;
    $schema .= "item$i \@$i $args[$i];\n";
  }

  $schema .= "}\n";

  #print STDERR "SCHEMA: $schema\n";

  Qstruct::load_schema($schema);

  my $builder = TestSchema->build;

  my @build_order = shuffle 0..$#args;
  my @test_vals;

  for my $i (@build_order) {
    my $method = "item$i";
    $test_vals[$i] = gen_rand_vals($args[$i]);
    #use Data::Dumper; print STDERR "$method: ".Dumper($test_vals[$i]);
    $builder->$method($test_vals[$i]);
  }

  my $encoded = $builder->encode;
  undef $builder;

  #print $encoded;

  my $obj = TestSchema->decode($encoded);

  for my $i (0..$#args) {
    my $method = "item$i";
    my $val = $obj->$method;
    is_deeply($val, $test_vals[$i], "$args[$i] ($curr_test, $i)");
  }

  $curr_test++;
}

sub gen_rand_vals {
  my $spec = shift;

  $spec =~ m/^(\w+)/ || die "unknown type spec [$spec]";
  my $type = $1;

  my $type_spec = $type_specs->{$type} || die;

  if ($spec =~ m/\[(\d+)\]$/) {
    my $array_size = $1;
    die "$type can't be fixed array" if $type_spec->{no_array_fixed};
    return [ map { pick_rand($type_spec->{vals}) } 1..$array_size ];
  } elsif ($spec =~ m/\[\]$/) {
    die "$type can't be dyn array" if $type_spec->{no_array_dyn};
    return [ map { pick_rand($type_spec->{vals}) } 0..int(rand(100)) ];
  } else {
    return pick_rand($type_spec->{vals});
  }
}

sub pick_rand {
  my $arr_ref = shift;
  return $arr_ref->[int(rand(scalar @$arr_ref))];
}





srand(0);

for (1 .. ($ENV{QSTRUCT_TEST_ROUNDTRIP_ITERS} || 10)) {
  run_test(qw{ int8 uint8 int16 uint16 int32 uint32 int64 uint64 bool string blob float double }x4);
  run_test(qw{ int8 bool string[] bool uint64[4] float });
  run_test(qw{ string[] blob[] string[] string[] blob[] });
  run_test((qw{ bool int8 }) x 9);
  run_test(qw{ int8[] uint8[] int16[] uint16[] int32[] uint32[] int64[] uint64[] string[] blob[] float[] double[] }x10);
  run_test(qw{ int8[x] uint8[x] int16[x] uint16[x] int32[x] uint32[x] int64[x] uint64[x] float[x] double[x] }x10);
}
