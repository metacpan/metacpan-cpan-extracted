use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Test::More;

use Mojo::Collection;
use Mojo::Collection::XS;

subtest 'each_fast aliases $_ and matches Mojo::Collection::each' => sub {
  my $xs   = Mojo::Collection::XS->new(1, 2);
  my $pure = Mojo::Collection->new(1, 2);
  my (@xs_seen, @pure_seen);

  my $ret_xs = $xs->each_fast(sub {
    my ($e, $num) = @_;
    push @xs_seen, [$e, $_, $num];
    $_ *= 3;
  });

  my $ret_pure = $pure->each(sub {
    my ($e, $num) = @_;
    push @pure_seen, [$e, $_, $num];
    $_ *= 3;
  });

  is($ret_xs,   $xs,   'each_fast returns self');
  is($ret_pure, $pure, 'each returns self');
  is_deeply(\@xs_seen, \@pure_seen, 'callback args and $_ alias match');
  is_deeply([@$xs],    [@$pure],    'collections mutated equally');
};

subtest 'each_fast chained with Mojo map/grep matches pure pipeline' => sub {
  my $xs   = Mojo::Collection::XS->new(qw/a b c/);
  my $pure = Mojo::Collection->new(qw/a b c/);

  my $xs_out = $xs->each_fast(sub { $_ = uc $_ })->map(sub { $_[0] . '!' })->grep(sub { $_[0] ne 'B!' });

  my $pure_out = $pure->each(sub { $_ = uc $_ })->map(sub { $_[0] . '!' })->grep(sub { $_[0] ne 'B!' });

  is_deeply([@$xs_out], [@$pure_out], 'pipelines produce same output');
  is_deeply([@$xs],     [@$pure],     'original collections mutated equally');
};

subtest 'each_fast with Mojo reverse/head yields expected slice' => sub {
  my $xs = Mojo::Collection::XS->new(qw/x y z/);

  my $slice = $xs->each_fast(sub { $_ = uc $_ })    # [X,Y,Z]
    ->reverse                                       # [Z,Y,X]
    ->head(2)                                       # [Z,Y]
    ->to_array;

  is_deeply($slice, [qw/Z Y/],   'reverse then head returns expected items');
  is_deeply([@$xs], [qw/X Y Z/], 'each_fast mutation reflected');
};

done_testing;
