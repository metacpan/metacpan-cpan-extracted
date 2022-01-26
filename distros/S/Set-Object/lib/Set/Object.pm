=head1 NAME

Set::Object - set of objects and strings

=head1 SYNOPSIS

  use Set::Object qw(set);

  my $set = set();            # or Set::Object->new()

  $set->insert(@thingies);
  $set->remove(@thingies);

  @items = @$set;             # or $set->members for the unsorted array

  $union = $set1 + $set2;
  $intersection = $set1 * $set2;
  $difference = $set1 - $set2;
  $symmetric_difference = $set1 % $set2;

  print "set1 is a proper subset of set2"
      if $set1 < $set2;

  print "set1 is a subset of set2"
      if $set1 <= $set2;

  # common idiom - iterate over any pure Perl structure
  use Set::Object qw(reftype);
  my @stack = $root;
  my $seen = Set::Object->new(@stack);
  while (my $object = pop @stack) {
      if (reftype $object eq "HASH") {
          # do something with hash members

          # add the new nodes to the stack
          push @stack, grep { ref $_ && $seen->insert($_) }
              values %$object;
      }
      elsif (reftype $object eq "ARRAY") {
          # do something with array members

          # add the new nodes to the stack
          push @stack, grep { ref $_ && $seen->insert($_) }
              @$object;

      }
      elsif (reftype $object =~ /SCALAR|REF/) {
          push @stack, $$object
              if ref $$object && $seen->insert($$object);
      }
  }

=head1 DESCRIPTION

This modules implements a set of objects, that is, an unordered
collection of objects without duplication.

The term I<objects> is applied loosely - for the sake of
L<Set::Object>, anything that is a reference is considered an object.

L<Set::Object> 1.09 and later includes support for inserting scalars
(including the empty string, but excluding C<undef>) as well as
objects.  This can be thought of as (and is currently implemented as)
a degenerate hash that only has keys and no values.  Unlike objects
placed into a Set::Object, scalars that are inserted will be flattened
into strings, so will lose any magic (eg, tie) or other special bits
that they went in with; only strings come out.

=head1 CONSTRUCTORS

=head2 Set::Object->new( [I<list>] )

Return a new C<Set::Object> containing the elements passed in I<list>.

=head2 C<set(@members)>

Return a new C<Set::Object> filled with C<@members>.  You have to
explicitly import this method.

B<New in Set::Object 1.22>: this function is now called as a method
to return new sets the various methods that return a new set, such as
C<-E<gt>intersection>, C<-E<gt>union>, etc and their overloaded
counterparts.  The default method always returns C<Set::Object>
objects, preserving previous behaviour and not second guessing the
nature of your derived L<Set::Object> class.

=head2 C<weak_set()>

Return a new C<Set::Object::Weak>, filled with C<@members>.  You have
to explicitly import this method.

=head1 INSTANCE METHODS

=head2 insert( [I<list>] )

Add items to the C<Set::Object>.

Adding the same object several times is not an error, but any
C<Set::Object> will contain at most one occurrence of the same object.

Returns the number of elements that were actually added.  As of
Set::Object 1.23, C<undef> will not insert.

=head2 includes( [I<list>] )

=head2 has( [I<list>] )

=head2 contains( [I<list>] )

Return C<true> if B<all> the objects in I<list> are members of the
C<Set::Object>.  I<list> may be empty, in which case C<true> is
always returned.

As of Set::Object 1.23, C<undef> will never appear to be present in
any set (even if the set contains the empty string).  Prior to 1.23,
there would have been a run-time warning.

=head2 member( [I<item>] )

=head2 element( [I<item>] )

Like C<includes>, but takes a single item to check and returns that
item if the value is found, rather than just a true value.

=head2 members

=head2 elements

Return the objects contained in the C<Set::Object> in random (hash)
order.

Note that the elements of a C<Set::Object> in list context are returned
sorted - C<@$set> - so using the C<members> method is much faster.

=head2 size

Return the number of elements in the C<Set::Object>.

=head2 remove( [I<list>] )

=head2 delete( [I<list>] )

Remove objects from a C<Set::Object>.

Removing the same object more than once, or removing an object absent
from the C<Set::Object> is not an error.

Returns the number of elements that were actually removed.

As of Set::Object 1.23, removing C<undef> is safe (but having an
C<undef> in the passed in list does not increase the return value,
because it could never be in the set)

