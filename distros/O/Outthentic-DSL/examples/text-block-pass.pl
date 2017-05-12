use Outthentic::DSL;

my $otx = Outthentic::DSL->new(<<'HERE');
  this string followed by
  that string followed by
  another one string
  with that string
  at the very end.
HERE

$otx->validate(<<'CHECK');

  # this text block
  # consists of 5 strings
  # going consecutive

  begin:
      # plain strings
      this string followed by
      that string followed by
      another one
      # regexps patterns:
      regexp: with\s+(this|that)
      # and the last one in a block
      at the very end
  end:

CHECK

for my $r (@{$otx->results}) {
    print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
}

