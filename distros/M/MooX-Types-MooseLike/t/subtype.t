use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
  package Local::TypeLibrary;
  use MooX::Types::MooseLike;
  use Exporter 5.57 'import';
  MooX::Types::MooseLike::register_types([{
        name    => 'BaseType',
        test    => sub { defined $_[0] && !ref $_[0] },
        message => sub { 'not a simple string' },
      }], __PACKAGE__);
  MooX::Types::MooseLike::register_types([{
        name    => 'SubType',
        subtype_of => 'BaseType',
        from    => __PACKAGE__,
        test    => sub { length $_[0] },
        message => sub { 'not a string length > 0' },
      }], __PACKAGE__);
  MooX::Types::MooseLike::register_types([{
        name    => 'SubSubType',
        subtype_of => SubType(),
        test    => sub { $_[0] },
        message => sub { 'not a true value' },
      }], __PACKAGE__);
  $INC{'Local/TypeLibrary.pm'} = __FILE__;
}

{
  package MooX::Types::MooseLike::Test;
  use strict;
  use warnings FATAL => 'all';
  use Moo;
  use Local::TypeLibrary qw/BaseType SubType SubSubType/;

  has string => (
    is  => 'ro',
    isa => BaseType,
    );
  has string_w_length => (
    is  => 'ro',
    isa => SubType,
    );
  has true_string => (
    is  => 'ro',
    isa => SubSubType,
    );
}

ok(MooX::Types::MooseLike::Test->new(string => ''), 'empty string is a string');
ok(MooX::Types::MooseLike::Test->new(string_w_length => '0'), '0 is a string with length');
ok(MooX::Types::MooseLike::Test->new(true_string => '1'), '1 is true string');
like(
  exception {
    MooX::Types::MooseLike::Test->new(string => undef);
  },
  qr/not a simple string/,
  'undef is not a simple string',
  );
like(
  exception {
    MooX::Types::MooseLike::Test->new(string_w_length => '');
  },
  qr/not a string length > 0/,
  'empty string has no length',
  );
like(
  exception {
    MooX::Types::MooseLike::Test->new(string_w_length => {});
  },
  qr/not a string length > 0/,
  'hashref is not a simple string',
);
like(
  exception {
    MooX::Types::MooseLike::Test->new(true_string => '0');
  },
  qr/not a true value/,
  '0 is not a true value',
  );

done_testing;
