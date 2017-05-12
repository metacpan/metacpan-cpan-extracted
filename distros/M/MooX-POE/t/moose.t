#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
  eval "use Moose";
  plan skip_all => "Moose not installed; skipping" if $@;
}

my $mem_cycle = eval { require Test::Memory::Cycle } || 0;
my $num_objs = 10;

plan tests => 10 * $num_objs + $mem_cycle *2;
 
{
  package Counter;

  use Moose;
  with 'MooX::POE';

  has count => (
    isa     => 'Int',
    is      => 'rw',
    lazy    => 1,
    default => sub { 1 },
  );

  has foo => (
    is => 'rw'
  );

  sub START {
    my ( $self, $session, $kernel ) = @_;
    ::pass('Starting ');
    ::isa_ok($kernel, "POE::Kernel", "kernel in START");
    ::isa_ok($session, "POE::Session", "session in START");
    ::is($self->foo, 1, "foo attribute has correct value");
    $self->{heap}->{count} = 0;
    $self->yield('dec');
  }

  sub on_inc {
    my ( $self ) = @_;
    $self->count( $self->count + 1 );
    ::is( $self->count, $self->{heap}->{count}, $self.": count is correct with ".$self->{heap}->{count} );
    return if 3 < $self->count;
    $self->{heap}->{count} = $self->count + 1;
    $self->yield('inc');
  }

  sub on_dec {
    my ( $self ) = @_;
    $self->count($self->count - 1 );
    ::is( $self->count, $self->{heap}->{count}, $self.": count is correct with ".$self->{heap}->{count} );
    $self->{heap}->{count} = 1;
    $self->yield('inc');
  }

  sub STOP {
    ::pass('Stopping');
  }
}
 
my @objs = map { Counter->new( foo => 1 ) } ( 1 .. $num_objs );

Test::Memory::Cycle::memory_cycle_ok(\@objs, "no memory cycles") if $mem_cycle;
 
POE::Kernel->run();
 
Test::Memory::Cycle::memory_cycle_ok(\@objs, "no memory cycles") if $mem_cycle;