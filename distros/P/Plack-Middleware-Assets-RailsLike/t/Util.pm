package t::Util;

use utf8;
use strict;
use warnings;
use parent 'Exporter';

use constant {
    minified_js  => 'var foo=1;function bar(name){alert(name);}',
    minified_css => '#foo{size:5em}.bar{height:40%;width:60%}',
};

sub compiled_js() {
    my $js = <<JS;
var foo = 1;
function bar(name) {
    alert(name);
}
JS
    chomp $js;
    return $js;
}

sub compiled_css() {
    my $css = <<CSS;
#foo {
    size: 5em;
}
.bar {
    height: 40%;
    width: 60%;
}
CSS
    chomp $css;
    return $css;
}

our @EXPORT_OK = qw(
    compiled_js minified_js
    compiled_css minified_css
);

1;
