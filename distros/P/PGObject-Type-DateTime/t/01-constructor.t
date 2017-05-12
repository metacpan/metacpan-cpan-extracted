use PGObject::Type::DateTime;
use Test::More tests => 22;

my $test;

$test = PGObject::Type::DateTime->from_db("2013-12-11 11:11:11.11234-08");
isa_ok $test, 'DateTime', 'long parse, isa date time';
isa_ok $test, 'PGObject::Type::DateTime', 'long parse, is expected class';
is $test->to_db, "2013-12-11 11:11:11.11234-08", 'long parse, expected db out';
ok $test->is_tz, 'long parse, timezone';

$test = PGObject::Type::DateTime->from_db('2012-12-11'); 
isa_ok $test, 'DateTime', 'date only, isa date time';
isa_ok $test, 'PGObject::Type::DateTime', 'date only, is expected class';
is $test->to_db, "2012-12-11", 'date only, expected db out';
is $test->is_tz, 0, 'date only, no timezone';

$test = PGObject::Type::DateTime->from_db('11:11:23.1111');
isa_ok $test, 'DateTime', 'time only, isa date time';
isa_ok $test, 'PGObject::Type::DateTime', 'time only, is expected class';
is $test->to_db, "11:11:23.1111", 'long parse, expected db out';
is $test->is_tz, 0, 'time only, no timezone';

$test = PGObject::Type::DateTime->from_db("2013-12-11 00:00:00.0000-08");
isa_ok $test, 'DateTime', 'Midnight, isa date time';
isa_ok $test, 'PGObject::Type::DateTime', 'Midnight. is expected class';
is $test->to_db, "2013-12-11 00:00:00.0-08", 'Midnight, expected db out';
ok $test->is_tz, 'Midnight, timezone';

$test = PGObject::Type::DateTime->from_db("2013-12-11 00:00:00.0000+08");
isa_ok $test, 'DateTime', 'Midnight, positive offset, isa date time';
isa_ok $test, 'PGObject::Type::DateTime', 'Midnight positive offset. is expected class';
is $test->to_db, "2013-12-11 00:00:00.0+08", 'Midnight positive offset, expected db out';
ok $test->is_tz, 'Midnight, positive offset, timezone';

$test =  PGObject::Type::DateTime->from_db(undef);
isa_ok $test, 'DateTime', 'undef';
is $test->to_db, undef;

