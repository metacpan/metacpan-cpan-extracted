use strict;
use utf8;
use Test::More;
use Test::Exception;
use Poz qw/z/;

my $strSchema = z->string;
isa_ok($strSchema, 'Poz::Types::string');
is($strSchema->parse('foo'), 'foo', 'string: foo');
is($strSchema->parse(''), '', 'string: ""');
is($strSchema->parse(0), 0, 'number: 0 (however it looks as a string in Perl)');
is($strSchema->parse(1), 1, 'number: 1 (however it looks as a string in Perl)');
is($strSchema->parse(-3), -3, 'number: -3 (however it looks as a string in Perl)');
throws_ok { $strSchema->parse(undef) } qr/^required/, 'undef is not a string';
throws_ok { $strSchema->parse({test => "foo"}) } qr/^Not a string/, 'hashref: {test => "foo"}';
throws_ok { $strSchema->parse([1, 2, 3]) } qr/^Not a string/, 'arrayref: [1, 2, 3]';

my $strSchemaRequiredError = z->string({required_error => 'tuna is required string'});
is($strSchemaRequiredError->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaRequiredError->parse(undef) } qr/^tuna is required string/, 'undef is not a string';

my $strSchemaInvalidTypeError = z->string({invalid_type_error => 'tuna is invalid'});
is($strSchemaInvalidTypeError->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaInvalidTypeError->parse([1, 2]) } qr/^tuna is invalid/, '[1, 2] is not a string';

my $strSchemaDefault = z->string->default('tuna');
is($strSchemaDefault->parse('foo'), 'foo', 'string: foo');
is($strSchemaDefault->parse(''), '', 'string: ""');
is($strSchemaDefault->parse(0), 0, 'number: 0 (however it looks as a string in Perl)');
is($strSchemaDefault->parse(1), 1, 'number: 1 (however it looks as a string in Perl)');
is($strSchemaDefault->parse(-3), -3, 'number: -3 (however it looks as a string in Perl)');
is($strSchemaDefault->parse(undef), 'tuna', 'when undef, default to "tuna"');

my $strSchemaDefaultSub = z->string->default(sub { 'tuna' });
is($strSchemaDefaultSub->parse('foo'), 'foo', 'string: foo');
is($strSchemaDefault->parse(''), '', 'string: ""');
is($strSchemaDefault->parse(0), 0, 'number: 0 (however it looks as a string in Perl)');
is($strSchemaDefault->parse(1), 1, 'number: 1 (however it looks as a string in Perl)');
is($strSchemaDefault->parse(-3), -3, 'number: -3 (however it looks as a string in Perl)');
is($strSchemaDefault->parse(undef), 'tuna', 'when undef, default to "tuna"');

my $strSchemaNullable = z->string->nullable;
is($strSchemaNullable->parse('foo'), 'foo', 'string: foo');
is($strSchemaNullable->parse(''), '', 'string: ""');
is($strSchemaNullable->parse(0), 0, 'number: 0 (however it looks as a string in Perl)');
is($strSchemaNullable->parse(1), 1, 'number: 1 (however it looks as a string in Perl)');
is($strSchemaNullable->parse(-3), -3, 'number: -3 (however it looks as a string in Perl)');
is($strSchemaNullable->parse(undef), undef, 'undef is nullable');

my $strSchemaOptional = z->string->optional;
is($strSchemaOptional->parse('foo'), 'foo', 'string: foo');
is($strSchemaOptional->parse(''), '', 'string: ""');
is($strSchemaOptional->parse(0), 0, 'number: 0 (however it looks as a string in Perl)');
is($strSchemaOptional->parse(1), 1, 'number: 1 (however it looks as a string in Perl)');
is($strSchemaOptional->parse(-3), -3, 'number: -3 (however it looks as a string in Perl)');
is($strSchemaOptional->parse(undef), undef, 'undef is optional');

