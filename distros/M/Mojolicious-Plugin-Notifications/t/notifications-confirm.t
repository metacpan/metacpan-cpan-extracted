#!/usr/bin/env perl
use Test::Mojo::Session;
use Test::More;
use Mojo::File qw/tempfile/;
use Mojolicious::Lite;
use utf8;

use_ok('Mojolicious::Plugin::Notifications::HTML', 'notify_html');

app->log->level('warn');

app->log->path(tempfile);

is(notify_html('announce',{
  ok => 'http://example.com/ok',
    ok_label => 'Okay!'
},'Confirm, please!'),
   '<div class="notify notify-announce">Confirm, please!<form action="http://example.com/ok" method="post"><button class="ok">Okay!</button></form></div>'."\n");

my $t = Test::Mojo->new;

post '/ok' => sub {
  shift->render(text => 'Okay!')
} => 'ok';

post '/cancel' => sub {
  shift->render(text => 'Canceled!')
} => 'cancel';

get '/confirm' => sub {
  shift->render(text => 'Please confirm');
} => 'confirm';

helper 'reply.notifications' => sub {
  my $c = shift;
  if ($c->stash('notetype') eq 'json') {
    return $c->render(json => $c->notifications(json => { text => 'example' }));
  }
  else {
    return $c->render(inline => '<%= notifications stash("notetype") %>');
  };
};


my $loglines = '';
app->log->on(
  message => sub {
    my ($log, $level, @lines) = @_;
    if ($level eq 'warn') {
      $loglines = join ',', @lines;
    };
  });

