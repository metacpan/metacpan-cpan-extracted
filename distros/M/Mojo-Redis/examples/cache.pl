#/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Mojo::Redis;

helper redis => sub { state $r = Mojo::Redis->new };

helper cache => sub {
  my $c = shift;
  return $c->stash->{'redis.cache'} ||= $c->redis->cache->refresh($c->param('_refresh'));
};

helper get_redis_stats_p => sub {
  my ($c, $section) = @_;
  return $c->redis->db->info_structured_p($section ? ($section) : ());
};

get '/stats' => sub {
  my $c = shift->render_later;

  $c->cache->memoize_p($c, get_redis_stats_p => [$c->param('section')])->then(sub {
    $c->render(json => shift);
  })->catch(sub {
    $c->reply_exception(shift);
  });
};

app->start;