my $strSchemaCoerce = z->coerce->string;
is($strSchemaCoerce->parse('foo'), 'foo', 'string: foo');
is($strSchemaCoerce->parse(''), '', 'string: ""');
is($strSchemaCoerce->parse(0), '0', 'number: 0 coerce to "0"');
is($strSchemaCoerce->parse(1), '1', 'number: 1 coerce to "1"');
is($strSchemaCoerce->parse(-3), '-3', 'number: -3 coerce to "-3"');
throws_ok { $strSchemaCoerce->parse(undef) } qr/^required/, 'undef';

my $strSchemaMax = z->string->max(3);
is($strSchemaMax->parse('foo'), 'foo', 'string: foo');
is($strSchemaMax->parse('fo'), 'fo', 'string: fo');
is($strSchemaMax->parse('f'), 'f', 'string: f');
throws_ok { $strSchemaMax->parse('fooo') } qr/^Too long/, 'string: fooo';

my $strSchemaMaxWithMessage = z->string->max(3, {message => 'tuna is too long'});
is($strSchemaMaxWithMessage->parse('f'), 'f', 'string: f');
throws_ok { $strSchemaMaxWithMessage->parse('fooo') } qr/^tuna is too long/, 'string: fooo';

my $strSchemaMin = z->string->min(3);
is($strSchemaMin->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaMin->parse('fo') } qr/^Too short/, 'string: fo';
throws_ok { $strSchemaMin->parse('f') } qr/^Too short/, 'string: f';
is($strSchemaMin->parse('fooo'), 'fooo', 'string: fooo');

my $strSchemaMinWithMessage = z->string->min(3, {message => 'tuna is too short'});
is($strSchemaMinWithMessage->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaMinWithMessage->parse('fo') } qr/^tuna is too short/, 'string: fo';

my $strSchemaLength = z->string->length(3);
is($strSchemaLength->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaLength->parse('fo') } qr/^Not the right length/, 'string: fo';
throws_ok { $strSchemaLength->parse('f') } qr/^Not the right length/, 'string: f';
throws_ok { $strSchemaLength->parse('fooo') } qr/^Not the right length/, 'string: fooo';

my $strSchemaLengthWithMessage = z->string->length(3, {message => 'tuna is not the right length'});
is($strSchemaLengthWithMessage->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaLengthWithMessage->parse('fo') } qr/^tuna is not the right length/, 'string: fo';

my $strSchemaEmail = z->string->email;
is($strSchemaEmail->parse('ytnobody@example.com'), 'ytnobody@example.com', 'string: ytnobody@example.com');
throws_ok { $strSchemaEmail->parse('ytnobody.example') } qr/^Not an email/, 'string: ytnobody.example';

my $strSchemaEmailWithMessage = z->string->email({message => 'tuna is not an email'});
is($strSchemaEmailWithMessage->parse('ytnobody@example.com'), 'ytnobody@example.com', 'string: ytnobody@example.com');
throws_ok { $strSchemaEmailWithMessage->parse('ytnobody.example') } qr/^tuna is not an email/, 'string: ytnobody.example';

my $strSchemaUrl = z->string->url;
is($strSchemaUrl->parse('http://example.com'), 'http://example.com', 'string: http://example.com');
is($strSchemaUrl->parse('https://example.com'), 'https://example.com', 'string: https://example.com');
throws_ok { $strSchemaUrl->parse('example') } qr/^Not an URL/, 'string: example';
throws_ok { $strSchemaUrl->parse('example.com') } qr/^Not an URL/, 'string: example.com';

my $strSchemaUrlWithMessage = z->string->url({message => 'tuna is not an URL'});
is($strSchemaUrlWithMessage->parse('http://example.com'), 'http://example.com', 'string: http://example.com');
throws_ok { $strSchemaUrlWithMessage->parse('example') } qr/^tuna is not an URL/, 'string: example';