=head2 weaken

Makes all the references in the set "weak" - that is, they do not
increase the reference count of the object they point to, just like
L<Scalar::Util|Scalar::Util>'s C<weaken> function.

This was introduced with Set::Object 1.16, and uses a brand new type
of magic.  B<Use with caution>.  If you get segfaults when you use
C<weaken>, please reduce your problem to a test script before
submission.

B<New:> as of Set::Object 1.19, you may use the C<weak_set> function
to make weak sets, or C<Set::Object::Weak-E<gt>new>, or import the
C<set> constructor from C<Set::Object::Weak> instead.  See
L<Set::Object::Weak> for more.

B<Note to people sub-classing C<Set::Object>:> this method re-blesses
the invocant to C<Set::Object::Weak>.  Override the method C<weak_pkg>
in your sub-class to control this behaviour.

=head2 is_weak

Returns a true value if this set is a weak set.

=head2 strengthen

Turns a weak set back into a normal one.

B<Note to people sub-classing C<Set::Object>:> this method re-blesses
the invocant to C<Set::Object>.  Override the method C<strong_pkg> in
your sub-class to control this behaviour.

=head2 invert( [I<list>] )

For each item in I<list>, it either removes it or adds it to the set,
so that a change is always made.

Also available as the overloaded operator C</>, in which case it
expects another set (or a single scalar element), and returns a new
set that is the original set with all the second set's items inverted.

=head2 clear

Empty this C<Set::Object>.

=head2 as_string

Return a textual Smalltalk-ish representation of the C<Set::Object>.
Also available as overloaded operator "".

=head2 equal( I<set> )

Returns a true value if I<set> contains exactly the same members as
the invocant.

Also available as overloaded operator C<==> (or C<eq>).

=head2 not_equal( I<set> )

Returns a false value if I<set> contains exactly the same members as
the invocant.

Also available as overloaded operator C<!=> (or C<ne>).

=head2 intersection( [I<list>] )

Return a new C<Set::Object> containing the intersection of the
C<Set::Object>s passed as arguments.

Also available as overloaded operator C<*>.

=head2 union( [I<list>] )

Return a new C<Set::Object> containing the union of the
C<Set::Object>s passed as arguments.

Also available as overloaded operator C<+>.

=head2 difference ( I<set> )

Return a new C<Set::Object> containing the members of the first
(invocant) set with the passed C<Set::Object>s' elements removed.

Also available as overloaded operator C<->.

=head2 unique ( I<set> )

=head2 symmetric_difference ( I<set> )

Return a new C<Set::Object> containing the members of all passed sets
(including the invocant), with common elements removed.  This will be
the opposite (complement) of the I<intersection> of the two sets.

Also available as overloaded operator C<%>.

=head2 subset( I<set> )

Return C<true> if this C<Set::Object> is a subset of I<set>.

Also available as operator C<E<lt>=>.

=head2 proper_subset( I<set> )

Return C<true> if this C<Set::Object> is a proper subset of I<set>
Also available as operator C<E<lt>>.

=head2 superset( I<set> )

Return C<true> if this C<Set::Object> is a superset of I<set>.
Also available as operator C<E<gt>=>.

=head2 proper_superset( I<set> )

Return C<true> if this C<Set::Object> is a proper superset of I<set>
Also available as operator C<E<gt>>.

=head2 is_null( I<set> )

Returns a true value if this set does not contain any members, that
is, if its size is zero.

=head1 Set::Scalar compatibility methods

By and large, L<Set::Object> is not and probably never will be
feature-compatible with L<Set::Scalar>; however the following
functions are provided anyway.

=head2 compare( I<set> )

returns one of:

  "proper intersect"
  "proper subset"
  "proper superset"
  "equal"
  "disjoint"

=head2 is_disjoint( I<set> )

Returns a true value if the two sets have no common items.

=head2 as_string_callback( I<set> )

Allows you to define a custom stringify function.  This is only a
class method.  If you want anything fancier than this, you should
sub-class Set::Object.


=head1 FUNCTIONS

The following functions are defined by the Set::Object XS code for
convenience; they are largely identical to the versions in the
Scalar::Util module, but there are a couple that provide functions not
catered to by that module.

Please use the versions in L<Scalar::Util> in preference to these
functions.  In fact, if you use these functions in your production
code then you may have to rewrite it some day.  They are retained only
because they are "mostly harmless".

