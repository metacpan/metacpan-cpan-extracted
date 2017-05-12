use Mojo::Base -strict;
use Test::More;
use Mojo::YR;

plan skip_all => 'LIVE_TEST=1 is not set' unless $ENV{LIVE_TEST};

my $yr = Mojo::YR->new;
my @res;

{
  $yr->sunrise(
    {lat => 59, lon => 10, date => '2015-01-01'},
    sub { @res = @_; Mojo::IOLoop->stop; }
  );
  Mojo::IOLoop->start;

  is $res[0], $yr, 'callback receive $yr';
  is $res[1], '', 'callback without error';
  isa_ok($res[2], 'Mojo::DOM');

  ok $res[2]->find('time location sun noon', 'found time location forecast');
}

done_testing;
