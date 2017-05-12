# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More; # tests => 8;
BEGIN { use_ok('Petal::Tiny') };

ok (Petal::Tiny->modifier_true('stuff', { stuff => 'i am true stuff' } ), 'true' );
ok (Petal::Tiny->modifier_false('nostuff', { stuff => 'i am true stuff' } ), 'false' );
my $string = Petal::Tiny->modifier_string ("here is some true stuff : \${stuff}", { stuff => 'i am true stuff' } );
like ($string, qr/i am true stuff/, 'string');
Test::More::done_testing();

__DATA__
<XML xmlns:tal="http://purl.org/petal/1.0/">
  <xml foo="bar" tal:define="foo foo">
    This is a test
  </xml>
  <xml xmlns:petal="http://purl.org/petal/1.0/" petal:condition="foo">
    This is a test <span petal:replace="string:two">three</span>
  </xml>
  <xml tal:repeat="item list">
    <span tal:attributes="content item; bar foo" tal:content="item">foo</span>
    <span tal:replace="item">foo</span>
    <p>repeat/index: <span tal:replace="repeat/index">index</span></p>
    <p>repeat/number: <span tal:replace="repeat/number">number</span></p>
    <p>repeat/even: <span tal:replace="repeat/even">even</span></p>
    <p>repeat/odd: <span tal:replace="repeat/odd">odd</span></p>
    <p>repeat/start: <span tal:replace="repeat/start">start</span></p>
    <p>repeat/end: <span tal:replace="repeat/end">end</span></p>
    <p>repeat/inner: <span tal:replace="repeat/inner">inner</span></p>
  </xml>
  <xml tal:condition="false:nothing">This should appear</xml>
  <xml tal:condition="true:nothing">This should not appear</xml>
  <xml tal:condition="false:false:false:nothing">This should appear</xml>
  <xml tal:content="string:hello, world">foobar</xml>
  <xml tal:content="string:hello, $foo world ${foo}">foobar</xml>
</XML>
