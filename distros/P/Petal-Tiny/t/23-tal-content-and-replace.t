# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More; # tests => 8;
BEGIN { use_ok('Petal::Tiny') };


my $data = join '', <DATA>;
my $petal  = Petal::Tiny->new($data);
my $output = $petal->process(
    foo  => 'bar',
    content => 'CONTENT',
    list => [ qw /foo bar baz buz/ ],
);

like ($output, qr/\<xml\>bar\<\/xml\>/, 'some content');
like ($output, qr/\<xml\>\<\/xml\>/, 'empty content');
unlike ($output, qr/replaced/, 'replaced tag is not there');
like ($output, qr/CONTENT/, 'but content is');

my $test = Petal::Tiny->new (qq|<xml petal:content="data">foo</xml>|);
my $res  = $test->process (data => '$one $two', one => 'foo', two => 'bar');
unlike ($res, qr/foo/, 'content is not interpolated');

Test::More::done_testing();

__DATA__
<XML xmlns:tal="http://purl.org/petal/1.0/">
  <xml tal:content="foo">foo</xml>
  <xml tal:content="">foo</xml>
  <replaced tal:replace="content">content</replaced>
  <replaced tal:replace="">foo</replaced>
</XML>
