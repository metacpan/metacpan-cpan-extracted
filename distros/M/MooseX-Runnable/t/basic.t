use strict;
use warnings;
use Test::Fatal;
use Test::More tests => 8;

use ok 'MooseX::Runnable';
use ok 'MooseX::Runnable::Invocation';

{ package Class;
  use Moose;
  with 'MooseX::Runnable';

  sub run {
      my ($self, @args) = @_;
      my $result;
      $result += $_ for @args;
      return $result;
  }
}

my $invocation = MooseX::Runnable::Invocation->new(
    class => 'Class',
);

ok $invocation;

my $code;
is exception {
    $code = $invocation->run(1,2,3);
}, undef, 'run lived';

is $code, 6, 'run worked';

{ package MooseX::Runnable::Invocation::Plugin::ExitFixer;
  use Moose::Role;

  around run => sub {
      my ($next, $self, @args) = @_;
      my $code = $self->$next(@args);
      if($code){ return 0 }
      else { confess "Exited with error." }
  };
}

$invocation = MooseX::Runnable::Invocation->new(
    class   => 'Class',
    plugins => {'+MooseX::Runnable::Invocation::Plugin::ExitFixer' => []},
);

ok $invocation;

is exception {
    $code = $invocation->run(1,2,3);
}, undef, 'run lived';

is $code, 0, 'run worked, and plugin changed the return code';
