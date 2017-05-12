#! perl
#
# Extended tests for values

use strict;
use warnings;

use Test::More tests => 5;
use Template::Flute;

my ($spec, $html, $flute, $out);

# value with op=hook, using class
$spec = q{<specification>
<value name="content" op="hook"/>
</specification>
};

$html = q{<div class="content">CONTENT</div>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {content => q{<p>Enter <b>dancefloor</b></p>}},
    );

$out = $flute->process();

like($out, qr{\Q<div class="content"><p>Enter <b>dancefloor</b></p></div>\E},
     'value op=hook test with class')
    or diag $out;

# value with op=hook, using id
$spec = q{<specification>
<value name="content" id="content" op="hook"/>
</specification>
};

$html = q{<div id="content">CONTENT</div>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {content => q{<p>Enter <b>dancefloor</b></p>}},
    );

$out = $flute->process();

like($out,  qr{\Q<div id="content"><p>Enter <b>dancefloor</b></p></div>\E},
     'value op=hook test with id')
  or diag $out;

# value with op=hook, using id and select HTML element
$spec = q{<specification>
<value name="available_shipmodes" class="available_shipmodes" op="hook"/>
</specification>
};

$html = q{<select id="available_shipmodes" class="available_shipmodes" name="available_shipmodes">
</select>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
			      values => {available_shipmodes => q{
<option cost="" value="">Select Shipping</option>}},
    );

$out = $flute->process();

like($out,  qr{\Q<select class="available_shipmodes" id="available_shipmodes" name="available_shipmodes"><option cost="" value="">Select Shipping</option></select>\E},
     'value op=hook test with select HTML element')
  or diag $out;

# value with op=hook and empty value
$spec = q{<specification>
<value name="content" op="hook"/>
</specification>
};

$html = q{<div class="content">CONTENT</div>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
    );

$out = $flute->process();

like($out, qr{\Q<div class="content"></div>\E},
     'value op=hook test with class and empty value')
    or diag $out;

# value with op=hook, HTML child element and empty value
$spec = q{<specification>
<value name="content" op="hook"/>
</specification>
};

$html = q{<div class="content"><p>CONTENT</p></div>};

$flute = Template::Flute->new(template => $html,
			      specification => $spec,
    );

$out = $flute->process();

like($out, qr{\Q<div class="content"></div>\E},
     'value op=hook test with class, HTML child element and empty value')
    or diag $out;
