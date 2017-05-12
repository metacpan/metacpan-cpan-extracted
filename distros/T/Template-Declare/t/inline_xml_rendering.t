use strict;
use warnings;
package MyApp::Templates;
use base 'Template::Declare';
use Template::Declare::Tags;

template main => sub {
    html {
	body { p { 'hi' } }
    }
}; 

package main;
use Test::More tests => 2;
Template::Declare->init( dispatch_to => ['MyApp::Templates']);

for
( [ "
<html>
 <body>
  <p>hi</p>
 </body>
</html>"
]
, [ "<html><body><p>hi</p></body></html>" => sub {
	$Template::Declare::Tags::TAG_INDENTATION  = 0;
	$Template::Declare::Tags::EOL              = "";
    }
] ) {

    my ( $expected, $get_ready ) = @$_;
    $get_ready and $get_ready->();
    my $got      = Template::Declare->show('main');

    for ($got,$expected) {
	s/\n/Z/gxms;
	s/\s/X/g;
    } # easier to debug then :)

    is $got, $expected;
}
