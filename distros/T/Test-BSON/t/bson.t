use strict;
use warnings;
use Test::Tester;
use Test::More tests => 36;
use Test::BSON;

my $valid = "1\x00\x00\x00\x04BSON\x00&\x00\x00\x00\x020\x00"
          . "\x08\x00\x00\x00awesome\x00\x011\x00333333\x14@"
          . "\x102\x00\xC2\x07\x00\x00\x00\x00";

my $different = $valid;
$different =~ s/awesome/AWSUM!!/;
$different =~ tr/\xC2/\xC0/;

my $invalid = $valid . 'KTHXBYE!';

my $name;

note 'Testing bson_ok';

$name = 'Valid BSON should succeed';
check_test(
    sub { bson_ok $valid, $name },
    {
        ok   => 1,
        name => $name,
    },
    $name
);

$name = 'Invalid BSON should fail';
check_test(
    sub { bson_ok $invalid, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);

note 'Testing bson_is';

$name = 'Identical BSON should match';
check_test(
    sub { bson_is $valid, $valid, $name },
    {
        ok   => 1,
        name => $name,
    },
    $name
);

$name = 'Different BSON should fail';
check_test(
    sub { bson_is $different, $valid, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);

$name = 'Invalid BSON as 1st argument should fail';
check_test(
    sub { bson_is $valid, $invalid, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);

$name = 'Invalid BSON as 2nd argument should fail';
check_test(
    sub { bson_is $invalid, $valid, $name },
    {
        ok   => 0,
        name => $name,
    },
    $name
);
