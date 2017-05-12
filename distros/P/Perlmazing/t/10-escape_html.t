use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;
use Perlmazing;

my @html = split /\n/, <<'end';
<html>
	<head>
		<title>This is HTML</title>
		<style>
			body {
				background-color: white;
				color: blue;
			}
			.mydiv {
				width: 50%;
			}
		</style>
		<script type="text/javascript">
			alert('Hello world!');
		</script>
	</head>
	<body>
		<div class="mydiv">
			This is some content!
		</div>
	</body>
</html>
end
my $scalar = escape_html @html;
is $scalar, '&#60;html&#62;', 'scalar';
is join("\n", escape_html @html), q[&#60;html&#62;
	&#60;head&#62;
		&#60;title&#62;This is HTML&#60;/title&#62;
		&#60;style&#62;
			body {
				background-color: white;
				color: blue;
			}
			.mydiv {
				width: 50%;
			}
		&#60;/style&#62;
		&#60;script type=&#34;text/javascript&#34;&#62;
			alert('Hello world!');
		&#60;/script&#62;
	&#60;/head&#62;
	&#60;body&#62;
		&#60;div class=&#34;mydiv&#34;&#62;
			This is some content!
		&#60;/div&#62;
	&#60;/body&#62;
&#60;/html&#62;], 'list';
is join("\n", @html), q[<html>
	<head>
		<title>This is HTML</title>
		<style>
			body {
				background-color: white;
				color: blue;
			}
			.mydiv {
				width: 50%;
			}
		</style>
		<script type="text/javascript">
			alert('Hello world!');
		</script>
	</head>
	<body>
		<div class="mydiv">
			This is some content!
		</div>
	</body>
</html>], 'untouched array';
escape_html @html;
is join("\n", @html), q[&#60;html&#62;
	&#60;head&#62;
		&#60;title&#62;This is HTML&#60;/title&#62;
		&#60;style&#62;
			body {
				background-color: white;
				color: blue;
			}
			.mydiv {
				width: 50%;
			}
		&#60;/style&#62;
		&#60;script type=&#34;text/javascript&#34;&#62;
			alert('Hello world!');
		&#60;/script&#62;
	&#60;/head&#62;
	&#60;body&#62;
		&#60;div class=&#34;mydiv&#34;&#62;
			This is some content!
		&#60;/div&#62;
	&#60;/body&#62;
&#60;/html&#62;], 'changed array';
