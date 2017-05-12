#! perl
#
# Test for HTML files with UTF-8 content

use strict;
use warnings;

use utf8;

use Test::More tests => 10;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";


use Template::Flute;

binmode STDOUT, ":encoding(utf-8)";

my ($spec, $html, $flute, $out);

my %values = (camel => 'ラクダ');

$spec = q{<specification>
<value name="camel" />
</specification>
};

$html = <<'HTML';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
</head>
<body><a href="" class="camel">Camel</a><span>&nbsp;</span>
</body>
</html>
HTML

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => \%values);
$out = $flute->process;

like $out, qr/\x{a0}/, "Test for &nbsp; in the output as character.";
like $out, qr/ラクダ/, "Found the value";
like $out, qr/\Qcharset=utf-8\E/, "Found the encoding";

$html = <<'HTML';
<div>XXXX</div>
<a href="" class="camel">Camel</a><span>&nbsp;</span>
HTML

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => \%values);
$out = $flute->process;

like $out, qr/\x{a0}/, "Test for &nbsp; in the output as character.";
like $out, qr/ラクダ/, "Found the value";
unlike $out, qr/\Qcharset=utf-8\E/, "Encoding not found (was not declared)";
like $out, qr/XXXX/, "Found the marker";
unlike $out, qr/iso-8859-1/, "Not iso-8859 xml output";


$html = <<'HTML';
<a href="" class="camel">Camel</a><span>&nbsp;</span>
HTML

# beware: this one would trigger an <?xml version="1.0" encoding="iso-8859-1"?>
# for unknown reasons
# $html = q{<a href="" class="camel">Camel</a><span>&nbsp;</span>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => \%values);
$out = $flute->process;
like $out, qr/\x{a0}/, "Test for &nbsp; in the output as character.";
unlike $out, qr/iso-8859-1/, "Not iso-8859 xml output";


