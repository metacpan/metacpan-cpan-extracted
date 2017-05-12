package QGlobal;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(&qRound);
@EXPORT_OK = qw(%Align $SingleLine $DontClip $ExpandTabs $ShowPrefix $WordBreak
		$GrayText $DontPrint

		%Key $SHIFT $CTRL $ALT $ASCII_ACCEL

		%RasterOp);

$VERSION = '0.03';
bootstrap QGlobal $VERSION;

package Qt::Hash;

sub setImmortal {
    my $self = shift;

    delete $$self{'DELETE'} if exists $$self{'DELETE'};

    return $self;
}

1;
__END__

=head1 NAME

QGlobal - Internal PerlQt class, required by all other classes

=head1 SYNOPSIS

C<require QGlobal;>

C<use QGlobal qw(...);>

$object = new QClass->setImmortal

=head1 DESCRIPTION

The only relevant function in QGlobal (so far) is setImmortal(). It
removes the tendency of Perl to free the memory used by an object
when it goes out of scope. If you create say... a button that can
live a life of it's own while within a subroutine, that button
will be killed at the end of the subroutine without setImmortal().

Reading beyond this point implies that you care about the internals.
Everything in here is subject to change at my whim (and probably already has).

=head2 Object internals

QGlobal is a repository for constansts requires by more than one independant
class, and contains Qt::Hash which is inherited by all Qt classes.
The name Qt::Hash is a remnant from when all Qt objects were blessed
references to tied hashes. It is no-longer relevant because I sacrificed
safety and a bit of convienience in exchange for speed. Every Qt object
has two vital elements, C<THIS> and C<DESTROY>. The C<THIS> element
holds the actual pointer to the C++ object represented in ram. PerlQt
sub-classes all classes for convienience, access to protected members,
and garbage-collection.

Internally, there are two types of sub-class types, the PClass, and the
pClass. The pClass is availble only for classes which have protected
members which are accessible via Perl. There is a macro, C<pQtTHIS(type)>,
in F<virtual.h> from libperlqt, which automatically typecasts PClass objects
into pClass objects. The PClass is the main sub-class type. Every class has
a P version, and when a PClass is returned from an XS function, the
C<DESTROY> key is created and set to true. Only the existance of
C<DESTROY> is necessary to delete the object on destruction. PClass
objects are returned from all constructors, and from all classes returning
S<QClass &>.

=head2 Object access

There are two functions that are universally useful and likely to be
permanent. They are declared in F<pqt.h>, and every class requires that
header.

=over 4

=item SV *objectify_ptr(void *ptr, char *clname, int delete_on_destroy = 0)

This function is used when you want to convert a class pointer to an object.
I<NEVER, EVER, EVER> try to convert a pointer to an SV manually!!! The
internals are subject to change daily. And believe me, I've done it.
This function is automatically used in the typemap.

The ptr argument is the object to be accessable in Perl. The clname argument
is the name of the class. It is automatically modified so as to strip
off any trailing garbage like spaces or *'s. That means macro conversions
of pointer-types to strings are acceptable. In fact, that's how the typemap
does it. The delete_on_destroy argument is pretty obvious. Just set it to
a true value if you want the object to be deleted when it is destroyed.

=item void *extract_ptr(SV *obj, char *clname)

This does the opposite conversion from objectify_ptr. It I<will> cause
the program to croak if passed what it considers an invalid object.

=back

=head2 Virtual functions

The way in which virtual function-calls from C++ to Perl are achieved
is pretty simple at the moment. For every virtual function to be
overridden, a function named QClass_virtualFunction is created in the
virtualize class. The virtualize class, in turn, is inherited by all
classes which have virtual functions that can be overridden in Perl.

Since the PClasses don't inherit each other, the same virtual function
must be overridden in all the sub-classes of the class with the virtual
function as well, if you want people to sub-class those classes. Since
every PClass which implements virtual classes inherits virtualize,
all that is needed in the virtual override function is a stub which calls
QClass_virtualFunction.

The QClass_virtualFunction itself just does a method-call to a perl object
which was automatically saved when the object was created.

=head2 Signals and slots

Once they are setup, signals and slots are pretty fast and efficient in
Perl. The process of getting there is not.

The signals and slots for a class are accesible through
C<%$signals::signals{QClass}> and C<%$slots::slots{QClass}>. These are
filled in with C<use signals> and C<use slots>.

For every conection to a Perl QObject slot, a dummy pQtSigSlot object is
created. It is given the object it is to be an interface to, and the slot-name
it is supposed to call. The pQtSigSlot class holds all the stub functions
to be used to call Perl methods. Mostly, those stub function just call the
main functions, C<slot1(SV*)>, C<slot2(SV*,SV*)>, etc, with their arguments
converted to their scalar values.

For every perl signal, a single dummy XS function is just given a new name.
Since the C<CV*> of a function is always passed to an XS function, it
just sees which function-name it was called as, checks the C<%signals>
table for the signal to emit, and calls the relevant internal activate*()
function.

All of the actual code for this is in F<QObject.xs> from the main source-tree
and F<sigslot.xs> from libperlqt.

=head1 EXPORTED

Exports &qRound. EXPORT_OK's a bunch of useful enum values. See
F<QGlobal.pm> for a list of those.

=head1 CAVEATS

Everything will change.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
