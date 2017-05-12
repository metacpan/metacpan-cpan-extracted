use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
  package Local::TypeLibrary;
  use MooX::Types::MooseLike qw/ exception_message /;
  use MooX::Types::MooseLike::Base qw/ Object AllOf InstanceOf ConsumerOf HasMethods /;
  use Exporter 5.57 'import';
  MooX::Types::MooseLike::register_types([{
        name       => 'Douche',
        subtype_of => AllOf[InstanceOf['Man'], ConsumerOf['Role::Dick'], HasMethods['thought', 'testosterone']],
        from       => 'MooX::Types::MooseLike::Base',
        test       => sub { ($_[0]->testosterone =~ /beaucou/) and ($_[0]->thought < 0.5) },
        message    => sub { return exception_message($_[0], 'a douche') },
      }], __PACKAGE__);
  $INC{'Local/TypeLibrary.pm'} = __FILE__;
}
{
  package Human;
  use Moo;
  use MooX::Types::MooseLike::Base qw/ Num /;
  has thought => (is => 'ro', isa => Num);
}
{ package Woman; use Moo; extends 'Human'; sub sings {}; }
{ package Man;   use Moo; extends 'Human'; sub hunts {}; }
{
  package Role::Dick;
  use Moo::Role;
  sub testosterone { 'beaucoupe' };
}
{
  package Brogrammer;
  use Moo;
  extends 'Man';
  with ('Role::Dick');
}
{
  package MooX::Types::MooseLike::Test;
  use Moo;
  use Local::TypeLibrary qw/Douche/;
  has brogrammer => (
    is  => 'ro',
    isa => Douche,
    );
}

ok(MooX::Types::MooseLike::Test->new(brogrammer => Brogrammer->new(thought => 0)), 'A brogrammer is a douche');
like(
  exception {
    MooX::Types::MooseLike::Test->new(brogrammer => bless {}, 'Elkman');
  },
  qr/is not a douche/,
  'Elk man is not a douche',
  );

done_testing();
