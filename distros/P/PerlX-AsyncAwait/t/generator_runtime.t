use strictures 2;
use PerlX::Generator::Runtime;
use Test::More;

my @got;

my $gen = generator {
  __gen_resume;
  my ($x) = @_;
  __gen_suspend '__GEN_1', $x; __GEN_1: __gen_sent;
  while ($x--) {
    my $sent = do { __gen_suspend '__GEN_2', $x; __GEN_2: __gen_sent };
    push @got, $sent if $sent;
  }
  return;
};

my $inv = $gen->start(5);

push @got, $inv->next;
push @got, $inv->next;
push @got, $inv->next('foo');

while (defined(my $val = $inv->next)) {
  push @got, $val;
}

is_deeply(
  \@got,
  [ 5, 4, 'foo', 3, 2, 1, 0 ],
  'Generator results ok'
);

ok($inv->done, 'Generator marked done');

done_testing;
