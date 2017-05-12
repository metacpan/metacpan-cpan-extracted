#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $mem_cycle = eval { require Test::Memory::Cycle } || 0;
my $num_objs = 10;

plan tests => 9 * $num_objs + $mem_cycle * 2;

{
  package Counter;
  use Moo;

  with 'MooX::POE';

  has count => (
    is => 'rw',
    lazy_build => 1,
    default => sub { 1 },
  );

  sub START {
    my ( $self, $session, $kernel ) = @_;
    ::pass('Starting ');
    ::isa_ok($kernel, "POE::Kernel", "kernel in START");
    ::isa_ok($session, "POE::Session", "session in START");
    $self->{heap}->{set} = 1;
    $self->yield( set => 1 );
  }

  sub on_set {
    my ( $self, $new ) = @_;
    ::is( $new, $self->{heap}->{set}, $self.": arg is correct with ".$self->{heap}->{set} );
    $self->count( $new );
    return if 4 < $self->count;
    $self->{heap}->{set} = $self->count + 1;
    $self->yield( set => $self->count + 1 );
  }

  sub STOP {
    ::pass('Stopping');
  }
}
 
my @objs = map { Counter->new( foo => 1 ) } ( 1 .. $num_objs );

Test::Memory::Cycle::memory_cycle_ok(\@objs, "no memory cycles") if $mem_cycle;
 
POE::Kernel->run();
 
Test::Memory::Cycle::memory_cycle_ok(\@objs, "no memory cycles") if $mem_cycle;
