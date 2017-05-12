package Object::Hybrid;

#use 5.006; 

use strict qw[vars subs];
$Object::Hybrid::VERSION = '0.07';  

$Object::Hybrid::Class::VERSION  = '0';
$Object::Hybrid::HASH::VERSION   = '0';
$Object::Hybrid::ARRAY::VERSION  = '0';
$Object::Hybrid::GLOB::VERSION   = '0';
$Object::Hybrid::SCALAR::VERSION = '0';

=head1 NAME

Object::Hybrid - promote Perl primitives (hashes, scalars, arrays, and filehandles), either tie()d or not, to become hybrid objects

=head1 WARNING

Any specific interface that Object::Hybrid exposes may change (as it already did) until version 1.0 is reached. 

=head1 SYNOPSIS

Here (and everywhere in this documentation) notion of "primitive" refers to hash, scalar, array, or filehandle (i.e. perltie types), either tie()d or non-tie()d, bless()ed or non-bless()ed.

Promote $primitive to become hybrid object:

	use Object::Hybrid qw(promote); # declare promote() for use
	promote $primitive; 

Or (especially if you prefer to not export anything) use new() constructor... 

	use           Object::Hybrid;
	$hybrid = new Object::Hybrid      $primitive;  # $primitive becomes hybrid object
	$hybrid =     Object::Hybrid->new($primitive); # same

NOTE: tie()d primitive must be tie()d before promote(). If it needs to be tie()d later, either re-promote() it or use tieable => 1 argument to promote() (see L</"promote() function">).

After that $primitive remains the same, but it is now bless()ed as object that exposes corresponding perltie methods, so that the following, for example, become interchangeable for B<both tied() and not tied()> %$primitive:

	$primitive->{foo};
	$primitive->FETCH('foo'); # same
	$primitive->fetch('foo'); # same

Also, in case of tie()d primitive instead of:

	tied(%$primitive)->method();

just be tied()less:

	$primitive->method();

In case non-tied() primitives need to be interchangeable with tied() ones that have extended tied() interface, instead of cumbersome (possibly repeating many times) tied()-conditional access expression:

	tied(%$primitive) ? 
	tied(%$primitive)->FETCH('foo', @args)
	:     $primitive->{foo};

just say:

	$primitive->FETCH('foo', @args);

or faster:

	$primitive->fast->FETCH('foo', @args);

However, for non-tie()d primitives the above tied()-conditional switch expression may still be significantly faster, so that it is still preferred for hot paths (tight loops, etc.). For speed and other trade-offs involved see L</"Performance"> and L</"fast()"> sections.

If $FH is a plain filehandle or tiehandle tied to class that implements stat(), ftest() (and others) and self() method, then the following simple code need not to discriminate between plain filehandle and tiehandle:

	promote $FH;

	$FH->stat(); 
	$FH->ftest('-X'); 

	# same in indirect method notation:
	STAT  $FH;
	FTEST $FH '-X';

=head1 DESCRIPTION

Some applications need to accept both plain primitives as well as tie()d primitives with additional (non-perltie) methods and parameters supported by extended interface available through tied() object. For example, application cache may be allowed to optionally use either screamingly fast plain hash or some highly evolved persistent hashes tie()d to disk storage (like DB_File, etc.). There are many similar examples for filehandles, arrays and even scalars. Those are cases when Object::Hybrid combined with simple coding style can make code that handles those primitives compatible across whole spectrum, from plain primitives to all types of extended tied() primitives. There are also other uses, including working around gaps in tiehandle implementation, adding some fancy operations to primitives without using tie() as well as plain syntactic sugar.

In the context of this module hybrid object is defined as a Perl object that represents its own bless()ed primitive (i.e. the primitive it is implemented with, currently hash, scalar, array, or filehandle). According to this definition, hybrid object can be seen as both primitive and object at the same time. In general case, it is a violation of object encapsulation to access object's underlying bless()ed primitive directly (at least outside of class's methods), but in special case of hybrid objects it is perfectly ok to do so - no violation of encapsulation takes place. 

Hybrid objects are instances of the class that is referred to as "hybrid class". This module implements default hybrid classes and exports promote() function that bless()es Perl's primitives (hash, scalar, array, or filehandle) into either default or user-specified (custom) hybrid classes to make them hybrid objects.

Promoting primitive to become hybrid (i.e. bless()ing it into hybrid class) simply adds object interface to primitive and is a way to extend Perl primitives that is compatible with and complementary to another major way of extending primitives - perltie API. 

Specifically, benefits of promote()ing primitives are:

=over

=item Compatibility

Hybrid object has corresponding perltie methods interface for accessing underlying bless()ed primitive that object is implemented with (e.g. tiehash methods for accessing underlying bless()ed hash, etc.). Moreover, for hybrid object the following, for example, are equivalent and interchangeable for B<both tied() and not tied()> primitives:

	$hybrid->{foo};
	$hybrid->FETCH('foo'); # same 
	$hybrid->fetch('foo'); # same 

Promoting primitives to become hybrids allows the same simple portable, non-specific code to manipulate (be compatible with) anything ranging from plain primitives to highly extended tie()d primitives as it unifies their interfaces and make them interchangeable.

For example, if same code is required to accept and handle both plain hashes, i.e. fast, in-memory hashes, and tie()d hashes with extended perltie interface, e.g. slow persistent hashes tie()d to disk storage, then it is useful to promote() each of those hashes to become hybrid. Whenever plain access is required the following code:

	$hybrid->{foo};

will work for both in-memory and persistent hashes, and is really fast in case of in-memory hash. And in case you need to use extended interface, something like next code will also work for promote()d both in-memory and persistent hashes:

	$hybrid->FETCH('foo', @args); 

	$hybrid->can('custom_method') 
	and  $hybrid->custom_method();

For performance comparison of various interface options see L</"Performance"> section.

Despite promoting primitives to become hybrids turn them into Perl objects, compatibility with arbitrary Perl objects in practice has little value, since code that manipulates objects usually assume objects to be of very specific class. 

=item tied()less access

Accessing tied() interface of tie()d primitive no longer requires cumbersome (possibly conditional) tied() call, i.e. instead of:

	tied(%$hybrid)->method();

one can write:

	$hybrid->method();       # same
	$hybrid->fast->method(); # same, but may be faster 

For performance comparison of various interface options see L</"Performance"> and L</"fast()"> sections.

=item Incomplete tie() implementation workaround

Currently tie()ing filehandles is still incomplete in Perl: sysopen(), truncate(), flock(), fcntl(), stat() and -X cannot currently be trapped. However, both tieclasses and hybrid classes can define corresponding methods or use self() method  (see L</"Properties of hybrid objects">) to not distinguish between primitives for that matter:

	promote $FH;

	$FH->stat(); 
	$FH->ftest('-X'); 

	# same in indirect method notation:
	STAT  $FH;
	FTEST $FH '-X';

	# or sometimes self() method can be used for that end too:
	stat $FH->self;
	-X   $FH->self;

=item Operator overloading

Custom hybrid classes can be used for overloading operators on primitives. However, unfortunately such hybrid classes currently can only be used to promote() non-tied() primitives (see L</"Operator overloading">). 

=back

Object::Hybrid is a lightweight pure Perl module with no dependencies beyond core.

=head1 Stop reading now (or how to use this documentation)

Usually, there is no need to read any of the following documentation to use Object::Hybrid - you can stop reading at this point. What you have read so far, or even just self-explanatory SYNOPSIS, is enough in most cases. The following documentation covers optional features that need not to be learned for using Object::Hybrid in most usual case (e.g. occasionally).

=head1 C<use Object::Hybrid>

	use Object::Hybrid;           # exports nothing
	use Object::Hybrid  $feature;  # enables single named feature
	use Object::Hybrid \@feature;  # enables array of named features
	use Object::Hybrid \%options;  # most general form
	use Object::Hybrid  %options;  # most general form

The following features are supported:

	use Object::Hybrid             'promote';
	use Object::Hybrid feature =>  'promote';  # same
	use Object::Hybrid feature => ['promote']; # same
	use Object::Hybrid export  =>  'promote';  # same
	use Object::Hybrid export  => ['promote']; # same

which exports (i.e. declares for use) the promote() function into caller's namespace.

Next features depend on autobox pragma being installed (can be installed from CPAN archive):

	use Object::Hybrid             'autobox';
	use Object::Hybrid feature =>  'autobox';            # same
	use Object::Hybrid feature => ['autobox'];           # same
	use Object::Hybrid autobox => Object::Hybrid->CLASS; # same, but can be custom hybrid class

