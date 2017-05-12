use Mojolicious::Lite;

plugin 'Log::Timestamp' => {pattern => '%y%m%d%H%M%S', path => '/tmp/xxx.log'};

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Sample';
Welcome to Mojolicious with customised log timestamps!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
