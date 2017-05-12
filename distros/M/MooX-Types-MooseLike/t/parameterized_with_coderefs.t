{
  package MooX::Types::MooseLike::Test;
  use strict;
  use warnings FATAL => 'all';
  use Moo;
  use MooX::Types::MooseLike::Base qw/ AnyOf AllOf Object Int ArrayRef HashRef InstanceOf HasMethods /;

  has any_of => (
    is  => 'ro',
    isa => AnyOf[Int, HashRef[Int], Object],
    );
  has all_of => (
    is  => 'ro',
    isa => AllOf[InstanceOf['IO::Handle'], HasMethods['print']],
    );
}
package main;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;
use IO::Handle;

# AnyOf
ok(MooX::Types::MooseLike::Test->new(any_of => IO::Handle->new ), 'value is AnyOf[Int, ArrayRef[Int], HashRef[Int], Object]');
ok(MooX::Types::MooseLike::Test->new(any_of =>  108  ), 'Int is AnyOf[Int, ArrayRef[Int], HashRef[Int], Object]');
ok(MooX::Types::MooseLike::Test->new(any_of => {auspicious_number => 108} ), 'HashRef[Int] is AnyOf[Int, ArrayRef[Int], HashRef[Int], Object]');
ok(MooX::Types::MooseLike::Test->new(any_of => {} ), 'HashRef is AnyOf[Int, ArrayRef[Int], HashRef[Int], Object]');
my $false_value;
like(
  exception {
    MooX::Types::MooseLike::Test->new(any_of => $false_value);
  },
  qr/is not any of/,
  'undef is not an any of the types given"'
  );
$false_value = { nada => undef };
like(
  exception {
    MooX::Types::MooseLike::Test->new(any_of => $false_value);
  },
  qr/is not any of/,
  'A HashRef with an undefined value is not an any of the types given'
  );
$false_value = [];
like(
  exception {
    MooX::Types::MooseLike::Test->new(any_of => $false_value);
  },
  qr/is not any of/,
  'ArrayRef is not an any of the types given'
  );
$false_value = 'peace_treaty';
like(
  exception {
    MooX::Types::MooseLike::Test->new(any_of => $false_value);
  },
  qr/is not any of/,
  'a string is not any of the types given'
  );

# AllOf
ok(MooX::Types::MooseLike::Test->new(all_of => IO::Handle->new ),
  "value is AllOf[InstanceOf('IO::Handle'), HasMethods['print']]");
$false_value = undef;
like(
  exception {
    MooX::Types::MooseLike::Test->new(all_of => $false_value);
  },
  qr/No instance given/,
  'undef is not an instance of IO::Handle"'
  );
$false_value = 'peace_treaty';
like(
  exception {
    MooX::Types::MooseLike::Test->new(all_of => $false_value);
  },
  qr/is not blessed/,
  'a string is not an instance of IO::Handle'
  );

done_testing;
