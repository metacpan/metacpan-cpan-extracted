use Mojo::Base -strict;
use Test::More;
use Mojo::YR;

plan skip_all => 'LIVE_TEST=1 is not set' unless $ENV{LIVE_TEST};

my $yr = Mojo::YR->new;
my @res;

{
  $yr->location_forecast([59, 10], sub { @res = @_; Mojo::IOLoop->stop; });
  Mojo::IOLoop->start;

  is $res[0], $yr, 'callback receive $yr';
  is $res[1], '', 'callback without error';
  isa_ok($res[2], 'Mojo::DOM');

  my $now  = $res[2]->find('time')->first;
  my $temp = $now->at('temperature');

  diag "$temp->{value} $temp->{unit}";
  like "$temp->{value} $temp->{unit}", qr{^[\d\.]+ celsius$},
    'got temperature';
}

done_testing;
