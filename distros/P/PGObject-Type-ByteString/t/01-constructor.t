use PGObject::Type::ByteString;
use Test::More;

my $test;

$test = PGObject::Type::ByteString->from_db("\xCA\xFE\xBA\xBE");
isa_ok $test, 'PGObject::Type::ByteString', 'non-UTF characters in string; expected class';
is $test->to_db->{value}, "\xCA\xFE\xBA\xBE", 'expected db out';

done_testing;
