package MooX::Types::MooseLike::Test;
use strict;
use warnings FATAL => 'all';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has 'a_bool' => (
  is  => 'ro',
  isa => Bool,
  );
has 'an_undef' => (
  is  => 'ro',
  isa => Undef,
  );
has 'a_defined' => (
  is  => 'ro',
  isa => Defined,
  );
has 'a_value' => (
  is  => 'ro',
  isa => Value,
  );
has 'a_string' => (
  is  => 'ro',
  isa => Str,
  );
has 'a_number' => (
  is  => 'ro',
  isa => Num,
  );
has 'an_integer' => (
  is  => 'ro',
  isa => Int,
  );
has 'a_ref' => (
  is  => 'ro',
  isa => Ref,
  );
has 'an_array' => (
  is  => 'ro',
  isa => ArrayRef,
  );
has 'a_hash' => (
  is  => 'ro',
  isa => HashRef,
  );
has 'a_code' => (
  is  => 'ro',
  isa => CodeRef,
  );
has 'a_regex' => (
  is  => 'ro',
  isa => RegexpRef,
  );
has 'a_glob' => (
  is  => 'ro',
  isa => GlobRef,
  );
has 'a_filehandle' => (
  is  => 'ro',
  isa => FileHandle,
  );
has 'an_object' => (
  is  => 'ro',
  isa => Object,
  );
has 'legal_age' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not of legal age"
      unless (is_Int($_[0]) && $_[0] > 17);
    },
  );

package main;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;
use IO::Handle;
use MooX::Types::MooseLike::Base qw(:all);

ok(is_Str('x'),       'is_Str');
ok(!is_Str([]),       'is_Str fails on ArrayRef');
ok(is_Num(3.142),     'is_Num');
ok(is_Num('9'),       'is_Num');
ok(!is_Num('xxx'),    'is_Num fails on a non-numeric string');
ok(is_Int(-3),        'is_Int');
ok(!is_Int(3.142),    'is_Int fails on a Float');
ok(is_Bool('0'),      '0 is_Bool');
ok(is_Bool(''),       'empty string is_Bool');
ok(is_Bool(),         'undef is_Bool');
ok(is_Bool(1),        '1 is_Bool');
ok(!is_Bool(-1),      'is_Bool fails on -1');
ok(is_ArrayRef([]),   'is_ArrayRef');
ok(!is_ArrayRef('1'), 'is_ArrayRef fails on 1');
ok(is_HashRef({}),    'is_HashRef');
ok(!is_HashRef([]),   'is_HashRef fails on []');
ok(is_CodeRef(sub { }), 'is_CodeRef');
ok(!is_CodeRef({}),            'is_CodeRef fails on {}');
ok(is_Object(IO::Handle->new), 'Object');
ok(!is_Object({}),             'is_Object fails on HashRef');

# Test Bool
ok(MooX::Types::MooseLike::Test->new(a_bool => undef), 'undef is a Bool');
ok(MooX::Types::MooseLike::Test->new(a_bool => 0), '0 is a Bool');
my $false_boolean_value = 0.001;
like(
  exception {
    MooX::Types::MooseLike::Test->new(a_bool => $false_boolean_value);
  },
  qr/$false_boolean_value is not a Boolean/,
  'a non-boolean is an exception when we want a Bool'
  );

# Undef
ok(MooX::Types::MooseLike::Test->new(an_undef => undef), 'Undef');
like(
  exception { MooX::Types::MooseLike::Test->new(an_undef => '') },
  qr/is not undef/,
  'empty string is an exception when we want an Undef type'
  );

# Defined
ok(MooX::Types::MooseLike::Test->new(a_defined => ''), 'Defined');
like(
  exception { MooX::Types::MooseLike::Test->new(a_defined => undef) },
  qr/is not defined/,
  'undef is an exception when we want a Defined type'
  );

