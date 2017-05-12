use strict;
use warnings;

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags qw/ HTML XUL /;

template main => sub {
    groupbox {
        caption { attr { label => 'Colors' } }
        radiogroup {
          for my $id ( qw< orange violet yellow > ) {
              radio { attr { id => $id, label => ucfirst($id), $id eq 'violet' ? (selected => 'true') : () } }
          }
        }
        html {
            body { p { 'hi' } }
        }
    }
};

package main;
use Test::More tests => 1;
Template::Declare->init( dispatch_to => ['MyApp::Templates']);
my $out = Template::Declare->show('main') . "\n";
is $out, <<_EOC_;

<groupbox>
 <caption label="Colors" />
 <radiogroup>
  <radio id="orange" label="Orange" />
  <radio id="violet" label="Violet" selected="true" />
  <radio id="yellow" label="Yellow" />
 </radiogroup>
 <html>
  <body>
   <p>hi</p>
  </body>
 </html>
</groupbox>
_EOC_

