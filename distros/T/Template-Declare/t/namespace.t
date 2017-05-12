use strict;
use warnings;
use Test::More tests => 5;

### TEST 1:

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags
    'XUL', HTML => { namespace => 'html' };

template main => sub {
    groupbox {
        caption { attr { label => 'Colors' } }
        html::div { html::p { 'howdy!' } }
        html::br {}
    }
};

package main;
Template::Declare->init( dispatch_to => ['MyApp::Templates']);
my $out = Template::Declare->show('main') . "\n";
is $out, <<_EOC_;

<groupbox>
 <caption label="Colors" />
 <html:div>
  <html:p>howdy!</html:p>
 </html:div>
 <html:br></html:br>
</groupbox>
_EOC_


### TEST 2:

package MyApp::Templates2;

use base 'Template::Declare';
use Template::Declare::Tags
    'XUL', HTML => {
        namespace => 'htm',
        package => 'MyHtml'
    };

template main => sub {
    groupbox {
        caption { attr { label => 'Colors' } }
        MyHtml::div { MyHtml::p { 'howdy!' } }
        MyHtml::br {}
        html::label {}
    }
};

eval "htm::div {};";
::ok $@, 'htm:: is invalid';
::ok !defined &htm::div, 'package htm is intact';

package main;
Template::Declare->init( dispatch_to => ['MyApp::Templates']);
Template::Declare->init( dispatch_to => ['MyApp::Templates2']);
$out = Template::Declare->show('main') . "\n";
is $out, <<_EOC_;

<groupbox>
 <caption label="Colors" />
 <htm:div>
  <htm:p>howdy!</htm:p>
 </htm:div>
 <htm:br></htm:br>
 <html:label></html:label>
</groupbox>
_EOC_

### TEST 3:

package MyApp::Templates;

use base 'Template::Declare';
use Template::Declare::Tags
    HTML => { namespace => 'blah', from => 't::MyTagSet' },
    Blah => { namespace => undef, from => 't::MyTagSet' };

template main => sub {
    foo {
        blah::bar { attr { label => 'Colors' } }
        blah::baz { 'howdy!' }
    }
};

package main;
Template::Declare->init( dispatch_to => ['MyApp::Templates']);
$out = Template::Declare->show('main') . "\n";
is $out, <<_EOC_;

<foo>
 <blah:bar label="Colors" />
 <blah:baz>howdy!</blah:baz>
</foo>
_EOC_

