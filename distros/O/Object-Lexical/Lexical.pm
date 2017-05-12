package Object::Lexical;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

use PadWalker;

my $counter = 0;

my $opt_wrap = 1;
my $opt_export = 1;
my $opt_nonlex = 1;

my %methods = ();

sub instance {

  # create a new object instance with its own stash from an existing object

  my $type = shift() || DB::_ext_fetch_args() || caller();

  my $package = sprintf 'Object::Lexical::X%09d', $counter++;

  # move methods into the new package from the symbol table. this is a destructive copy -
  # methods will need to be created again. this way, each copy has its own
  # seperate lexical data.

  no strict 'refs';

  if($opt_nonlex) {
    foreach my $x (keys %{$type.'::'}) {
      # no warnings 'redefine';
      next if $x eq 'new' or $x eq 'DESTROY' or $x eq 'instance' or $x eq 'method';
      next unless defined &{$type.'::'.$x};
      my $source = $type.'::'.$x;
      my $target = $package.'::'.$x;
      my $code = \&{$source};
      my $thisglob = $package.'::this';
      if($opt_wrap) {
        *{$target} = sub { *{$thisglob} = shift; goto &$code; };
      } else {
        *{$target} = $code;
      }
      undef *{$source};
    }
  }

  # move lexically defined subs, too

  my $pad = PadWalker::peek_my(1);
  foreach my $x (keys %$pad) {
    my $code = ${$pad->{$x}};
    next unless ref($code) eq 'CODE';
    substr($x, 0, 1, ''); # remove sigil
    my $target = $package.'::'.$x;
    my $thisglob = $package.'::this';
    if($opt_wrap) {
      *{$target} = sub { *{$thisglob} = shift; goto &$code; };
    } else {
      *{$target} = $code;
    }
  }

  # and anything defined with method()

  foreach my $x (keys %methods) {
    my $code = $methods{$x};
    my $target = $package.'::'.$x;
    my $thisglob = $package.'::this';
    if($opt_wrap) {
      *{$target} = sub { *{$thisglob} = shift; goto &$code; };
    } else {
      *{$target} = $code;
    }
  }

  # inherit whomever our client is inheriting.
  # count references for destruction - barrowed from Class::Object

  push @{$package.'::ISA'}, $type;
  ${$package.'::_count'} = 1;

  *{$package.'::DESTROY'} = sub {
     my $obj_class = ref shift; 
     ${$obj_class.'::_count'}--;
     if( ${$obj_class.'::_count'} == 0 ) {
        undef %{$obj_class.'::'};
     }
  };
  
  # bless \(my $foo), $package;
  bless \%{$package.'::'}, $package;

}

sub method (&*) {
  my $caller = caller;
  my $code = shift;
  my $name = shift;
  $methods{$name} = $code;
  # *{$caller.'::'.$name} = $code;
}

sub import {

  # cleaning up
  %methods = ();

  # default options
  $opt_wrap = 1;   # sub wrapper to read $this automatically
  $opt_export = 1; # export instance() and method()
  $opt_nonlex = 1; # move non-lexically defined methods too

  # options
  foreach(@_) {
    $opt_wrap = 0   if $_ eq 'no_wrap' or $_ eq 'nowrap';
    $opt_export = 0 if $_ eq 'no_export' or $_ eq 'noexport';
    $opt_nonlex = 0 if $_ eq 'no_nonlex' or $_ eq 'nononlex';
  }

  # export
  if($opt_export) {
    no strict 'refs';
    my $caller = caller;
    *{$caller.'::instance'} = *instance;
    *{$caller.'::method'} = *method;
  }

  1;

}

package DB;

sub _ext_fetch_args {
  our @args;
  (undef, undef) = caller(2);
  return undef unless @args;
  return $args[0];
}

1;

__END__


=head1 NAME

Object::Lexical - Syntactic Sugar for Easy Object Instance Data & More

=head1 SYNOPSIS

  use Object::Lexical;
  use Sub::Lexical;

  sub new {

    my $counter;
    our $this;

    my sub inc { 
       $counter++; 
    }

    my sub dec { 
       $counter--;
    } 

    my sub inc3x {
      $this->inc() for(1..3); 
    }

    instance();

  } 

=head1 ABSTRACT

Object::Lexical provides syntactic sugar to create objects.

Normal C<my> variables are used for instance data. C<$this> is automatically 
read off of the argument stack. This follows "real" OO languages, where
user code need not concern itself with helping the language implement objects.

Normal OO Perl code is ugly, hard to read, tedious to type, and error prone.
The C<$self->{field}> syntax is cumbersome, and using an object field with
a built in, like C<push()>, requires syntax beyond novice Perl programmers:
C<push @{$self->{field}}, $value>.
Spelling field names wrong results in hard to find bugs: the hash autovivicates, 
and no "variables must be declared" warning is issued. 

=head1 DESCRIPTION

C<instance()> returns a new object that subclasses the current object, and contains
all of the just-defined methods. The object returned is a blessed symbol table (stash)
reference, which functions like a blessed hash reference for most purposes. In
other words, it is a normal object.

C<instance()> takes an optional argument: the name of the package the object being
created is to belong to. If the C<new()> method reads the class
name off of the argument stack, this class name should be passed to C<instance()>,
to support the creation of subclasses of your class.
This is similar to the operation of C<bless()>, except C<instance()> will read the
class name off of the stack for you if you don't.

