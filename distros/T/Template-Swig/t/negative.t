use strict;

use Test::More;
use Test::Exception;

use Template::Swig;

my $swig = Template::Swig->new;

my $template = <<EOT;
{% for image in images -%}
	<img src="{{ image.src }}" width="{{ image.width }}" height="{{ image.height }}">
{% endfor %}
EOT

throws_ok { $swig->compile } qr/need a template_string/, 'compile dies without a template string';

$swig->compile($template, 'images.html');

throws_ok { $swig->render } qr/need a template_name/, 'render dies without a template name';

throws_ok { $swig->render('xxx') } qr/couldn't find template/, 'render dies for bad template name';

done_testing;

__END__

my $output = $swig->render('images.html', { images => $images });
my $expected_output = <<EOT;
<img src="1.jpg" width="100" height="67">
<img src="2.jpg" width="100" height="67">
<img src="3.jpg" width="100" height="67">
<img src="4.jpg" width="100" height="67">
<img src="5.jpg" width="100" height="67">
EOT

is($output, $expected_output, 'rendered output matches what we expect');