=over

=item B<blessed>

B<Do not use in production code>

Returns a true value if the passed reference (RV) is blessed.  See
also L<Acme::Holy>.

=item B<reftype>

B<Do not use in production code>

A bit like the perl built-in C<ref> function, but returns the I<type>
of reference; ie, if the reference is blessed then it returns what
C<ref> would have if it were not blessed.  Useful for "seeing through"
blessed references.

=item B<refaddr>

B<Do not use in production code>

Returns the memory address of a scalar.  B<Warning>: this is I<not>
guaranteed to be unique for scalars created in a program; memory might
get re-used!

=item B<is_int>, B<is_string>, B<is_double>

B<Do not use in production code>

A quick way of checking the three bits on scalars - IOK (is_int), NOK
(is_double) and POK (is_string).  Note that the exact behaviour of
when these bits get set is not defined by the perl API.

This function returns the "p" versions of the macro (SvIOKp, etc); use
with caution.

=item B<is_overloaded>

B<Do not use in production code>

A quick way to check if an object has overload magic on it.

=item B<ish_int>

B<Deprecated and will be removed in 2014>

This function returns true, if the value it is passed looks like it
I<already is> a representation of an I<integer>.  This is so that you
can decide whether the value passed is a hash key or an array
index.

=item B<is_key>

B<Deprecated and will be removed in 2014>

This function returns true, if the value it is passed looks more like
an I<index> to a collection than a I<value> of a collection.  Similar
to the looks_like_number internal function, but weird.  Avoid.

=item B<get_magic>

B<Do not use in production code>

Pass to a scalar, and get the magick wand (C<mg_obj>) used by the weak
set implementation.  The return will be a list of integers which are
pointers to the actual C<ISET> structure.  Whatever you do don't
change the array :).  This is used only by the test suite, and if you
find it useful for something then you should probably conjure up a
test suite and send it to me, otherwise it could get pulled.

=back

=head1 CLASS METHODS

These class methods are probably only interesting to those
sub-classing C<Set::Object>.

=over

=item strong_pkg

When a set that was already weak is strengthened using
C<-E<gt>strengthen>, it gets re-blessed into this package.

=item weak_pkg

When a set that was NOT already weak is weakened using
C<-E<gt>weaken>, it gets re-blessed into this package.

=item tie_array_pkg

When the object is accessed as an array, tie the array into this
package.

=item tie_hash_pkg

When the object is accessed as a hash, tie the hash into this package.

=back

=head1 SERIALIZATION

It is possible to serialize C<Set::Object> objects via L<Storable> and
duplicate via C<dclone>; such support was added in release 1.04.  As
of C<Set::Object> version 1.15, it is possible to freeze scalar items,
too.

However, the support for freezing scalar items introduced a backwards
incompatibility.  Earlier versions than 1.15 will C<thaw> sets frozen
using Set::Object 1.15 and later as a set with one item - an array
that contains the actual members.

Additionally, version 1.15 had a bug that meant that it would not
detect C<freeze> protocol upgrades, instead reverting to pre-1.15
behaviour.

C<Set::Object> 1.16 and above are capable of dealing correctly with
all serialized forms, as well as correctly aborting if a "newer"
C<freeze> protocol is detected during C<thaw>.

=head1 PERFORMANCE

The following benchmark compares C<Set::Object> with using a hash to
emulate a set-like collection (this is an old benchmark, but still
holds true):

   use Set::Object;

   package Obj;
   sub new { bless { } }

   @els = map { Obj->new() } 1..1000;

   require Benchmark;

   Benchmark::timethese(100, {
      'Control' => sub { },
      'H insert' => sub { my %h = (); @h{@els} = @els; },
      'S insert' => sub { my $s = Set::Object->new(); $s->insert(@els) },
      } );

   %gh = ();
   @gh{@els} = @els;

   $gs = Set::Object->new(@els);
   $el = $els[33];

   Benchmark::timethese(100_000, {
	   'H lookup' => sub { exists $gh{33} },
	   'S lookup' => sub { $gs->includes($el) }
      } );

