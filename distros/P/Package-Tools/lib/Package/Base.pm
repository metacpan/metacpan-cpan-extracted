=head1 NAME

Package::Base - An abstract base for implementation classes to inherit from

=head1 SYNOPSIS

  #don't use this module directly, but rather inherit from it.
  package My::Package;
  use base qw(Package::Base);

  #define a couple of get/setters
  sub slot1 {
    my($self,$val) = @_;
    $self->{'slot1'} = $val if defined($val);
    return $self->{'slot1'};
  }

  sub slot2 {
    my($self,$val) = @_;
    $self->{'slot2'} = $val if defined($val);
    return $self->{'slot2'};
  }

  package main:
  my $object = My::Package->new(slot1 => 'value1', slot2 => 'value2', slot3 => 'value3');
  #slot3 => 'value3' is silently ignored

  $object->slot1; #returns 'value1'
  $object->slot2; #returns 'value2'
  $object->slot3; #error, method undefined

=head1 DESCRIPTION

Package::Base is an abstract base class, meaning it isn't intended to be used directly,
but rather inherited from by an instantiable class.  In fact, attempting to instantiate
a Package::Base object directly will result in an error.

B<Q: So why would you want to inherit from Package::Base?>

B<A: Because it provides some nice functionality:>

* a built-in new() method that does instantiation of a hash based object

* new() accepts an anonymous hash as arguments (a list of key/value pairs, essentially).
and sets attributes appropriately within your object if methods of the same name
as the keys are found.

* Package::Base::Devel is a subclass specifically designed for debugging Perl classes
is bundled with Package::Base, and the inherited interface works the same way.  This
means that while developing/debugging a module, you can do:

  package My::Package;
  use base qw(Package::Base::Devel);

  #...

and have nice Log::Log4perl logging about what your method is doing sent to a file,
filehandle, email, database... whatever (see L<Log::Log4perl> for details about this
amazing logging API).  Then, when you're ready to ship, just change the line:

  package My::Package;
  -use base qw(Package::Base::Devel);
  +use base qw(Package::Base);

and the heavy debugging toll paid for the debug logging vanishes.

* Package::Base comes with a pstub, a drop-in replacement for h2xs if you're writing
a module that doesn't rely on Perl XS or C files.

Now to be "fair and balanced" :)

B<Q: Why might Package::Base not be right for me?>

B<A: It does some things you might not like for stylistic reasons:>

* Package::Base currently only works for hash-based objects.  This may be extended to
support array-based objects in the future.

* Package::Base assumes you have methods overloaded to act as accessors/mutators.
e.g. calling C<$obj->foo(1)> sets object's foo attribute to 1, and calling
C<$obj->foo()> retrieves object's foo attribute's value.  See L<Class::Accessor>
for an easy way to set these up.

* Package::Base tries to initialize slots for all passed key/value pairs, instead of
allowing the constructor, new(), to filter out only those it wants.  Class::Base
allows filtering like this.

=head1 AUTHOR

Allen Day, E<lt>allenday@ucla.eduE<gt>

=head1 SEE ALSO

For another way to do it, see L<Class::Base>.

L<Class::Accessor>.

=cut

#these Package::Base::Stub classes
package Package::Base::Stub::Log;
use strict;
use AutoLoader;

my $instance = undef;

sub get_instance {
  my $class = shift;
  if(!$instance){
    $instance = bless {}, $class;
  } else {
    return $instance;
  }
}


#=head2 AUTOLOAD()
#
#method to support swapability of Package::Base and Package::Base::Devel.
#returns 1
#
#this means all method calls succeed, and everything but get_instance()
#is a no-op.
#
#=cut

sub AUTOLOAD {
  return 1;
}

package Package::Base;

use strict;
use Data::Dumper;
use Carp qw(cluck);

our $VERSION = '0.03';

=head1 METHODS

=head2 new()

 Usage   : This is an abstract constructor, and can't be called directly.
           Use it by either calling it from your subclass directly, e.g.:

           package My::Class;
           use base qw(Package::Base);

           sub new {
             my($class,%arg) = @_;
             my $self = $class->SUPER::new();
             return $self
           }

           or by not declaring a new() method at all, and letting your class
           inherit the new() method at object construction time.

 Function: Provides universal construction for hash-based objects.
 Returns : An object reference of the calling class, or undef if an attempt is made
           to instantiate Package::Base directly.
 Args    : an anonymous hash of object attribute/value pairs.  L</init()>.

=cut

sub new {
  my($class,%arg) = @_;

  if($class eq __PACKAGE__){
    cluck( __PACKAGE__." is an abstract base class, and not directly instantiable" );
    return undef;
  }

  my $self = bless {}, $class;
  $self->init(%arg);

  return $self;
}

=head2 init()

 Usage   : $object->init(key1 => 'value1', key2 => 'value2');
 Returns : a reference to the calling object
 Args    : an anonymous hash of object attribute/value pairs.
 Function:

a method to initialize a new object.  Package::Base::init() provides
the following functionality:

1. treats arguments as an anonymous hash, and calls set-type methods
if possible for each key/value pair.  Consider the following code:

  package My::Class;
  use base qw(Package::Base);

  sub meth { my($self,$arg) = @_;
    $self->{'foo'} = $arg if defined($arg);
    return $self->{'foo'}
  }

  package main;
  my $foo = My::Class->new(meth => 'some value');
  print $foo->meth(); #prints "some value"

If method meth() was not defined in My::Class, or any of My::Class's
superclasses, the key/value pair is silently ignored.  Take advantage
of this method as well as any custom initialization you need in your
subclass like this:

  package My::Class;
  use base qw(Package::Base);

  sub init {
    my($self,%arg) = @_;
    $self->SUPER::init(@_);

    # now do your stuff
  }

=cut

sub init {
  my($self,%arg) = @_;
  foreach my $a (keys %arg){
    $self->$a($arg{$a}) if $self->can($a);
  }

  return $self;
}

=head1 SWAP-IN/OUT METHODS FOR Package::Base::Devel

these methods allow the interchangeable usage of Package::Base
and Package::Base::Devel.  They're essentially no-op methods.

=cut

=head2 log()

returns a singleton instance of an object that accepts
Log::Log4perl::Logger calls (any calls, actually, it ISA
Autoloader), but does nothing with them.

=cut

sub log {
  return Package::Base::Stub::Log->get_instance();
}

=head2 loglevel()

method to support swapability of Package::Base and Package::Base::Devel.
returns 1

=cut

sub loglevel {1}

=head2 logconfig()

method to support swapability of Package::Base and Package::Base::Devel.
returns 1

=cut

sub logconfig {1}

1;
__END__