my $strSchemaEmoji = z->string->emoji;
is($strSchemaEmoji->parse('🍣'), '🍣', 'string: emoji(sushi)');
is($strSchemaEmoji->parse('🍣🍣🍣'), '🍣🍣🍣', 'string: emoji(sushi)x3');
throws_ok { $strSchemaEmoji->parse('sushi') } qr/^Not an emoji/, 'string: sushi';

my $strSchemaEmojiWithMessage = z->string->emoji({message => 'tuna wants emoji'});
is($strSchemaEmojiWithMessage->parse('🍣'), '🍣', 'string: emoji(sushi)');
throws_ok { $strSchemaEmojiWithMessage->parse('sushi') } qr/^tuna wants emoji/, 'string: sushi';

my $strSchemaUUID = z->string->uuid;
is($strSchemaUUID->parse('550e8400-e29b-41d4-a716-446655440000'), '550e8400-e29b-41d4-a716-446655440000', 'string: 550e8400-e29b-41d4-a716-446655440000');
throws_ok { $strSchemaUUID->parse('550e8400-e29b-41d4-a716-4466554400g') } qr/^Not an UUID/, 'string: 550e8400-e29b-41d4-a716-4466554400g';

my $strSchemaUUIDWithMessage = z->string->uuid({message => 'tuna wants UUID'});
is($strSchemaUUIDWithMessage->parse('550e8400-e29b-41d4-a716-446655440000'), '550e8400-e29b-41d4-a716-446655440000', 'string: 550e8400-e29b-41d4-a716-446655440000');
throws_ok { $strSchemaUUIDWithMessage->parse('550e8400-e29b-41d4-a716-4466554400g') } qr/^tuna wants UUID/, 'string: 550e8400-e29b-41d4-a716-4466554400g';

my $strSchemaNanoID = z->string->nanoid;
is($strSchemaNanoID->parse('V1StGXR8_Z5jdHi6B-myT'), 'V1StGXR8_Z5jdHi6B-myT', 'string: V1StGXR8_Z5jdHi6B-myT');
throws_ok { $strSchemaNanoID->parse('V1StGXR8_Z5jdHi6B-myT!') } qr/^Not a nanoid/, 'string: V1StGXR8_Z5jdHi6B-myT!';

my $strSchemaNanoIDWithMessage = z->string->nanoid({message => 'tuna wants nanoid'});
is($strSchemaNanoIDWithMessage->parse('V1StGXR8_Z5jdHi6B-myT'), 'V1StGXR8_Z5jdHi6B-myT', 'string: V1StGXR8_Z5jdHi6B-myT');
throws_ok { $strSchemaNanoIDWithMessage->parse('V1StGXR8_Z5jdHi6B-myT!') } qr/^tuna wants nanoid/, 'string: V1StGXR8_Z5jdHi6B-myT!';

my $strSchemaCUID = z->string->cuid;
is($strSchemaCUID->parse('ck7q2x5qg0000y3z1z1v6zj5v'), 'ck7q2x5qg0000y3z1z1v6zj5v', 'string: ck7q2x5qg0000y3z1z1v6zj5v');
throws_ok { $strSchemaCUID->parse('ck7q2x5qg0000y3z1z1v6zj5v!') } qr/^Not a cuid/, 'string: ck7q2x5qg0000y3z1z1v6zj5v!';

my $strSchemaCUIDWithMessage = z->string->cuid({message => 'tuna wants cuid'});
is($strSchemaCUIDWithMessage->parse('ck7q2x5qg0000y3z1z1v6zj5v'), 'ck7q2x5qg0000y3z1z1v6zj5v', 'string: ck7q2x5qg0000y3z1z1v6zj5v');
throws_ok { $strSchemaCUIDWithMessage->parse('ck7q2x5qg0000y3z1z1v6zj5v!') } qr/^tuna wants cuid/, 'string: ck7q2x5qg0000y3z1z1v6zj5v!';

