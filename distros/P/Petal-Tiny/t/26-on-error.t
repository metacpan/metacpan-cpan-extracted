# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More tests => 2;
BEGIN { use_ok('Petal::Tiny') };


my $data = join '', <DATA>;
my $petal = Petal::Tiny->new($data);
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

like ($output, qr/\<fail\>ouch...\<\/fail\>/, 'ouchy');

__DATA__
<XML xmlns:tal="http://purl.org/petal/1.0/">
  <fail tal:on-error="string:ouch...">
    <othertag tal:content="i/is/fail">success!</othertag>
  </fail>
</XML>
