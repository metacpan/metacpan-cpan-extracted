# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More tests => 3;
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

unlike ($output, qr/omit/, 'omitted');
like ($output, qr/imhere/, 'not-omitted');

__DATA__
<XML xmlns:tal="http://purl.org/petal/1.0/">
  <omit tal:omit-tag="">stuff</omit>
  <omit tal:omit-tag="true:--stuff">stuff</omit>
  <imhere tal:omit-tag="false:--stuff">stuff</imhere>
</XML>
