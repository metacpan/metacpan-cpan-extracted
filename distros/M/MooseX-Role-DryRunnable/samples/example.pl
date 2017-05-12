use strict;
use warnings;

package Foo;
use Data::Dumper;
use Moose;
use lib '../lib';

use MooseX::Role::DryRunnable::Attribute; # EXPERIMENTAL, export : dry_it

with 'MooseX::Role::DryRunnable' => { 
  methods => [ qw'bar buzz' ]
};

has dry_run => (is => 'ro', isa => 'Bool', default => 0);

sub logger {
  my $self = shift;
  my $msg  = shift;
  print $msg, Dumper \@_;
}

sub bar {
  shift;
  print "Foo::bar @_\n";
}

sub baz : dry_it {
  shift;
  print "Foo::baz @_\n";
}

sub is_dry_run { # required !
  shift->dry_run
}

sub on_dry_run { # required !
  my $self   = shift;
  my $method = shift;
  $self->logger("Dry Run method=$method, args: \n", @_);
}

no Moose;
1;

package main;
use feature 'say';

say "\n====> Without dry_run\n";
my $a = Foo->new();
$a->bar(1,2,3);
$a->baz(4,5,6);

say "\n====> With dry_run\n";
my $b = Foo->new(dry_run => 1);
$b->bar(1,2,3);
$b->baz(4,5,6);