The C<use Method::Lexical> line takes optional arguments: "nononlex" specifies
that non-lexically defined methods shouldn't be moved. Methods defined using
C<*name = sub { }> and C<sub name { }> won't be moved. If subroutines are
created out side of the C<sub new { }> block, then this option should be 
specified, or else the subroutines will mysteriously disappear. "noexport"
specifies that C<method()> and C<instance()> should not be exported into
your namespace. To get at these functions, you will need to qualify their names:
C<Object::Lexical::method()> and C<Object::Lexical::instance()>, respectively.
"nowrap" specifies that methods should be wrapped in logic that reads C<$this>
automatically, as they are moved into their new symbol table. If you want to
refer to C<$this> as C<$_[0]>, or you want to process it yourself, or you want
keep memory usage on par with normal objects, use this.

C<instance()> is the heart of this module: lexically scoped methods (coderefs held
in C<my> variables) and methods placed into the symbol table are moved into a
new namespace created just for that object instance. A thin wrapper is placed around
each symbol table entry in this namespace that reads the reference to
the current object into an C<our> variable named C<$this>.  

Any number of independent objects can be returned by C<new()>.
By defining methods in side the block of the C<new()> method,
each returned object has its own private copies of each C<my> variable. 
This uses the "lambda closure" feature of Perl. A closure is code that holds
references to variables - in this example, C<$counter> will go out of scope,
but C<inc>, C<dec>, C<inc3x> all keep a reference to it. The next time C<new()> is run, 
a new C<$counter> lexical will be created, and new methods will be created that reference
that.

This serves to avoid the messy C<$this->{counter}++> syntax, making it easier
to refactor code, move code into methods from subroutines, and turn plain old
modules into objects. 

=head2 ALTERNATE IDIOMS

The "lite" approach: use built in Perl constructs to create normal closures. They
may either be placed into the symbol table or stored in C<my> variables.
These three alternate idioms remove the need to C<use Sub::Lexical>. L<Sub::Lexical> uses 
souce filtering, which may clash with other source filters or 
introduce bugs into code.

  package MyPackage;

  use Object::Lexical; 

  sub new {

    my $counter;
    our $this;

    *inc = sub { $counter++ };

    *dec = sub { $counter-- };

    *inc3x = sub {
      $this->inc() for(1..3); 
    };

    instance();

  }

Rather than use globals, lexicals may be used:

  package MyPackage;

  use Object::Lexical; 

  sub new {

    my $counter;
    our $this;

    my $inc = sub { $counter++ };

    my $dec = sub { $counter-- };

    my $inc3x = sub {
      $this->inc() for(1..3); 
    };

    instance();

  }


A C<method()> function is provided:

  use Object::Lexical;
  no strict 'subs';

  sub new {

    my $counter;
    our $this;

    method { $counter++ } inc;

    method { $counter-- } dec;

    method { 
      $this->inc() for(1..3); 
    } inc3x;

    instance();

  }

This is logically the same thing as the previous example, using C<my> with
closures.

=head2 BUGS

Making a function call instead of a method call, treating the blessed stash
(symbol table) as a hash and looking up the method in it, and invoking it
directly after making a normal method call to that method
causes a coredump in Perl 5.8.0, 5.6.1, and perhaps earlier. Voodoo.
This was meant to be supported as a feature, to allow hash style access to
objects that are only namespaces full of closures.

  $ob->{method}->();

Subs declared outside of the C<new()> block are annihilated in this version.
Specifically, they are moved into the first object created, never replunished,
as they aren't created run-time from inside the C<new()> block.
Use the 'nononlex' option to C<use> to avoid this. You'll need to use one
of the three lexical subs idioms: L<Sub::Lexical>, the C<method> statement,
or C<my $subname = sub { }>, the plain old Perl closure syntax.

Perl prototypes support magic that allows allows user defined functions
follow the form of builtings C<grep { } @list> and C<map { } @list> to be created,
but not of the form used by the builtin C<sub name { }>. This gives C<method { }>
a strange syntax.

Magic may not play nice with out modules that mangle the nametable or other
trickery. Best to confine use to small container objects and the like for now.
Unless you're brave.

=head2 EXPORT

C<instance()> is always exported, and so is C<method()> - unless the 
'noexport' option is given.

=head1 SEE ALSO

=over 1

=item http://perldesignpatterns.com/?AnonymousSubroutineObjects

=item L<Class::Classless>

Can easily provide the same facility as this module if closures
are passed to the C<sub()> method. Requires more syntax - 
Object::Lexical is specialized.

=item L<Class::Object>

Ditto. Barrowed code from. 

=item ImplicitThis

ImplicitThis, an earlier attempt, wrapped methods to automatically read C<$this>,
but it was error prone, and ignored the problem of accessing instance data.

=item L<Sub::Lexical>

Provides a syntax for lexically scoped subroutines. 

=back

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

# 
# what if... methods were declared using some method 'foo' = sub { ... }; syntax
# (method() being lvalue) at the top level, and a lexical references module or
# B::Generate were used to minipulate, runtime, which lexicals each saw, so 
# code references could be copy, configured, and populated into namespaces?
#

#
# Lexical::Alias and PadWalker and AUTOLOAD together could do this:
# use the old-style hash dispatch logic, but before dispatching, each lexical
# in the PAD of the code reference would be aliased to a lexical stored in
# the per object hash.
#
# ie, given a blessed hash, $foo = { }, $foo->{my_method} might reference $a and $b.
# these would be aliased to $foo->{a} and $foo->{b} for that invocation
#

#
# changes
#

# 0.1: initial version
# 0.2: updated documentation to encourage use of Sub::Lexical, knocks docs around a bit.
#      no code changes.
