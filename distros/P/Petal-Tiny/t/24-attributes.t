# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More tests => 8;
BEGIN { use_ok('Petal::Tiny') };


my $data = join '', <DATA>;
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
);

like ($output, qr/item="foo"/, 'item');
like ($output, qr/content="CONTENT"/, 'content');
like ($output, qr/foo="bar"/, 'foo');
like ($output, qr/special="&quot;&apos;&amp;&lt;&gt;"/, 'special');
like ($output, qr/bar="yes no"/, 'bar');
like ($output, qr/added="really"/, 'added');
like ($output, qr/baz="qux"/, 'baz');

__DATA__
<XML xmlns:tal="http://purl.org/petal/1.0/">
  <xml bar="yes " baz="qux" tal:attributes="foo foo; content content; item list/0; special string:$dquote$squote$andamp$lesser$greate; +bar --no; +added --really; +baz undef"></xml>
</XML>