On my computer the results are:

   Benchmark: timing 100 iterations of Control, H insert, S insert...
      Control:  0 secs ( 0.01 usr  0.00 sys =  0.01 cpu)
               (warning: too few iterations for a reliable count)
     H insert: 68 secs (67.81 usr  0.00 sys = 67.81 cpu)
     S insert:  9 secs ( 8.81 usr  0.00 sys =  8.81 cpu)
   Benchmark: timing 100000 iterations of H lookup, S lookup...
     H lookup:  7 secs ( 7.14 usr  0.00 sys =  7.14 cpu)
     S lookup:  6 secs ( 5.94 usr  0.00 sys =  5.94 cpu)

This benchmark compares the unsorted members method, against the sorted @$ list context.

   perl -MBenchmark -mList::Util -mSet::Object -e'
   $set = Set::Object::set (List::Util::shuffle(1..1000));
   Benchmark::timethese(-3, {
      "Slow \@\$set       " => sub { $i++ for @$set; },
      "Fast set->members" => sub { $i++ for $set->members(); },
      });'

    Benchmark: running Fast set->members, Slow @$set        for at least 3 CPU seconds...
    Fast set->members:  4 wallclock secs ( 3.17 usr +  0.00 sys =  3.17 CPU) @ 9104.42/s (n=28861)
    Slow @$set       :  4 wallclock secs ( 3.23 usr +  0.00 sys =  3.23 CPU) @ 1689.16/s (n=5456)

=head1 THREAD SAFETY

This module is not thread-safe.

=head1 AUTHOR

Original Set::Object module by Jean-Louis Leroy, <jll@skynet.be>

Set::Scalar compatibility, XS debugging, weak references support
courtesy of Sam Vilain, <samv@cpan.org>.

New maintainer is Reini Urban <rurban@cpan.org>.
Patches against L<https://github.com/rurban/Set-Object/> please.
Tickets at RT L<https://rt.cpan.org/Public/Dist/Display.html?Name=Set-Object>

=head1 LICENCE

Copyright (c) 1998-1999, Jean-Louis Leroy. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License, either the
original, or at your option, any later version.

Portions Copyright (c) 2003 - 2005, Sam Vilain.  Same license.

Portions Copyright (c) 2006, 2007, Catalyst IT (NZ) Limited.  This
module is free software. It may be used, redistributed and/or modified
under the terms of the Perl Artistic License

Portions Copyright (c) 2013, cPanel.  Same license.
Portions Copyright (c) 2020, Reini Urban.  Same license.

=head1 SEE ALSO

perl(1), perltie(1), L<Set::Scalar>, L<overload>

=cut

package Set::Object;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT_OK = qw( ish_int is_int is_string is_double blessed reftype
		 refaddr is_overloaded is_object is_key set weak_set );
$VERSION = '1.42';

bootstrap Set::Object $VERSION;

# Preloaded methods go here.

our $cust_disp;

sub as_string
{
    return $cust_disp->(@_) if $cust_disp;
    my $self = shift;
    croak "Tried to use as_string on something other than a Set::Object"
	unless (UNIVERSAL::isa($self, __PACKAGE__));

    ref($self).'(' . (join ' ', sort { $a cmp $b }
		     $self->members) . ')'
}

sub equal
{
   my ($s1, $s2) = @_;
   return undef unless (UNIVERSAL::isa($s2, __PACKAGE__));

   $s1->size() == $s2->size() && $s1->includes($s2->members);
}

sub not_equal
{
   !shift->equal(shift);
}

sub union
{
    $_[0]->set
	    ( map { $_->members() }
	      grep { UNIVERSAL::isa($_, __PACKAGE__) }
	      @_ );
}

sub op_union
{
    my $self = shift;
    my $other;
    if (ref $_[0]) {
	$other = shift;
    } else {
	$other = $self->set(shift);
    }

    croak("Tried to form union between Set::Object & "
	  ."`$other'")
	if ref $other and not UNIVERSAL::isa($other, __PACKAGE__);

    $self->union($other);

}

sub intersection
{
   my $s = shift;
   my $rem = $s->set($s->members);

   while ($s = shift)
   {
       if (!ref $s) {
	   $s = $rem->new($s);
       }

       croak("Tried to form intersection between Set::Object & "
	     .(ref($s)||$s)) unless UNIVERSAL::isa($s, __PACKAGE__);

       $rem->remove(grep { !$s->includes($_) } $rem->members);
   }

   $rem;
}

sub op_intersection
{
    my $s1 = shift;
    my $s2;
    if (ref $_[0]) {
	$s2 = shift;
    } else {
	$s2 = $s1->set(shift);
    }
    my $r = shift;
    if ( $r ) {
	return intersection($s2, $s1);
    } else {
	return intersection($s1, $s2);
    }

}

