#! perl
#
# Test for <script> elements inside HTML snippets insertd with op="hook".

use strict;
use warnings;

use Test::More;
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
			      values => {content => q{<script type="text/javascript"></script>}},
    );

$out = $flute->process();

like($out, qr{\Q<div class="content"><script type="text/javascript"></script></div>\E},
     'value op=hook test with <script> elements inside')
    or diag $out;

done_testing;