my $strSchemaCUID2 = z->string->cuid2;
is($strSchemaCUID2->parse('xijvsn3eopgrhwmy231rc3nv'), 'xijvsn3eopgrhwmy231rc3nv', 'string: xijvsn3eopgrhwmy231rc3nv');
throws_ok { $strSchemaCUID2->parse('xijvsn3eopgrhwmy231rc3nv!') } qr/^Not a cuid2/, 'string: xijvsn3eopgrhwmy231rc3nv!';

my $strSchemaCUID2WithMessage = z->string->cuid2({message => 'tuna wants cuid2'});
is($strSchemaCUID2WithMessage->parse('xijvsn3eopgrhwmy231rc3nv'), 'xijvsn3eopgrhwmy231rc3nv', 'string: xijvsn3eopgrhwmy231rc3nv');
throws_ok { $strSchemaCUID2WithMessage->parse('xijvsn3eopgrhwmy231rc3nv!') } qr/^tuna wants cuid2/, 'string: xijvsn3eopgrhwmy231rc3nv!';

my $strSchemaULID = z->string->ulid;
is($strSchemaULID->parse('01JASTEZMB38WMAF25QFKQBPSN'), '01JASTEZMB38WMAF25QFKQBPSN', 'string: 01JASTEZMB38WMAF25QFKQBPSN');
throws_ok { $strSchemaULID->parse('01JASTEZMB38WMAF25QFKQBPSN!') } qr/^Not an ulid/, 'string: 01JASTEZMB38WMAF25QFKQBPSN!';

my $strSchemaULIDWithMessage = z->string->ulid({message => 'tuna wants ulid'});
is($strSchemaULIDWithMessage->parse('01JASTEZMB38WMAF25QFKQBPSN'), '01JASTEZMB38WMAF25QFKQBPSN', 'string: 01JASTEZMB38WMAF25QFKQBPSN');
throws_ok { $strSchemaULIDWithMessage->parse('01JASTEZMB38WMAF25QFKQBPSN!') } qr/^tuna wants ulid/, 'string: 01JASTEZMB38WMAF25QFKQBPSN!';

my $strSchemaRegex = z->string->regex(qr/^\d{3}-\d{4}$/);
is($strSchemaRegex->parse('123-4567'), '123-4567', 'string: 123-4567');
throws_ok { $strSchemaRegex->parse('1234-567') } qr/^Not match regex/, 'string: 1234-567';

my $strSchemaRegexWithMessage = z->string->regex(qr/^\d{3}-\d{4}$/, {message => 'tuna wants like 123-4567'});
is($strSchemaRegexWithMessage->parse('123-4567'), '123-4567', 'string: 123-4567');
throws_ok { $strSchemaRegexWithMessage->parse('1234-567') } qr/^tuna wants like 123-4567/, 'string: 1234-567';

my $strSchemaIncludes = z->string->includes('foo');
is($strSchemaIncludes->parse('foo'), 'foo', 'string: foo');
is($strSchemaIncludes->parse('foobar'), 'foobar', 'string: foobar');
is($strSchemaIncludes->parse('barfoo'), 'barfoo', 'string: barfoo');
throws_ok { $strSchemaIncludes->parse('bar') } qr/^Not includes foo/, 'string: bar';

my $strSchemaIncludesWithMessage = z->string->includes('foo', {message => 'tuna wants to include foo'});
is($strSchemaIncludesWithMessage->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaIncludesWithMessage->parse('bar') } qr/^tuna wants to include foo/, 'string: bar';

my $strSchemaStartsWith = z->string->startsWith('foo');
is($strSchemaStartsWith->parse('foo'), 'foo', 'string: foo');
is($strSchemaStartsWith->parse('foobar'), 'foobar', 'string: foobar');
throws_ok { $strSchemaStartsWith->parse('barfoo') } qr/^Not starts with foo/, 'string: barfoo';

