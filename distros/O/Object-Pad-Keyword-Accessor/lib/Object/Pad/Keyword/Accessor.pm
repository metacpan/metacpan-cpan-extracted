#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2023 -- leonerd@leonerd.org.uk

package Object::Pad::Keyword::Accessor 0.02;

use v5.14;
use warnings;

use Object::Pad;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::Keyword::Accessor> - declare lvalue accessors on C<Object::Pad> classes

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::Keyword::Accessor;

   class Counter {
      use Carp;

      field $count = 0;

      accessor count {
         get { return $count }
         set ($new) {
            $new =~ m/^\d+$/ or croak "Invalid new value for count";

            $count = $new;

            say "Count has been updated to $count";
         }
      }
   }

   my $c = Counter->new;
   $c->count = 20;

   $c->count = "hello";  # is not permitted

=head1 DESCRIPTION

This module provides a new keyword for declaring accessor methods that behave
as lvalues as members of L<Object::Pad>-based classes.

While C<Object::Pad> does permit fields of classes to be exposed to callers
via lvalue mutator methods by using the C<:mutator> field attribute, these are
generally not that useful in real cases. Fields exposed using this technique
have no validation, and cannot trigger any other code to be executed after
update.

The L</accessor> keyword provided by this module offers an alternative. The
lvalue accessor methods it provides into the class fully support running
arbitrary code on read and write access, permitting any kind of check or
triggering action. In fact, the accessor does not even need to be directly
backed by a field at all. The accessor permits the class to specify its
interface by which other code will interact with it, without being forced into
any particular implementation of that interface.

This module is a very early proof-of-concept, both of the syntax itself and
the underlying ability of C<Object::Pad> to support such syntax extensions as
a third-party module.

=head2 Motivation

At first glance it may not seem immediately obvious why you would want to do
this. After all, these accessors do not permit any new behaviours that
couldn't be performed with a more traditional pair of C<get_*> + C<set_*>
methods.

The first reason is simply the declaration of intent on behalf of the class.
Given a similarly-named C<get>/C<set> pair of methods, a user could guess that
they probably behave like an accessor. But by providing the behaviour as a
real accessor this makes a much firmer statement; where the user can much more
strongly expect things like multiple read accesses to be idempotent and yield
the same value as the most recent write access.

The second reason is that perl already provides quite a number of mutating
operators that allow a value to be edited in-place. These would not work at
all with a C<get>/C<set> method pair, whereas they work just fine with these
accessors. For example, given the code in the synopsis, the counter could be
incremented simply by

   $c->count++;

Whereas, if an lvalue accessor did not exist you would have to write this as
something like

   $c->set_count( $c->count + 1 );

The earlier form is much simpler, shorter, and much more obvious at first
glance what it's doing. You don't, for example, have to check that the C<get>
and C<set> method pair are indeed operating on the same thing. There's just
one accessor of one object.

=head1 KEYWORDS

=head2 accessor

   accessor NAME { PARTS... }

Declares a new accessor method of the given name into the class. This will
appear as a regular method, much as if declared by code such as

   method NAME :lvalue { ... }

The behaviour of the accessor will be controlled by the parts given in the
braces following its name. Note that these braces are not simply a code block;
it does not accept arbitrary perl code. Only the following keywords may be
used there.

=head3 get

   accessor NAME { get { CODE... } }

Provides a body of code to be invoked when a caller is attempting to read the
value of the accessor. The code block behaves as a method, having access to
the C<$self> lexical as well as any fields already defined on the class. The
value it returns will be the value passed back to the caller who read the
accessor.

=head3 set

   accessor NAME { set { CODE... } }

   accessor NAME { set ($var) { CODE... } }

Provides a body of code to be invoked when a caller is attempting to write a
new value for the accessor. The code block behaves like a method, having
access to the C<$self> lexical as well as any fields already defined on the
class. The new value written by the caller will appear as the first positional
argument to the method, accessible by code such as C<shift> or C<$_[0]>.

A second more succinct form allows the block to be written with a prefixed
declaration of a variable name, using the same syntax as a subroutine
signature (though this is not implemented by the same mechanism; it works on
perl versions older than signatures are supported, and does not allow a
defaulting expression or other syntax).

If the code in this block throws an exception, that will propagate up to the
caller who attempted to write the value. If this happens before the code block
has stored the new value somewhere as a side-effect, then this will have the
appearance of denying the modification at all. This is the way in which a
validation check can be implemented.

Similarly, the code is free to perform any other activity after it has stored
the new value. This is is the way that post-update code triggering can be
implemented. For example, if the object represents some sort of UI display
widget it might decide to redraw the screen to reflect the updated value of
whatever field just changed.

=cut

sub import
{
   $^H{"Object::Pad::Keyword::Accessor"}++;
}

sub unimport
{
   delete $^H{"Object::Pad::Keyword::Accessor"};
}

=head1 TODO

=over 4

=item *

Some syntax to allow a field to be associated with the accessor, so it can
automatically generate the C<get> code, and assist the C<set> code. This would
permit an alternative form where code blocks for value validation check and
post-update trigger were specified instead.

Perhaps:

   field $x;

   accessor x {
      field($x)
      check ($new) { $new >= 0 or croak "Must be non-negative"; }
      trigger { $self->updated; }
   }

=item *

Integration with the constructor to permit a named-parameter at construction
time that would automatically set the value of the accessor, as if the user
had done so manually.

Perhaps:

   accessor x :param { ... }

=item *

Consider whether to permit the accessor method itself to take arguments,
allowing for some kind of indexed or parametric accessor.

Perhaps:

   field @palette;

   accessor colour($index) {
      get { return $palette[$index]; }
      set ($new) { $palette[$index] = $new; }
   }

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
