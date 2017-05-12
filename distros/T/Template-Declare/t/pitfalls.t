use strict;
use warnings;
use Test::More tests => 7;

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags 'XUL', 'HTML' => { namespace => 'html' };

template main => sub {
    xml_decl { 'xml', version => '1.0' }
    xml_decl { 'xml-stylesheet',  href => "chrome://global/skin/", type => "text/css" }
};

template foo => sub {
    html::p {
        html::a { attr { src => '1.png' } }
        html::a { attr { src => '2.png' } }
        html::a { attr { src => '3.png' } }
    }
};

eval q{
    p { a { attr { src => 'cat.gif' } } }
};
::ok $@, 'attr in an invalid tag';
::like $@, qr/Subroutine attr failed: src => 'cat\.gif'
\t\(Perhaps you're using an unknown tag in the outer container\?\)/, 'attr in an invalid tag';

template inline => sub {
    no warnings 'void';
    html::p { "hello, "; html::em { "world" } }
    html::p { html::em { 'hello' }; 'world' }
};

eval q{
    groupbox { attr { id => 'a' } }
    for (1..10) {
        radio { attr { id => $_ } }
    }
};
::ok $@, 'semicolon required before for stmt';
::like $@, qr/syntax error at.*near "\) \{"/, 'error expected';

package main;
Template::Declare->init( dispatch_to => ['MyApp::Templates']);
my $out = Template::Declare->show('main') . "\n";
isnt $out, <<_EOC_;
<?xml version="1.0"?>
<?xml-stylesheet href="chrome://global/skin/" type="text/css"?>

_EOC_

$out = Template::Declare->show('foo') . "\n";
is $out, <<_EOC_;

<html:p>
 <html:a src="1.png"></html:a>
 <html:a src="2.png"></html:a>
 <html:a src="3.png"></html:a>
</html:p>
_EOC_

TODO: {
local $TODO = "it can be fixed partially";
$out = Template::Declare->show('inline') . "\n";
is $out, <<_EOC_, "'hello, ' is missing";

<html:p>
 <html:em>world</html:em>
</html:p>
<html:p>
 <html:em>hello</html:em>world</html:p>
_EOC_
}