my $strSchemaStartsWithMessage = z->string->startsWith('foo', {message => 'tuna wants to start with foo'});
is($strSchemaStartsWithMessage->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaStartsWithMessage->parse('barfoo') } qr/^tuna wants to start with foo/, 'string: barfoo';

my $strSchemaEndsWith = z->string->endsWith('foo');
is($strSchemaEndsWith->parse('foo'), 'foo', 'string: foo');
is($strSchemaEndsWith->parse('barfoo'), 'barfoo', 'string: barfoo');
throws_ok { $strSchemaEndsWith->parse('foobar') } qr/^Not ends with foo/, 'string: foobar';

my $strSchemaEndsWithMessage = z->string->endsWith('foo', {message => 'tuna wants to end with foo'});
is($strSchemaEndsWithMessage->parse('foo'), 'foo', 'string: foo');
throws_ok { $strSchemaEndsWithMessage->parse('foobar') } qr/^tuna wants to end with foo/, 'string: foobar';

my $strSchemaIP = z->string->ip;
is($strSchemaIP->parse('10.20.30.40'), '10.20.30.40', 'string: 10.20.30.40');
throws_ok { $strSchemaIP->parse('10.20.30.256') } qr/^Not an IP address/, 'string: 10.20.30.256';
is($strSchemaIP->parse('2001:0db8:85a3:0000:0000:8a2e:0370:7334'), '2001:0db8:85a3:0000:0000:8a2e:0370:7334', 'string: 2001:0db8:85a3:0000:0000:8a2e:0370:7334');
throws_ok { $strSchemaIP->parse('2001:0db8:85a3:0000:0000:8a2e:0370:7334:1') } qr/^Not an IP address/, 'string: 2001:0db8:85a3:0000:0000:8a2e:0370:7334:1';

my $strSchemaIPWithMessage = z->string->ip({message => 'tuna wants IP address'});
is($strSchemaIPWithMessage->parse('10.20.30.40'), '10.20.30.40', 'string: 10.20.30.40');
throws_ok { $strSchemaIPWithMessage->parse('10.20.30.256') } qr/^tuna wants IP address/, 'string: 10.20.30.256';
is($strSchemaIPWithMessage->parse('2001:0db8:85a3:0000:0000:8a2e:0370:7334'), '2001:0db8:85a3:0000:0000:8a2e:0370:7334', 'string: 2001:0db8:85a3:0000:0000:8a2e:0370:7334');
throws_ok { $strSchemaIPWithMessage->parse('2001:0db8:85a3:0000:0000:8a2e:0370:7334:1') } qr/^tuna wants IP address/, 'string: 2001:0db8:85a3:0000:0000:8a2e:0370:7334:1';

my $strSchemaIPv4 = z->string->ip({version => 'v4'});
is($strSchemaIPv4->parse('10.20.30.40'), '10.20.30.40', 'string: 10.20.30.40');
throws_ok { $strSchemaIPv4->parse('10.20.30.256') } qr/^Not an IP address/, 'string: 10.20.30.256';
throws_ok { $strSchemaIPv4->parse('2001:0db8:85a3:0000:0000:8a2e:0370:7334') } qr/^Not an IP address/, 'string: 2001:0db8:85a3:0000:0000:8a2e:0370:7334';
throws_ok { $strSchemaIPv4->parse('2001:0db8:85a3:0000:0000:8a2e:0370:7334:1') } qr/^Not an IP address/, 'string: 2001:0db8:85a3:0000:0000:8a2e:0370:7334:1';

my $strSchemaIPv6 = z->string->ip({version => 'v6'});
throws_ok { $strSchemaIPv6->parse('10.20.30.40') } qr/^Not an IP address/, 'string: 10.20.30.40';
throws_ok { $strSchemaIPv6->parse('10.20.30.256') } qr/^Not an IP address/, 'string: 10.20.30.256';
is($strSchemaIPv6->parse('2001:0db8:85a3:0000:0000:8a2e:0370:7334'), '2001:0db8:85a3:0000:0000:8a2e:0370:7334', 'string: 2001:0db8:85a3:0000:0000:8a2e:0370:7334');
throws_ok { $strSchemaIPv6->parse('2001:0db8:85a3:0000:0000:8a2e:0370:7334:1') } qr/^Not an IP address/, 'string: 2001:0db8:85a3:0000:0000:8a2e:0370:7334:1';