get '/:notetype/simple' => sub {
  my $c = shift;
  $c->notify(warn => {
    ok => $c->url_for('ok'),
    cancel => $c->url_for('cancel')
  } => q/That's a warning/);
  $c->reply->notifications;
};

get '/:notetype/labels' => sub {
  my $c = shift;
  $c->notify(warn => {
    ok => $c->url_for('ok'),
    ok_label => 'Fine!',
    cancel => $c->url_for('cancel'),
    cancel_label => 'Nope!'
  } => q/That's a warning/);
  $c->reply->notifications;
};

get '/:notetype/confirmroute' => sub {
  my $c = shift;
  $c->notify(warn => {
    ok => $c->url_for('ok'),
    ok_label => 'Fine!',
    cancel => $c->url_for('cancel'),
    cancel_label => 'Nope!',
    confirm => $c->url_for('confirm'),
    confirm_label => 'confirm_route'
  } => q/That's a warning/);
  $c->reply->notifications;
};

get '/:notetype/onlycancel' => sub {
  my $c = shift;
  $c->notify(warn => {
    cancel => $c->url_for('cancel'),
  } => q/That's a warning/);
  $c->reply->notifications;
};

get '/:notetype/onlyok' => sub {
  my $c = shift;
  $c->notify(warn => {
    ok => $c->url_for('ok'),
  } => q/That's a warning/);
  $c->reply->notifications;
};

app->plugin(Notifications => {
  HTML => 1,
  Alertify => 1,
  JSON => 1,
  Humane => 1
});

# Test HTML response
$t->get_ok('/html/simple')
  ->status_is(200)
  ->text_is('div.notify.notify-warn', 'That\'s a warning')
  ->text_is('div.notify form[action$=ok][method="post"] > button', 'OK')
  ->element_exists('div.notify form[action$=ok] > input[type=hidden][name=csrf_token]')
  ->text_is('div.notify form[action$=cancel][method="post"] > button', 'Cancel')
  ->element_exists('div.notify form[action$=cancel] > input[type=hidden][name=csrf_token]')
  ;

$t->get_ok('/html/labels')
  ->status_is(200)
  ->text_is('div.notify.notify-warn', 'That\'s a warning')
  ->text_is('div.notify form[action$=ok][method="post"] > button', 'Fine!')
  ->text_is('div.notify form[action$=cancel][method="post"] > button', 'Nope!')
  ->element_exists('div.notify form[action$=cancel] > input[type=hidden][name=csrf_token]')
  ;


$t->get_ok('/html/confirmroute')
  ->status_is(200)
  ->text_is('div.notify.notify-warn', 'That\'s a warning')
  ->text_is('div.notify form[action$=ok][method="post"] > button', 'Fine!')
  ->text_is('div.notify form[action$=cancel][method="post"] > button', 'Nope!')
  ->element_exists('div.notify form[action$=cancel] > input[type=hidden][name=csrf_token]')
  ;


$t->get_ok('/html/onlycancel')
  ->status_is(200)
  ->text_is('div.notify.notify-warn', 'That\'s a warning')
  ->element_exists_not('form[action$=ok] > button')
  ->text_is('div.notify form[action$=cancel][method="post"] > button', 'Cancel')
  ->element_exists('div.notify form[action$=cancel] > input[type=hidden][name=csrf_token]')
  ;

unlike($loglines, qr/Notifications/);

# Test alertify
$t->get_ok('/alertify/simple')
  ->status_is(200)
  ->text_is('noscript div.notify.notify-warn', 'That\'s a warning')
  ->text_is('noscript div.notify form[action$=ok][method="post"] > button', 'OK')
  ->text_is('noscript div.notify form[action$=cancel][method="post"] > button', 'Cancel')
  ->element_exists('noscript div.notify form[action$=ok] > input[type=hidden][name=csrf_token]')
  ->content_unlike(qr/alertify\.set/)
  ->content_like(qr/alertify\.confirm\(\"That\'s/)
  ->content_like(qr/,function\(ok\)\{var /)
  ->content_like(qr/XMLHttpRequest\(\);/)
  ->content_like(qr/r\.setRequestHeader\([^)]+\);/)
  ->content_like(qr/if\(ok\)\{r\.open\(\"POST\"\,\"\/ok\"\)/)
  ->content_like(qr/\}else\{r\.open\(\"POST\",\"\/cancel\"\)/)
  ->content_like(qr/;v=true\}else/)
  ->content_like(qr/;v=true\};/)
  ->content_like(qr/r\.send\("csrf_token="\+x\)/)
  ;

$t->get_ok('/alertify/labels')
  ->status_is(200)
  ->text_is('noscript div.notify.notify-warn', 'That\'s a warning')
  ->text_is('noscript div.notify form[action$=ok][method="post"] > button', 'Fine!')
  ->text_is('noscript div.notify form[action$=cancel][method="post"] > button', 'Nope!')
  ->element_exists('noscript div.notify form[action$=ok] > input[type=hidden][name=csrf_token]')
  ->content_like(qr/;alertify\.set\(\{labels:\{ok:\"Fine!\",cancel:\"Nope!\"\}\}\);/)
  ->content_like(qr/alertify\.confirm\(\"That\'s/)
  ->content_like(qr/,function\(ok\)\{var /)
  ->content_like(qr/XMLHttpRequest\(\);/)
  ->content_like(qr/r\.setRequestHeader\([^)]+\);/)
  ->content_like(qr/if\(ok\)\{r\.open\(\"POST\"\,\"\/ok\"\)/)
  ->content_like(qr/\}else\{r\.open\(\"POST\",\"\/cancel\"\)/)
  ->content_like(qr/r\.send\("csrf_token="\+x\)/)
  ->content_like(qr/;v=true\};/)
  ;

$t->get_ok('/alertify/onlycancel')
  ->status_is(200)
  ->text_is('noscript div.notify.notify-warn', 'That\'s a warning')
  ->element_exists_not('form[action$=ok] > button')
  ->text_is('noscript div.notify form[action$=cancel][method="post"] > button', 'Cancel')
  ->element_exists('noscript div.notify form[action$=cancel] > input[type=hidden][name=csrf_token]')
  ->content_unlike(qr/alertify\.set/)
  ->content_like(qr/alertify\.confirm\(\"That\'s/)
  ->content_like(qr/,function\(ok\)\{var /)
  ->content_like(qr/;if\(!ok\)\{r\.open\(\"POST\"\,\"\/cancel\"\)/)
  ;

$t->get_ok('/alertify/onlyok')
  ->status_is(200)
  ->text_is('noscript div.notify.notify-warn', 'That\'s a warning')
  ->element_exists_not('form[action$=cancel] > button')
  ->text_is('noscript div.notify form[action$=ok][method="post"] > button', 'OK')
  ->element_exists('noscript div.notify form[action$=ok] > input[type=hidden][name=csrf_token]')
  ->content_unlike(qr/alertify\.set/)
  ->content_like(qr/alertify\.confirm\(\"That\'s/)
  ->content_like(qr/,function\(ok\)\{var /)
  ->content_like(qr/if\(ok\)\{r\.open\(\"POST\"\,\"\/ok\"\)/)
  ->content_like(qr/XMLHttpRequest\(\);/)
  ->content_like(qr/r\.setRequestHeader\([^)]+\);/)
  ;

unlike($loglines, qr/Notifications/);

# Test JSON
$t->get_ok('/json/simple')
  ->status_is(200)
  ->json_is('/text', 'example')
  ->json_is('/notifications/0/0', 'warn')
  ->json_is('/notifications/0/1', "That's a warning")
  ->json_is('/notifications/0/2/cancel/method', "POST")
  ->json_is('/notifications/0/2/cancel/url', "/cancel")
  ->json_is('/notifications/0/2/ok/method', "POST")
  ->json_is('/notifications/0/2/ok/url', "/ok")
  ;

$t->get_ok('/json/labels')
  ->status_is(200)
  ->json_is('/text', 'example')
  ->json_is('/notifications/0/0', 'warn')
  ->json_is('/notifications/0/1', "That's a warning")
  ->json_is('/notifications/0/2/Nope!/method', "POST")
  ->json_is('/notifications/0/2/Nope!/url', "/cancel")
  ->json_is('/notifications/0/2/Fine!/method', "POST")
  ->json_is('/notifications/0/2/Fine!/url', "/ok")
  ;

$t->get_ok('/json/confirmroute')
  ->json_is('/text', 'example')
  ->json_is('/notifications/0/0', 'warn')
  ->json_is('/notifications/0/1', "That's a warning")
  ->json_is('/notifications/0/2/confirm_route/method', "GET")
  ->json_is('/notifications/0/2/confirm_route/url', "/confirm")
  ->json_hasnt('/notifications/0/2/ok')
  ->json_hasnt('/notifications/0/2/cancel')
  ->json_hasnt('/notifications/0/2/Nope!')
  ->json_hasnt('/notifications/0/2/Fine!')
  ;

$t->get_ok('/json/onlycancel')
  ->json_is('/text', 'example')
  ->json_is('/notifications/0/0', 'warn')
  ->json_is('/notifications/0/1', "That's a warning")
  ->json_is('/notifications/0/2/cancel/method', "POST")
  ->json_is('/notifications/0/2/cancel/url', "/cancel")
  ->json_hasnt('/notifications/0/2/ok')
  ;


unlike($loglines, qr/Notifications/);

# Test humane
$t->get_ok('/humane/simple')
  ->status_is(200)
  ->text_is('noscript div.notify.notify-warn', 'That\'s a warning')
  ->text_is('noscript div.notify form[action$=ok][method="post"] > button', 'OK')
  ->text_is('noscript div.notify form[action$=cancel][method="post"] > button', 'Cancel')
  ->element_exists('noscript div.notify form[action$=ok] > input[type=hidden][name=csrf_token]')
  ->content_like(qr/var x=\"/)
  ->content_like(qr/notify\.warn\(\"That\'s a warning\",/)
  ->content_like(qr/\{\"timeout\":0\}/)
  ->content_like(qr/function\(\)\{var r=new XMLHttpRequest\(\)/)
  ->content_like(qr/;r\.open\(\"POST\",\"\/ok\"\);r\.send\(\"csrf/)
  ;

$t->get_ok('/humane/labels')
  ->status_is(200)
  ->text_is('noscript div.notify.notify-warn', 'That\'s a warning')
  ->text_is('noscript div.notify form[action$=ok][method="post"] > button', 'Fine!')
  ->text_is('noscript div.notify form[action$=cancel][method="post"] > button', 'Nope!')
  ->element_exists('noscript div.notify form[action$=ok] > input[type=hidden][name=csrf_token]')
  ->content_like(qr/notify\.warn\(\"That\'s a warning\",/)
  ->content_like(qr/\{\"timeout\":0\}/)
  ->content_like(qr/function\(\)\{var r=new XMLHttpRequest\(\);/)
  ->content_like(qr/XMLHttpRequest\(\);r\.setRequestHeader\([^)]+\);/)
  ->content_like(qr/r\.open\(\"POST\",\"\/ok\"\);r\.send\(\"csrf_token=\"/)
  ;

like($loglines, qr/Notifications/);
$loglines = '';

$t->get_ok('/humane/onlycancel')
  ->status_is(200)
  ->text_is('noscript div.notify.notify-warn', 'That\'s a warning')
  ->element_exists_not('form[action$=ok] > button')
  ->text_is('noscript div.notify form[action$=cancel][method="post"] > button', 'Cancel')
  ->element_exists('noscript div.notify form[action$=cancel] > input[type=hidden][name=csrf_token]')
  ->content_like(qr/notify\.warn\(\"That\'s a warning\"\)/)
  ;

like($loglines, qr/Notifications/);
$loglines = '';

$t->get_ok('/humane/onlyok')
  ->status_is(200)
  ->text_is('noscript div.notify.notify-warn', 'That\'s a warning')
  ->element_exists_not('form[action$=cancel] > button')
  ->text_is('noscript div.notify form[action$=ok][method="post"] > button', 'OK')
  ->content_like(qr/notify\.warn\(\"That\'s a warning\",/)
  ->content_like(qr/\{\"timeout\":0\}/)
  ->content_like(qr/function\(\)\{var r=new XMLHttpRequest\(\);/)
  ->content_like(qr/XMLHttpRequest\(\);r\.setRequestHeader\([^)]+\);/)
  ->content_like(qr/r\.open\(\"POST\",\"\/ok\"\);r.send\(\"csrf_token=\"\+x/)
  ;

unlike($loglines, qr/Notifications/);

done_testing;
__END__
