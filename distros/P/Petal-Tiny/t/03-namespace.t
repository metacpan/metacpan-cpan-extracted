# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More; # tests => 8;
BEGIN { use_ok('Petal::Tiny') };

my $data   = join '', <DATA>;
my $petal  = Petal::Tiny->new($data);
my $output = $petal->process(
    foo  => 'bar',
    list => [ qw /foo bar baz buz/ ],
);

unlike ($output, qr/wackoNameSpace/, 'wacko namespace');
unlike ($output, qr/moreWackoNameSpace/, 'more wackonamespace');
Test::More::done_testing();

__DATA__
<XML xmlns:wackoNameSpace="http://purl.org/petal/1.0/">
  <xml foo="bar" wackoNameSpace:define="foo foo">
    This is a test
  </xml>
  <xml xmlns:moreWackoNameSpace="http://purl.org/petal/1.0/" moreWackoNameSpace:repeat="item list">
    <span moreWackoNameSpace:attributes="content item; bar foo" moreWackoNameSpace:content="item">foo</span>
    <span moreWackoNameSpace:replace="item">foo</span>
    <p>repeat/index: <span moreWackoNameSpace:replace="repeat/index">index</span></p>
    <p>repeat/number: <span moreWackoNameSpace:replace="repeat/number">number</span></p>
    <p>repeat/even: <span moreWackoNameSpace:replace="repeat/even">even</span></p>
    <p>repeat/odd: <span moreWackoNameSpace:replace="repeat/odd">odd</span></p>
    <p>repeat/start: <span moreWackoNameSpace:replace="repeat/start">start</span></p>
    <p>repeat/end: <span moreWackoNameSpace:replace="repeat/end">end</span></p>
    <p>repeat/inner: <span moreWackoNameSpace:replace="repeat/inner">inner</span></p>
  </xml>
  <xml wackoNameSpace:condition="false:nothing">This should appear</xml>
  <xml wackoNameSpace:condition="true:nothing">This should not appear</xml>
  <xml wackoNameSpace:condition="false:false:false:nothing">This should appear</xml>
  <xml wackoNameSpace:content="string:hello, world">foobar</xml>
  <xml wackoNameSpace:content="string:hello, $foo world ${foo}">foobar</xml>
</XML>
