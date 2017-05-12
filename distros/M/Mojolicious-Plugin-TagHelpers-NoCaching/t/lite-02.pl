use Mojolicious::Lite;
use lib '../lib';

plugin 'TagHelpers::NoCaching', {key => 'v'};

get '/' => 'index';

app->start();

__DATA__

@@index.html.ep
<html>
	<head>
		%= stylesheet_nc "p1/style.css";
		%= javascript_nc "/app.js";
	</head>
	<body>
		%= image_nc "/t.gif";
		%= javascript_nc begin
			var a = 1 + 1;
		% end
	</body>
</html>
