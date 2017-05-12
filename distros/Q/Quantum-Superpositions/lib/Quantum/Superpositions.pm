
package Quantum::Superpositions;

########################################################################
# housekeeping
########################################################################

use strict;

use Carp;
use Class::Multimethods;

our $VERSION = '2.02';

sub import
{
	{
		my $caller = caller;

		no strict 'refs';

		*{ $caller . '::' . $_ } = __PACKAGE__->can( $_ )
			for qw( all any eigenstates );
	}

	my ($class, %quantized) = @_;

	quantize_unary($_,'quop')   for @{$quantized{UNARY}};
	quantize_unary($_,'qulop')  for @{$quantized{UNARY_LOGICAL}};

	quantize_binary($_,'qbop')  for @{$quantized{BINARY}};
	quantize_binary($_,'qblop') for @{$quantized{BINARY_LOGICAL}};


	1
}

########################################################################
# utility subroutines and package variables
#
# these are small enough to get lost in the shuffle. easier to put them
# up here than loose 'em...
########################################################################

# used to print intermediate results if $debug is true.

my $debug = 0;

sub debug
{ 
	print +(caller(1))[3], "(";
	print +overload::StrVal($_), "," for @_;
	print ")\n";
}

# cleans up overloaded calls.

sub swap { $_[2] ? @_[1,0] : @_[0,1] }

# eigencache tracks objects results. destructor has to clean
# out the cache. due to overloading this cannot simply use 
# the $hash{$referent} trick.

my %eigencache;

sub DESTROY { delete $eigencache{overload::StrVal($_[0])}; }

# replaces the cartesian product with an iterator. normal use is 
# something like:
#
#	my ( $n, $sub ) = iterator \@list1, \@list2
#
#	my @result = map { somefunc @$sub->() } (1..$n );
#
# note the limit check on $j: this returns an empty list
# after the process has iterated once. this allows for
# while( @pair = $iter->() ){ ... } and gracefully handles
# (0..$count) also.

sub iterator
{
	my ( $a, $b ) = ( shift, shift );
	my ( $i, $j ) = ( -1, -1 );

	# caller gets back ( iterator count, closure ).
	# the $j test also allows for while or for(;;)
	# loops testing the return.

	(
		@$a * @$b,

		sub
		{
			$i = ++$i % @$a;
			++$j unless $i;

			$j < @$b ? [ $a->[$i], $b->[$j] ] : ()
		}
	)

}


########################################################################
# what users call. the rest of this stuff is generally called
# indirectly via multimethods on the contents of the objects.

sub any   { bless [@_], 'Quantum::Superpositions::Disj' }
sub all   { bless [@_], 'Quantum::Superpositions::Conj' }

sub all_true { bless [@_], 'Quantum::Superpositions::Conj::True' }


########################################################################
# what the hell do these really do?

sub quantize_unary
{
	my ($fullsubname, $type) = @_;

	my ($package,$subname) = m/(.+)::(.+)$/;

	my $caller = caller;

	my $original = "CORE::$subname";

	if( $package ne 'CORE' )
	{
		$original = "Quantum::Superpositions::Quantized::$fullsubname";

		no strict;

		*{$original} = \&$fullsubname;
	}
	else
	{
		$package = 'CORE::GLOBAL';
	}

	eval
	qq{
		package $package;

		use subs '$subname';

		use Class::Multimethods '$type';
		local \$SIG{__WARN__} = sub{};

		no strict 'refs';

		*{"${package}::$subname"} =
		sub
		{
			local \$^W;
			return \$_[0]->$type(sub{$original(\$_[0])})
			    if UNIVERSAL::isa(\$_[0],'Quantum::Superpositions')
			    || UNIVERSAL::isa(\$_[1],'Quantum::Superpositions');

			no strict 'refs';

			return $original(\$_[0]);
		};
	}
	|| croak "Internal error: $@";
} 

