#! perl
#
# Test append/prepend with values

use strict;
use warnings;

use Test::More;
use Test::Warnings;
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

# simple prepend
$spec = q{<specification>
<value name="test" op="prepend"/>
</specification>
};

$html = q{<div class="test">FOO</div>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

like ($out, qr%<div class="test">BARFOO</div>%,
      "value with op=prepend");

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

# simple prepend with joiner
$spec = q{<specification>
<value name="test" op="prepend" joiner="&amp;"/>
</specification>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                          );

$out = $flute->process;

like ($out, qr%<div class="test">BAR&amp;FOO</div>%,
    "value with op=prepend and joiner=&");

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

# simple prepend with joiner without value
$spec = q{<specification>
<value name="test" op="prepend" joiner="&amp;"/>
</specification>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => ''},
                          );

$out = $flute->process;

like ($out, qr%<div class="test">FOO</div>%,
    "value with op=prepend, joiner=& and empty value");

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

# simple prepend with joiner which doesn't escape
$spec = q{<specification>
<value name="test" op="prepend" joiner="|"/>
</specification>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

like ($out, qr%<div class="test">BAR|FOO</div>%,
    "value with op=prepend and joiner=&");

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

# prepend to target
$spec = q{<specification>
<value name="test" op="prepend" target="href"/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'BAR'},
                             );

$out = $flute->process;

like ($out, qr%<a class="test" href="BARFOO">FOO</a>%,
    "value with op=prepend and target=href");

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

# prepend with joiner
$spec =  q{<specification>
<value name="test" op="prepend" target="class" joiner=" "/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => 'bar'},
                             );

$out = $flute->process;

like ($out, qr%<a class="bar test" href="FOO">FOO</a>%,
    "value with op=prepend, target=class and joiner");

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

# prepend with joiner without value
$spec =  q{<specification>
<value name="test" op="prepend" target="class" joiner=" "/>
</specification>
};

$html = q{<a href="FOO" class="test">FOO</a>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                             );

$out = $flute->process;

like ($out, qr%<a class="test" href="FOO">FOO</a>%,
    "value with op=prepend, target=class and joiner without value");

done_testing;
