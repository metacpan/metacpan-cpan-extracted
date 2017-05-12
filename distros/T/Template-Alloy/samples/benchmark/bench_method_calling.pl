#!/usr/bin/perl -w

use strict;
use Benchmark qw(cmpthese);
use CGI::Ex::Dump qw(debug);

my $n = 500_000;

{
  package A;
  use vars qw($AUTOLOAD);
  sub AUTOLOAD {
    my $self = shift;
    my $meth = ($AUTOLOAD =~ /::(\w+)$/) ? $1 : die "Bad method $AUTOLOAD";
    die "Unknown property $meth" if ! exists $self->{$meth};
    if ($#_ != -1) {
      $self->{$meth} = shift;
    } else {
      return $self->{$meth}
    }
  }
  sub DETROY {}
}

{
  package B;
  sub add_property {
    my $self = shift;
    my $prop = shift;
    no strict 'refs';
    * {"B::$prop"} = sub {
      my $self = shift;
      if ($#_ != -1) {
        $self->{$prop} = shift;
      } else {
        return $self->{$prop};
      }
    };
    $self->$prop(@_) if $#_ != -1;
  }
}

{
  package C;
  sub add_property {
    my $self = shift;
    my $prop = shift;
    no strict 'refs';
    my $name = __PACKAGE__ ."::". $prop;
    *$name = sub : lvalue {
      my $self = shift;
      $self->{$prop} = shift() if $#_ != -1;
      $self->{$prop};
    } if ! defined &$name;
    $self->$prop() = shift() if $#_ != -1;
  }
}

my $a = bless {}, 'A';
$a->{foo} = 1;
#debug $a->foo();
#$a->foo(2);
#debug $a->foo();

my $b = bless {}, 'B';
$b->add_property('foo', 1);
#debug $b->foo();
#$b->foo(2);
#debug $b->foo();

my $c = bless {}, 'C';
$c->add_property('foo', 1);
#debug $c->foo();
#$c->foo(2);
#debug $c->foo();

my $d = bless {}, 'C';
$d->add_property('foo', 1);
#debug $d->foo();
#$d->foo = 2;
#debug $d->foo();


use constant do_set => 1;

cmpthese($n, {
  autoloadonly => sub {
    my $v = $a->foo();
    if (do_set) {
      $a->foo(2);
    }
  },
  addproperty => sub {
    my $v = $b->foo();
    if (do_set) {
      $b->foo(2);
    }
  },
  addproperty_withlvalue => sub {
    my $v = $c->foo();
    if (do_set) {
      $c->foo(2);
    }
  },
  addproperty_withlvalue2 => sub {
    my $v = $d->foo();
    if (do_set) {
      $d->foo = 2;
    }
  },
});