which will automatically promote() any primitive within the current scope, and "unpromote" them back beyond that scope. It is is equivalent to:

	use Object::Hybrid;
	use autobox 
	HASH   => Object::Hybrid->HASH_STATIC,
	SCALAR => Object::Hybrid->SCALAR_STATIC,
	ARRAY  => Object::Hybrid->ARRAY_STATIC;

And closely related is:

	use Object::Hybrid                 'autopromote';
	use Object::Hybrid feature     =>  'autopromote';         # same
	use Object::Hybrid feature     => ['autopromote'];        # same
	use Object::Hybrid autopromote =>  Object::Hybrid->CLASS; # same, but can be custom hybrid class

which makes any method call on non-blessed primitive in the lexical scope to automatically promote() that primitive.

=head1 promote() function

	promote $primitive;                   # bless() $primitive to make it hybrid object
	promote $primitive => \%args;         # same, but with named arguments
	promote $primitive =>  %args;         # same
	promote $primitive => $class;         # same, but with explicit $class to tie() to or bless() into
	promote $primitive => $class, \%args; # same, but with named arguments
	promote $primitive => $class,  %args; # same

The function promote() is an exportable constructor of hybrid objects.

In case $primitive is tied(), the tied() object is used as object interface of the hybrid (see L</"Delegation to tied() object">), unless custom hybrid $class is specified (see L</"Custom hybrid $class">).

In any case, promote() never (re)tie()s primitive, only bless()es it.

Exception is raised if $primitive specified is of type not currently supported by Object::Hybrid, no or not defined $primitive is specified.

The return value is $primitive itself bless()ed to become a hybrid object (return value may be useful if promote() is used in expressions).

The class that $primitive is bless()ed into is generated based on the type of primitive, whether it is tied(), custom $class and "mutable" option, if any are specified. User should not assume anything about resulting ref($primitive) class, except: 

	Object::Hybrid->Class->is(ref($primitive));
	ref($primitive)->isa($class); # in case $class was specified

If promote() is called on a hybrid object, it gets re-bless()ed according to arguments provided. This may be useful for performance optimization in some cases, since performance depends on the way primitive is promote()d.

If promote() is called on non-hybrid object, the exception is raised, except when rebless => 1 option is provided. Later essentially is a "doorway" for converting objects into hybrids in rare case it may be needed (almost always a bad idea). (One such likely case is promote()ing some hybrid object incompatible with Object::Hybrid, e.g. IO::Object, using its class as custom hybrid class.)

The "tieable" boolean option specifies whether untied primitive can be tie()d after promote(). If primitive gets tie()d, its object interface immediately changes accordingly. However, for (much) better performance it is recommended to re-promote() such hybrid after tie()ing it instead of using tieable => 1 option (unless promote() cost is an issue).

The "mutable" boolean option commands whether the tied or tieable (tieable => 1) hybrid can be untie()d or re-tie()d after it has been tied. If tieable hybrid gets tie()d or untie()d, its object interface immediately changes accordingly. However, for (much) better performance it is recommended to re-promote() such hybrid after untie()ing or re-tie()ing it instead of using tieable => 1 option (unless promote() cost is an issue).

The "caller" boolean option commands whether the method calls on tied or tieable (tieable => 1) hybrid preserve caller(). This may need to be enabled in rare case that methods of unaware tied class (may) rely on caller(). By default, for hybrids that neither "mutable" (caller may not be preserved) nor "caller" (caller is always preserved) were set true upon promote(), the global $Object::Hybrid::CALLER = 1 can be used to preserve caller. In later case local($Object::Hybrid::CALLER) allows to exercise fine-granularity control over whether caller() is preserved for specific methods:

	{
		local $Object::Hybrid::CALLER = 1;
		$hybrid->foo();
	}

Note that use of either "mutable", "tieable" (in case of non-tied primitives), "caller" options or any combination of them may (some combinations - significantly) reduce performance of hybrid object interface.

The tie => $value option can be used to initialize tied() attribute of the hybrid object - see tied() attribute.

=head2 Custom hybrid $class

If custom hybrid $class is specified, then $primitive is bless()ed into hybrid class that inherits from $class. 

If and only if $class overrides methods of the hybrid object, then L<properties of hybrid objects|/"Properties of hybrid objects"> become requirements for $class to comply with. Otherwise there are no requirements for the class, except it should make sense to use it as hybrid class, i.e. according to L<hybrid object definition|/DESCRIPTION> class should represent its bless()ed primitive (e.g. IO::Handle and subclasses may well be used as custom hybrid classes). In particular, calling promote() with the $class name of the empty class is equivalent to calling promote() without specifying custom $class, i.e. it will work. For lengthy discussion of hybrid class requirements refer to L<Object::Hybrid::Class>.

If custom $class is type-specific for given $primitive, the type-conditional expression for $class may need to be used by caller.

The alternative to using custom hybrid class is subclassing Object::Hybrid. Usually this way allows much more efficient implementations of hybrids, but it is more involved as as well.

=head1 Properties of hybrid objects

The following are the properties of hybrid objects:

=head2 Equivalent perltie API

Hybrid object exposes perltie interface (perltie methods) for its underlying bless()ed primitive B<and> that interface is equivalent to directly accessing underlying primitive - B<both> tie()d and not tie()d. This interface equivalence is what makes, say, next two lines to have exactly same effect for hash hybrids:

	$hybrid->{foo};
	$hybrid->FETCH('foo'); # same

For performance comparison of various interface options see L</"Performance"> section.

=head2 Complete perltie API

Currently tie()ing filehandles is still incomplete in Perl: sysopen(), truncate(), flock(), fcntl(), stat() and -X can't currently be trapped. However, hybrid object provides equivalent samename methods and their uppercase aliases (SYSOPEN(), TRUNCATE(), FLOCK(), FCNTL(), STAT() and FTEST()) to fill the gap and also allow compatibility with tiehandle classes that also implement them. This allows to write portable code that works around gaps in tiehandle implementation by B<always> using methods on hybrids filehandles instead of Perl built-in functions, for example:

	promote $FH;

	$FH->stat(); 
	$FH->ftest('-X'); 

	# same with indirect method calls...
	STAT  $FH;
	FTEST $FH  '-X';

Thus, to avoid problems with gaps in tiehandle implementation simply always call samename methods on hybrids instead of corresponding built-in functions.

=head2 Delegation to tied() object

In case of tied() primitives, hybrid object tries to delegate all method calls to tied() object. Delegation invokes called method on tied() object instead of hybrid. This allows invoking perltie methods B<with parameters> on hybrid directly (instead of on tied() object):

	$hybrid->STORE($value, @args);

Delegation exposes entire interface of tied() object as hybrid object interface. Caller may use $hybrid->can('foo') to determine whether tied() object (if any) or hybrid implement certain methods.

If tied() object provides no called method, delegation fails and then hybrid object falls back to calling its own samename method (called "fallback method") on hybrid itself. Fallback methods are simply same methods that would be called if hybrid is not tied(). This means methods of the non-tied() hybrid remain available if hybrid is tied(), unless tied() object exposes its own samename methods. 

In other words, tie()d hybrid may expose methods that tied() object do not provide. For example, since stat() is not a perltie method currently, it is unlikely to be implemented by tiehandle class, but it is provided by hybrid object to have portable C<< promote($tied_fh)->stat() >> workarounds for currently broken C<stat($tied_fh)>.

Note that delegation for standard perltie methods almost always works (no fallback), because normally tieclass does implement perltie methods.

=head2 Method aliases

The promote()ing of primitive to become hybrid object provides altered-case aliases for all its methods (including lowercase aliases for all perltie methods).

This feature is especially relevant in case when there are samename built-in functions for accessing primitives: shift(), exists(), seek(), etc. In this case and as general coding style for hybrids: the lower case should be used as functions or in direct method calls notation, while upper case can be used for indirect method call notation (later minimizes chances of indirect method notation colliding with non-parenthesized same name function calls with single scalar argument, like C<foo $FH>). For example:

	seek $FH, 0, 0;         #        function call (coma after $FH, no extra arguments)
	SEEK $FH  0, 0, @args;  # indirect method call (no coma after $FH, @args extended interface)
	$FH->seek(0, 0, @args); #   direct method call (@args extended interface)

In case of tie()d hybrid it is more efficient to call method that is defined by underlying tied() class, for example, FETCH() is likely to be faster than fetch() for tie()d primitives (as their tied() classes usually define no fetch(), just FETCH()). In all other cases aliases are equally efficient.

