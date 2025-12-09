use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Test::More;

use Mojo::Collection;
use Mojo::Collection::XS;

subtest 'map_fast matches Mojo::Collection::map' => sub {
  my $xs   = Mojo::Collection::XS->new(qw/a b/);
  my $pure = Mojo::Collection->new(qw/a b/);

  my $cb = sub {
    my ($e) = @_;
    $_ .= '!';    # verify aliasing
    return ($e, uc $_);
  };

  my $xs_out   = $xs->map_fast($cb);
  my $pure_out = $pure->map($cb);

  isa_ok($xs_out,   'Mojo::Collection::XS', 'xs map returns XS collection');
  isa_ok($pure_out, 'Mojo::Collection',     'pure map returns Mojo collection');
  is_deeply([@$xs_out], [@$pure_out], 'outputs match');
  is_deeply([@$xs],     [@$pure],     'original collections mutated equally');
};

subtest 'map_ultra keeps $_ untouched and returns scalar list' => sub {
  my $c = Mojo::Collection::XS->new(1, 2);
  local $_ = 'outer';

  my $mapped = $c->map_ultra(sub {
    my ($e) = @_;
    is($_, 'outer', '$_ untouched inside callback');
    return $e + 1;
  });

  isa_ok($mapped, 'Mojo::Collection::XS', 'class preserved');
  is_deeply([@$mapped], [2, 3], 'scalar results collected');
  is($_, 'outer', 'outer $_ intact');
};

subtest 'map_ultra output aligns with Mojo::Collection map' => sub {
  my $xs   = Mojo::Collection::XS->new(1, 2, 3);
  my $pure = Mojo::Collection->new(1, 2, 3);

  my $xs_out   = $xs->map_ultra(sub { my ($e) = @_; $e * 2 });
  my $pure_out = $pure->map(sub { my ($e)     = @_; $e * 2 });

  is_deeply([@$xs_out], [@$pure_out], 'ultra map matches pure map values');
};

subtest 'map_fast followed by Mojo grep/each matches pure pipeline' => sub {
  my $xs   = Mojo::Collection::XS->new(1, 2, 3, 4);
  my $pure = Mojo::Collection->new(1, 2, 3, 4);

  my (@xs_seen, @pure_seen);

  my $xs_out = $xs->map_fast(sub { $_ *= 2; $_ })->grep(sub { $_[0] > 4 });

  my $pure_out = $pure->map(sub { $_ *= 2; $_ })->grep(sub { $_[0] > 4 });

  $xs_out->each(sub {
    my ($e, $num) = @_;
    push @xs_seen, [$num, $e, $_];
  });

  $pure_out->each(sub {
    my ($e, $num) = @_;
    push @pure_seen, [$num, $e, $_];
  });

  is_deeply([@$xs_out], [@$pure_out], 'map_fast → grep matches pure map → grep');
  is_deeply(\@xs_seen,  \@pure_seen,  'each over filtered results matches');
  is_deeply([@$xs],     [@$pure],     'original collections mutated equally by map');
};

subtest 'map_ultra results consumed by Mojo each match pure pipeline' => sub {
  my $xs   = Mojo::Collection::XS->new(qw/foo bar baz/);
  my $pure = Mojo::Collection->new(qw/foo bar baz/);

  my (@xs_seen, @pure_seen);

  my $xs_out   = $xs->map_ultra(sub { length $_[0] });
  my $pure_out = $pure->map(sub { length $_[0] });

  $xs_out->each(sub {
    my ($e, $num) = @_;
    push @xs_seen, [$num, $e, $_];
  });

  $pure_out->each(sub {
    my ($e, $num) = @_;
    push @pure_seen, [$num, $e, $_];
  });

  is_deeply([@$xs_out], [@$pure_out], 'map_ultra output matches pure map output');
  is_deeply(\@xs_seen,  \@pure_seen,  'Mojo each over map_ultra result matches');
};

subtest 'map_fast with Mojo uniq/sort/join yields expected string' => sub {
  my $xs = Mojo::Collection::XS->new(qw/a b a b c/);

  my $out = $xs->map_fast(sub { uc $_ })->uniq->sort(sub { $_[0] cmp $_[1] })->join(',');

  is($out, 'A,B,C', 'unique sorted uppercase values joined correctly');
  is_deeply([@$xs], [qw/a b a b c/], 'original collection unchanged by pure transform');
};

subtest 'map_ultra with Mojo head/reduce produces expected aggregate' => sub {
  my $xs = Mojo::Collection::XS->new(2, 4, 6, 8);

  my $head = $xs->map_ultra(sub { $_[0] * 2 })    # [4,8,12,16]
    ->head(3);                                    # [4,8,12]

  my $sum_head = 0;
  $head->each(sub { $sum_head += $_[0] });        # Mojo each

  is($sum_head, 24, 'map_ultra + head + each sum computed correctly');
};

done_testing;
