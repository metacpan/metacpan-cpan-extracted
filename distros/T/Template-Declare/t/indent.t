use strict;
use warnings;

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags 'HTML';

template main => sub {
    body {
        pre {
          local $Template::Declare::Tags::TAG_NEST_DEPTH = 0;
          script { attr { src => 'foo.js' } }
        }
    }
};

package main;
use Test::More tests => 1;
Template::Declare->init( dispatch_to => ['MyApp::Templates']);
my $out = Template::Declare->show('main') . "\n";
is $out, <<_EOC_;

<body>
 <pre>
<script src="foo.js"></script>
 </pre>
</body>
_EOC_

