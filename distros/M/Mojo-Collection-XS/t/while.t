use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Test::More;

use Mojo::Collection;
use Mojo::Collection::XS;

subtest 'while_fast mirrors Mojo::Collection::each' => sub {
  my $xs   = Mojo::Collection::XS->new(qw/a b/);
  my $pure = Mojo::Collection->new(qw/a b/);

  my (@xs_seen, @pure_seen);

  my $ret_xs = $xs->while_fast(sub {
    my ($e, $num) = @_;
    push @xs_seen, [$e, $_, $num];
    $_ .= '!';
  });

  my $ret_pure = $pure->each(sub {
    my ($e, $num) = @_;
    push @pure_seen, [$e, $_, $num];
    $_ .= '!';
  });

  is($ret_xs,   $xs,   'while_fast returns self');
  is($ret_pure, $pure, 'each returns self');
  is_deeply(\@xs_seen, \@pure_seen, 'callback args and $_ alias match');
  is_deeply([@$xs],    [@$pure],    'collections mutated the same');
};

subtest 'while_ultra leaves $_ untouched' => sub {
  my $c = Mojo::Collection::XS->new(qw/foo bar/);
  my @calls;
  local $_ = 'outer';

  my $ret = $c->while_ultra(sub {
    my ($e, $num) = @_;
    push @calls, [$e, $num, $_];
  });

  is($ret, $c, 'returns same object');
  is_deeply(\@calls, [['foo', 1, 'outer'], ['bar', 2, 'outer']], 'uses @_ only');
  is($_, 'outer', '$_ unchanged');
};

subtest 'while_fast chained with Mojo map/grep matches pure pipeline' => sub {
  my $xs   = Mojo::Collection::XS->new(qw/a b c/);
  my $pure = Mojo::Collection->new(qw/a b c/);

  my $xs_out = $xs->while_fast(sub { $_ = uc $_ })->map(sub { $_[0] . '!' })->grep(sub { $_[0] ne 'B!' });

  my $pure_out = $pure->each(sub { $_ = uc $_ })->map(sub { $_[0] . '!' })->grep(sub { $_[0] ne 'B!' });

  is_deeply([@$xs_out], [@$pure_out], 'pipelines produce same output');
  is_deeply([@$xs],     [@$pure],     'original collections mutated equally');
};

subtest 'while_fast pipeline with Mojo helpers yields expected values' => sub {
  my $xs = Mojo::Collection::XS->new(1 .. 5);

  my $out = $xs->while_fast(sub { $_ *= 3 })    # mutate in XS
    ->map(sub { $_[0] + 1 })                    # Mojo map
    ->grep(sub { $_[0] % 2 == 0 })              # Mojo grep
    ->reverse                                   # Mojo reverse
    ->to_array;                                 # Mojo to_array

  is_deeply($out, [16, 10, 4], 'combined pipeline returns expected values');
  is_deeply([@$xs], [3, 6, 9, 12, 15], 'while_fast mutation reflected in original');
};

done_testing;