Setting C<local $Object::Hybrid::Portable = 1> (local()ized to some scope) changes behavior of aliases making them non-equivalent. Calls of lower-case aliases now do not fail (are "fail-safe") due to method being not defined by either hybrid class or underlying tied() class (if any), becoming no-op and returning empty list or undef scalar. This allows to write portable code that calls non-standard methods on tied() hybrids without (ab)using can() calls or eval{} wraps, which otherwise would make code cumbersome (e.g. in case of eval{} it is necessary to manually distinguish "can't find method" from errors in defined method, etc.). But it is of course risky too, as typos will not blow up, leading to silent error propagation, so that $Object::Hybrid::Portable = 1 is an optional feature that should be used with care, after first testing code without it.

In contrast, upper-case aliases are not similarly fail-safe under C<local $Object::Hybrid::Portable = 1>, calling them is a fatal error if method, both lower-case and upper-case, is not defined, so that they can be used to ensure method is really called (mnemonics: insist on it being called by writing it in upper case). If, however, lower-case method is defined, the upper-case call will call it, not fail. For example:

	{
		local $Object::Hybrid::Portable = 1;

		$hybrid->non_existing_method();   # will not fail due to "can't find method"
		$hybrid->NON_EXISTING_METHOD();   # fatal "can't find method" error

		$hybrid->maybe_existing_method(); # will not fail due to "can't find method"
		$hybrid->MAYBE_EXISTING_METHOD(); # may be a fatal "can't find method" error

		$filehandle_hybrid->fetch();      # will not fail due to "can't find method"
		$filehandle_hybrid->FETCH();      # likely fatal "can't find method" error (since filehandles normally have no FETCH()), but will call fetch() (not fail) if fetch() happens to be defined
	}

=head2 call()

	$hybrid->call(method => @args); 

is the short form of:

	{
		local $Object::Hybrid::Portable = 1;
		$hybrid->method(@args);
	}

Except in case of call() &$method sees real caller one level deeper in the stack (which may be unexpected by methods that use caller()) and character case of method()'s name is irrelevant.

=head2 fast()

The fast() efficiently returns tied() object for tie()d invocant, and invocant itself for non-tied. The fast() method is used for "manual" delegation to tied() object as a way of performance optimization:

	$hybrid->fast->FETCH('a'); # for tied() $hybrid is much faster than...
	$hybrid->FETCH('a');

	$hybrid->fast->can('foo'); # for tied() $hybrid is much faster than...
	$hybrid->can('foo');

For non-tied hybrids, however, situation is reversed, but in absolute terms using fast() often pays off, especially where tied hybrids are more common throughput. The trade-off however is that $hybrid->fast->FETCH() syntax provides no method aliases, no fail-safety for non-defined methods in case of true $Object::Hybrid::Portable, and raises exception instead of falling back to calling samename hybrid's method in case tied() class defines no called method, so that using it is more risky and requires better knowledge of tied() classes involved.

=head2 self() method

The self() method returns underlying primitive: either bless()ed primitive of the hybrid object (i.e. hybrid object itself) or, if possible, real underlying primitive that is used by tied() object/class. 

Many tied() objects (like Tie::ExtraHash) transparently delegate operations on tie()d primitive to real primitive encapsulated somewhere inside that tied() object, using that object just to store some additional state. If this is the case, tied() class may define self() as accessor for that underlying primitive to directly expose it to methods of the hybrid class and to users. The self() method allows to access that real primitive directly, falling back to hybrid's bless() primitive, if it is not possible or tied() class do not provide self() method. As a result, methods of custom hybrid class can have access to both tie()d bless()ed primitive (slow) and underlying real primitive (fast). 

The tied() class must not define self() if this may result in violation of encapsulation, i.e. if delegation to underlying real primitive is not transparent enough. Example of transparent tieclass that may define self() is Tie::ExtraHash. On the other hand some tieclasses, like Tie::StdHash, are so transparent that need not to define self() at all as default one is good for them.

The self() method can have a number of useful applications, in particular to work around gaps in tiehandle implementation and to increase performance, as it allows hybrid methods to quickly bypass perltie layer and operate on underlying primitive directly, which may bring significant efficiency benefits, especially for some bulk operations.

For example, since there is no yet perltie support for stat(), -X tests called on tiehandle do not propagate to underlying real filehandle, so they should be somehow propagated manually, but it requires knowing how to get underlying filehandle, if there is any, out of tied() object. Defining self() method in tieclass is supposed to do just that, and hybrid classes are expected to define self() method as well, so that portable code (assuming tied() classes define self()) can simply be:

	promote $FH;

	stat $FH->self;
	-X   $FH->self;

	# or nearly same using methods (default implementations of these methods also use self() under the hood):
	STAT  $FH;
	FTEST $FH '-X';
	$FH->stat(); 
	$FH->ftest('-X'); 

If tieclass defines self(), the sysopen(), truncate(), flock(), fcntl(), stat() and ftest() methods of corresponding tie()d hybrid object will operate correctly without tieclass implementing them.

The Hybrid::Object makes use of self() only if it is defined by tieclass of tie()d primitive, so that hybrids do not depend on tieclass implementing self() method.

=head2 tied() method

Returns what built-in tied() would return called on hybrid. The only difference is that it is a method and reference type of the hybrid need not to be known.

=head2 Optional bless() method

If custom hybrid class defines bless() method, the C<< $hybrid_class->bless($primitive) >> is called instead of otherwise calling C<bless($primitive, $hybrid_class)>. The bless() method is optional. It can be used as constructor/initializer for hybrid object, except it is to reuse $primitive (same as built-in bless()) instead of creating new.

=head2 C<< Object::Hybrid->Class >>

Hybrid objects can be recognized with the following test:

	Object::Hybrid->Class->is($hybrid);

=head1 new() method

	$hybrid = new Object::Hybrid $primitive;                   # bless() to make $primitive a hybrid
	$hybrid = new Object::Hybrid $primitive => \%args;         # same, but with named arguments
	$hybrid = new Object::Hybrid $primitive =>  %args;         # same
	$hybrid = new Object::Hybrid $primitive => $class;         # same, but with explicit $class to tie() to or bless() into
	$hybrid = new Object::Hybrid $primitive => $class, \%args; # same, but with named arguments
	$hybrid = new Object::Hybrid $primitive => $class,  %args; # same

Or corresponding direct method call notation for any of the above can be used, for example:

	$hybrid = Object::Hybrid->new($primitive); # etc.

The new() constructor promote()s $primitive to hybrid and returns it. It is roughly equivalent to:

	sub new { shift; return promote(@_) }

Refer to promote() documentation.

Note that new() do not construct object of Object::Hybrid class, even not $hybrid->isa('Object::Hybrid'), so beware.

=head1 tie() method

	$tied = Object::Hybrid->tie( $primitive, $tieclass, @args); # for %$primitive same as...
	$tied =                 tie(%$primitive, $tieclass, @args); # ... except $primitive also gets promote()d to hybrid

=head1 Class() method

Object::Hybrid relies on Class::Tag to store and query inheritable meta-data of hybrid classes, and uses Object::Hybrid::Class as tagger class in Class::Tag's terms. The Class() method always returns the name of that tagger class. This is primarily for convenience of using it in expressions. Refer to L<Object::Hybrid::Class> for currently supported tags and their semantics.

	package Foo; 
	use Object::Hybrid::Class; # tags Foo as standalone hybrid class

	Object::Hybrid->Class  eq 'Object::Hybrid::Class'; # true
	Object::Hybrid->Class->is('Foo');                  # true
	Object::Hybrid->Class->is('Bar');                  # false

=head1 is() method

The is () is  an equivalent of Object::Hybrid->Class->is():

	promote                       $hybrid;
	Object::Hybrid->is(           $hybrid); # true
	Object::Hybrid->Class->is(    $hybrid); # same
	Object::Hybrid->is(       $not_hybrid); # false
	Object::Hybrid->Class->is($not_hybrid); # same

=head1 ref_*() methods

These are utility methods useful to sort things out. Generally, all ref_foo() (ref_*()) methods return boolean that tells whether its argument is reference or not, but exact boolean value depends of the value of 'foo' suffix:

=head2 ref_type() method

	Object::Hybrid->ref_type({})              eq 'HASH'; # true
	Object::Hybrid->ref_type(bless {}, 'Foo') eq 'HASH'; # true

and so on...