# Test Value
ok(MooX::Types::MooseLike::Test->new(a_value => ''), 'empty string Value');
ok(MooX::Types::MooseLike::Test->new(a_value => 0), 'zero Value');
ok(MooX::Types::MooseLike::Test->new(a_value => 'yarn'), 'word Value');
like(
  exception { MooX::Types::MooseLike::Test->new(a_value => undef) },
  qr/undef is not a value/,
  'undef is an exception when we want a Value'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_value => []) },
  qr/ARRAY.*?is not a value/,
  'an ArrayRef is an exception when we want a Value'
  );

# Test Str
ok(MooX::Types::MooseLike::Test->new(a_string => ''), 'Empty string');
ok(MooX::Types::MooseLike::Test->new(a_string => '0'), 'Zero as a string');
ok(MooX::Types::MooseLike::Test->new(a_string => 'barn'), 'Word string');
like(
  exception { MooX::Types::MooseLike::Test->new(a_string => undef) },
  qr/undef is not a string/,
  'undef is an exception when we want a Str'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_string => []) },
  qr/ARRAY.*?is not a string/,
  'an ArrayRef is an exception when we want a Str'
  );

# Test Num
ok(MooX::Types::MooseLike::Test->new(a_number => 0), 'Num: zero');
ok(MooX::Types::MooseLike::Test->new(a_number => "+3"), 'Num string: positive int');
ok(MooX::Types::MooseLike::Test->new(a_number => "-5"), 'Num string: negative int');
ok(MooX::Types::MooseLike::Test->new(a_number => 123), 'Num: positive int');
ok(MooX::Types::MooseLike::Test->new(a_number => 3.14), 'Num: positive decimal');
ok(MooX::Types::MooseLike::Test->new(a_number => -5.26), 'Num: negative decimal');
ok(MooX::Types::MooseLike::Test->new(a_number => "+3.14"), 'Num string: positive decimal');
ok(MooX::Types::MooseLike::Test->new(a_number => ".14"), 'Num string: positive decimal, short form');
ok(MooX::Types::MooseLike::Test->new(a_number => "-.14"), 'Num string: negative decimal, short form');
ok(MooX::Types::MooseLike::Test->new(a_number => "1E1"), 'Num string: E');
ok(MooX::Types::MooseLike::Test->new(a_number => ".5e+123"), 'Num string: E');
ok(MooX::Types::MooseLike::Test->new(a_number => "12.5e-2"), 'Num string: E');
ok(MooX::Types::MooseLike::Test->new(a_number => "0123"), 'Num string: octal int');
like(
  exception { MooX::Types::MooseLike::Test->new(a_number => undef) },
  qr/undef is not a number/,
  'undef is an exception when we want a number'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_number => '') },
  qr/The empty string is not a number/,
  'The empty string is an exception when we want a number'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_number => '5x5') },
  qr/is not a number/,
  'a non number is an exception when we want a number'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_number => "0b1110011") },
  qr/is not a number/,
  'binary integer string is an exception when we want a number'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_number => "0x1234") },
  qr/is not a number/,
  'hexadecimal integer string is an exception when we want a number'
  );

# Test Int
ok(MooX::Types::MooseLike::Test->new(an_integer => -1), 'Int');
like(
  exception { MooX::Types::MooseLike::Test->new(an_integer => undef) },
  qr/undef is not an integer/,
  'undef is an exception when we want an Integer'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(an_integer => '') },
  qr/The empty string is not an integer/,
  'The empty string is an exception when we want an Integer'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(an_integer => 1.01) },
  qr/is not an integer/,
  'a non-integer is an exception when we want an Integer'
  );

# Test Ref
ok(MooX::Types::MooseLike::Test->new(a_ref => []), 'Ref: ArrayRef');
like(
  exception { MooX::Types::MooseLike::Test->new(a_ref => undef) },
  qr/is not a reference/,
  'undef is an exception when we want a reference'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_ref => '') },
  qr/is not a reference/,
  'The empty string is an exception when we want a reference'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_ref => 0) },
  qr/is not a reference/,
  'zero is an exception when we want an reference'
  );