my $strSchemaTrim = z->string->trim;
is($strSchemaTrim->parse(' foo '), 'foo', 'string: foo');
is($strSchemaTrim->parse('foo '), 'foo', 'string: foo');
is($strSchemaTrim->parse(' foo'), 'foo', 'string: foo');
is($strSchemaTrim->parse('foo'), 'foo', 'string: foo');

my $strSchemaToLowerCase = z->string->toLowerCase;
is($strSchemaToLowerCase->parse('FOO'), 'foo', 'string: foo');
is($strSchemaToLowerCase->parse('foo'), 'foo', 'string: foo');

my $strSchemaToUpperCase = z->string->toUpperCase;
is($strSchemaToUpperCase->parse('foo'), 'FOO', 'string: FOO');
is($strSchemaToUpperCase->parse('FOO'), 'FOO', 'string: FOO');

my $strSchemaDate = z->string->date;
is($strSchemaDate->parse('2020-01-01'), '2020-01-01', 'string: 2020-01-01');
throws_ok { $strSchemaDate->parse('2020-01-32') } qr/^Not a date/, 'string: 2020-01-32';
throws_ok { $strSchemaDate->parse('2020-13-01') } qr/^Not a date/, 'string: 2020-13-01';
throws_ok { $strSchemaDate->parse('2020-01-01T00:00:00Z') } qr/^Not a date/, 'string: 2020-01-01T00:00:00Z';

my $strSchemaDateWithMessage = z->string->date({message => 'tuna wants date'});
is($strSchemaDateWithMessage->parse('2020-01-01'), '2020-01-01', 'string: 2020-01-01');
throws_ok { $strSchemaDateWithMessage->parse('2020-01-32') } qr/^tuna wants date/, 'string: 2020-01-32';

my $strSchemaTime = z->string->time;
is($strSchemaTime->parse('00:00:00'), '00:00:00', 'string: 00:00:00');
is($strSchemaTime->parse('00:00:10.102'), '00:00:10.102', 'string: 00:00:10.102');
is($strSchemaTime->parse('00:00:10.102345'), '00:00:10.102345', 'string: 00:00:10.102345');
throws_ok { $strSchemaTime->parse('24:00:00') } qr/^Not a time/, 'string: 24:00:00';
throws_ok { $strSchemaTime->parse('00:00:60') } qr/^Not a time/, 'string: 00:00:60';
throws_ok { $strSchemaTime->parse('00:60:00') } qr/^Not a time/, 'string: 00:60:00';
throws_ok { $strSchemaTime->parse('60:00:00') } qr/^Not a time/, 'string: 60:00:00';
throws_ok { $strSchemaTime->parse('00:00:00Z') } qr/^Not a time/, 'string: 00:00:00Z';

my $strSchemaTimeWithMessage = z->string->time({message => 'tuna wants time'});
is($strSchemaTimeWithMessage->parse('00:00:00'), '00:00:00', 'string: 00:00:00');
throws_ok { $strSchemaTimeWithMessage->parse('24:00:00') } qr/^tuna wants time/, 'string: 24:00:00';

