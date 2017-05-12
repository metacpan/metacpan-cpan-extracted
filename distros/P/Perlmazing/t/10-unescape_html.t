use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
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

my @test = @html;
escape_html @test;
isnt join('', @html), join('', @test), 'result differs from original';
unescape_html @test;
is_deeply \@html, \@test, 'data OK';
is join('', @html), join('', @test), 'right result';