sub quantize_binary
{
	my ($fullsubname, $type) = @_;
	my ($package,$subname) = m/(.*)::(.*)/;
	my $caller = caller;
	my $original = "CORE::$subname";
	if ($package ne 'CORE')
	{
		$original = "Quantum::Superpositions::Quantized::$fullsubname";

		no strict;

		*{$original} = \&$fullsubname;
	}
	else
	{
		$package = 'CORE::GLOBAL';
	}
	eval
	qq{
		package $package;
		use subs '$subname';

		use Class::Multimethods '$type';

		local \$SIG{__WARN__} = sub{};

		no strict 'refs';

		*{"${package}::$subname"} =
		sub
		{
			local \$^W;
			return $type(\@_[0,1],sub{$original(\$_[0],\$_[1])})
			    if UNIVERSAL::isa(\$_[0],'Quantum::Superpositions')
			    || UNIVERSAL::isa(\$_[1],'Quantum::Superpositions');

			no strict 'refs';

			return $original(\$_[0],\$_[1]);
		};
	} || croak "Internal error: $@";
}

########################################################################
# assign the multimethods operations for various types

multimethod qbop =>
( qw(
	Quantum::Superpositions::Conj
	Quantum::Superpositions::Conj
	CODE

) ) =>
sub
{
	my ( $count, $iter ) = iterator @_[0,1];

	all map { qbop(@{$iter->()}, $_[2]) } (1..$count);
};

multimethod qbop =>
( qw(
	Quantum::Superpositions::Disj
	Quantum::Superpositions::Disj
	CODE
) ) =>
sub
{
	my ( $count, $iter ) = iterator( @_[0,1] );

	any map { qbop(@{$iter->()}, $_[2]) } (1..$count);
};

multimethod qbop =>
( qw(
	Quantum::Superpositions::Conj
	Quantum::Superpositions::Disj
	CODE
) ) =>
sub
{
	all map { qbop($_, $_[1], $_[2]) } @{$_[0]};
};

multimethod qbop =>
( qw(
	Quantum::Superpositions::Disj
	Quantum::Superpositions::Conj
	CODE
) ) =>
sub
{
	any map { qbop($_, $_[1], $_[2]) } @{$_[0]}
};

multimethod qbop =>
( qw(
	Quantum::Superpositions::Conj
	*
	CODE
) ) =>
sub
{
	all map { qbop($_, $_[1], $_[2]) } @{$_[0]}
};

multimethod qbop =>
( qw(
	Quantum::Superpositions::Disj
	*
	CODE
) ) =>
sub
{
	any map { qbop($_, $_[1], $_[2]) } @{$_[0]}
};

multimethod qbop =>
( qw(
	*
	Quantum::Superpositions::Disj
	CODE
) ) =>
sub
{
	any map { qbop($_[0], $_, $_[2]) } @{$_[1]}
};

multimethod qbop =>
( qw(
	*
	Quantum::Superpositions::Conj
	CODE
) ) =>
sub
{
	all map { qbop($_[0], $_, $_[2]) } @{$_[1]}
};

multimethod qbop =>
( qw(
	*
	*
	CODE
) ) =>
sub
{
	$_[2]->(@_[0..1])
};

multimethod qblop =>
( qw(
	Quantum::Superpositions::Conj
	Quantum::Superpositions::Conj
	CODE
) ) =>
sub
{
	&debug if $debug;

	return all() unless @{$_[0]} && @{$_[1]};

	my ( $count, $iter ) = iterator @_[0,1];

	istrue( qblop(@{$iter->()}, $_[2]) ) || return all() for (1..$count);

	all_true @{$_[0]};
};

multimethod qblop =>
( qw(
	Quantum::Superpositions::Conj
	Quantum::Superpositions::Disj
	CODE
) ) =>
sub
{
	&debug if $debug;

	return all() unless @{$_[0]} && @{$_[1]};

	my @cstates = @{$_[0]};

	my @matchstates;

	my $okay = 0;

	for my $cstate ( @cstates )
	{
		for my $dstate ( @{$_[1]} )
		{
			++$okay && last
				if istrue(qblop($cstate, $dstate, $_[2]));
		}
	}

	return all() unless $okay == @cstates;
	return all_true @{$_[0]};
};

