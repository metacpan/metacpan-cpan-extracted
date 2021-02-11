#!/usr/bin/env perl
use Mojolicious::Lite;

plugin 'Config';

get '/' => sub {
    my $c = shift;
    my $json = {
		"entities" => {
			       "Q100148272" => {
						"id" => "Q100148272",
						"sitelinks" => {
								"enwiki" => {
									     "badges" => [],
									     "site" => "enwiki",
									     "title" => "Canyons (song)"
									    }
							       },
						"type" => "item"
					       }
			      },
		"success" => 1
	       };

    $c->render(json => $json);
};

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Welcome to the Mojolicious real-time web framework!</h1>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
