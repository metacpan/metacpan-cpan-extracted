#! perl
#
# Test for HTML files with UTF-8 content

use strict;
use warnings;

use utf8;
use Test::More tests => 1;

use Template::Flute;

my ($spec, $html, $flute, $out);

my %values = (camel => 'ラクダ');

binmode(STDOUT, ':encoding(utf-8)');

$spec = q{<specification>
<value name="test" class="camel"/>
<value name="camel" class="test" target="href"/>
</specification>
};

$html = q{<a href="" class="test">Camel</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => \%values);

$out = $flute->process;

ok($out =~ /ラクダ/, "Test for UTF-8 string in values.")
    || diag("Output: $out.");