sub difference
{
   my ($s1, $s2, $r) = @_;
   if ( ! ref $s2 ) {
       if ( is_int($s2) and !is_string($s2) and $s2 == 0 ) {
	   return __PACKAGE__->new();
       } else {
	   my $set = __PACKAGE__->new($s2);
	   $s2 = $set;
       }
   }
   croak("Tried to find difference between Set::Object & "
	 .(ref($s2)||$s2)) unless UNIVERSAL::isa($s2, __PACKAGE__);

   my $s;
   if ( $r ) {
       $s = $s2->set( grep { !$s1->includes($_) } $s2->members );
   } else {
       $s = $s1->set( grep { !$s2->includes($_) } $s1->members );
   }
   $s;
}

sub op_invert
{
    my $self = shift;
    my $other;
    if (ref $_[0]) {
	$other = shift;
    } else {
	$other = __PACKAGE__->new(shift);
    }

    croak("Tried to form union between Set::Object & "
	  ."`$other'")
	if ref $other and not UNIVERSAL::isa($other, __PACKAGE__);

    my $result = $self->set( $self->members() );
    $result->invert( $other->members() );
    return $result;

}

sub op_symm_diff
{
    my $self = shift;
    my $other;
    if (ref $_[0]) {
	$other = shift;
    } else {
	$other = __PACKAGE__->new(shift);
    }
    return $self->symmetric_difference($other);
}

sub unique {
    my $self = shift;
    $self->symmetric_difference(@_);
}

sub symmetric_difference
{
   my ($s1, $s2) = @_;
   croak("Tried to find symmetric difference between Set::Object & "
	 .(ref($s2)||$s2)) unless UNIVERSAL::isa($s2, __PACKAGE__);

   $s1->difference( $s2 )->union( $s2->difference( $s1 ) );
}

sub proper_subset
{
   my ($s1, $s2) = @_;
   croak("Tried to find proper subset of Set::Object & "
	 .(ref($s2)||$s2)) unless UNIVERSAL::isa($s2, __PACKAGE__);
   $s1->size < $s2->size && $s1->subset( $s2 );
}

sub subset
{
   my ($s1, $s2, $r) = @_;
   croak("Tried to find subset of Set::Object & "
	 .(ref($s2)||$s2)) unless UNIVERSAL::isa($s2, __PACKAGE__);
   $s2->includes($s1->members);
}

sub proper_superset
{
   my ($s1, $s2, $r) = @_;
   croak("Tried to find proper superset of Set::Object & "
	 .(ref($s2)||$s2)) unless UNIVERSAL::isa($s2, __PACKAGE__);
   proper_subset( $s2, $s1 );
}

sub superset
{
   my ($s1, $s2) = @_;
   croak("Tried to find superset of Set::Object & "
	 .(ref($s2)||$s2)) unless UNIVERSAL::isa($s2, __PACKAGE__);
   subset( $s2, $s1 );
}

# following code pasted from Set::Scalar; thanks Jarkko Hietaniemi

use overload
   '""'  =>		\&as_string,
   '+'   =>		\&op_union,
   '*'   =>		\&op_intersection,
   '%'   =>		\&op_symm_diff,
   '/'   =>		\&op_invert,
   '-'   =>		\&difference,
   '=='  =>		\&equal,
   '!='  =>		\&not_equal,
   '<'   =>		\&proper_subset,
   '>'   =>		\&proper_superset,
   '<='  =>		\&subset,
   '>='  =>		\&superset,
   '%{}'  =>		sub { my $self = shift;
			      my %h = ();
			      tie %h, $self->tie_hash_pkg, [], $self;
			      \%h },
   '@{}'  =>		sub { my $self = shift;
			      my @h = {};
			      tie @h, $self->tie_array_pkg, [], $self;
			      \@h },
   'bool'  =>		sub { 1 },
    fallback => 1,
   ;

sub tie_hash_pkg { "Set::Object::TieHash" };
sub tie_array_pkg { "Set::Object::TieArray" };

