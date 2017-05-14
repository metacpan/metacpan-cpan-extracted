#! perl
#
# Test append with values

use strict;
use warnings;

use Test::More tests => 7;
use Template::Flute;

my ($spec, $html, $flute, $out);

# simple append
$spec = q{<specification>
<value name="test" op="append"/>
</specification>
};

$html = q{<div class="test">FOO</div>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

like ($out, qr%<div class="test">FOOBAR</div>%,
    "value with op=append");


# simple append with joiner
$spec = q{<specification>
<value name="test" op="append" joiner="&amp;"/>
</specification>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

like ($out, qr%<div class="test">FOO&amp;BAR</div>%,
    "value with op=append and joiner=&");

# simple append with joiner without value
$spec = q{<specification>
<value name="test" op="append" joiner="&amp;"/>
</specification>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => ''},
                             );

$out = $flute->process;

like ($out, qr%<div class="test">FOO</div>%,
    "value with op=append, joiner=& and empty value");

# simple append with joiner which doesn't escape
$spec = q{<specification>
<value name="test" op="append" joiner="|"/>
</specification>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

like ($out, qr%<div class="test">FOO|BAR</div>%,
    "value with op=append and joiner=&");


# append to target
$spec = q{<specification>
<value name="test" op="append" target="href"/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

like ($out, qr%<a class="test" href="FOOBAR">FOO</a>%,
    "value with op=append and target=href");


# append with joiner
$spec =  q{<specification>
<value name="test" op="append" target="class" joiner=" "/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'bar'},
                             );

$out = $flute->process;

like ($out, qr%<a class="test bar" href="FOO">FOO</a>%,
    "value with op=append, target=class and joiner");


# append with joiner without value
$spec =  q{<specification>
<value name="test" op="append" target="class" joiner=" "/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                             );

$out = $flute->process;

like ($out, qr%<a class="test" href="FOO">FOO</a>%,
    "value with op=append, target=class and joiner without value");
