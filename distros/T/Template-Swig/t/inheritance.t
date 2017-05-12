use strict;

use Template::Swig;
use Test::More;

my $swig = Template::Swig->new;

my $layout = <<EOT;
<!doctype html>
<head>
	{% block title -%}
		<title>Default Title</title>
	{% endblock %}
</head>
<body>
	{% block content -%}
		default content
	{% endblock %}
</body>
EOT

my $page = <<EOT;
{% extends 'layout.html' %}

{% block title %}
	<title>Custom Title!</title>
{% endblock %}

{% block content %}
	custom content too!
{% endblock %}
EOT

$swig->compile('layout.html', $layout);
$swig->compile('page.html', $page);

my $output = $swig->render('page.html');

my $expected_output = <<EOT;
<!doctype html>
<head>
	<title>Custom Title!</title>
</head>
<body>
	custom content too!
</body>
EOT

$output = trim_whitespace($output);
$expected_output = trim_whitespace($expected_output);

is($output, $expected_output, 'rendered output matches what we expect');

done_testing;

sub trim_whitespace {

	my ($string) = @_;

	$string =~ s/\s+/ /gs;
	$string =~ s/\s+$//gs;

	return $string;
}
