use strict;
use warnings;

package Soo;

use Carp 'croak';

our $VERSION = '0.0.4';


my $extends = sub {
  my $parent = shift;
  eval "require $parent;";
  eval "package ${\scalar(caller)}; use parent -norequire, '$parent';";
};

my $has = sub {
  my ($method, $meta) = @_;

  my $package = caller;

  no strict 'refs';

  if($method eq 'new') {
    no warnings;
    *{"$package\::__soo_new_set__"} = $meta->{set} if($meta->{set});
    return;
  }

  my $fn = sub {
    my $self = shift;

    my $set = $meta->{set} || sub {$_[1]};

    my @call = caller(1);
    @call = caller(0) unless(@call);
    my ($callpkg, $callfn) = split(/::/, $call[3]);

    $self->__soo_get_set__($method, $set->($self, shift)) if(@_ && ( $meta->{rw} || ($callpkg eq 'Soo' && $callfn eq '__ANON__') ));

    $self->__soo_get_set__($method) || $meta->{default};
  };

  # set method
  *{"$package\::$method"} = $fn;

};

my $new = sub {
  my ($class, $params) = @_;

  my $self = bless({}, $class);

  # init/clean context
  $self->__soo_init__;

  # constructor set
  $params = $self->__soo_new_set__($params);

  # default behaviour of the constructor is receive a hash ref
  $self->$_($params->{$_}) foreach (keys %$params);

  $self;
};

sub import {
  my $package = caller;

  no strict 'refs';

  # context, we will use this closure context to encapsulate data and provide readonly or readwrite capabilities
  # the context is at class level and will differ object data by using the object ref as key 
  my $context = {};

  *{"$package\::__soo_init__"} = sub {
    $context->{+shift} = {};
  };

  *{"$package\::__soo_get_set__"} = sub {
    my $self = shift;
    my $field = shift;

    return unless($field);

    my @call = caller(1);
    @call = caller(0) unless(@call);
    my ($callpkg, $callfn) = split(/::/, $call[3]);

    croak "Access denied for $callpkg\::$callfn" unless($callpkg eq 'Soo' && $callfn eq '__ANON__');

    $context->{$self}->{$field} = shift if(@_);

    $context->{$self}->{$field};
  };

  # export extends
  *{"$package\::extends"} = $extends;

  # export has
  *{"$package\::has"} = $has;

  # default constructor
  *{"$package\::new"} = $new unless(defined(*{"$package\::new"}));

  # default constructor setter
  *{"$package\::__soo_new_set__"} = sub {$_[1]} unless(defined(*{"$package\::__soo_new_set__"}));

}


1;

__END__
 
# ABSTRACT: Simple object oriented system for Perl

=pod
 
=encoding UTF-8
 
=head1 NAME
 
Soo - Simple object oriented system for Perl
 
=head1 VERSION
 
version 0.0.4

=head1 SYNOPSIS
 
In F<Person.pm>:
 
  package Person;
 
  use Soo;

  has 'name'; 
  # has name => {}; is valid also

  has age => { rw => 1, default => 0 };  # age can change
 
  1;
 
In F<Employee.pm>:
 
  package Employee;

  use Soo;

  extends 'Person'; # or use parent 'Person';
 
  has 'id';
  has email => {
    # set is used to change received values
    # here we will make sure that email will be always lowercase
    set => sub {
      my $self = shift;
      lc(shift);
    } 
  };
 
  1;
 
In F<example.pl>:
 
  use Employee;
 
  # constructor params must be in a hash ref
  my $obj = Employee->new({ name => "Gabi", id => "123", email => "GABI@FOLLOW.ME" });
 
  $obj->name; # Gabi
  $obj->name('Gisele');
  $obj->name; # Gabi - the name remains the same, because every method is by default readonly

  $obj->id; # 123

  $obj->age; # 0
  $obj->age(19);
  $obj->age; # 19 - age method was defined readwrite

  $obj->email; # gabi@follow.me
  # the email was specified in uppercase in the constructor
  # but the set function changed it to lowercase

=head1 DESCRIPTION
 
A tiny module that provides some sugars for object oriented programming in Perl. A list of characteristics:
 
=over 4
 
=item *
 
compatible with bless stuff
 
=item *
 
can be mixed with your own methods declared with sub {}
 
=item *
 
can be imported with: use parent 'MyModule'
 
=item *
 
generates read only methods by default
 
=item *
 
generates read write methods if specified
 
=item *
 
C<new> takes a hash reference as param
 
=item *
 
does not inherit from a special base class
 
=back

=head1 USAGE
 
=head2 A small example

  use strict;
  use warnings;

  package Pet;

  use Soo;

  has eat => { default => 'eating' };
  has fly => { default => 'flying' };
  has 'name';
  has run => { default => 'running' };
  has talk => { default => 'talking' };
  has sleep => { default => 'sleeping' };


  package Pet::Cat;

  use Soo;

  extends 'Pet';

  has fly => { default => 'I cannot fly' };
  has talk => { default => 'meow' };


  package Pet::Dog;

  use Soo;

  extends 'Pet';

  has fly => { default => 'I cannot fly' };
  has talk => { default => 'wow' };


  package Pet::Parrot;

  use Soo;

  extends 'Pet';

  has run => { default => 'I cannot run' };
  has talk => { default => 'argh' };


  package main;

  my $cat = Pet::Cat->new({ name => 'Simba' });
  my $dog = Pet::Dog->new({ name => 'Buddy' });
  my $parrot = Pet::Parrot->new({ name => 'Petey' });

  $cat->name;      # Simba
  $cat->eat;       # eating
  $cat->fly;       # I cannot fly
  $cat->run;       # running
  $cat->talk;      # meow
  $cat->sleep;     # sleeping
  

  $dog->name;      # Buddy
  $dog->eat;       # eating
  $dog->fly;       # I cannot fly
  $dog->run;       # running
  $dog->talk;      # wow
  $dog->sleep;     # sleeping
  

  $parrot->name;   # Petey
  $parrot->eat;    # eating
  $parrot->fly;    # flying
  $parrot->run;    # I cannot run
  $parrot->talk;   # argh
  $parrot->sleep;  # sleeping

=head1 SUPPORT
 
=head2 Bugs / Feature Requests
 
Please report any bugs or feature requests through the issue tracker
at L<https://github.com/geovannyjs/soo/issues>.
You will be notified automatically of any progress on your issue.
 
=head2 Source Code
 
This is open source software.  The code repository is available for
public review and contribution under the terms of the license.
 
L<https://github.com/geovannyjs/soo>
 
  git clone https://github.com/geovannyjs/soo.git

=head1 AUTHOR
 
Geovanny Junio <geovannyjs@gmail.com>