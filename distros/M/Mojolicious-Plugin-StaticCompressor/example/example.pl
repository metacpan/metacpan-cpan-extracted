use Mojolicious::Lite;
use lib '../lib/';
plugin('StaticCompressor');

get '/' => sub {
	my $self = shift;
	$self->render('index');
};

app->start;

# $ morbo example.pl
# Let's access to http://localhost:3000/ with your browser.

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
	<title>Example for Mojolicious::Plugin::StaticCompressor</title>
	<!-- Import tag (minified and combined) -->
	<%= js '/js/foo.js', '/js/bar.js' %>
	<!-- Import tag (It is minified only, because single.) -->
	<%= css '/css/style.css' %>
	<!---->
	<style type="text/css"> footer{font-size:small;position:fixed;right:5px;bottom:5px;} </style>
</head>
<body>
	<header><h2>Example for Mojolicious::Plugin::StaticCompressor</h2></header>

	<p>See this page source (html-source) with your browser.<br/>
	<small>In this page, compressed and imported a js-files (two file was combined) and css-file.</small></p>
	<p>Also, you can watch a raw js-files in here: <a href="/js/foo.js" target="_blank">/js/foo.js</a>, <a href="/js/bar.js" target="_blank">/js/bar.js</a>,<br/>
	And raw css-file in here: <a href="/css/style.css" target="_blank">/css/style.css</a></p>
	
	<footer>
	<a href="https://github.com/mugifly/p5-Mojolicious-Plugin-StaticCompressor" target="_blank">Mojolicious::Plugin::StaticCompressor</a> (on GitHub).<br>
	 - Your feedback is highly appreciated :) 
	</footer>
</body>
</html>
