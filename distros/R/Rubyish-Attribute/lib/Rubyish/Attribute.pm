package Rubyish::Attribute;
use 5.010;

=head1 NAME

Rubyish::Attribute - ruby-like accessor builder: attr_accessor, attr_writer and attr_reader.

=cut

use Want;

sub import {
  my $caller = caller;
  for (qw(attr_accessor attr_reader attr_writer)) {
    *{$caller . "::" . $_} = *{$_};
  }
  eval qq{package $caller; use PadWalker qw(peek_my);};
}


=head1 VERSION

This document is for version 1.2

=cut

our $VERSION = "1.2";

=head1 SYNOPSIS

    #!/usr/bin/env perl
   
    use 5.010;

    use strict;
    use warnings;

    {
        package Animal;
        
        use Rubyish::Attribute; 
        # import attr_accessor, attr_writer and attr_reader

        BEGIN {
          attr_accessor "name", "color", "type"; 
        }
        # pass a list as the only one parameter
        # invoke it in compile time to avoid using parenthesis when using instance variable as below

        # then create a constructer based on hashref
        sub new {
            $class = shift;
            bless {}, $class;
        }

        sub rename_as {
          my ($self, $new_name) = @_;
          __name__ = $new_name;

          # __name__ is accurately a lvalue subroutine &__name__() which refer to $self->{name}
          # now it looks like a instance variable.
        }

        1;
    }
   
    $dogy = Animal->new()->name("rock")
                  ->color("black")->type("unknown");
    # new Animal with three attribute

    say $dogy->name;  #=> rock
    say $dogy->color; #=> black
    say $dogy->type;  #=> unknown

=head1 FUNCTIONS

=head2 attr_accessor(@list)

attr_accessor provides getters double as setters.
Because all setter return instance itself, now we can manipulate object in ruby way more than ruby.

    attr_accessor qw(name color type master)
    $dogy = Animal->new()->name("lucky")->color("white")
                  ->type("unknown")->master("shelling");

Each attribute could be read by getter as showing in synopsis.

=cut


sub make_accessor {
    my $field = shift;
    return sub {
        my ($self, $arg) = @_;
        if ($arg) {
            $self->{$field} = $arg;
            $self;
        }
        else {
            $self->{$field};
        }
    }
}

sub attr_accessor {
    no strict;
    my $package = caller;
    for my $field (@_) {
        *{"${package}::${field}"} = make_accessor($field);
        make_instance_vars_accessor($package, $field);
    }
}

=head2 attr_reader(@list)

attr_reader create only getter for the class you call it

    attr_reader qw(name) # pass a list
    $dogy = Animal->new({name => "rock"}) # if we write initialize function in constructor
    $dogy->name()       #=> rock
    $dogy->name("jack") #=> undef (with warn msg)

=cut

sub make_reader {
    my $field = shift;
    return sub {
        my ($self, $arg) = @_;
        if ($arg) {
            warn "error - $field is only reader\n";
            return;             # because no writer
        }
        else {
            $self->{$field};
        }
    }
};

sub attr_reader {
    no strict;
    my $package = caller;
    for my $field (@_) {
        *{"${package}::${field}"} = make_reader($field);
        make_instance_vars_accessor($package, $field);
    }
}

=head2 attr_writer(@list)

attr_writer create only setter for the class you call it.

    attr_writer qw(name) # pass a list
    $dogy = Animal->new()->name("lucky") # initialize and set and get instance itself
    $dogy->name("jack") #=> instance itself 
    $dogy->name         #=> undef (with warn msg)

=cut

sub make_writer {
    my $field = shift;
    return sub {
        my ($self, $arg) = @_;
        if ($arg) {
            $self->{$field} = $arg;
            $self;
        }
        else {
            warn "error - $field is only writer\n";
            return;             # because no reader 
        }
    }
}

sub attr_writer {
    no strict;
    my $package = caller;
    for my $field (@_) {
        *{"${package}::${field}"} = make_writer($field);
        make_instance_vars_accessor($package, $field);
    }
}

sub make_instance_vars_accessor {
  no strict;
  my ($package, $field) = @_;
  eval qq|package $package;
    sub __${field}__ : lvalue {
      unless ( caller eq $package ) {
        require Carp;
        Carp::croak "__${field}__ is a protected method of $package!";
      }
      \${ peek_my(1)->{\'\$self\'} }->{$field};
    }
  |;
}

=head1 DEPENDENCE

L<Want>

=head1 SEE ALSO

L<autobox::Core>, L<List::Rubyish>, L<Class::Accessor::Lvalue>, L<Want>

L<http://ruby-doc.org/core-1.8.7/classes/Module.html#M000423>

L<http://chupei.pm.org/2008/11/rubyish-attribute.html> chinese introduction

=head1 AUTHOR

shelling <navyblueshellingford at gmail.com>

gugod    <gugod at gugod.org>

=head2 acknowledgement

Thanks to gugod providing testing script and leading me on the way of perl

=head1 REPOSITORY

host:       L<http://github.com/shelling/rubyish-attribute/tree/master>

checkout:   git clone git://github.com/shelling/rubyish-attribute.git

=head1 BUGS

please report bugs to <shelling at cpan.org> or <gugod at gugod.org>

=head1 COPYRIGHT & LICENCE 

Copyright (C) 2008 shelling, gugod, all rights reserved.

Release under MIT (X11) Lincence.

=cut

1;