=head2 ref_isa() method

	$obj = bless {}, 'Foo';
	Object::Hybrid->ref_isa($obj);                # true
	Object::Hybrid->ref_isa($obj)        eq $obj; # true
	Object::Hybrid->ref_isa($obj, 'Foo') eq $obj; # true
	Object::Hybrid->ref_isa($obj, 'Bar');         # false
	Object::Hybrid->ref_isa({});                  # false

and so on...

This method is useful to try some unknown $thing at hands that it is too uncertain to call $thing->isa('Foo') on it. It returns true, more specifically passes through its argument (for use in expressions and chained calls) if reference is blessed and, if second argument defined, isa() of second argument type (exact type can be obtained with ref(ref_isa($var)) instead). Otherwise returns false. More specifically, returns 0 for blessed references, '' for non-blessed references and undef for non-references.

=head2 ref_tied() method

	$tied =             tie %$primitive, 'Foo';
	Object::Hybrid->ref_tied($primitive) eq $tied; # true
	Object::Hybrid->ref_tied({})         eq '0';   # true
	Object::Hybrid->ref_tied(sub{})      eq '';    # true, since sub{} is not tie()able
	Object::Hybrid->ref_tied('string')   eq '';    # true, since 'string' is not tie()able

and so on.

=head1 Perltie classes

Hybrid objects are out of the box compatible with any valid tieclass.

However, to support workarounds for "gaps" in perltie implementation, tieclasses may need to meet additional requirements - those are some of requirements that hybrid classes already comply with, intended specifically to work around perltie implementation gaps, namely: L</"Complete perltie API"> and L</"self() method">. Currently tie()ing filehandles is still incomplete in Perl, so these requirements mainly apply to tiehandle classes. The most simple tiehandle classes, like Tie::StdHandle (loaded by "use Tie::Handle"), already comply with this requirements, as for them default self() and other methods provided by default hybrid class are good enough. A bit more complex tiehandle classes need just to implement self() method. If defining self() is not possible in case of more complex tiehandle classes, additional SYSOPEN(), TRUNCATE(), FLOCK(), FCNTL(), STAT() and FTEST() methods may need to be implemented as workarounds by tiehandle class.

Since tie() do not pass primitive to be tie()d to TIE*() constructor, TIE*() cannot be made to optionally promote() that primitive. Instead, tieclass can expose promote() as one of its methods allowing user to promote primitives or expose Object::Hybrid->tie() method analog for built-in tie() that both tie()s and promote() given primitive. This, however, should probably not be dove via subclassing.

=head1 Operator overloading

Custom hybrid classes can be used for overloading operators on promote()d primitives. However, unfortunately hybrid classes with overloaded operators currently can only be used to promote() non-tied() primitives. This is because currently overload pragma is broken - bless()ing tie()d primitive into such class will implicitly untie() it. Should this be fixed in the future, operator overloading can be used without this limitation.

However, even used on non-tied() primitives operator overloading is very powerful and can have some interesting (and possibly even useful) applications. In particular, overloading of dereference operators allows to achieve effects somewhat similar to using tie(), like "back-door" state similar to that of tied() objects. It is even possible to have "hybrid primitive" that is simultaneously hash, scalar, array, subroutine and glob (however such hybrid class may violate equivalence requirement as FETCH(0) need to be equivalent to $hybrid->{0} and $hybrid->[0] at the same time). 

=head1 Performance

The performance preferences for hash hybrids are (in order from fastest to slowest, all figures are quoted for CPU-constrained virtual server, so only their comparison with each other matters):

	      $non_blessed->{foo}                # ~ 1_700_000/s
	   $nontied_hybrid->{foo};               # ~ 1_700_000/s
	   $nontied_hybrid->FETCH('foo');        # ~   300_000/s
	tied(%$tied_hybrid)->FETCH('foo');       # ~   230_000/s
	   $nontied_hybrid->fast->FETCH('foo');  # ~   200_000/s (slower despite fast())
	      $tied_hybrid->fast->FETCH('foo');  # ~   150_000/s
	      $tied_hybrid->FETCH('foo');        # ~    80_000/s
	      $tied_hybrid->{foo};               # ~    60_000/s

For comparison, the promote() performance (all including DESTROY() cost):

	bless   $primitive => $hybrid_class      # ~    80_000/s (this is fast analog of promote())
	promote($primitive)                      # ~    35_000/s
	promote($primitive => $class)            # ~    21_000/s

These results are produced by bench/benchmark_hash.pl script available in the Object::Hybrid distribution, and assume default hybrid classes. Figures for promote($primitive => $class) realistically assume same $class value is used in benchmarked calls (otherwise it will be significantly slower), and also include DESTROY() costs. For fast promote()ing of same type of primitives, simply bless() to proper hybrid class:

	my $hybrid_class = ref promote({});
	bless {}, $hybrid_class foreach (1..1000000);

Above results suggests that tied()-conditional access switching expression is (currently) the fastest solution that is to be used in hot paths (tight loops, etc.) and it requires no promote()ing:

	tied(%$primitive) ? 
	tied(%$primitive)->FETCH('foo')          #   ~230_000/s 
	:     $primitive->{foo};                 # ~1_700_000/s 

However, using this construct repeatedly may be too cumbersome, so out of hot paths (tight loops, etc.) promote()ing to hybrid can be used to simplify code while retaining and enhancing its portability across various tie()d and non-tie()d primitives.

For hybrid interfaces performance varies widely depending on whether it is a tied or non-tied respectively:

	$hybrid->{foo};               # ~  60_000 - 1_700_000/s
	$hybrid->FETCH('foo');        # ~  80_000 -   300_000/s
	$hybrid->fast->FETCH('foo');  # ~ 150_000 -   200_000/s

Consequently, use of any of these should be decided based on the projected use mix of tied vs. non-tied primitives.

=head1 TODO

Currently tests cover only tiehashes and tiehandles, there should be tests for other types as well.

As soon as (and if) Object::Hybrid interface stabilizes enough, its version is to jump to 1.0.

=head1 SEE ALSO

The C<use autobox> pragma is another way of doing somewhat similar, but not the same things, so autobox and Object::Hybrid are not mutually substitutive. However, if C<autobox> pragma is installed, then either "autobox" or "autopromote" feature can be enabled  - see L</"use Object::Hybrid">.

Objects of standard IO::Handle class and its subclasses (such as IO::File or IO::Socket) are hybrid objects according to general hybrid object definition used by Object::Hybrid, but they are incompatible with promote()d hybrids. However, it should be possible to promote() IO::Handle object to become compatible hybrid. 

=head1 SUPPORT

Send bug reports, patches, ideas, suggestions, feature requests or any module-related information to L<mailto:parsels@mail.ru>. They are welcome and each carefully considered.

In particular, if you find certain portions of this documentation either unclear, complicated or incomplete, please let me know, so that I can try to make it better. 

If you have examples of a neat usage of Object::Hybrid, drop a line too.

=head1 AUTHOR

Alexandr Kononoff (L<mailto:parsels@mail.ru>)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Alexandr Kononoff (L<mailto:parsels@mail.ru>). All rights reserved.

This program is free software; you can use, redistribute and/or modify it either under the same terms as Perl itself or, at your discretion, under following Simplified (2-clause) BSD License terms:

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

no warnings;  

use Scalar::Util qw(reftype refaddr weaken blessed);

use Object::Hybrid::Class (); # Object::Hybrid itself is not a hybrid class

sub HASH_UNTIED           () { 'Object::Hybrid::HASH'  }
sub HASH_STATIC           () { 'Object::Hybrid::HASH_STATIC' }
sub HASH_STATIC_CALLER    () { 'Object::Hybrid::HASH_STATIC_CALLER' }
sub HASH_MUTABLE          () { 'Object::Hybrid::HASH_MUTABLE'        }
sub HASH_MUTABLE_CALLER   () { 'Object::Hybrid::HASH_MUTABLE_CALLER' }

sub SCALAR_UNTIED         () { 'Object::Hybrid::SCALAR'  }
sub SCALAR_STATIC         () { 'Object::Hybrid::SCALAR_STATIC' }
sub SCALAR_STATIC_CALLER  () { 'Object::Hybrid::SCALAR_STATIC_CALLER' }
sub SCALAR_MUTABLE        () { 'Object::Hybrid::SCALAR_MUTABLE'        }
sub SCALAR_MUTABLE_CALLER () { 'Object::Hybrid::SCALAR_MUTABLE_CALLER' }

