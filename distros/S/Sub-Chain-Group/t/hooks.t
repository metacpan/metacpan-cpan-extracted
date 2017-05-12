# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.88;

my $mod = 'Sub::Chain::Group';
eval "require $mod";

my $last_hook;
sub hook_type {
  my $r = shift;
  if( ref($r) eq 'HASH' ){
    $last_hook = $r->{type} = 'hash'
  }
  elsif( ref $r ){
    unshift(@$r, $last_hook = 'array');
  }
  else {
    $r .= $last_hook = 'string';
  }
  return $r;
}

sub last_hook_was {
  my ($in, $hooked) = @_;
  $hooked ||= $in;
  is $last_hook, $hooked, "hook with $in called as $hooked";
}

sub run_tests {
  my ($in, $exp) = @_;
  my $chain = new_chain();
  my @in_k = sort keys %$in;
  my @out_k = (@in_k, 'debug');

  is_deeply($chain->call($in), { type => 'hash', %$exp }, 'hash transformed');
  last_hook_was 'hash';

  is_deeply($chain->call(\@in_k, [@$in{@in_k}]), [array => @$exp{@out_k}], 'array transformed');
  last_hook_was 'array';

  {
    my $chain2 = new_chain(hook_as_hash => 1);

    # we don't get the extra fields on this one because they were set on the hash
    is_deeply($chain2->call(\@in_k, [@$in{@in_k}]), [@$exp{@in_k}], 'array transformed as hash');
    last_hook_was array => 'hash';

    is $chain2->call(shape => 'square'), 'SQUARE', 'transformed string';
    last_hook_was string => 'hash';
  }

  is $chain->call(shape => 'square'), 'SQUAREstring', 'transformed string with hook as string';
  last_hook_was 'string';
}

sub up { uc $_[0] };
sub x10 { $_[0] * 10 }

sub desc {
  my $d = shift;
  if( ref $d eq 'HASH' ){
    no warnings 'uninitialized'; # hook_as_hash won't have some of these
    $d->{desc} = $d->{sprinkles}
      ? "$d->{desc} with $d->{sprinkles} sprinkles"
      : "$d->{shape} with $d->{desc}";
  }
  elsif( ref $d eq 'ARRAY' ){
    $d->[0] = $d->[2]
      ? "$d->[0] with $d->[2] sprinkles"
      : "$d->[1] with $d->[0]";
  }
  $d;
}

sub debug {
  my $d = shift;
  if( ref $d eq 'HASH' ){
    no warnings 'uninitialized'; # hook_as_hash won't have some of these
    $d->{debug} = substr($d->{shape}, 0, 1) . "/" . $d->{sprinkles};
  }
  elsif( ref $d eq 'ARRAY' ){
    push @$d, substr($d->[1], 0, 1) . "/" . $d->[2];
  }
  $d;
}

sub new_chain {
  my $chain = new_ok($mod, [@_]);
  $chain->append(\&up,    fields => 'shape');
  $chain->append(\&x10,   fields => ['sprinkles']);
  $chain->append(\&desc,  hook => 'before');
  $chain->append(\&debug, hook => ['after']);
  $chain->append(\&hook_type, hook => 'after');
  return $chain;
}

run_tests(
  {
    shape => 'round',
    sprinkles => 45,
    desc => 'blue frosting',
  },
  {
    shape => 'ROUND',
    sprinkles => 450,
    desc => 'blue frosting with 45 sprinkles',
    debug => 'R/450',
  },
);

run_tests(
  {
    shape => 'round',
    sprinkles => 0,
    desc => 'blue frosting',
  },
  {
    shape => 'ROUND',
    sprinkles => 0,
    desc => 'round with blue frosting',
    debug => 'R/0',
  },
);

done_testing;
