use strict;
use warnings;

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags qw/ XUL /;

template main => sub {
    xml_decl { 'xml', version => '1.0' };
    xml_decl { 'xml-stylesheet',  href => "chrome://global/skin/", type => "text/css" };
    groupbox {
        caption { attr { label => 'Colors' } }
        radiogroup {
          for my $id ( qw< orange violet yellow > ) {
              radio { attr { id => $id, label => ucfirst($id), $id eq 'violet' ? (selected => 'true') : () } }
          }
        }
    }
};

package main;
use Test::More tests => 1;
Template::Declare->init( dispatch_to => ['MyApp::Templates']);
my $out = Template::Declare->show('main') . "\n";
is $out, <<_EOC_;
<?xml version="1.0"?>
<?xml-stylesheet href="chrome://global/skin/" type="text/css"?>

<groupbox>
 <caption label="Colors" />
 <radiogroup>
  <radio id="orange" label="Orange" />
  <radio id="violet" label="Violet" selected="true" />
  <radio id="yellow" label="Yellow" />
 </radiogroup>
</groupbox>
_EOC_