sub ARRAY_UNTIED          () { 'Object::Hybrid::ARRAY'   }
sub ARRAY_STATIC          () { 'Object::Hybrid::ARRAY_STATIC' }
sub ARRAY_STATIC_CALLER   () { 'Object::Hybrid::ARRAY_STATIC_CALLER' }
sub ARRAY_MUTABLE         () { 'Object::Hybrid::ARRAY_MUTABLE'        }
sub ARRAY_MUTABLE_CALLER  () { 'Object::Hybrid::ARRAY_MUTABLE_CALLER' }

sub GLOB_UNTIED           () { 'Object::Hybrid::GLOB'    }
sub GLOB_STATIC           () { 'Object::Hybrid::GLOB_STATIC' }
sub GLOB_STATIC_CALLER    () { 'Object::Hybrid::GLOB_STATIC_CALLER' }
sub GLOB_MUTABLE          () { 'Object::Hybrid::GLOB_MUTABLE'        }
sub GLOB_MUTABLE_CALLER   () { 'Object::Hybrid::GLOB_MUTABLE_CALLER' }

sub CLASS_AUTOPROMO       () { 'Object::Hybrid::AUTOPROMOTE' }
sub FRONTAL               () { 'FRONTAL' }
sub Class                 () { 'Object::Hybrid::Class' }
sub CLASS_DEFAULT         () { undef }

sub frontclass_name { 
	my (undef,       $class,     $primitive) = @_;
	return join '_', $class, ref $primitive ? reftype($primitive) : $primitive||(), FRONTAL
}

my %class4type = (
	HASH   => HASH_STATIC,
	ARRAY  => ARRAY_STATIC,
	SCALAR => SCALAR_STATIC,
	GLOB   => GLOB_STATIC,
);

my %untied_class4type = (
	HASH   => HASH_UNTIED,
	ARRAY  => ARRAY_UNTIED,
	SCALAR => SCALAR_UNTIED,
	GLOB   => GLOB_UNTIED,
);

sub class4type {
	my     $self = shift;
	my            $accessor = $self->name4type(@_);
	return $self->$accessor||()
}

sub name4type { # the only required parameter is 'reftype' - can be ref() or reference of corresponding type
	my ($self,  $type);
	   ($self, %$type) = @_;

	push my @accessor
	, ref     $type->{reftype} 
	? reftype $type->{reftype} 
	:         $type->{reftype}
	if        $type->{reftype}
	or     croak("No 'reftype' parameter specified");

	if (!$type->{tieable}) { 
		push @accessor, 'UNTIED';
	}
	else { 
		push @accessor, $type->{mutable} ? 'MUTABLE' : 'STATIC';
		push @accessor,        'CALLER' 
		if              $type->{caller};
	}

	my $accessor = join '_', @accessor;

	return $accessor
}

__PACKAGE__->import(qw(promote));
sub import {
	my $self = shift;

	# interface...
	my $opt 
	=     @_ > 1           ?              {@_} 
	:    !@_               ?              {  } 
	: ref $_[0] eq 'HASH'  ?               $_[0] 
	: ref $_[0] eq 'ARRAY' ? { feature => [$_[0]] } 
	:                        { feature => [$_[0]] };

	# normalize %$opt...
	foreach my $list (qw(feature export autopromote)) { 
		next 
		if !exists $opt->{$list};
		ref        $opt->{$list} eq 'ARRAY' 
		or         $opt->{$list} 
		=         [$opt->{$list}];
	}

	my @goto;

	# process features first...
	foreach my $feature (ref $opt->{feature} eq 'ARRAY' ? @{$opt->{feature}} : $opt->{feature}) {
		if ($feature eq 'promote') { push @{$opt->{export}}, $feature }

		# mutually exclusive features...
		if ($feature eq 'autobox') {
			#load_type($self->CLASS);
			$self->load_type('HASH_STATIC');
			$self->load_type('SCALAR_STATIC');
			$self->load_type('ARRAY_STATIC');

			require 
			autobox;
			autobox::import( ref($self)||$self, 
			HASH   =>  $opt->{$feature}||$self->HASH_STATIC, # method instead of constant, for subclassing...
			SCALAR =>  $opt->{$feature}||$self->SCALAR_STATIC,
			#GLOB  =>  $opt->{$feature}||$self->GLOB_STATIC, # not supported by autobox
			ARRAY  =>  $opt->{$feature}||$self->ARRAY_STATIC, );
		}
		elsif ($feature eq 'autopromote') {
			require 
			autobox;
			autobox::import( ref($self)||$self, 
			HASH           => CLASS_AUTOPROMO,
			SCALAR         => CLASS_AUTOPROMO,
			#GLOB          => CLASS_AUTOPROMO, # not supported by autobox
			ARRAY          => CLASS_AUTOPROMO, );
			my $autoload 
			=      __PACKAGE__ . '::AUTOLOAD'; 
			*{ CLASS_AUTOPROMO . '::AUTOLOAD' } = sub{ 
				$self->new($_[0], @{$opt->{$feature}}||()); 
				$$autoload =~ s/^.*:://;
				goto &{ $_[0]->can($$autoload) 
				or croak(_cant_locate_object_method($_[0], $$autoload)) };
			};
		}
		elsif ($feature eq  'SAFE') { $opt->{$feature} = 1; }
	}

	# process options...
	if ($opt->{export}) {
		my @symbols;
		foreach my $symbol (@{$opt->{export}||[]}) {
			if (   $symbol eq 'promote' ) { 
				my $promote = $self->can(qw(new));
				*{join '::', scalar caller, $symbol} 
				#= sub{ unshift @_, $self; goto &$promote };
				=  sub{ $self->$promote(@_) };
			}
			else { push @symbols, $symbol }
		}

		if (@symbols 
		or  @{(ref($self)||$self).'::EXPORT'}
		or  @{        __PACKAGE__.'::EXPORT'}) {
			require 
			Exporter;
			Exporter::export_to_level(1, $self,       @symbols) or 
			Exporter::export_to_level(1, __PACKAGE__, @symbols); # "inheritance" of export, subclasses can define their own @EXPORTs,
		}
	}

	if (@goto) {
		@_ = @goto;
		goto &{shift(@_)};
	}
}

sub is { Object::Hybrid::Class->is($_[1]) }

my %PromoclassCache; 
my %PromoclassCache2; 
my %PromoclassCache3; 
my %HybridClass;
my %DefaultClass;

*promote = \&new; # method, not function
sub new { 
	my $primitive_is_tied = (
	my $primitive_tied    = _ref_tied($_[1]) ) ? 1 : 0;

	{ return          bless $_[1]
	, $PromoclassCache2{ref $_[1]}->[$primitive_is_tied]||next 
	if @_ == 2; } # fast shortcircuit

	@_>1 or croak("Error: Nothing to promote");

	my $self      = shift;
	my $primitive = $_[0]; 

	my                      ($class,  $args);
	( undef 
	, ref $_[1] eq 'HASH' ? (         $args) 
	: ref $_[2] eq 'HASH' ? ($class,  $args) 
	:     @_ %  2         ?          %$args 
	:                       ($class, %$args) ) = @_;

	$class ||= ($DefaultClass{ref($self)||$self} ||= $self->CLASS_DEFAULT);

	{ return          bless $primitive
	, $PromoclassCache3{ref $primitive}->{$class}[$primitive_is_tied]||next 
	if !%$args; } # slower shortcircuit 

	my   $hybrid_is_tieable = $args->{tieable}||$primitive_is_tied ? 1 : 0;
	my   $hybrid_is_mutable = $args->{mutable}                     ? 1 : 0;
	my   $hybrid_is_caller  = $args->{caller}                      ? 1 : 0;
	my   $no_opt = 1 
	if  !$hybrid_is_tieable 
	and !$hybrid_is_mutable 
	and !$hybrid_is_caller; 

	{ return         bless $primitive
	, $PromoclassCache{ref $primitive}->{$class}[$hybrid_is_tieable][
	                                                 $hybrid_is_mutable][
	                                                 $hybrid_is_caller ]||next } # slower shortcircuit 

	ref      $primitive  or croak("Can't promote() non-reference value $primitive");
	!blessed($primitive) or $args->{rebless}
	or                          $HybridClass{ref     $primitive } 
	and delete $Object::Hybrid::Cache4object{refaddr($primitive)}, 1
	or croak("Can't promote() object $primitive");

	my $primitive_ref     = ref     $primitive; 
	my $primitive_reftype = reftype($primitive);

	$class4type{$primitive_reftype}
	or croak("Error: promote()ing $primitive_reftype primitive is not supported");

	my $frontclass;
	my $typename = $self->name4type(
		reftype => $primitive_reftype, 
		tieable => $hybrid_is_tieable, 
		mutable => $hybrid_is_mutable, 
		caller  => $hybrid_is_caller, 
	);
	my $typeclass = $self->$typename;
	if ($class) {
		unless ( $self->Class->is($class) ) { # use $class as subclass...
			   $frontclass = $self->frontclass_name($class, $primitive_reftype);
			@{ $frontclass . '::ISA' } or 
			@{ $frontclass . '::ISA' } = ( $class, $typeclass||() );
		}
	} else {   $frontclass = $typeclass; }

	# custom hybrid class may subclass $typeclass or subclass of Object::Hybrid may override $typename() methods, so call load_type() anyway
	$self->load_type($typename); 

	my 
	$bless = $frontclass->can('bless');
	$bless ? $frontclass->$bless($primitive)
	:                      bless $primitive, $frontclass; 

	$HybridClass{ ref $primitive}                                   = ref $primitive;
	$PromoclassCache2{$primitive_ref}->[        $primitive_is_tied] = ref $primitive if $no_opt and $class eq '';
	$PromoclassCache3{$primitive_ref}->{$class}[$primitive_is_tied] = ref $primitive if $no_opt; 
	$PromoclassCache{ $primitive_ref}->{$class}[$hybrid_is_tieable][
	                                            $hybrid_is_mutable][
	                                            $hybrid_is_caller ] = ref $primitive;

	$primitive->shadow($args->{shadow})
	if exists          $args->{shadow};

	return $primitive 
}

