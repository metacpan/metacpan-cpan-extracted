#line 1

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

