#!/usr/bin/perl
#
use PDLA::LiteF;
use Test::More tests => 6;

# Test PDLA Subclassing via hashes

########### First test normal subclassing ###########

package PDLA::Derived;

@PDLA::Derived::ISA = qw/PDLA/;

sub new {
   my $class = shift;
   my $x = bless {}, $class;
   my $value = shift;
   $$x{PDLA} = $value;
   $$x{SomethingElse} = 42;
   return $x;
}

package main;

# Create a PDLA::Derived instance

$z = PDLA::Derived->new( ones(5,5) ) ;

# PDLA::Derived should have PDLA properties

$z++;

ok(sum($z)==50, "derived object does PDLA stuff");

# And should also have extra bits

ok($$z{SomethingElse}==42, "derived has extra bits" );

# And survive destruction

undef $z;

ok(1==1, "survives distruction");  # huh?


########### Now test magic subclassing i.e. PDLA=code ref ###########

package PDLA::Derived2;

# This is a array of ones of dim 'Coeff'
# All that is stored initially is "Coeff", the
# PDLA array is only realised when a boring PDLA
# function is called on it. One can imagine methods
# in PDLA::Derived2 doing manipulation on the Coeffs
# rather than actualizing the data.

@PDLA::Derived2::ISA = qw/PDLA/;

sub new {
   my $class = shift;
   my $x = bless {}, $class;
   my $value = shift;
   $$x{Coeff} = $value;
   $$x{PDLA} = sub { return $x->cache };
   $$x{SomethingElse} = 42;
   return $x;
}

# Actualize the value (demonstrating cacheing)
# One can imagine expiring the cache if say, Coeffs change

sub cache {
  my $self = shift;
  my $v = $self->{Coeff};
  $self->{Cache} = PDLA->ones($v,$v)+2 unless exists $self->{Cache};
  return $self->{Cache};
}

package main;

# Create a PDLA::Derived2 instance

$z = PDLA::Derived2->new(5);

# PDLA::Derived2 should have PDLA properties

$z++;

ok(sum($z)==100, "derived2 has PDLA properties");

# And should also have extra bits

ok($$z{SomethingElse}==42, "derived2 has extra bits" );

# And survive destruction

undef $z;

ok(1==1, "derived2 survives destruction");

