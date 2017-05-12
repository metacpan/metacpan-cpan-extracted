use strict;
use warnings;
use Test::Fatal;
use Test::More tests => 9;

use MooseX::Runnable::Invocation;
use ok 'MooseX::Runnable::Invocation::Scheme::MooseX::Getopt';

my $foo;

{ package Class;
  use Moose;
  with 'MooseX::Runnable', 'MooseX::Getopt';

  has 'foo' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  sub run {
      my ($self, $code) = @_;
      $foo = $self->foo;
      return $code;
  }
}

{ package Class2;
  use Moose;
  extends 'Class';
}

foreach my $class (qw(Class Class2))
{
    my $invocation = MooseX::Runnable::Invocation->new(
        class => $class,
    );

    ok $invocation, 'class is instantiatable';

    my $code;
    is exception {
        $code = $invocation->run('--foo', '42', 0);
    }, undef, 'run lived';

    is $foo, '42', 'got foo from cmdline';

    is $code, 0, 'exit status ok';
}


