use Mojolicious::Lite;
use lib '../lib';

plugin 'TagHelpers::NoCaching';

get '/'      => 'index';
get '/p1'    => 'p1';
get '/p1/p2' => 'p2';

app->start();

__DATA__

@@index.html.ep
<html>
	<head>
		%= stylesheet_nc "app.css";
		%= javascript_nc "/foo.js";
	</head>
	<body>
		%= image_nc "/t.gif";
	</body>
</html>

@@p1.html.ep
<html>
	<head>
		%= javascript_nc "/app.js?v=12";
		%= stylesheet_nc "mem.css";
	</head>
	<body>
		%= image_nc "../lite-01.pl"
	</body>
</html>

@@p2.html.ep
<html>
	<head>
		%= stylesheet_nc "./style.css";
		%= stylesheet_nc "app.css";
	</head>
	<body>
	</body>
</html>

@@mem.css
.xxx {
	font-size: 20px;
}
