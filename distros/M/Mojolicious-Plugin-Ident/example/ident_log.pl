#!/usr/bin/env perl

use Mojolicious::Lite;

plugin 'ident';

under sub {
  my($self) = @_;

  $self->ident(sub {
    my $res = shift;
    if($res->is_success)
    {
      app->log->info("ident user is " . $res->username);
    }
    else
    {
      app->log->info("unable to ident remote user");
    }
  });

  return 1;
};

get '/' => 'index';

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'ident test';
<p>hello world</p>