multimethod qblop =>
( qw(
	Quantum::Superpositions::Disj
	Quantum::Superpositions::Conj
	CODE
) ) =>
sub
{
	&debug if $debug;

	return any() unless @{$_[0]} && @{$_[1]};

	my @dstates = @{$_[0]};
	my @cstates = @{$_[1]};

	my @dokay = (0) x @dstates;
		for my $cstate ( @cstates )
		{
			my $matched;
			for my $d ( 0..$#dstates )
			{
				$matched = ++$dokay[$d]
					if istrue(qblop($dstates[$d], $cstate, $_[2]));
			}

			return any() unless $matched;
		}

		return any @dstates[grep { $dokay[$_] == @cstates } (0..$#dstates)];
};

multimethod qblop =>
( qw(
	Quantum::Superpositions::Conj
	*
	CODE
) ) =>
sub
{
	&debug if $debug;

	return all() unless @{$_[0]};
	istrue(qblop($_, $_[1], $_[2])) || return all() for @{$_[0]};
	return all_true @{$_[0]};
};

multimethod qblop =>
( qw(
	*
	Quantum::Superpositions::Conj
	CODE
) ) =>
sub
{
	&debug if $debug;

	return all() unless @{$_[1]};
	istrue(qblop($_[0], $_, $_[2])) || return all() for @{$_[1]};
	return all_true $_[0];
};

multimethod qblop =>
( qw(
	Quantum::Superpositions::Disj
	*
	CODE
) ) =>
sub
{
	&debug if $debug;

	return any() unless @{$_[0]};
	return any grep { istrue(qblop($_, $_[1], $_[2])) } @{$_[0]};
};

multimethod qblop =>
( qw(
	*
	Quantum::Superpositions::Disj
	CODE
) ) =>
sub
{
	&debug if $debug;

	return any() unless @{$_[1]};
	return any grep { istrue(qblop($_[0], $_, $_[2])) } @{$_[1]};
};

multimethod qblop =>
( qw(
	Quantum::Superpositions::Disj
	Quantum::Superpositions::Disj
	CODE
) ) =>
sub
{
	&debug if $debug;

	return any() unless @{$_[0]} && @{$_[1]};
	return any grep { istrue(qblop($_[0], $_, $_[2])) } @{$_[1]};
};

multimethod qblop =>
( qw(
	*
	*
	CODE
) ) =>
sub
{
	&debug if $debug;

	return qbop(@_) ? $_[0] : ();
};

########################################################################
# overload everything possible into appropraite multimethods.
# this is where the limitation for regexen hits. 

use overload

	q{+}	=>  sub { qbop(swap(@_), sub { $_[0] + $_[1]  })},
	q{-}	=>  sub { qbop(swap(@_), sub { $_[0] - $_[1]  })},
	q{*}	=>  sub { qbop(swap(@_), sub { $_[0] * $_[1]  })},
	q{/}	=>  sub { qbop(swap(@_), sub { $_[0] / $_[1]  })},
	q{%}	=>  sub { qbop(swap(@_), sub { $_[0] % $_[1]  })},
	q{**}	=>  sub { qbop(swap(@_), sub { $_[0] ** $_[1] })},
	q{<<}	=>  sub { qbop(swap(@_), sub { $_[0] << $_[1] })},
	q{>>}	=>  sub { qbop(swap(@_), sub { $_[0] >> $_[1] })},
	q{x}	=>  sub { qbop(swap(@_), sub { $_[0] x $_[1]  })},
	q{.}	=>  sub { qbop(swap(@_), sub { $_[0] . $_[1]  })},
	q{&}	=>  sub { qbop(swap(@_), sub { $_[0] & $_[1]  })},
	q{^}	=>  sub { qbop(swap(@_), sub { $_[0] ^ $_[1]  })},
	q{|}	=>  sub { qbop(swap(@_), sub { $_[0] | $_[1]  })},
	q{atan2}=>  sub { qbop(swap(@_), sub { atan2($_[0],$_[1]) })},

	q{<}	=>  sub { qblop(swap(@_), sub { $_[0] < $_[1]   })},
	q{<=}	=>  sub { qblop(swap(@_), sub { $_[0] <= $_[1]  })},
	q{>}	=>  sub { qblop(swap(@_), sub { $_[0] > $_[1]   })},
	q{>=}	=>  sub { qblop(swap(@_), sub { $_[0] >= $_[1]  })},
	q{==}	=>  sub { qblop(swap(@_), sub { $_[0] == $_[1]  })},
	q{!=}	=>  sub { qblop(swap(@_), sub { $_[0] != $_[1]  })},
	q{<=>}	=>  sub { qblop(swap(@_), sub { $_[0] <=> $_[1] })},
	q{lt}	=>  sub { qblop(swap(@_), sub { $_[0] lt $_[1]  })},
	q{le}	=>  sub { qblop(swap(@_), sub { $_[0] le $_[1]  })},
	q{gt}	=>  sub { qblop(swap(@_), sub { $_[0] gt $_[1]  })},
	q{ge}	=>  sub { qblop(swap(@_), sub { $_[0] ge $_[1]  })},
	q{eq}	=>  sub { qblop(swap(@_), sub { $_[0] eq $_[1]  })},
	q{ne}	=>  sub { qblop(swap(@_), sub { $_[0] ne $_[1]  })},
	q{cmp}	=>  sub { qblop(swap(@_), sub { $_[0] cmp $_[1] })},

	q{cos}	=>  sub { $_[0]->quop(sub { cos $_[0]  })},
	q{sin}	=>  sub { $_[0]->quop(sub { sin $_[0]  })},
	q{exp}	=>  sub { $_[0]->quop(sub { exp $_[0]  })},
	q{abs}	=>  sub { $_[0]->quop(sub { abs $_[0]  })},
	q{sqrt}	=>  sub { $_[0]->quop(sub { sqrt $_[0] })},
	q{log}	=>  sub { $_[0]->quop(sub { log $_[0]  })},
	q{neg}	=>  sub { $_[0]->quop(sub { -$_[0]     })},
	q{~}	=>  sub { $_[0]->quop(sub { ~$_[0]     })},

	q{&{}}  => 
	sub
	{
		my $s = shift;
		return sub { bless [map {$_->(@_)} @$s], ref $s }
	},

	q{!}	=>  sub { $_[0]->qulop(sub { !$_[0]     })},

	q{bool}	=>  'qbool',
	q{""}	=>  'qstr',
	q{0+}	=>  'qnum',
;

########################################################################
# extract results from the Q::S objects.

multimethod collapse =>
( 'Quantum::Superpositions' ) =>
	sub { return map { collapse($_) } @{$_[0]} };

multimethod collapse => ( '*' ) => sub { return $_[0] };

sub eigenstates($)
{
	my ($self) = @_;
	my $eigencache_id = overload::StrVal($self);
	return @{$eigencache{$eigencache_id}}
		if defined $eigencache{$eigencache_id};
	my %uniq;
	@uniq{collapse($self)} = ();
	local $^W=1;
	return @{$eigencache{$eigencache_id}} =
		grep
		{
		  my $okay=1;
		  local $SIG{__WARN__} = sub {$okay=0};
		  istrue($self eq $_) || istrue($self == $_) && $okay
		}
		keys %uniq;
}

multimethod istrue => ( 'Quantum::Superpositions::Disj' ) =>
	sub
	{
		my @states = @{$_[0]} || return 0;
		istrue($_) && return 1 for @states; return 0;
	};

multimethod istrue => ( 'Quantum::Superpositions::Conj::True' ) =>
	sub { return 1; };

multimethod istrue => ( 'Quantum::Superpositions::Conj' ) =>
	sub
	{
		my @states = @{$_[0]} || return 0;
		istrue($_) || return 0 for @states; return 1;
	};

multimethod istrue => ( '*' ) => sub { return defined $_[0]; };

multimethod istrue => () => sub { return 0; };

sub qbool { $_[0]->eigenstates ? 1 : 0; }
sub qnum  { my @states = $_[0]->eigenstates; return $states[rand @states] }

########################################################################
########################################################################
# embedded classes.
#
# these are what the constructors bless things into.
########################################################################

package Quantum::Superpositions::Disj;
use base 'Quantum::Superpositions';
use Carp;

sub qstr
{
	my @eigenstates = $_[0]->eigenstates;
   return "@eigenstates" if @eigenstates == 1;
   return "any(".join(",",@eigenstates).")"
}

sub quop  { Quantum::Superpositions::any(map  { $_[1]->($_) } @{$_[0]}) }

sub qulop { Quantum::Superpositions::any(grep { $_[1]->($_) } @{$_[0]}) }


package Quantum::Superpositions::Conj;
use base 'Quantum::Superpositions';
use Carp;

sub qstr
{
	my @eigenstate = $_[0]->eigenstates;

	@eigenstate ? "@eigenstate" : "all(".join(",",@{$_[0]}).")" 
}

sub quop { return Quantum::Superpositions::all(map { $_[1]->($_) } @{$_[0]}) }

sub qulop
{
	$_[1]->($_) || return Quantum::Superpositions::all() for @{$_[0]};

	Quantum::Superpositions::all(@{$_[0]})
}


package Quantum::Superpositions::Conj::True;
use base 'Quantum::Superpositions::Conj';

sub qbool { 1 }


1;

__END__

=head1 NAME

Quantum::Superpositions - QM-like superpositions in Perl

=head1 VERSION

This document describes version 1.03 of Quantum::Superpositions,
released August 11, 2000.

=head1 SYNOPSIS

	use Quantum::Superpositions;

	if ($x == any($a, $b, $c)) { ...  }

	while ($nextval < all(@thresholds)) { ... }

	$max = any(@value) < all(@values);


	use Quantum::Superpositions BINARY => [ CORE::index ];

	print index( any("opts","tops","spot"), "o" );
	print index( "stop", any("p","s") ); 


=head1 BACKGROUND

Under the standard interpretation of quantum mechanics, until they are observed, particles exist only as a discontinuous probability 
function. Under the Cophenhagen Interpretation, this situation is often visualized by imagining the state of an unobserved particle to be 
a ghostly overlay of all its possible observable 
states simultaneously. For example, a particle 
that might be observed in state A, B, or C may 
be considered to be in a pseudo-state where 
it is simultaneously in states A, B, and C.
Such a particle is said to be in a superposition of states.

Research into applying particle superposition 
in construction of computer hardware is already well advanced. The aim of such 
research is to develop reliable quantum 
memories, in which an individual bit is stored 
as some measurable property of a quantised 
particle (a qubit). Because the particle can be 
physically coerced into a superposition of 
states, it can store bits that are simultaneously 
1 and 0. 

Specific processes based on the interactions of 
one or more qubits (such as interference, entanglement, or additional superposition) are 
then be used to construct quantum logic 
gates. Such gates can in turn be employed to 
perform logical operations on qubits, allowing logical and mathematical operations to be 
executed in parallel.

Unfortunately, the math required to design and use
quantum algorithms on quantum computers is painfully
hard. The Quantum::Superpositions module offers
another approach, based on the superposition of
entire scalar values (rather than individual qubits).

=head1 DESCRIPTION

The Quantum::Superpositions module adds two
new operators to Perl: C<any> and C<all>.

Each of these operators takes a list of values (states) 
and superimposes them into a single scalar 
value (a superposition), which can then be 
stored in a standard scalar variable. 

The C<any> and C<all> operators produce two distinct kinds of superposition. The C<any>
operator produces a disjunctive superposition, 
which may (notionally) be in any one of its 
states at any time, according to the needs of 
the algorithm that uses it.

In contrast, the C<all>
operator creates a conjunctive superposition, 
which is always in every one of its states 
simultaneously.

Superpositions are scalar values and hence 
can participate in arithmetic and logical operations just like any other type of scalar. 
However, when an operation is applied to a 
superposition, it is applied (notionally) in parallel to each 
of the states in that superposition.

For example, if a superposition of states 1, 2, and 3 is 
multiplied by 2:

	$result = any(1,2,3) * 2;

the result is a superposition of states 2, 4, and 
6. If that result is then compared with the 
value 4:

	if ($result == 4) { print "fore!" } 

then the comparison also returns a superposition: one that is both true and false (since the 
equality is true for one of the states of        
C<$result> and false for the other two).

Of course, a value that is both true and false is 
of no use in an C<if> statement, so some mechanism is needed to decide which superimposed boolean state should take precedence. 

This mechanism is provided by the two types 
of superposition available. A disjunctive superposition is true if any of its states is true, 
whereas a conjunctive superposition is true 
only if all of its states are true.

Thus the previous example does print 
"fore!", since the C<if> condition is equivalent 
to:

	if (any(2,4,6) == 4)... 
	
It suffices that any one of 2, 4, or 6 is equal to 4, so the condition
is true and the C<if> block executes.

On the other hand, had the control statement 
been:

        if (all(2,4,6) == 4)... 

the condition would fail, since it is not true 
that all of 2, 4, and 6 are equal to 4.

Operations are also possible between two superpositions:

        if (all(1,2,3)*any(5,6) < 21) 
                { print "no alcohol"; }
                
        if (all(1,2,3)*any(5,6) < 18)
                { print "no entry"; }
                
        if (any(1,2,3)*all(5,6) < 18)
                { print "under-age" }
                
In this example, the string "no alcohol" is printed because the
superposition produced by the multiplication is the Cartesian product of
the respective states of the two operands: C<all(5,6,10,12,15,18)>.
Since all of these resultant states are less that 21, the condition is
true. In contrast, the string "no entry" is not printed, because not all
the product's states are less than 18.

Note that the type of the first operand determines the type of the result of an operation. 
Hence the third string -- "underage" -- is 
printed, because multiplying a disjunctive 
superposition by a conjunctive superposition 
produces a result that is disjunctive: 
C<any(5,6,10,12,15,18)>. The condition of 
the C<if> statement asks whether any of these 
values is less than 18, which is true.

=head2 Composite Superpositions

The states of a superposition may be any kind 
of scalar value -- a number, a string, or a reference:

        $wanted = any("Mr","Ms").any(@names);
        if ($name eq $wanted) { print "Reward!"; } 

        $okay = all(\&check1,\&check2);
        die unless $okay->();

        my $large =
                all(    BigNum->new($centillion),
                        BigNum->new($googol),
                        BigNum->new($SkewesNum)
                );
        @huge =  grep {$_ > $large} @nums;

More interestingly, since the individual states 
of a superposition are scalar values and a superposition is itself a scalar value, a superposition may have states that are themselves 
superpositions:

	$ideal = any( all("tall", "rich", "handsome"),
	              all("rich", "old"),
	              all("smart","Australian","rich")
	            );

Operations involving such a composite superposition operate recursively and in parallel on each its states individually and then 
recompose the result. For example:

        while (@features = get_description)
		{
                if (any(@features) eq $ideal)
				{
                        print "True love";
                }
        }

The C<any(@features) eq $ideal> equality 
is true if the input characteristics collectively 
match any of the three superimposed conjunctive superpositions. That is, if the characteristics collectively equate to each of "tall" 
and "rich" and "handsome", or to both 
"rich" and "old", or to all three of 
"smart" and "Australian" and "rich". 

=head2 Eigenstates

It is useful to be able to determine the list of 
states that a given superposition represents. 
In fact, it is not the I<states> per se, but the
values to which the states may collapse -- the
I<eigenstates> that are useful.

In programming terms this is the 
set of values C<@ev> for a given superposition C<$s> 
such that C<any(@ev) == $s> or
C<any(@ev) eq $s>.

This list is provided by the C<eigenstates>
operator, which may be called on any superposition:

        print "The factor was: ",
              eigenstates($factor);

        print "Don't use any of:",
              eigenstates($badpasswds);


=head2 Boolean evaluation of superpositions

The examples shown above assume the same meta-semantics for both 
arithmetic and boolean operations, namely 
that a binary operator is applied to the Cartesian product of the states of its two operands, 
regardless of whether the operation is arithmetic or logical. Thus the comparison of two 
superpositions produces a superposition of 
1's and 0's, representing any (or all) possible 
comparisons between the individual states of 
the two operands.

The drawback of applying arithmetic metasemantics to logical operations is that it 
causes useful information to be lost. Specifically, which states were responsible for the 
success of the comparison. For example, it is 
possible to determine if any number in the 
array C<@newnums> is less than all those in the 
array C<@oldnums> with:

        if (any(@newnums) < @all(oldnums))
		{
          print "New minimum detected";
        }

But this is almost certainly unsatisfactory, because it does not reveal which element(s) of 
C<@newnum> caused the condition to be true.

It is, however, possible to define a different 
meta-semantics for logical operations between superpositions; one that preserves the 
intuitive logic of comparisons but also gives 
limited access to the states that cause those 
comparsions to succeed. 

The key is to deviate from the arithmetic view 
of superpositional comparison (namely, that a 
compared superposition yields a superposition of compared state combinations). 
Instead, the various comparison operators are 
redefined so that they form a superposition of 
those eigenstates of the left operand that cause 
the operation to be true. In other words, the 
old meta-semantics superimposed the result 
of each parallel comparison, whilst the new 
meta-semantics superimposes the left operands of each parallel comparison that succeeds.

For example, under the original semantics, 
the comparisons:

        all(7,8,9) <= any(5,6,7)        #A
        all(5,6,7) <= any(7,8,9)        #B
        any(6,7,8) <= all(7,8,9)        #C

would yield:

        all(0,0,1,0,0,0,0,0,0)          #A (false)
        all(1,1,1,1,1,1,1,1,1)          #B (true)
        any(1,1,1,1,1,1,0,1,1)          #C (true)

Under the new semantics they would yield:

        all(7)                          #A (false)
        all(5,6,7)                      #B (true)
        any(6,7)                        #C (true)

The success of the comparison (the truth of 
the result) is no longer determined by the I<values>
of the resulting states, but by the I<number> of 
states in the resulting superposition.

The Quantum::Superpositions module treats logical
operations and boolean conversions in exactly this way.
Under these meta-semantics, it is possible to 
check a comparison and also determine 
which eigenstates of the left operand were 
responsible for its success:

        $newmins = any(@newnums) < all(@oldnums);

        if ($newmins)
		{
                print "New minima found:", eigenstates($newmins);
        }

Thus, these semantics provide a mechanism 
to conduct parallel searches for minima and maxima :

        sub min { eigenstates( any(@_) <= all(@_) ) }

        sub max { eigenstates( any(@_) >= all(@_) ) } 

These definitions are also quite intuitive, almost declarative: the minimum is any value 
that is less-than-or-equal-to all of the other 
values; the maximum is any value that is 
greater-than-or-equal to all of them.

=head2 String evaluation of superpositions

Converting a superposition to a string produces
a string that encode the simplest set of eigenstates
equivalent to the original superposition.

If there is only one eigenstate, the stringification 
of that state is the string representation.
This eliminates the need to explicitly apply the C<eigenstates>
operator when only a single 
resultant state is possible. For example:

        print "lexicographically first: ",
              any(@words) le all(@words);

In all other cases, superpositions are stringified
in the format: C<"all(I<eigenstates>)"> or
C<"any(I<eigenstates>)">.

=head2 Numerical evaluation of superpositions

Providing an implicit conversion to numeric (for situations where
superpositions are used as operands to an arithmetic operation, or as
array indices) is more challenging than stringification, since there is
no mechanism to capture the entire state of a superposition in a single
non-superimposed number.

Again, if the superposition has a single eigenstate, the conversion is just the standard conversion for that value. For instance, to output 
the value in an array element with the smallest index in the set of indices @i:

        print "The smallest element is: ",
              $array[any(@i)<=all(@i)];

If the superposition has no eigenstates, there 
is no numerical value to which it could collapse, so the result is C<undef>.

If a disjunctive superposition has more than 
one eigenstate, that superposition could collapse to any of those values. And it is convenient to allow it to do exactly that -- collapse 
(pseudo-)randomly to one of its eigenstates. 
Indeed, doing so provides a useful notation 
for random selection from a list:

        print "And the winner is...",
              $entrant[any(0..$#entrant)]; 

=head2 Superpositions as subroutine arguments

When a superposition is used as a subroutine 
argument, that subroutine is applied in parallel to each state of the superposition and the 
results re-superimposed to form the same 
type of superposition. For example, given:

        $n1 = any(1,4,9);
        $r1 = sqrt($n1);

        $n2 = all(1,4,9);
        $r2 = pow($n2,3);

        $r3 = pow($n1,$r1);

then $r1 contains the disjunctive superposition C<any(1,2,3)>, C<$r2> contains the conjunctive superposition C<all(1,64,729)>, and <$r3 >
contains the conjunctive superposition 
C<any(1,4,9,16,64,81,729)>.

Because the built-in C<sqrt> and C<pow> functions
don't know about superpositions, the module 
provides a mechanism for informing them that their
arguments may be superimposed.

If the call to C<use Quantum::Superpositions>
is given an argument list, that list specifies
which functions should be rewritten to handle
superpositions. Unary functions and subroutine
can be "quantized" like  so:

        sub incr    { $_[0]+1 }
        sub numeric { $_[0]+0 eq $_[0] }

        use Quantum::Superpositions
                UNARY         => ["CORE::int", "main::incr"],
                UNARY_LOGICAL => ["main::numeric"];

For binary functions and subroutines use:

        sub max  { $_[0] < $_[1] ? $_[1] : $_[0] }

        sub same { my $failed; $IG{__WARN__}=sub{$failed=1};
                   return $_[0] eq $_[1] || $_[0]==$_[1] && !$failed;
                 }

        use Quantum::Superpositions
                BINARY         => ['main::max', 'CORE::index'],
                BINARY_LOGICAL => ['main::same'];


=head1 EXAMPLES

=head2 Primality testing

The power of programming with scalar superpositions is perhaps best seen
by returning the quantum computing's favourite adversary: prime numbers.
Here, for example is an O(1) prime-number tester, based on naive
trial division:

        sub is_prime
		{
          my ($n) = @_;
          return $n % all(2..sqrt($n)+1) != 0 
        }

The subroutine takes a single argument (C<$n>) 
and computes (in parallel) its modulus with 
respect to every integer between 2 and C<sqrt($n)>. 
This produces a conjunctive superposition of 
moduli, which is then compared with zero. 
That comparison will only be true if all the 
moduli are not zero, which is precisely the 
requirement for an integer to be prime.

Because C<is_prime> takes a single scalar argument, it can also be passed a superposition. 
For example, here is a constant-time filter for 
detecting whether a number is part of a pair 
of twin primes:

        sub has_twin
		{
                my ($n) = @_;
                return is_prime($n) && is_prime($n+any(+2,-2);
        }

=head2 Set membership and intersection

Set operations are particularly easy to perform using superimposable scalars. 
For example, given an array of values 
C<@elems>, representing the elements of a set, 
the value C<$v> is an element of that set if:

        $v == any(@elems)

Note that this is equivalent to the definition of 
an eigenstate. That equivalence can be used to 
compute set intersections. Given two disjunctive superpositions, C<$s1=any(@elems1)>
and C<$s2=any(@elems2)>, representing two 
sets, the values that constitute the intersection 
of those sets must be eigenstates of both <$s1>
and C<$s2>. Hence:

        @intersection = eigenstates(all($s1, $s2));

This result can be extended to extract the 
common elements from an arbitrary number 
of arrays in parallel: 

        @common = eigenstates( all(     any(@list1),
                                        any(@list2),
                                        any(@list3),
                                        any(@list4),
                                  )
                     );

=head2 Factoring

Factoring numbers is also trivial using superpositions.
The factors of an integer N are all 
the quotients q of N/n (for all positive integers n < N) that are also integral. A positive 
number q is integral if floor(q)==q. Hence the factors of a given number are computed by:

        sub factors
		{
          my ($n) = @_;
          my $q = $n / any(2..$n-1);
          return eigenstates(floor($q)==$q);
        }

=head2 Query processing

Superpositions can also be used to perform 
text searches. 
For example, to determine whether a given string 
($target) appears in a collection of strings 
(@db):

        use Quantum::Superpositions BINARY => ["CORE::index"];

        $found = index(any(@db), $target) >= 0;

To determine which of the database strings 
contain the target:

        sub contains_str
		{
			return $dbstr if (index($dbstr, $target) >= 0;
        }

        $found = contains_str(any(@db), $target);
        @matches = eigenstates $found;

It is also possible to superimpose the target 
string, rather than the database, so as to 
search a single string for any of a set of targets:

        sub contains_targ
		{
                if (index($dbstr, $target) >= 0)
				{
                        return $target;
                }
        }

        $found = contains_targ($string, any(@targets)); 
        @matches = eigenstates $found;

or in every target simultaneously:

        $found = contains_targ($string, all(@targets));
        @matches = eigenstates $found;

=head1 AUTHOR

Damian Conway (damian@conway.org)

Now maintainted by Steven Lembark (lembark@wrkhors.com)

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in code this funky :-)
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

Copyright (c) 1998-2002, Damian Conway.
Copyright (c) 2002, Steven Lembark

All Rights Reserved.

This module is free software. It may be used, redistributed
and/or modified under the stame terms as Perl-5.6.1 (or later)
(see http://www.perl.com/perl/misc/Artistic.html).
