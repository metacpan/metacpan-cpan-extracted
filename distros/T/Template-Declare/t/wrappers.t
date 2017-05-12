#!/usr/bin/perl
package MyApp::Templates;
use strict;
use warnings;
use Template::Declare::Tags;
use base 'Template::Declare';

BEGIN {
    create_wrapper wrap => sub {
        my $code = shift;
        my %params = @_;
        html {
            head { title { outs "Hello, $params{user}!"} };
            body {
                $code->();
                div { outs 'This is the end, my friend' };
            };
        }
    };
}

template inner => sub {
    wrap {
        h1 { outs "Hello, Jesse, s'up?" };
    } user => 'Jesse';
};

package main;
use strict;
use warnings;
use Test::More tests => 2;
use Template::Declare;
Template::Declare->init(dispatch_to => ['MyApp::Templates']);

ok my $out = Template::Declare->show('inner'), 'Get inner output';
is $out, '
<html>
 <head>
  <title>Hello, Jesse!</title>
 </head>
 <body>
  <h1>Hello, Jesse, s&#39;up?</h1>
  <div>This is the end, my friend</div>
 </body>
</html>', 'Should have the wrapped output';

