use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Test::More;

use Mojo::Collection::XS;

subtest 'while_fast aliases $_ and returns self' => sub {
  my $c = Mojo::Collection::XS->new(qw/a b c/);
  my (@seen, @idx);

  my $ret = $c->while_fast(sub {
    my ($e, $num) = @_;
    push @seen, $e;
    push @idx,  $num;
    $_ .= '!';
  });

  is($ret, $c, 'returns same object');
  is_deeply(\@seen, [qw/a b c/],    'saw elements');
  is_deeply(\@idx,  [1, 2, 3],      '1-based index');
  is_deeply([@$c],  [qw/a! b! c!/], '$_ aliased to elements');
};

subtest 'while_ultra keeps $_ untouched' => sub {
  my $c = Mojo::Collection::XS->new(qw/foo bar/);
  my @calls;
  local $_ = 'outer';

  my $ret = $c->while_ultra(sub {
    my ($e, $num) = @_;
    push @calls, [$e, $num, $_];
  });

  is($ret, $c, 'returns same object');
  is_deeply(\@calls, [['foo', 1, 'outer'], ['bar', 2, 'outer']], 'uses @_ args only');
  is($_, 'outer', 'outer $_ unchanged');
};

subtest 'each_fast aliases $_ and returns self' => sub {
  my $c = Mojo::Collection::XS->new(1, 2);
  my @pairs;

  my $ret = $c->each_fast(sub {
    my ($e, $num) = @_;
    push @pairs, [$e, $_, $num];
    $_ *= 2;
  });

  is($ret, $c, 'returns same object');
  is_deeply(\@pairs, [[1, 1, 1], [2, 2, 2]], 'saw element, $_ alias, index');
  is_deeply([@$c], [2, 4], 'elements mutated through $_ alias');
};

subtest 'map_fast returns new collection with list context values' => sub {
  my $c = Mojo::Collection::XS->new(1, 2);

  my $mapped = $c->map_fast(sub {
    my ($e) = @_;
    return ($e * 2, $e + 1);
  });

  isa_ok($mapped, 'Mojo::Collection::XS', 'mapped class preserved');
  isnt($mapped, $c, 'returns new object');
  is_deeply([@$mapped], [2, 2, 4, 3], 'list results flattened');
};

subtest 'map_ultra returns new collection with scalar results via @_ only' => sub {
  my $c = Mojo::Collection::XS->new(1, 2);
  local $_ = 'outer';

  my $mapped = $c->map_ultra(sub {
    my ($e) = @_;
    is($_, 'outer', '$_ untouched in ultra map');
    return $e + 1;
  });

  isa_ok($mapped, 'Mojo::Collection::XS', 'mapped class preserved');
  isnt($mapped, $c, 'returns new object');
  is_deeply([@$mapped], [2, 3], 'scalar results collected');
};

subtest 'grep_fast filters with alias to $_' => sub {
  my $c = Mojo::Collection::XS->new(qw/a b c d/);

  my $filtered = $c->grep_fast(sub {
    my ($e) = @_;
    state $i = 0;
    my $num = ++$i;
    $_ .= $num;
    return $num % 2;
  });

  isa_ok($filtered, 'Mojo::Collection::XS', 'filtered class preserved');
  is_deeply([@$c],        [qw/a1 b2 c3 d4/], 'alias mutates original elements');
  is_deeply([@$filtered], [qw/a1 c3/],       'only truthy callbacks kept');
};

subtest 'croaks on non-code callback' => sub {
  my $c = Mojo::Collection::XS->new(1);
  eval { $c->while_fast('not code') };
  like($@, qr/callback must be a CODE ref/, 'croaks with helpful message');
};

done_testing;
