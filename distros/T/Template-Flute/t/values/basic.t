#
# Basic tests for values
use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{<specification>
<value name="test"/>
</specification>
};

$html = q{<div class="test">TEST</div>};

for my $value (0, 1, ' ', 'test') {
    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  values => {test => $value},
    );

    $out = $flute->process();

    ok ($out =~ m%<div class="test">$value</div>%,
        "basic value test with: $value")
        || diag $out;
}

# test targets in values
$spec = q{<specification>
<value name="test" target="src"/>
</specification>
};

$html = q{<iframe class="test" src="test"></iframe>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => '/test.html'},
    );

$out = $flute->process();

ok($out =~ m%<iframe class="test" src="/test.html"></iframe>%, 'basic value target test by class')
    || diag $out;

$spec = q{<specification>
<value name="test" id="test" target="src"/>
</specification>
};

$html = q{<iframe id="test" src="test"></iframe>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {test => '/test.html'});

$out = $flute->process();

ok($out =~ m%<iframe id="test" src="/test.html"></iframe>%, 'basic value target test by id')
    || diag $out;

# test "field"

$spec = q{<specification>
<value name="foo" field="bar"/>
</specification>
};

$html = q{<div class="foo">TEST</div>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {foo => 'nevairbe',
                                         bar => 'success',
                                        },
                             );

$out = $flute->process();

ok ($out =~ m%<div class="foo">success</div>%,
        "value test with field attribute")
        || diag $out;

# test "dotted" values

$spec = q{<specification>
<value name="test" field="session.test"/>
</specification>
};

$html = q{<div class="test">TEST</div>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {session => {test => 'My message'}},
                             );

$out = $flute->process();

ok ($out =~ m%<div class="test">My message</div>%,
    "dotted value test")
    || diag $out;

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {session => 'My message'},
                             );

$out = $flute->process();

ok ($out =~ m%<div class="test"></div>%,
    "dotted value test (missing reference in values)")
    || diag $out;

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {session => {test => {bar => 'My message'}}},
                             );

$out = $flute->process();

ok ($out =~ m%<div class="test"></div>%,
    "dotted value test (extra hash reference in values)")
    || diag $out;

$spec = q{<specification>
<value name="test" field="session.foo.bar"/>
</specification>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {session => {foo => {bar => 'My message'}}},
                             );

$out = $flute->process();

ok ($out =~ m%<div class="test">My message</div>%,
    "dotted value test (three levels)")
    || diag $out;

$spec = q{<specification>
<value name="test" field="session.foo.bar"/>
</specification>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {session => {foo => {baz => 'My message'}}},
                             );

$out = $flute->process();

ok ($out =~ m%<div class="test"></div>%,
    "dotted value test (three levels, wrong key)")
    || diag $out;

# test "dotted" values with wrong level in passed values

$spec = q{<specification>
<value name="test" field="session.test"/>
</specification>
};

$html = q{<div class="test">TEST</div>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {session => 'Wrong message'},
                             );

$out = $flute->process();

ok ($out =~ m%<div class="test"></div>%,
    "dotted value test with wrong level in passed values")
    || diag $out;

done_testing;
