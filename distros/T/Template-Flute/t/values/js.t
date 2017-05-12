#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode STDOUT, ":encoding(utf-8)";

use Test::More;
use Template::Flute;

use XML::Twig;
use Data::Dumper;

plan tests => 7;


my $js_first = 'value layout < 0 && value >= 0 && value <= 1 && value > 1 || 0';
my $js_second = 'hello if ( this > value && ( !request.term || request ) && 0 < 1 body)';

my $layout_html =<< "LAYOUT";
<!doctype html>
<html>
<head>
<title>Test</title>
</head>
<body>
<div id="content">
This is the default page.
</div>
<div id="test">
<script>
$js_first
</script>
</div>
</body>
</html>
LAYOUT

my $layout_spec = q{<specification><value name="content" id="content" op="hook"/></specification>};

my $template_html =<< "HTML";
<div id="body">body</div>
<script>
$js_second
</script>
<div id="test">hello</div>
<span id="spanning" style="display:none">hello</span>
HTML

my $template_spec = q{<specification><value name="body" id="body"/><value name="none" id="spanning"/></specification>};

my $flute = Template::Flute->new(specification => $template_spec,
                                 template => $template_html,
                                 values => {
                                            body => "body",
                                            none => "hello",
                                           });

my $output = $flute->process();

like $output, qr/\Q$js_second\E/, "js found verbatim in body";

my $layout = Template::Flute->new(specification => $layout_spec,
                                  template => $layout_html,
                                  values => {content => $output});

my $final = $layout->process;

like $final, qr/\Q$js_first\E/, "js (body) found verbatim";
like $final, qr/\Q$js_second\E/, "js (layout) found verbatim";

my $fixed_html =<< "HTML";
<div id="body">body</div>
<script>
//<![CDATA[
$js_second
//]]>
</script>
<div id="test">test</div>
<span id="spanning" style="display:none">test</span>
HTML




$flute = Template::Flute->new(specification => $template_spec,
                              template => $fixed_html,
                              values => {
                                         body => "hello",
                                         none => "hello",
                                        });

$output = $flute->process();


like $output, qr/\Q$js_second\E/, "found js verbatim in content";

if ($output =~ m/\]\]&gt;/) {
    diag "End of CDATA escaped because of XML::Twig";
}

my $fixed_layout_html =<< "HTML";
<!doctype html>
<html>
<head>
<title>Test</title>
</head>
<body>
<div id="content">
This is the default page.
</div>
<div id="test">
<script>
//<![CDATA[
$js_first
//]]>
</script>
</div>
</body>
</html>
HTML

$layout = Template::Flute->new(specification => $layout_spec,
                                  template => $fixed_layout_html,
                                  values => {content => $output});

$final = $layout->process;

like $final, qr/\Q$js_first\E/, "js (body) found verbatim";
like $final, qr/\Q$js_second\E/, "js (layout) found verbatim";

unlike $final,  qr/\]\]&gt;/, "End of CDATA escaped correctly";

