use strict;
use warnings;
use Test::More tests => 3;
use Template::Flute;
use utf8;
binmode STDOUT, ":encoding(utf-8)";

use XML::Twig;

my $layout_html = << 'EOF';
<html>
<head>
<title>Test</title>
</head>
<body>
<div id="content">
This is the default page.
</div>
<div id="test">&nbsp;</div>
</body>
</html>
EOF

my $layout_spec = q{<specification><value name="content" id="content" op="hook"/></specification>};
my $template_html = << 'EOF';
<html>
	<head>
	<title>Test</title>
	</head>
	<div id="body">body</div>
	<div id="test">&nbsp; v&amp;r</div>
	<span id="spanning" style="display:none">&nbps;</span>
</html>
EOF
my $template_spec = q{<specification><value name="body" id="body"/><value name="none" id="spanning"/></specification>};

my $flute = Template::Flute->new(specification => $template_spec,
                                 template => $template_html,
                                 values => {
                                            body => "v&r",
                                            none => "hello",
                                           });

my $out = $flute->process();

my $expected = q{<div id="body">v&amp;r</div><div id="test">  v&amp;r</div><span id="spanning" style="display:none">hello</span>};
ok((index($out, $expected) >= 0),
  "body rendered") || diag "Out: $out";

my $layout = Template::Flute->new(specification => $layout_spec,
                                  template => $layout_html,
                                  values => {content => $out});

my $final = $layout->process;
ok ((index($final, $expected) >= 0), "the layout contains the body")
    || diag "Out: $final";
ok ((index($final, q{<div id="test"> </div>}) >= 0), "the layout has the decoded &nbsp;")
    || diag "Out: $final";
