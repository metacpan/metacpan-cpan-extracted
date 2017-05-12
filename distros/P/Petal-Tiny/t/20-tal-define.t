# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;
BEGIN { use_ok('Petal::Tiny') };

my $data = join '', <DATA>;
my $petal  = Petal::Tiny->new($data);
my $output = $petal->process(
    foo  => 'bar',
    list => [ qw /foo bar baz buz/ ],
);

like ($output, qr/\>one\</, 'one');
like ($output, qr/\>two\</, 'two');

Test::More::done_testing();

__DATA__
<xml petal:define="one string:one; two string:two">
    <xml petal:content="one">GET</xml>
    <xml petal:content="two">UP - AAAA</xml>
</xml>