my $strSchemaTimeWithPrecision3 = z->string->time({precision => 3});
is($strSchemaTimeWithPrecision3->parse('00:00:00'), '00:00:00', 'string: 00:00:00');
is($strSchemaTimeWithPrecision3->parse('00:00:10.102'), '00:00:10.102', 'string: 00:00:10.102');
throws_ok { $strSchemaTimeWithPrecision3->parse('00:00:10.102345') } qr/^Not a time/, 'string: 00:00:10.102345';
throws_ok { $strSchemaTimeWithPrecision3->parse('24:00:00') } qr/^Not a time/, 'string: 24:00:00';
throws_ok { $strSchemaTimeWithPrecision3->parse('00:00:60') } qr/^Not a time/, 'string: 00:00:60';
throws_ok { $strSchemaTimeWithPrecision3->parse('00:60:00') } qr/^Not a time/, 'string: 00:60:00';
throws_ok { $strSchemaTimeWithPrecision3->parse('60:00:00') } qr/^Not a time/, 'string: 60:00:00';
throws_ok { $strSchemaTimeWithPrecision3->parse('00:00:00Z') } qr/^Not a time/, 'string: 00:00:00Z';

my $strSchemaDateTime = z->string->datetime({offset => 1, precision => 6});
is($strSchemaDateTime->parse('2020-01-01T00:00:00'), '2020-01-01T00:00:00', 'string: 2020-01-01T00:00:00');
is($strSchemaDateTime->parse('2020-01-01T00:00:00Z'), '2020-01-01T00:00:00Z', 'string: 2020-01-01T00:00:00Z');
is($strSchemaDateTime->parse('2020-01-01T00:00:00+09:00'), '2020-01-01T00:00:00+09:00', 'string: 2020-01-01T00:00:00+09:00');
is($strSchemaDateTime->parse('2020-01-01T00:00:00+09'), '2020-01-01T00:00:00+09', 'string: 2020-01-01T00:00:00+09');
is($strSchemaDateTime->parse('2020-01-01T00:00:00+0900'), '2020-01-01T00:00:00+0900', 'string: 2020-01-01T00:00:00+0900');
is($strSchemaDateTime->parse('2020-01-01T00:00:00.123Z'), '2020-01-01T00:00:00.123Z', 'string: 2020-01-01T00:00:00.123Z');
is($strSchemaDateTime->parse('2020-01-01T00:00:00.123456+09'), '2020-01-01T00:00:00.123456+09', 'string: 2020-01-01T00:00:00.123456+09');
throws_ok { $strSchemaDateTime->parse('2020-01-32T00:00:00') } qr/^Not a datetime/, 'string: 2020-01-32T00:00:00';
throws_ok { $strSchemaDateTime->parse('2020-13-01T00:00:00') } qr/^Not a datetime/, 'string: 2020-13-01T00:00:00';
throws_ok { $strSchemaDateTime->parse('2020-01-01T24:00:00') } qr/^Not a datetime/, 'string: 2020-01-01T24:00:00';
throws_ok { $strSchemaDateTime->parse('2020-01-01T00:00:60') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:60';
throws_ok { $strSchemaDateTime->parse('2020-01-01T00:60:00') } qr/^Not a datetime/, 'string: 2020-01-01T00:60:00';
throws_ok { $strSchemaDateTime->parse('2020-01-01T60:00:00') } qr/^Not a datetime/, 'string: 2020-01-01T60:00:00';
throws_ok { $strSchemaDateTime->parse('2020-01-01T00:00:00Z+09:00') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00Z+09:00';

my $strSchemaDateTimeWithMessage = z->string->datetime({
    offset => 1, precision => 6, message => 'tuna wants datetime',
});
is($strSchemaDateTimeWithMessage->parse('2020-01-01T00:00:00'), '2020-01-01T00:00:00', 'string: 2020-01-01T00:00:00');
throws_ok { $strSchemaDateTimeWithMessage->parse('2020-01-32T00:00:00') } qr/^tuna wants datetime/, 'string: 2020-01-32T00:00:00';

my $strSchemaDateTimeNoOffset = z->string->datetime({precision => 6});
is($strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:00'), '2020-01-01T00:00:00', 'string: 2020-01-01T00:00:00');
is($strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:00Z'), '2020-01-01T00:00:00Z', 'string: 2020-01-01T00:00:00Z');
is($strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:00.123Z'), '2020-01-01T00:00:00.123Z', 'string: 2020-01-01T00:00:00.123Z');
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:00+09:00') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00+09:00';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:00+09') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00+09';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:00+0900') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00+0900';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:00.123456+09') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00.123456+09';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-32T00:00:00') } qr/^Not a datetime/, 'string: 2020-01-32T00:00:00';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-13-01T00:00:00') } qr/^Not a datetime/, 'string: 2020-13-01T00:00:00';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T24:00:00') } qr/^Not a datetime/, 'string: 2020-01-01T24:00:00';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:60') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:60';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T00:60:00') } qr/^Not a datetime/, 'string: 2020-01-01T00:60:00';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T60:00:00') } qr/^Not a datetime/, 'string: 2020-01-01T60:00:00';
throws_ok { $strSchemaDateTimeNoOffset->parse('2020-01-01T00:00:00Z+09:00') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00Z+09:00';

my $strSchemaDateTimeNoOffsetWithPrecision3 = z->string->datetime({precision => 3});
is($strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00'), '2020-01-01T00:00:00', 'string: 2020-01-01T00:00:00');
is($strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00Z'), '2020-01-01T00:00:00Z', 'string: 2020-01-01T00:00:00Z');
is($strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00.123Z'), '2020-01-01T00:00:00.123Z', 'string: 2020-01-01T00:00:00.123Z');
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00+09:00') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00+09:00';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00+09') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00+09';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00+0900') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00+0900';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00.123456+09') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00.123456+09';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00.123456') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00.123456';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-32T00:00:00') } qr/^Not a datetime/, 'string: 2020-01-32T00:00:00';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-13-01T00:00:00') } qr/^Not a datetime/, 'string: 2020-13-01T00:00:00';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T24:00:00') } qr/^Not a datetime/, 'string: 2020-01-01T24:00:00';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:60') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:60';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:60:00') } qr/^Not a datetime/, 'string: 2020-01-01T00:60:00';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T60:00:00') } qr/^Not a datetime/, 'string: 2020-01-01T60:00:00';
throws_ok { $strSchemaDateTimeNoOffsetWithPrecision3->parse('2020-01-01T00:00:00Z+09:00') } qr/^Not a datetime/, 'string: 2020-01-01T00:00:00Z+09:00';

