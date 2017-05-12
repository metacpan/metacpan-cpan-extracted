use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Server::PSGI;
use FindBin;
use lib "$FindBin::Bin/lib";

plugin 'Parallol';

# Sleep for 0.1 seconds, then return 1 in the callback
sub one {
  my $c = pop;
  Mojo::IOLoop->timer(0.1, sub { $c->(1) });
}

helper one => sub { one(@_); };

get '/' => sub {
  my $self = shift;
  my $a = 0;
  my $b = 0;

  $self->on_parallol(sub { shift->render(text => $a + $b) } );

  one $self->parallol(weaken => 0, sub {
    $a = pop;
  });

  one $self->parallol(sub {
    $self->req;
    $b = pop;
  });
};

get '/stash' => sub {
  my $self = shift;
  one $self->parallol('a');
  one $self->parallol('b');
};

get '/nested' => sub {
  my $self = shift;

  $self->on_parallol(sub { shift->render('stash') });

  one $self->parallol(sub {
    $self->stash(a => pop);
    one $self->parallol('b');
  });
};

get '/instant' => sub {
  my $self = shift;

  $self->on_parallol(sub { shift->render('stash') });

  $self->parallol('a')->(1);
  $self->parallol('b')->(1);
};

get '/error' => sub {
  my $self = shift;
  $self->one($self->parallol(weaken => 0, sub {
    die "oh no";
  }));
};

get '/error_done' => sub {
  my $self = shift;
  $self->on_parallol(sub {
    die "oh no";
  });
  $self->one($self->parallol('one'));
};

my $r = app->routes;

$r->route('/app')->to('ParallolController#do_index');
$r->route('/app/stash')->to('ParallolController#do_stash');
$r->route('/app/nested')->to('ParallolController#do_nested');
$r->route('/app/instant')->to('ParallolController#do_instant');
$r->route('/app/error')->to('ParallolController#do_error');
$r->route('/app/error_done')->to('ParallolController#do_error_done');

my $t = Test::Mojo->new;
my $p = Mojo::Server::PSGI->new;

sub plack_body {
  my $body = shift;
  my $res = "";
 
  if (ref $body eq 'ARRAY') {
    for my $line (@$body) {
      $res .= $line if length $line;
    }
  } else {
    local $/ = \65536 unless ref $/;
    while (defined(my $line = $body->getline)) {
      $res .= $line if length $line;
    }
    $body->close;
  }

  $res;
}

sub t {
  my ($path, $content, $status) = @_;
  $status //= 200;
  $t->get_ok($path)->status_is($status)->content_like($content);

  {
    my ($status, $header, $body) = @{$p->run({PATH_INFO => $path})};
    is $status, $status;
    like plack_body($body), $content;
  };
}

# Lite
t '/', qr/2/;
t '/stash', qr/11/;
t '/nested', qr/11/;
t '/instant', qr/11/;
t '/error', qr/Server error/, 500;
t '/error_done', qr/Server error/, 500;

# Controller
t '/app', qr/2/;
t '/app/stash', qr/11/;
t '/app/nested', qr/11/;
t '/app/instant', qr/11/;
t '/app/error', qr/Server error/, 500;
t '/app/error_done', qr/Server error/, 500;

done_testing;

__DATA__

@@ stash.html.ep
<%= $a %><%= $b %>

