package  Object::Hybrid::Class; 
use Class::Tag qw(tagger_class);
use      Object::Hybrid::Class qw(is);

1;

=head1 DESCRIPTION

By default, Object::Hybrid->new() and promote() bless primitive into one of default hybrid classes based on primitive type and arguments specified. Default hybrid classes can be extended/overriden in two ways: 1) specifying custom class as argument to new()/promote() to subclass default hybrid class with; and/or 2) subclassing Object::Hybrid class to redefine default hybrid classes, possibly by subclassing them as well. Subclassing default hybrid class in either of those cases allows to easily extend hybrid class, since all requirements for hybrid class are already met by superclass, but since subclassing extends and/or overrides superclass, it may be necessary to ensure that hybrid class requirements are met by subclass as well. 

Hybrid class is required to implement L<Properties of hybrid objects|Object::Hybrid/"Properties of hybrid objects">. Here those requirements are not repeated, but instead discussed in more detail.

There are many benefits of using custom hybrid classes, in particular - opportunity of L<operator overloading|Object::Hybrid/"Operator overloading">.

=head1 Hybrid classes

=begin comment

Custom hybrid class may in theory target only specific type of primitives, as well as either tied() or not tied(), but then it is the responsibility of caller to use it conditionally only for promote()ing primitives of corresponding type.

=end comment

Promoting primitive to become hybrid (i.e. bless()ing it into hybrid class) simply adds object interface to primitive and is nothing more than a way to extend Perl primitives. There are many ways hybrid class can be designed. However, designing hybrid class in a special way allows to achieve compatibility and synergy with another major way of extending primitives - perltie API, as well as some other goals. 

Because of this, hybrid class is required to meet specific set of requirements. As a result of these requirements, which narrow design of hybrid class/interface, hybrids are useful not only as simple syntactic sugar, but become compatible with and complementary to using perltie API/classes for extending primitives. 

=begin comment

Essentially, perltie API allows to extend primitives in two related ways: 1) it allows to "pack" non-standard behavior into standard Perl primitives; and at the same time 2) allows to extend tied() objects beyond perltie interface. The first way is nearly perfect (except for gaps in perltie API implementation), but second is far from perfect as accessing extended interface of tied() object requires (conditional) tied() calls and that complicates code that is to manipulate extended tie()d primitives. The solution to this problem is exposing tied() object interface as hybrid object interface and, thus, unifying interfaces of both tie()d and non-tied() primitives. This is something that can be achieved with specific design of hybrid class and by promote()ing primitives to become hybrids.

As a result, promote()ing primitives with such hybrid class allows to write simple, non-specific code that can handle anything ranging from simple plain primitives to highly extended tied() objects. 

=end comment

Hybrid class is required to implement L<Properties of hybrid objects|Object::Hybrid/"Properties of hybrid objects">. Below some of those requirements are discusse in more detail:

=head2 Equivalent perltie API

Refer to L<Equivalent perltie API|Object::Hybrid/"Equivalent perltie API">.

There are several ways to comply with this requirement. If primitive is not tied(), then methods may operate on the primitive to produce same effect as corresponding direct access. There are two ways to modify the effect of direct access itself: tie() and dereference operators overloading. If primitive is tied(), then methods may delegate to tied() object to automatically achieve equivalence, or operate on tie()d primitive to produce same result as direct access would. If dereference operator is overloaded, corresponding access methods should take that into account and produce same result as overloaded direct access would.

For example:

	sub FETCH {
		my $self = shift;
		
		return tied(%$self)->FETCH(@_)
		if     tied(%$self);
		
		return $self->{$_[0]}
	}

The equivalence requirement limits hybrid classes to include only a subset of tieclasses. For example, the Tie::StdHash (of standard Tie::Hash module) meets equivalence requirement for non-tied() primitives, while Tie::ExtraHash - not.

In this context alternative to promote()ing primitive is tie()ing it to something like Tie::StdHash as it also will unify its interface with other tie()d hashes. However, this alternative gives up high speed of plain primitives (slowdown of about 30-40 times in some benchmarks), also tie()ing hash full of data may involve sizable costs of data copying, as well as this alternative cannot deliver same range of benefits hybrid objects can.

=head2 Delegation to tied() object

Refer to L<Delegation to tied() object|Object::Hybrid/"Delegation to tied() object">.

Although methods of the hybrid class may trigger methods of tied() class by simply accessing bless()ed primitive directly, they cannot pass arguments to them - this is why delegation is required. And it is significantly faster too. 

Examples of usefull fallback methods are stat() and few other methods implemented by default hybrid class for GLOB primitives like this: 

	sub stat { stat $_[0]->self }

Using self() method in fallback method provides compartibility with simple tied() classes like Tie::StdHash without any support form tied() class itself, as well as with tied() classes that just implement single additional self() method. If it is not possible for tied() class to define self() method, then tied() class may need to implement stat() and other methods itself.

Note that for perltie methods fallback methods are almost never called, because normally tieclass does implement perltie methods. If it is not, the equivalence requirement would be violated, since triggering perltie method implicitly, via primitive access, will lead to exception raised as call is on tied() object and corresponding perltie method is not provided, but calling that method on hybrid may end up calling fallback method, i.e. no exception is raised. Though, raising exception in both cases is not to be considered equivalence either.

=head2 Method aliases

Refer to L<Method aliases|Object::Hybrid/"Method aliases">.

The promote()ing of tied() primitive automatically provides altered-case aliases to methods of tied() object - no need to modify tied() classes.

