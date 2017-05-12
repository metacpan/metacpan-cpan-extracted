use Mojo::Base -strict;
use Test::More;
use Mojo::YR;

plan skip_all => 'LIVE_TEST=1 is not set' unless $ENV{LIVE_TEST};

my $yr = Mojo::YR->new;
my @res;

{
  is $yr->text_forecast(sub { @res = @_; Mojo::IOLoop->stop; }), $yr, 'text_forecast() async';
  Mojo::IOLoop->start;

  is $res[0], $yr, 'callback receive $yr';
  is $res[1], '', 'callback without error';
  isa_ok($res[2], 'Mojo::DOM');
  ok $res[2]->find('time forecasttype area location in'), 'found time forecasttype area location in';

  my $today = $res[2]->children('time')->first;
  my $hordaland = $today->at('area[name="Hordaland"]');
  diag $hordaland->at('header')->text;
}

{
  @res = $yr->text_forecast;

  is int(@res), 1, 'text_forecast() sync';
  isa_ok($res[0], 'Mojo::DOM') or diag @res;
  ok $res[0]->find('time forecasttype area location in'), 'found time forecasttype area location in';
}

done_testing;
