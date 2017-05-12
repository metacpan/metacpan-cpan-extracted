# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;
BEGIN { use_ok('Petal::Tiny') };

my $data   = join '', <DATA>;
my $petal  = Petal::Tiny->new($data);
my $output = $petal->process(
    foo  => 'bar',
    list => [ qw /foo bar baz buz/ ],
);
like ($output, qr/VISIBLE/, 'visible');
unlike ($output, qr/INVISIBLE/, 'invisible');
like ($output, qr/should be visible/, 'empty quotes');
unlike ($output, qr/strange/, 'crazyness');

like ($output, qr/>and works</, 'and');
unlike ($output, qr/>false and works 1</, 'not and');
like ($output, qr/>false and works 2</, 'not not and');

Test::More::done_testing();

__DATA__
<XML xmlns:tal="http://purl.org/petal/1.0/">
  <xml tal:condition="false:nothing">VISIBLE</xml>
  <xml tal:condition="true:nothing">INVISIBLE</xml>
  <xml tal:condition="">I guess since omit-tag="" should remove the tag, that means that "" must be true, thus this should be visible as well</xml>
  <xml tal:condition="??">strange stuff</xml>
  <xml tal:condition="true:--1;true:--2">and works</xml>
  <xml tal:condition="true:--1;true:undefined">false and works 1</xml>
  <xml tal:condition="true:--1;false:undefined">false and works 2</xml>
</XML>
