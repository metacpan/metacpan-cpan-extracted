#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use lib 'lib';
use Mojo::Redis;

helper redis => sub { state $r = Mojo::Redis->new };

get '/' => sub ($c) {
  return $c->render('login') unless my $username = $c->session('username');
  return $c->redirect_to(profile => {username => $username});
  },
  'index';

get '/logout' => sub ($c) {
  delete $c->session->{$_} for qw(uid username);
  $c->redirect_to('index');
};

get '/:username', sub ($c) {
  my $db        = $c->redis->db;
  my $username  = $c->stash('username');
  my $logged_in = my $uid;

  $c->stash(logged_in => $username eq $c->session('username') // '');
  $c->render_later;
  $db->hget_p('twitter_clone:users' => $username)->then(sub {
    $uid = shift or die $c->reply->not_found;
  })->then(sub {
    my $page           = $c->param('page') || 1;
    my $items_per_page = 20;
    my $start          = ($page - 1) * $items_per_page;
    $db->lrange_p("twitter_clone:posts:$uid", $start, $start + $items_per_page);
  })->then(sub {
    my $post_ids = shift;
    Mojo::Promise->all(map { $db->hgetall_p("twitter_clone:post:$_") } @$post_ids);
  })->then(sub {
    $c->render(posts => [map { $_->[0] } @_]);
  })->catch(sub {
    $c->reply->exception(shift) unless $c->stash('status');
  });
}, 'profile';

post '/:username', sub ($c) {
  my $v = $c->validation;
  my $uid = $c->session('uid') or return $c->redirect_to('index');

  $v->required('message');
  return $c->render(status => 400, posts => [], error => 'Missing input.') unless $v->is_valid;

  $c->render_later;
  my $db = $c->redis->db;
  my $post_id;
  $db->incr_p('twitter_clone:next_post_id')->then(sub {
    $post_id = shift;
    $db->hmset_p("twitter_clone:post:$post_id", uid => $uid, time => time, body => $v->param('message'));
  })->then(sub {
    $db->lpush_p("twitter_clone:posts:$uid", $post_id);
  })->then(sub {
    $db->lpush_p("twitter_clone:timeline", $post_id);
  })->then(sub {
    $db->ltrim_p("twitter_clone:timeline", 0, 1000);
  })->then(sub {
    $c->redirect_to('profile');
  })->catch(sub {
    $c->reply->exception(shift) unless $c->stash('status');
  });
}, 'post';

post '/login', sub ($c) {
  my $v = $c->validation;

  $v->csrf_protect;
  $v->required('password');
  $v->required('username');
  return $c->render(status => 400, error => 'Missing input.') unless $v->is_valid;

  $c->render_later;
  my $db = $c->redis->db;
  $db->hget_p('twitter_clone:users' => $v->param('username'))->then(sub {
    my $uid = shift;
    die $c->render(status => 400, error => 'Invalid username or password.') unless $uid;
    $c->session(uid => $uid, username => $v->param('username'));
    return $db->hget_p("twitter_clone:user:$uid", 'password');
  })->then(sub {
    my $password = shift;
    die $c->render(status => 400, error => 'Invalid username or password.')
      if !$password
      or $password ne $v->param('password');
    $c->redirect_to(profile => {username => $v->param('username')});
  })->catch(sub {
    $c->reply->exception(shift) unless $c->stash('status');
  });
}, 'login';

Mojo::IOLoop->next_tick(\&add_dummy_user);
app->defaults(layout => 'default');
app->secrets([$ENV{MOJO_TWITTER_CLONE_SECRET} || rand(1000)]);
app->start;

sub add_dummy_user {
  my $db = app->redis->db;
  my $uid;

  $db->hget_p('twitter_clone:users' => 'batgirl')->then(sub {
    die "--> User batgirl already added.\n" if $uid = shift;
  })->then(sub {
    $db->incr_p('twitter_clone:next_user_id');
  })->then(sub {
    $uid = shift;
    $db->hmset_p("twitter_clone:user:$uid", username => 'batgirl', password => 's3cret')
      ;    # Password should not be in plain text!
  })->then(sub {
    $db->hset_p('twitter_clone:users', batgirl => $uid);
    warn "--> User batgirl added.\n";
  })->catch(sub {
    warn $_[0];
  });
}

__DATA__
@@ login.html.ep
<h1>Login</h1>
<p>A dummy user has been added, so no need to change the form inputs.</p>
%= form_for 'login', begin
  <label>
    <span>Username</span>
     %= text_field 'username', 'batgirl'
  </label>
  <label>
    <span>Password</span>
     %= password_field 'password', 's3cret'
  </label>
  <button class="button">Login</button>
% end
@@ profile.html.ep
<h1><%= $username %></h1>
% if ($logged_in) {
  %= form_for 'post', begin
    <label>
      <span>Message</span>
      %= text_field 'message', placeholder => "What's on your mind?"
      <button class="button">Post</button>
    </label>
  % end
% }
<ul class="posts">
  % for my $post (@$posts) {
    <li>
      <small class="posts_time"><%= scalar localtime $post->{time} %></small>
      <div class="posts_body"><%= $post->{body} %></div>
    </li>
  % }
</ul>
@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Design and implementation of a simple Twitter clone using Perl and the Redis key-value store</title>
    <link rel="stylesheet" href="//fonts.googleapis.com/css?family=Roboto:300,300italic,700,700italic">
    <link rel="stylesheet" href="//cdn.rawgit.com/necolas/normalize.css/master/normalize.css">
    <link rel="stylesheet" href="//cdn.rawgit.com/milligram/milligram/master/dist/milligram.min.css">
    <style>
      body {
        margin: 3rem 1rem;
      }
      pre {
        padding: 0.2rem 0.5rem;
      }
      .wrapper {
        max-width: 35em;
        margin: 0 auto;
      }
      .posts {
        list-style: none;
      }
      .posts li {
        border-bottom: 1px solid #bbb;
        margin-bottom: 2rem;
      }
    </style>
  </head>
  <body>
    <div class="wrapper"><%= content %></div>
  </body>
</html>