sub tie {
	return undef 
	if !ref $_[1];

	my $tied 
	= reftype($_[1]) eq 'HASH'   ? tie( %{$_[1]}, @_[2..$#_] ) # $_[1] =~ m'(?:^|=)HASH'
	: reftype($_[1]) eq 'SCALAR' ? tie( ${$_[1]}, @_[2..$#_] ) # $_[1] =~ m'(?:^|=)SCALAR'
	: reftype($_[1]) eq 'ARRAY'  ? tie( @{$_[1]}, @_[2..$#_] ) # $_[1] =~ m'(?:^|=)ARRAY'
	: reftype($_[1]) eq 'GLOB'   ? tie( *{$_[1]}, @_[2..$#_] ) # $_[1] =~ m'(?:^|=)GLOB'
	:         undef 
	or return undef;

	Object::Hybrid->new($_[1]); 
	return $tied
}

my %Loaded;
sub load_type {
	$Loaded{$_[1]} and return undef;
	$Loaded{$_[1]} = 1; # immediately - to avoid infinite recursion 

	my ($self, $type) = @_;

	my $sub_type
	= !ref $type ? $self->can("LOAD_$type") 
	:  croak("Bad type $type")
	or croak("No $type() method defined");

	my   $class = $self->$sub_type($type); 
	     $class = $self->$class(   $type) if ref $class eq 'CODE';
	!ref $class                      or croak("Unrecorgnized value '$class' returned by $type()");
	!    $class or eval($class), !$@ or croak("Error: Can't eval() $type(): $@"); 

	return 1
}

sub ref_tied  { shift; _ref_tied(@_) }
sub _ref_tied2 { # this is much faster at least for tied hashes, but for non-tied tries all variants (still may be faster)
	return undef if !ref $_[0];
	return eval{ tied( %{$_[0]} ) }
	||     eval{ tied( ${$_[0]} ) }
	||     eval{ tied( @{$_[0]} ) }
	||     eval{ tied( *{$_[0]} ) } 
	||     undef
}
sub _ref_tied {
	#return undef if !ref $_[0]; # unlikely to be called on non-reference
	return  reftype($_[0]) eq 'HASH'   ? tied( %{$_[0]} )||0 # $_[0] =~ m'(?:^|=)HASH'
	:       reftype($_[0]) eq 'SCALAR' ? tied( ${$_[0]} )||0 # $_[0] =~ m'(?:^|=)SCALAR'
	:       reftype($_[0]) eq 'ARRAY'  ? tied( @{$_[0]} )||0 # $_[0] =~ m'(?:^|=)ARRAY'
	:       reftype($_[0]) eq 'GLOB'   ? tied( *{$_[0]} )||0 # $_[0] =~ m'(?:^|=)GLOB'
	:       undef
}

sub ref_type  {  reftype($_[1]) }
#sub ref_type { shift; reftype(@_) }
sub _ref_type {
	return undef if !ref $_[0];
	return $1    if      $_[0] =~ /=(\w+)/;
	return           ref $_[0]
}

sub ref_isa  { shift; _ref_isa(@_) }
sub _ref_isa { 
	return undef if !ref    $_[0];
	return ''    if exists $class4type{ref $_[0]};  
	return 0     if defined $_[1] and     !$_[0]->isa($_[1]);
	return $_[0]
}

sub croak { require Carp; goto &Carp::croak; }

sub _alter_case  { $_[0] =~ /[A-Z]/ ? lc($_[0]) : uc($_[0]) };
sub method_alias { _alter_case($_[1]) }

sub methods {
	shift;
	my $subs;
	ref $_[0] eq 'HASH' ? ($subs) : %$subs = @_;
	my $caller = caller;
	foreach my $method (keys %$subs) {
		# explicit aliases...
		ref       $subs->{$method}   eq 'CODE' 
		or ref(   $subs->{$method} 
		= $subs->{$subs->{$method}}) eq 'CODE' 
		or next; 

		# implicit altered-case aliases...
		my     $method2 = _alter_case($method);
		my     $goto;
		*{join '::', $caller, $method } = 
		*{join '::', $caller, $method2} = $subs->{$method};

	}
}

sub _cant_locate_object_method {
	join '', "Object::Hybrid: Can't locate object method \""
	, $_[1], "\" via package \""
	, ref($_[0])||$_[0], "\" (perhaps you forgot to load \""
	, ref($_[0])||$_[0], "\"?) "
}

{
	package Object::Hybrid::BASE;

	Object::Hybrid->methods( 
		shadow => sub {
			return $Object::Hybrid::Shadow4object{refaddr($_[0])} = $_[1] if @_ > 1;
			return $Object::Hybrid::Shadow4object{refaddr($_[0])};
		},
		call => sub{
			package Object::Hybrid;
			@_ > 1 or croak("Error: Nothing to call");

			local $Object::Hybrid::Portable = 1;
			my $method = lc(splice(@_, 1, 1));
			return shift->$method(@_) # is ok, except for caller()
		},
	);

	our $AUTOLOAD;
	sub AUTOLOAD {
		package Object::Hybrid;
		$Object::Hybrid::Portable and (split '::', $AUTOLOAD)[-1] !~ /[A-Z]/ and return  # lower-case aliases are fail-safe for compartibility
		or croak( _cant_locate_object_method($_[0], $AUTOLOAD) );
	}

	sub DESTROY { 
		package Object::Hybrid;
		delete $Object::Hybrid::Shadow4object{refaddr($_[0])};
		return 
	}
}

my $CLASS_TEMPLATE = <<'CLASS_TEMPLATE';

$INC{    INCKEY_REPLACE } ||= 1;
package PACKAGE_REPLACE; 

our @ISA = 'Object::Hybrid::BASE';

use Object::Hybrid::Class; # just labeling
use Scalar::Util qw(reftype refaddr);

sub can;  
#sub isa; 

#sub FETCH {                  tied(%{$_[0]})->FETCH(@_[1..$#_]) }             # 100_000 calls 0.94 CPU sec 106_157/s.
#sub FETCH { splice(@_, 0, 1, tied(%{$_[0]})); goto &{ $_[0]->can('FETCH') } } # 100_000 calls 2.08 CPU sec  48_007/s. goto() or plain ->() call are irrelevent - major cost is that of can().

Object::Hybrid->methods( 
	tied   => sub { TIED_REPLACE },
	SELF => sub { 

=This is too much of the guess-work, it is safer to just return $_[0]
		my      $self; 
		return  $self
		if      $self 
		=   Object::Hybrid::_ref_tied($_[0])
		and reftype($_[0]) 
		eq  reftype($self) 
		and ref($self) =~ /Std/;

		!$self or Object::Hybrid::croak("tied() class defines nor valid self() method for $_[0] (self() returned $self)");

=cut

		return $_[0]
	},
	fast => sub { 
		return TIED_REPLACE || $_[0];  

		return eval{ tied( %{$_[0]} ) }
		||     eval{ tied( ${$_[0]} ) }
		||     eval{ tied( @{$_[0]} ) }
		||     eval{ tied( *{$_[0]} ) }
		||                   $_[0];

		return $_[0] if            !ref     $_[0];
		my     $type =              reftype($_[0]);
		return $type eq 'HASH'   ?  tied( %{$_[0]} ) || $_[0] 
		:      $type eq 'SCALAR' ?  tied( ${$_[0]} ) || $_[0] 
		:      $type eq 'ARRAY'  ?  tied( @{$_[0]} ) || $_[0] 
		:      $type eq 'GLOB'   ?  tied( *{$_[0]} ) || $_[0] 
		:                                   $_[0];
	},
	call     => sub{
		@_ > 1 
		or Object::Hybrid::croak("Error: Nothing to call");

		local $Object::Hybrid::Portable = 1;
		my $method = lc(splice(@_, 1, 1));
		return shift->$method(@_) # is ok, except for caller()
	},
);

#my $AUTOLOAD = \&AUTOLOAD;
sub AUTOLOAD {
	package Object::Hybrid; # to not qualify _ref_tied(), reftype(), croak(), etc...

	( my     $METHOD = $PACKAGE_REPLACE::AUTOLOAD ) =~ s/^.*:://;
	  my     $METHOD_is_lc =       ($METHOD !~ /[A-Z]/);
	  my     $METHOD2 = _alter_case($METHOD);
	  my $SUB_METHOD;

	my $FALLBACK_METHOD;

	my $SUB_METHOD_NAME = join '::', ref($_[0])||$_[0], $METHOD;
	my $SYMTABLE           =        \%{(ref($_[0])||$_[0]) . '::'};

	goto   &{ *$SUB_METHOD_NAME
	=          $SUB_METHOD 
	=              $METHOD eq 'can' 
	? sub{

		my    $err;
		my    $can_method2;
		my    $can_method   =                $_[1];
		my    $sub_method   =               ($_[0])->UNIVERSAL::can($can_method) 
		||                                  ($_[0])->UNIVERSAL::can($can_method2 
		                                              = _alter_case($can_method));
		eval{ $sub_method ||= (TIED_REPLACE||$_[0])->UNIVERSAL::can($can_method) 
		or    $sub_method ||= (TIED_REPLACE||$_[0])->UNIVERSAL::can($can_method2) }; $err=$@; 
		eval{ $sub_method ||=     (SUBCLASS_REPLACE->UNIVERSAL::can($can_method )
		||                         SUBCLASS_REPLACE->UNIVERSAL::can($can_method2)) };

		croak("BUG in can() of mutable hybrid class: " . $err||$@) if $err||$@;  

		return $sub_method
	}
	: IS_MUTABLE_REPLACE && !KEEP_CALLER_REPLACE
	? sub{ 
		my $err;
		{   return wantarray 
		? (        eval{ TIED_REPLACE->$METHOD(@_[1..$#_]) } , $@ ? next :() )  
		: ( scalar(eval{ TIED_REPLACE->$METHOD(@_[1..$#_]) }), $@ ? next :() )[0] };

		{   return wantarray 
		? (        eval{ TIED_REPLACE->$METHOD2(@_[1..$#_]) } , $@ ? next :() )
		: ( scalar(eval{ TIED_REPLACE->$METHOD2(@_[1..$#_]) }), $@ ? next :() )[0] };

		{   return wantarray 
		? (         eval{ ($FALLBACK_METHOD ||= SUBCLASS_REPLACE->UNIVERSAL::can($METHOD)
		||  die("Cannot find method $METHOD() via $_[0]"))->(@_) } , $@ ? next :() )
		: ( scalar( eval{ ($FALLBACK_METHOD ||= SUBCLASS_REPLACE->UNIVERSAL::can($METHOD)
		||  die("Cannot find method $METHOD() via $_[0]"))->(@_) }), $@ ? next :() )[0] }; 

		$err   = $@;

		{   return wantarray 
		? (         eval{ ($FALLBACK_METHOD ||= SUBCLASS_REPLACE->UNIVERSAL::can($METHOD2)
		||  die("Cannot find method $METHOD() via $_[0]"))->(@_) } , $@ ? next :() )
		: ( scalar( eval{ ($FALLBACK_METHOD ||= SUBCLASS_REPLACE->UNIVERSAL::can($METHOD2)
		||  die("Cannot find method $METHOD() via $_[0]"))->(@_) }), $@ ? next :() )[0] }; 

		$err ||= $@;

		delete $SYMTABLE->{$METHOD}; 

		$METHOD_is_lc and $Object::Hybrid::Portable and return;  # lower-case aliases are fail-safe for compartibility
		#or croak( _cant_locate_object_method($_[0], $METHOD) );

		croak($err||"Failed to call $METHOD() on $_[0] (this is a BUG)")
	}
	: sub{ 

		my $cache = ($Object::Hybrid::Cache4object{refaddr($_[0])}->{$METHOD} ||= []) unless IS_MUTABLE_REPLACE;

		KEEP_CALLER_REPLACE || $Object::Hybrid::CALLER
		? (  splice(@_, 0, 1,       $cache->[0] ) 
		,                    goto &{$cache->[1]} ) # about twice slower, but preserves caller()
		: (   shift @_,    return   $cache->[1]->(
		                            $cache->[0], @_) )
		if !IS_MUTABLE_REPLACE and @$cache;

		my $sub_method;
		{
			my  
			$swap;   
			$swap = TIED_REPLACE and 
			$swap = splice(@_, 0, 1, $swap);  

			$swap and $sub_method
			=  $_[0]->UNIVERSAL::can($METHOD) 
			|| $_[0]->UNIVERSAL::can($METHOD2) 
			and last; 

			$swap and splice(@_, 0, 1, $swap); # revert swap, if any

			$sub_method
			=  SUBCLASS_REPLACE->UNIVERSAL::can($METHOD) 
			|| SUBCLASS_REPLACE->UNIVERSAL::can($METHOD2)
			and last;

			delete $SYMTABLE->{$METHOD};

			$METHOD_is_lc and $Object::Hybrid::Portable and return  # lower-case aliases are fail-safe for compatibility
			or  croak( _cant_locate_object_method($_[0], $METHOD) );
		}

		$sub_method ne $SUB_METHOD # this case is hopefully excluded by above logic, but it may screw up
		#and defined(&$sub_method) # here goto() to not defined(&method) is ok as it may be autoloadable in tied() class or otherwise
		or $sub_method = undef
		, croak( join '', "Undefined method \""
		, $METHOD, "\" called via package \""
		, ref($_[0])||$_[0], "\"");

		        $cache->[0] = $_[0], 
		        $cache->[1] = $sub_method,
		#weaken($cache->[0]),
		#weaken($cache->[1]), 
		unless IS_MUTABLE_REPLACE;

		goto &$sub_method
	} };
}

sub DESTROY {   
	#delete $Object::Hybrid::Tied4object{  refaddr($_[0])}; 
	delete  $Object::Hybrid::Shadow4object{refaddr($_[0])};
	delete  $Object::Hybrid::Cache4object{ refaddr($_[0])};
	return 
}

CLASS_TEMPLATE

sub _compile_class {
	my ($self, $class_template, $type) = @_;
	$type = uc($type);

	$type =~ /(HASH|ARRAY|GLOB|SCALAR)/ and my $reftype = $1 or croak("Bad $type name");

	my     $PACKAGE_REPLACE = $self->$type;
	( my    $INCKEY_REPLACE = 
	       $PACKAGE_REPLACE . '.pm' ) =~ s/::/\//g;
	my    $SUBCLASS_REPLACE = "${reftype}_UNTIED";
	my  $IS_MUTABLE_REPLACE = $type =~ /MUTABLE/ ? 1 : 0;
	my $KEEP_CALLER_REPLACE = $type =~ /CALLER/  ? 1 : 0;
	my        $TIED_REPLACE 
	= $reftype eq 'HASH'   ? 'tied( %{$_[0]} )'
	: $reftype eq 'ARRAY'  ? 'tied( @{$_[0]} )'
	: $reftype eq 'GLOB'   ? 'tied( *{$_[0]} )'
	: $reftype eq 'SCALAR' ? 'tied( ${$_[0]} )'
	: croak("Bad $reftype reftype");

	$self->load_type($SUBCLASS_REPLACE) 
	unless  $type eq $SUBCLASS_REPLACE;

	     $class_template =~     s/PACKAGE_REPLACE/$PACKAGE_REPLACE/g;
	     $class_template =~      s/INCKEY_REPLACE/'$INCKEY_REPLACE'/g;
	     $class_template =~    s/SUBCLASS_REPLACE/$SUBCLASS_REPLACE/g;
	     $class_template =~        s/TIED_REPLACE/$TIED_REPLACE/g;
		 $class_template =~  s/IS_MUTABLE_REPLACE/$IS_MUTABLE_REPLACE/g;
		 $class_template =~ s/KEEP_CALLER_REPLACE/$KEEP_CALLER_REPLACE/g;
	eval $class_template;
	!$@ or die($@);
}

sub LOAD_HASH_STATIC           { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_HASH_STATIC_CALLER    { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_HASH_MUTABLE          { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_HASH_MUTABLE_CALLER   { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }

sub LOAD_ARRAY_STATIC          { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_ARRAY_STATIC_CALLER   { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_ARRAY_MUTABLE         { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_ARRAY_MUTABLE_CALLER  { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }

sub LOAD_GLOB_STATIC           { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_GLOB_STATIC_CALLER    { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_GLOB_MUTABLE          { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_GLOB_MUTABLE_CALLER   { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }

sub LOAD_SCALAR_STATIC         { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_SCALAR_STATIC_CALLER  { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_SCALAR_MUTABLE        { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }
sub LOAD_SCALAR_MUTABLE_CALLER { $_[0]->_compile_class($CLASS_TEMPLATE, $_[1]); }

sub LOAD_HASH_UNTIED           { $_[0]->_compile_class(<<'CLASS',       $_[1]);

package PACKAGE_REPLACE; 
    $INC{INCKEY_REPLACE} ||= 1; 
our @ISA = 'Object::Hybrid::BASE'; 

use Object::Hybrid::Class; # just labeling
use Scalar::Util qw(reftype refaddr);

#sub can { $_[0]->UNIVERSAL::can($_[1]) } 

Object::Hybrid->methods({ 
	tied   => sub { undef },
	fast     => sub { $_[0] },
	self     => sub { $_[0] },
	TIEHASH  => sub { bless {}, ref($_[0])||$_[0] },
	STORE    => sub { $_[0]->{$_[1]} = $_[2] },
	FETCH    => sub { $_[0]->{$_[1]} },
	FIRSTKEY => sub { my $a = scalar keys %{$_[0]}; each %{$_[0]} },
	NEXTKEY  => sub { each %{$_[0]} },
	EXISTS   => sub { exists $_[0]->{$_[1]} },
	DELETE   => sub { delete $_[0]->{$_[1]} },
	CLEAR    => sub { %{$_[0]} = () },
	SCALAR   => sub { scalar %{$_[0]} },
});

CLASS

}

sub LOAD_SCALAR_UNTIED { $_[0]->_compile_class(<<'CLASS', $_[1]);

package PACKAGE_REPLACE; 
    $INC{INCKEY_REPLACE} ||= 1; 
our @ISA = 'Object::Hybrid::BASE'; 

use Object::Hybrid::Class; # just labeling
use Scalar::Util qw(reftype refaddr);

#sub can { $_[0]->UNIVERSAL::can($_[1]) } 

Object::Hybrid->methods({  
	tied   => sub { undef },
	fast      => sub { $_[0] },
	self      => sub { $_[0] },
	TIESCALAR => sub {
		my $class = shift;
		my $instance = shift || undef;
		return bless \$instance => $class;
	},
	FETCH   => sub { ${$_[0]}  },
	STORE   => sub { ${$_[0]} = $_[1] },
});

CLASS

}

sub LOAD_ARRAY_UNTIED { $_[0]->_compile_class(<<'CLASS', $_[1]);

package PACKAGE_REPLACE; 
    $INC{INCKEY_REPLACE} ||= 1; 
our @ISA = 'Object::Hybrid::BASE'; 

use Object::Hybrid::Class; # just labeling
use Scalar::Util qw(reftype refaddr);

#sub can { $_[0]->UNIVERSAL::can($_[1]) } 

Object::Hybrid->methods({ 
	tied      => sub { undef },
	fast      => sub { $_[0] },
	self      => sub { $_[0] },
	TIEARRAY  => sub { bless [], $_[0] },
	FETCHSIZE => sub { scalar @{$_[0]} },
	STORESIZE => sub { $#{$_[0]} = $_[1]-1 },
	STORE     => sub { $_[0]->[$_[1]] = $_[2] },
	FETCH     => sub { $_[0]->[$_[1]] },
	CLEAR     => sub { @{$_[0]} = () },
	POP       => sub { pop(@{$_[0]}) },
	PUSH      => sub { my $o = shift; push(@$o,@_) },
	SHIFT     => sub { shift(@{$_[0]}) },
	UNSHIFT   => sub { my $o = shift; unshift(@$o,@_) },
	EXISTS    => sub { exists $_[0]->[$_[1]] },
	DELETE    => sub { delete $_[0]->[$_[1]] },
	EXTEND    => sub {},
	SPLICE    => sub {
		my $ob  = shift;
		my $sz  = $ob->FETCHSIZE;
		my $off = @_ ? shift : 0;
		$off   += $sz if $off < 0;
		my $len = @_ ? shift : $sz-$off;
		return splice(@$ob,$off,$len,@_);
	},
});

CLASS

}

sub LOAD_GLOB_UNTIED  { $_[0]->_compile_class(<<'CLASS', $_[1]);

package PACKAGE_REPLACE; 
    $INC{INCKEY_REPLACE} ||= 1; 
our @ISA = 'Object::Hybrid::BASE'; 

use Object::Hybrid::Class; # just labeling
use Scalar::Util qw(reftype refaddr);

#sub can { $_[0]->UNIVERSAL::can($_[1]) } 

sub new { 
	goto &{ $_[0]->can(qw(TIEGLOB))
	||Object::Hybrid::croak("Method not defined:  new() / TIEGLOB()") } 
}

Object::Hybrid->methods({
	tied   => sub { undef },
	fast      => sub { $_[0] },
	self      => sub { $_[0] },
	TIEGLOB => sub { 
		my ($elf, $fh, @open_args) = @_;

		if ($fh eq '') {
			$fh = \do { local *GLOB }; 
		} else {
			eval{ $fh = *$fh }, !$@ or Object::Hybrid::croak("Not a GLOB reference");
		}

		$fh->OPEN(@open_args) or Object::Hybrid::croak($!)
		if        @open_args;

		return bless $fh, ref($elf)||$elf
	},

	OPEN => sub {
		defined $_[0]->FILENO
		and     $_[0]->CLOSE;

		@_ == 2 
		? open($_[0], $_[1]) 
		: open($_[0], $_[1], $_[2]);
	},

	WRITE2 => sub { 
		my    $fh = $_[0];
		print $fh substr($_[1],0,$_[2])
	},
	WRITE    => sub { my $fh = shift; write  $fh    },
	PRINT    => sub { my $fh = shift; print  $fh @_ },
	PRINTF   => sub { my $fh = shift; printf $fh @_ },

	READ     => sub { read     $_[0], $_[1], $_[2] },
	READLINE => sub { my $fh = $_[0]; <$fh> },
	GETC     => sub { getc     $_[0] },

	EOF      => sub { eof      $_[0] },
	TELL     => sub { tell     $_[0] },
	FILENO   => sub { fileno   $_[0] },
	SEEK     => sub { seek     $_[0], $_[1], $_[2] },
	CLOSE    => sub { close    $_[0] },
	BINMODE  => sub { binmode  $_[0] },

	SYSOPEN  => sub { 
		eval {
			@_ >= 3 or Object::Hybrid::croak("Not enough arguments for sysopen()");
			@_ == 3 ? sysopen $_[0]->self, $_[1], $_[2] : 
			@_ >= 4 ? sysopen $_[0]->self, $_[1], $_[2], $_[3] :();
		};
		!$@ or Object::Hybrid::croak($@);
	}, 
	FCNTL    => sub { 
		eval {
			@_ >= 3 or Object::Hybrid::croak("Not enough arguments for fcntl()");
			fcntl $_[0]->self, $_[1], $_[2];
		};
		!$@ or Object::Hybrid::croak($@);
	}, # TODO: same as for SYSOPEN()
	STAT     => sub { stat     $_[0]->self },
	FLOCK    => sub { flock    $_[0]->self, $_[1] },
	TRUNCATE => sub { truncate $_[0]->self, $_[1] },
	FTEST    => sub { 
		my $file = $_[0]->self;
		if ($_[1] =~ /^-\w$/) {
			eval "$_[1] \$file";
			!$@ or Object::Hybrid::croak($@);
		}
		else { Object::Hybrid::croak("Unknown argument to FTEST()") }
	},

});

#sub UNTIE;

CLASS

}

1;

