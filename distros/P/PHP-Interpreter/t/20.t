use strict;
use Test::More tests => 3;

BEGIN {
  use_ok 'PHP::Interpreter';
}


my $foo = Foo->new();
ok $foo->addInterp, "Add an intepreter to foo";
eval {
  $foo->upper();
};
is $@, "A PHP error occurred\n", "Invalid code causes a croak()";


package Foo;

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  bless {}, $class;
}

sub addInterp {
  my $self = shift;
  my $p = PHP::Interpreter->new;
  $self->{php} = $p;
}

sub upper {
  my $self = shift;
  my $p = $self->{php};
  $p->strln('george');
}

1;