{ package Set::Object::TieArray;
  sub TIEARRAY {
      my $p = shift;
      my $tie = bless [ @_ ], $p;
      require Scalar::Util;
      Scalar::Util::weaken($tie->[0]);
      Scalar::Util::weaken($tie->[1]);
      return $tie;
  }
  # note the sort here
  sub promote {
      my $self = shift;
      @{$self->[0]} = sort $self->[1]->members;
      return $self->[0];
  }
  sub commit {
      my $self = shift;
      $self->[1]->clear;
      $self->[1]->insert(@{$self->[0]});
  }
  sub FETCH {
      my $self = shift;
      my $index = shift;
      $self->promote->[$index];
  }
  sub STORE {
      my $self = shift;
      my $index = shift;
      $self->promote->[$index] = shift;
      $self->commit;
  }
  sub FETCHSIZE {
      my $self = shift;
      return $self->[1]->size;
  }
  sub STORESIZE {
      my $self = shift;
      my $count = shift;
      $#{$self->promote}=$count-1;
      $self->commit;
  }
  sub EXTEND {
  }
  sub EXISTS {
      my $self = shift;
      my $index = shift;
      if ( $index+1 > $self->[1]->size) {
	  return undef;
      } else {
	  return 1;
      }
  }
  sub DELETE {
      my $self = shift;
      delete $self->promote->[(shift)];
      $self->commit;
  }
  sub PUSH {
      my $self = shift;
      $self->[1]->insert(@_);
  }
  sub POP {
      my $self = shift;
      my $rv = pop @{$self->promote};
      $self->commit;
      return $rv;
  }
  sub CLEAR {
      my $self = shift;
      $self->[1]->clear;
  }
  sub SHIFT {
      my $self = shift;
      my $rv = shift @{$self->promote};
      $self->commit;
      return $rv;
  }
  sub UNSHIFT {
      my $self = shift;
      $self->[1]->insert(@_);
  }
  sub SPLICE {
      my $self = shift;
      my @rv;
      # perl5--
      if ( @_ == 1 ) {
	  splice @{$self->promote}, $_[0];
      }
      elsif ( @_ == 2 ) {
	  splice @{$self->promote}, $_[0], $_[1];
      }
      else {
	  splice @{$self->promote}, $_[0], $_[1], @_;
      }
      $self->commit;
      @rv;
  }
}

{ package Set::Object::TieHash;
  sub TIEHASH {
      my $p = shift;
      my $tie = bless [ @_ ], $p;
      require Scalar::Util;
      Scalar::Util::weaken($tie->[0]);
      Scalar::Util::weaken($tie->[1]);
      return $tie;
  }
  sub FETCH {
      my $self = shift;
      return $self->[1]->includes(shift);
  }
  sub STORE {
      my $self = shift;
      my $item = shift;
      if ( shift ) {
	  $self->[1]->insert($item);
      } else {
	  $self->[1]->remove($item);
      }
  }
  sub DELETE {
      my $self = shift;
      my $item = shift;
      $self->[1]->remove($item);
  }
  sub CLEAR {
      my $self = shift;
      $self->[1]->clear;
  }
  sub EXISTS {
      my $self = shift;
      $self->[1]->includes(shift);
  }
  sub FIRSTKEY {
      my $self = shift;
      @{$self->[0]} = $self->[1]->members;
      $self->NEXTKEY;
  }
  sub NEXTKEY {
      my $self = shift;
      if ( @{$self->[0]} ) {
	  return (shift @{$self->[0]});
      } else {
	  return ();
      }
  }
  sub SCALAR {
      my $self = shift;
      $self->[1]->size;
  }
}

# Autoload methods go after =cut, and are processed by the autosplit program.
# This function is used to differentiate between an integer and a
# string for use by the hash container types


# This function is not from Scalar::Util; it is a DWIMy function to
# decide whether the passed thingy could reasonably be considered
# to be an array index, and if so returns the index
sub ish_int {
    my $i;
    local $@;
    eval { $i = _ish_int($_[0]) };

    if ($@) {
	if ($@ =~ /overload/i) {
	    if (my $sub = UNIVERSAL::can($_[0], "(0+")) {
		return ish_int(&$sub($_[0]));
	    } else {
		return undef;
	    }
	} elsif ($@ =~ /tie/i) {
	    my $x = $_[0];
	    return ish_int($x);
	}
    } else {
	return $i;
    }
}