# Test ArrayRef
ok(MooX::Types::MooseLike::Test->new(an_array => []), 'ArrayRef');
like(
  exception { MooX::Types::MooseLike::Test->new(an_array => undef) },
  qr/is not an ArrayRef/,
  'undef is an exception when we want an ArrayRef'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(an_array => '') },
  qr/is not an ArrayRef/,
  'The empty string is an exception when we want an ArrayRef'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(an_array => 0) },
  qr/is not an ArrayRef/,
  'zero is an exception when we want an ArrayRef'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(an_array => {}) },
  qr/HASH.*?is not an ArrayRef/,
  'a HashRef is an exception when we want an ArrayRef'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(an_array => 'string') },
  qr/string is not an ArrayRef/,
  'a String is an exception when we want an ArrayRef'
  );

# Test HashRef
ok(MooX::Types::MooseLike::Test->new(a_hash => {}), 'HashRef');
like(
  exception { MooX::Types::MooseLike::Test->new(a_hash => undef) },
  qr/is not a HashRef/,
  'undef is an exception when we want a HashRef'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_hash => '') },
  qr/is not a HashRef/,
  'The empty string is an exception when we want a HashRef'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_hash => []) },
  qr/ARRAY.*?is not a HashRef/,
  'an ArrayRef is an exception when we want a HashRef'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(a_hash => 'string') },
  qr/string is not a HashRef/,
  'a String is an exception when we want a HashRef'
  );

# Test CodeRef
ok(MooX::Types::MooseLike::Test->new(a_code => sub { }), 'CodeRef');
like(
  exception { MooX::Types::MooseLike::Test->new(a_code => []) },
  qr/ARRAY.*?is not a CodeRef/,
  'an ArrayRef is an exception when we want a CodeRef'
  );

# Test RegexpRef
ok(MooX::Types::MooseLike::Test->new(a_regex => qr{}), 'RegexpRef');
like(
  exception { MooX::Types::MooseLike::Test->new(a_regex => []) },
  qr/ARRAY.*?is not a RegexpRef/,
  'an ArrayRef is an exception when we want a RegexpRef'
  );

# Test GlobRef
# avoid warning for using FOO only once
no warnings 'once';
ok(MooX::Types::MooseLike::Test->new(a_glob => \*FOO), 'GlobRef');
like(
  exception { MooX::Types::MooseLike::Test->new(a_glob => []) },
  qr/ARRAY.*?is not a GlobRef/,
  'an ArrayRef is an exception when we want a GlobRef'
  );

# Test FileHandle
ok(MooX::Types::MooseLike::Test->new(a_filehandle => IO::Handle->new),
  'FileHandle');
like(
  exception { MooX::Types::MooseLike::Test->new(a_filehandle => []) },
  qr/ARRAY.*?is not a FileHandle/,
  'an ArrayRef is an exception when we want a FileHandle'
  );

# Test Object
ok(MooX::Types::MooseLike::Test->new(an_object => IO::Handle->new), 'Object');
like(
  exception { MooX::Types::MooseLike::Test->new(an_object => []) },
  qr/ARRAY.*?is not an Object/,
  'an ArrayRef is an exception when we want an Object'
  );

# Test legal_age attribute which has an 'isa' that uses 'is_Int'
ok(MooX::Types::MooseLike::Test->new(legal_age => 18), 'Legal Age');
my $minor_age = 17;
like(
  exception { MooX::Types::MooseLike::Test->new(legal_age => $minor_age) },
  qr/$minor_age is not of legal age/,
  'an integer less than 18 is an exception when we want a legal age'
  );

like(
  exception { MooX::Types::MooseLike::Test->new(an_undef => '') },
  qr/is not undef.*\n.*MooX::Types::MooseLike::Test::new.*basic\.t/s,
  'The error looks like a useful stacktrace'
  );

done_testing;
