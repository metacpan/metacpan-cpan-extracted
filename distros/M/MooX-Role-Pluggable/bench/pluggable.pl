#!/usr/bin/env perl
use strict; use warnings FATAL => 'all';
use 5.10.1;

my $pcount = $ARGV[0] // 20;
my $count  = $ARGV[1] // 30_000;

{
  package
   Plug::O::P;
  use strict; use warnings FATAL => 'all';

  sub new { bless [], shift }

  sub plugin_register {
    my ($self, $core) = @_;
    $core->plugin_register( $self, 'SERVER', 'test', 'eat' );
    1
  }
  sub plugin_unregister {
    1
  }
  sub S_test {
    1
  }
  sub S_eat {
    2
  }
}

{
  package
   Plug::MX::P;
  use strict; use warnings FATAL => 'all';

  sub new { bless [], shift }

  sub plugin_register {
    my ($self, $core) = @_;
    $core->subscribe( $self, 'NOTIFY', 'test', 'eat' );
    1
  }
  sub plugin_unregister {
    1
  }
  sub N_test {
    1
  }
  sub N_eat {
    2
  }
}

{
  package
    Plug::NoEvents;
  use strict; use warnings FATAL => 'all';
  sub new { bless [], shift }
  sub plugin_register { 1 }
  sub plugin_unregister { 1 }
}

{
  package
   Disp::O::P;
  use strictures 1;
  use base 'Object::Pluggable';

  sub new {
    my $self = {};
    bless $self, shift;
    $self->_pluggable_init(
      types => { SERVER => 'S' },
    );
    $self
  }

  sub process {
    my ($self, $event, @args) = @_;
    $self->_pluggable_process( 'SERVER', $event, \@args )
  }
}

{
  package
   Disp::MX::P;
  use Moo;
  with 'MooX::Role::Pluggable';

  sub process {
    my ($self, $event, @args) = @_;
    $self->_pluggable_process( 'NOTIFY', $event, \@args )
  }
}

use Benchmark ':all';

my $op_disp = Disp::O::P->new;
my $mx_disp = Disp::MX::P->new;
$op_disp->plugin_add( 'A'.$_ => Plug::O::P->new )
      for 1 .. $pcount;
$op_disp->plugin_add( 'Null'.$_ => Plug::NoEvents->new )
      for 1 .. $pcount;
$mx_disp->plugin_add( 'B'.$_ => Plug::MX::P->new )
      for 1 .. $pcount;
$mx_disp->plugin_add( 'Null'.$_ => Plug::NoEvents->new )
     for 1 .. $pcount;
use feature 'say';
say "$count runs for $pcount x2 plugins";

my %stuff = ( $count, +{
  'object-pluggable' => sub {
    $op_disp->process( 'test', 'things' );
    $op_disp->process( 'eat', 'stuff' );
    $op_disp->process( 'not_handled' );
  },
  'moox-role-pluggable' => sub {
    $mx_disp->process( 'test', 'things' );
    $mx_disp->process( 'eat', 'stuff' );
    $op_disp->process( 'not_handled' );
  },
} );

#timethese(%stuff);
cmpthese(%stuff);
