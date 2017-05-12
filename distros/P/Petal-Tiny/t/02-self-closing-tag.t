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
    foo     => 'bar',
    content => 'CONTENT',
    dquote  => '"',
    squote  => "'",
    andamp  => "&",
    lesser  => "<",
    greate  => ">",
    list    => [ qw /foo bar baz buz/ ],
    count   => [ 1 .. 5 ],
);

like ($output, qr/\<plain i='am' un='touched'\/\>/);
like ($output, qr/\<define\s*\/\>/);
like ($output, qr/\<condition\s*\/\>/);
unlike ($output, qr/\<nogo\s*\/\>/);
like ($output, qr/\<repeat/);
like ($output, qr/\<repeat count="1"/);
like ($output, qr/\<repeat count="2"/);
like ($output, qr/\<repeat count="3"/);
like ($output, qr/\<repeat count="4"/);
like ($output, qr/\<repeat count="5"/);
unlike ($output, qr/\<replace\s*\/\>/);
like ($output, qr/CONTENT/);
like ($output, qr/\<content\>bar\<\/content\>/);
like ($output, qr/\<error\>something bad happened\<\/error\>/);

Test::More::done_testing();


__DATA__
<XML xmlns:tal="http://purl.org/petal/1.0/">
  <plain i='am' un='touched'/>
  <define tal:define="variable content; variable2 string:hello, world" />
  <condition tal:define="variable content; variable2 string:hello, world" tal:condition="true:variable" />
  <nogo tal:define="variable content; variable2 string:hello, world" tal:condition="false:variable" />
  <repeat tal:attributes="count count" tal:define="variable content; variable2 string:hello, world" tal:condition="true:variable" tal:repeat="count count" />
  <replace tal:replace="content" />
  <content tal:content="foo" />
  <error tal:content="foo/bar/baz" tal:on-error="string:something bad happened" />
</XML>