# returns true if the value looks like a key, not an object or a
# collection
sub is_key {
    if (my $class = tied $_[0]) {
	if ($class =~ m/^Tangram::/) { # hack for Tangram RefOnDemands
	    return undef;
	} else {
	    my $x = $_[0];
	    return is_key($x);
	}
    } elsif (is_overloaded($_[0])) {
	# this is a bit of a hack - intrude into the overload internal
	# space
	if (my $sub = UNIVERSAL::can($_[0], "(0+")) {
	    return is_key(&$sub($_[0]));
	} elsif ($sub = UNIVERSAL::can($_[0], '(""')) {
	    return is_key(&$sub($_[0]));
	} elsif ($sub = UNIVERSAL::can($_[0], '(nomethod')) {
	    return is_key(&$sub($_[0]));
	} else {
	    return undef;
	}
    } elsif (is_int($_[0]) || is_string($_[0]) || is_double($_[0])) {
	return 1;
    } else {
	return undef;
    }
}

# interface so that Storable may still work
sub STORABLE_freeze {
    my $obj = shift;
    my $am_cloning = shift;
    return ("v3-" . ($obj->is_weak ? "w" : "s"), [ $obj->members ]);
}

#use Devel::Peek qw(Dump);

sub STORABLE_thaw {
    #print Dump $_ foreach (@_);

    if ( $_[2] ) {
	if ( $_[2] eq "v2" ) {
	    @_ = (@_[0,1], "", @{ $_[3] });
	}
	elsif ( $_[2] =~ m/^v3-(w|s)/ ) {
	    @_ = (@_[0,1], "", @{ $_[3] });
	    if ( $1 eq "w" ) {
		my $self = shift;
		$self->_STORABLE_thaw(@_);
		$self->weaken();
		return;
	    }
	} else {
	    croak("Unrecognised Set::Object Storable version $_[2]");
	}
    }

    goto &_STORABLE_thaw;
    #print "Got here\n";
}

sub delete {
    my $self = shift;
    return $self->remove(@_);
}

our $AUTOLOAD;
sub AUTOLOAD {
    croak "No such method $AUTOLOAD";
}

sub invert {
    my $self = shift;
    while ( @_ ) {
	my $sv = shift;
	defined $sv or next;
	if ( $self->includes($sv) ) {
	    $self->remove($sv);
	} else {
	    $self->insert($sv);
	}
    }
}

sub compare {
    my $self = shift;
    my $other = shift;

    return "apples, oranges" unless UNIVERSAL::isa($other, __PACKAGE__);

    my $only_self = $self - $other;
    my $only_other = $other - $self;
    my $intersect = $self * $other;

    if ( $intersect->size ) {
	if ( $only_self->size ) {
	    if ( $only_other->size ) {
		return "proper intersect";
	    } else {
		return "proper subset";
	    }
	} else {
	    if ( $only_other->size ) {
		return "proper superset";
	    } else {
		return "equal";
	    }
	}
    } else {
	if ($self->size || $other->size) {
	    return "disjoint";
	} else {
	    # both sets are empty
	    return "equal";
	}
    }
}

sub is_disjoint {
    my $self = shift;
    my $other = shift;

    return "apples, oranges" unless UNIVERSAL::isa($other, __PACKAGE__);
    return !($self*$other)->size;
}

#use Data::Dumper;
sub as_string_callback {
    shift;
    if ( @_ ) {
	$cust_disp = shift;
	if ( $cust_disp &&
	     $cust_disp == \&as_string ) {
	    undef($cust_disp);
	}
    } else {
	\&as_string;
    }
}

sub elements {
    my $self = shift;
    return $self->members(@_);
}

sub has { (shift)->includes(@_) }
sub contains { (shift)->includes(@_) }
sub element { (shift)->member(@_) }
sub member {
    my $self = shift;
    my $item = shift;
    return ( $self->includes($item) ?
	     $item : undef );
}

sub set {
    local $@;
    if (eval { $_[0]->isa(__PACKAGE__) }) {
    	shift;
    }
    __PACKAGE__->new(@_);
}
sub weak_set {
    my $self = __PACKAGE__->new();
    $self->weaken;
    $self->insert(@_);
    return $self;
}

require Set::Object::Weak;
sub weaken {
    my $self = shift;
    $self->_weaken;
    bless $self, $self->weak_pkg;
}

sub strengthen {
    my $self = shift;
    $self->_strengthen;
    bless $self, $self->strong_pkg;
}

sub weak_pkg {
    "Set::Object::Weak";
}
sub strong_pkg {
    "Set::Object";
}
1;

__END__
