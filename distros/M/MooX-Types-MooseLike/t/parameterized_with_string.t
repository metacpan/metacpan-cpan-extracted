{
  package NoBool;
  use Moo;
  use overload ('bool' => sub { die });
}
{
  package MooX::Types::MooseLike::Test::Role;
  use Role::Tiny;
  sub foo { 'ja' };
  sub bar { 'ara' };
}
{
  package MooX::Types::MooseLike::Test::AnotherRole;
  use Role::Tiny;
  sub que { 'dius' };
  sub quoi { 'dieu' };
}
{
  package ClassA;
  use Moo;
  has fun => (is => 'ro');
  1;
}
{
  package ClassB;
  use Moo;
  extends 'ClassA';
  has funner => (is => 'ro');
  1;
}

{
  package MooX::Types::MooseLike::Test;
  use strict;
  use warnings FATAL => 'all';
  use Moo;
  use MooX::Types::MooseLike::Base qw/
    InstanceOf ConsumerOf HasMethods Enum
    /;
  with (
    'MooX::Types::MooseLike::Test::Role',
    'MooX::Types::MooseLike::Test::AnotherRole'
    );

  has instance_of_IO_Handle => (
    is  => 'ro',
    isa => InstanceOf['IO::Handle'],
    );
  has instance_of_A_and_B => (
    is  => 'ro',
    isa => InstanceOf['ClassA', 'ClassB'],
    );
  has instance_of_NoBool => (
    is  => 'ro',
    isa => InstanceOf['NoBool'],
    );
  has consumer_of => (
    is  => 'ro',
    isa => ConsumerOf[
      'MooX::Types::MooseLike::Test::Role',
      'MooX::Types::MooseLike::Test::AnotherRole'
      ],
    );
  has has_methods => (
    is  => 'ro',
    isa => HasMethods['foo', 'bar'],
    );
  has enum_type => (
    is  => 'ro',
    isa => Enum['estrella', 'lluna', 'deessa'],
    );
}
package main;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;
use IO::Handle;

# InstanceOf
ok(MooX::Types::MooseLike::Test->new(instance_of_IO_Handle => IO::Handle->new ), 'instance of IO::Handle');
my $false_instance;
like(
  exception {
    MooX::Types::MooseLike::Test->new(instance_of_IO_Handle => $false_instance);
  },
  qr/No instance given/,
  'undef is not an instance of IO::Handle'
  );
$false_instance = {};
like(
  exception {
    MooX::Types::MooseLike::Test->new(instance_of_IO_Handle => $false_instance);
  },
  qr/is not blessed/,
  'a hashref is not an instance of IO::Handle'
  );
$false_instance = bless {}, 'Foo';
like(
  exception {
    MooX::Types::MooseLike::Test->new(instance_of_IO_Handle => $false_instance);
  },
  qr/is not an instance of the class.*IO::Handle/,
  'a Foo instance is not an instance of IO::Handle'
  );
ok(MooX::Types::MooseLike::Test->new(instance_of_A_and_B => ClassB->new ), 'instance of ClassA and ClassB');
ok(MooX::Types::MooseLike::Test->new(instance_of_NoBool => NoBool->new ), 'instance of NoBool');

# ConsumerOf
ok(MooX::Types::MooseLike::Test->new(consumer_of => MooX::Types::MooseLike::Test->new ), 'consumer of a some roles');
my $false_consumer;
like(
  exception {
    MooX::Types::MooseLike::Test->new(consumer_of => $false_consumer);
  },
  qr/No instance given/,
  'undef is not a consumer of roles'
  );
$false_consumer = IO::Handle->new;
like(
  exception {
    MooX::Types::MooseLike::Test->new(consumer_of => $false_consumer);
  },
  qr/is not a consumer of roles/,
  'an IO::Handle instance is not a consumer of roles'
  );
like(
  exception {
    MooX::Types::MooseLike::Test->new(consumer_of => 'MooX::Types::MooseLike::Test');
  },
  qr/is not blessed/,
  'a class name is not a consumer of roles'
  );

# HasMethods
ok(MooX::Types::MooseLike::Test->new(has_methods => MooX::Types::MooseLike::Test->new ), 'has methods of madness');
my $false_has_methods;
like(
  exception {
    MooX::Types::MooseLike::Test->new(has_methods => $false_has_methods);
  },
  qr/No instance given/,
  'undef does not have the required methods'
  );
$false_has_methods = IO::Handle->new;
like(
  exception {
    MooX::Types::MooseLike::Test->new(has_methods => $false_has_methods);
  },
  qr/does not have the required methods/,
  'an object instance does not have the required methods'
  );
like(
  exception {
    MooX::Types::MooseLike::Test->new(has_methods => 'MooX::Types::MooseLike::Test');
  },
  qr/is not blessed/,
  'a class name is does not have methods'
  );

# Enum
ok(MooX::Types::MooseLike::Test->new(enum_type => 'estrella' ), 'has one of the possible values (enum)');
ok(MooX::Types::MooseLike::Test->new(enum_type => 'deessa' ), 'has one of the possible values (enum)');
my $false_enum = undef;
like(
  exception {
    MooX::Types::MooseLike::Test->new(enum_type => $false_enum);
  },
  qr/is not any of the possible values/,
  'undef is not one of the enumerated values'
  );
$false_enum = IO::Handle->new;
like(
  exception {
    MooX::Types::MooseLike::Test->new(enum_type => $false_enum);
  },
  qr/is not any of the possible values/,
  'an object is not one of the enumerated values'
  );
$false_enum = {};
like(
  exception {
    MooX::Types::MooseLike::Test->new(enum_type => $false_enum);
  },
  qr/is not any of the possible values/,
  'a HashRef is not one of the enumerated values'
  );
$false_enum = '';
like(
  exception {
    MooX::Types::MooseLike::Test->new(enum_type => $false_enum);
  },
  qr/is not any of the possible values/,
  'an empty string is not one of the enumerated values'
  );
$false_enum = 'Tot es possible';
like(
  exception {
    MooX::Types::MooseLike::Test->new(enum_type => $false_enum);
  },
  qr/is not any of the possible values/,
  'a different string is not one of the enumerated values'
  );

done_testing;
