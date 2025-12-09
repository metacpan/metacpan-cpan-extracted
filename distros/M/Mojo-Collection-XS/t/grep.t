use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Test::More;

use Mojo::Collection;
use Mojo::Collection::XS;

subtest 'grep_fast filters with $_ alias like Mojo::Collection::grep' => sub {
  my $xs   = Mojo::Collection::XS->new(qw/a b c d/);
  my $pure = Mojo::Collection->new(qw/a b c d/);

  my $counter = 0;
  my $cb      = sub {
    my ($e) = @_;
    my $num = ++$counter;
    $_ .= $num;    # aliasing check
    return $num % 2;
  };

  my $xs_out = $xs->grep_fast($cb);
  $counter = 0;
  my $pure_out = $pure->grep($cb);

  isa_ok($xs_out,   'Mojo::Collection::XS', 'xs grep returns XS collection');
  isa_ok($pure_out, 'Mojo::Collection',     'pure grep returns Mojo collection');
  is_deeply([@$xs_out], [@$pure_out], 'outputs match');
  is_deeply([@$xs],     [@$pure],     'original collections mutated equally');
};

subtest 'grep_fast chained into Mojo map matches pure pipeline' => sub {
  my $xs   = Mojo::Collection::XS->new(qw/red blue green/);
  my $pure = Mojo::Collection->new(qw/red blue green/);

  my $xs_out   = $xs->grep_fast(sub { $_ =~ /e/ })->map(sub { uc $_[0] });
  my $pure_out = $pure->grep(sub { $_    =~ /e/ })->map(sub { uc $_[0] });

  is_deeply([@$xs_out], [@$pure_out], 'grep_fast → map matches pure pipeline');
};

subtest 'grep_fast then Mojo each mirrors pure grep pipeline' => sub {
  my $xs   = Mojo::Collection::XS->new(qw/aa bb cc/);
  my $pure = Mojo::Collection->new(qw/aa bb cc/);

  my (@xs_seen, @pure_seen);

  my $xs_out   = $xs->grep_fast(sub { $_ =~ /b/ });
  my $pure_out = $pure->grep(sub { $_    =~ /b/ });

  $xs_out->each(sub {
    my ($e, $num) = @_;
    push @xs_seen, [$num, $e, $_];
  });

  $pure_out->each(sub {
    my ($e, $num) = @_;
    push @pure_seen, [$num, $e, $_];
  });

  is_deeply([@$xs_out], [@$pure_out], 'filtered results match');
  is_deeply(\@xs_seen,  \@pure_seen,  'each over filtered results matches');
};

subtest 'grep_fast with Mojo map/head produces expected array' => sub {
  my $xs = Mojo::Collection::XS->new(1 .. 5);

  my $out = $xs->grep_fast(sub { $_ % 2 })    # keep odd: 1,3,5
    ->map(sub { $_[0] * 2 })                  # 2,6,10
    ->head(2)                                 # 2,6
    ->to_array;

  is_deeply($out, [2, 6], 'filtered and transformed odds as expected');
  is_deeply([@$xs], [1, 2, 3, 4, 5], 'original collection unchanged aside from alias append');
};

done_testing;
