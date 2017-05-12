use Mojolicious::Lite;

plugin 'Log::Access';
plugin 'Log::Timestamp' => {pattern => '%y%m%d %X'};

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

app->secrets(['zy4uCwWYrd'])->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Sample';
See what has been logged.  If there is no log file then the log entries
have gone to STDERR.

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