my $strSchemaDuration = z->string->duration;
is($strSchemaDuration->parse('P1Y2M3DT4H5M6S'), 'P1Y2M3DT4H5M6S', 'string: P1Y2M3DT4H5M6S');
throws_ok { $strSchemaDuration->parse('P1Y2M3DT4H5M6S1') } qr/^Not a duration/, 'string: P1Y2M3DT4H5M6S1';
throws_ok { $strSchemaDuration->parse('P1Y2M3DT4H5M6S1Z') } qr/^Not a duration/, 'string: P1Y2M3DT4H5M6S1Z';

my $strSchemaDurationWithMessage = z->string->duration({message => 'tuna wants duration'});
is($strSchemaDurationWithMessage->parse('P1Y2M3DT4H5M6S'), 'P1Y2M3DT4H5M6S', 'string: P1Y2M3DT4H5M6S');
throws_ok { $strSchemaDurationWithMessage->parse('P1Y2M3DT4H5M6S1') } qr/^tuna wants duration/, 'string: P1Y2M3DT4H5M6S1';

my $strSchemaBase64 = z->string->base64;
is($strSchemaBase64->parse('VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw=='), 'VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw==', 'string: VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw==');
throws_ok { $strSchemaBase64->parse('!VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw') } qr/^Not a base64/, 'string: !VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw';

my $strSchemaBase64WithMessage = z->string->base64({message => 'tuna wants base64'});
is($strSchemaBase64WithMessage->parse('VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw=='), 'VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw==', 'string: VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw==');
throws_ok { $strSchemaBase64WithMessage->parse('!VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw') } qr/^tuna wants base64/, 'string: !VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGluZw';

done_testing();