This feature relies on AUTOLOAD() of default hybrid clas, so if custom hybrid class needs to implement its own AUTOLOAD(), it must behave accordingly or call overriden AUTOLOAD() from default hybrid class, but later cannot be done with ->SUPER::AUTOLOAD() notation, as custom hybrid class do not directly inherit from default hybrid class, so be ware.

Automatic altered-case aliases provided by default hybrid class are relatively costly, as they involve extra can() call to locate altered-case method in case originally called method is not defined. However, this is only relevant in case of mutable => 1 promote() for tie()d primitives, since in other cases hybrid class (either default or custom) is likely to have both aliases defined and extra cost is not incurred. In this rare case to avoid cost of automatic aliasing in case of tie()d primitives (tied to unaware tieclasses), it is better to call method's aliase that is known (or likely) to be defined by underlying tied() class. In this specific case, for example, FETCH() is likely to be faster than fetch() for tie()d primitives (as their tied() classes usually define no fetch(), just FETCH()).

=head2 self() method

Refer to L<self() method|Object::Hybrid/"self() method">.

Use of self() method is limited since it requires tieclass (with exception for simple tieclasses similar to Tie::StdHash, Tie::StdHandle, etc.) to also implement self() method, and also there may be tied primitives that simply do not have (single) underlying primitive to operate on it non-transparently, but still it is useful for writing code portable across specific tieclasses that are known to support self(), so it is a requirement for hybrid classes (to be compatible).

The self() method is intended primarily for performance optimizations and to work around gaps in perltie (specifically, tiehandles) implementation. If there were no gaps, then there is no need for self() method except for performance optimization, as hybrid primitive is then B<equivalent> to (but much slower than) what self() is supposed to return. However, gaps lead to situations when hybrid primitive is not equivalent and you need to get underlying primitive that tied() object uses under the hood - self() method is expected to return just that. To work around gaps in a way compatible with hybrid objects, it is recommended that tieclasses either implement self(), if possible, or implement corresponding workaround methods themselves (see L</"Complete perltie API">).

Simple tieclasses can define only self() method and automatically get sysopen(), truncate(), flock(), fcntl(), stat() and ftest() methods of default hybrid class to work for them correctly.

Accordingly, as a requirement, hybrid class must provide self() method that simply returns the hybrid object: 

	sub self { $_[0] }

Finally, for many tieclasses it may not be possible to implement correct self() method, those tieclasses should implement self{} that simply raises an exception with proper explanations.

=head2 Optional bless() method

Refer to L<Optional bless() method|Object::Hybrid/"Optional bless() method">.

TIE*() and new() constructors are not used as constructor/initializer for hybrid object, since in case of tied() hybrid (or in exotic case tieclass, like Tie::StdHash, is subclassed to make hybrid class) those are supposed to be perltie-style constructors and are kept as such.

=head2 C<use Object::Hybrid::Class>

To mark complete valid hybrid class as such, put this lines into it, unless it already inherits from such a class:

	package CustomHybridClass;	
	use Object::Hybrid;
	use Object::Hybrid::Class;

This requirement allows to use the following test to find out if $class is a hybrid class:

	Object::Hybrid->Class->is($class);

This test returns true for CustomHybridClass and all its subclasses, since subclasses of valid hybrid class are unlikely to (intentionally) make it invalid, but is not necessarily true in super-classes, as those may be not be (marked as) valid hybrid classes.

=head1 Overriding with methods()

The methods() method should always be used to define methods in custom hybrid classes, as it automatically defines altered-case aliases for methods and can also define other aliases as well. For example, the following defines self(), self(), only(), ONLY(), directly(), DIRECTLY() as aliases for same method:

	Object::Hybrid->methods(
		self     => sub{ $_[0] },
		only     => 'self',
		directly => 'self',
	);

=for comment Since indirect method notation unfortunately do not work for self(), the self() method name should read naturally in direct notation, and preferably be not readable in indirect notation to discourage its accidental use. This criteria reject just(), very() and leaves only(), directly(), itself() alternatives. The only() reads ok, but it reads ok in indirect notation too. The itself() reads nice with $FH, but not with, say, $LINES filehandle, etc. So, directly() seems to be viable alternative: stat $FH->directly.

=head1 Subclassing Object::Hybrid

Subclassing Object::Hybrid and overriding new() in the subclass will automatically override promote() exported by that subclass, so there is no need to explicitly redefine promote() in subclass.

The CLASS_DEFAULT() is to define name of default class to be used as custom hybrid class in case none are provided as argument to new() or promote(). Object::Hybrid->CLASS_DEFAULT value is not defined, but subclasses may well define it (it is one of the he  main reasons to support subclassing of Object::Hybrid). Subclass must load class referred to by CLASS_DEFAULT().

Values of certain Object::Hybrid attributes FOO() define names of type-specific hybrid classes, and corresponding LOAD_FOO() methods are expected to load those type-specific hybrid classes. Consequently, subclasses may redefine those attributes and methods to have different type-specific hybrid classes. For example, subclass may override them as follows:

	sub      HASH_UNTIED () {     'Tie::StdHash' }
	sub LOAD_HASH_UNTIED    { require Tie::Hash  } # Tie::Hash loads Tie::StdHash class

But note that Tie::StdHash class here is used only as example - it is not a complete hybrid class impplementation since it do not implement all properties hybrid class is required to have - see L</"Properties of hybrid objects">.

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



