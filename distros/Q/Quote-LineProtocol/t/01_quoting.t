use strict;
use lib 'lib';
use Test::More 0.98;
use Quote::LineProtocol qw(measurement tags fields timestamp);

is(measurement('Measurement'), 'Measurement', 'Measurement is correctly quoted');
is(measurement('Measurement,'), 'Measurement\,', 'Comma in measurement is correctly quoted');
is(measurement('Measure ment'), 'Measure\ ment', 'Space in measurement is correctly quoted');
isnt(measurement('Measure ment'), 'Measure ment', 'No space without quoting in measurement');

is(tags(foo => 'Bar'), 'foo=Bar', 'Tag value is correctly quoted');
is(tags(foo => 'Bar baz'), 'foo=Bar\ baz', 'Space in tag value is correctly quoted');
is(tags(foo => 'Bar='), 'foo=Bar\=', 'Equal sign in tag value is correctly quoted');
is(tags(foo => 'Bar,'), 'foo=Bar\,', 'Comma in tag value is correctly quoted');
is(tags('foo bar' => 'Baz'), 'foo\ bar=Baz', 'Space in tag is correctly quoted');
is(tags('fo=o' => 'Bar'), 'fo\=o=Bar', 'Equal sign in tag value is correctly quoted');
is(tags('fo,o' => 'Bar'), 'fo\,o=Bar', 'Comma in tag value is correctly quoted');

is(fields(foo => 'Bar'), 'foo="Bar"', 'Field value is correctly quoted');
is(fields(foo => 'Ba"r'), 'foo="Ba\"r"', 'Double quote in field value is correctly quoted');
is(fields('foo bar' => 'Baz'), 'foo\ bar="Baz"', 'Space in  is correctly quoted');
is(fields('fo=o' => 'Bar'), 'fo\=o="Bar"', 'Equal sign in tag value is correctly quoted');
is(fields('fo,o' => 'Bar'), 'fo\,o="Bar"', 'Comma in tag value is correctly quoted');
is(fields(foo => { type => 'f', value => 3.14}), 'foo=3.14', 'Float value is correctly displayed');
is(fields(foo => { type => 'i', value => 3}), 'foo=3i', 'Int value is correctly displayed');
is(fields(foo => { type => 'u', value => 1}), 'foo=1u', 'UInt value is correctly displayed');
is(fields(foo => { type => 'b', value => 'True'}), 'foo=True', 'Boolean value is correctly displayed');
is(fields(foo => { type => 's', value => 'True'}), 'foo="True"', 'String value is correctly displayed');

done_testing;

