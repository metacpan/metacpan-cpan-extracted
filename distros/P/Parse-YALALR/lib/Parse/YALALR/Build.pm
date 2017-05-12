# -*- cperl -*-
# FYI: -*-mode: Lisp; fill-column: 75; comment-column: 50; -*-
#

BEGIN {
    $SIG{__WARN__} = sub { print STDERR shift; $DB::single = 1; };
};

package chain;
use fields qw(RULEIDX FIRSTLA);

package Parse::YALALR::Build;

use Parse::YALALR::Common;
use Parse::YALALR::Read;
use Parse::YALALR::Vector;
use Parse::YALALR::Kernel;
use Parse::YALALR::Parser;
use Carp;

# Load in the explanation extensions. The BEGIN {require} stuff is
# just to make it clear that this is not an independent module; it
# would work to say use instead.
BEGIN { require 'Parse/YALALR/Explain.pl'; };

use fields
  (parser => 

# Lookup tables
   item2state =>         # { stringified item ref => state that contains it }
   itemmap =>            # { "statenum_itemidx" => item }
   quickstate =>         # { 96-bit hash of kernel items in a state => state }

   FIRST =>              #
   nullable =>           # { nullable symbol }
   chainrules =>         # { A => { B => [ chainrules for A=>B ] }
                         #  chainrule : [ grammar_index for rule => vec(??) ]
# misc & unclassified
   why_nullable =>       #
   chainreachable =>     #
   chainfirst =>         #
   WHY_FIRST =>          #

   why =>                # Whether to compute the WHY information

   'temp_tokmap');       #

use strict;
use Carp qw(verbose croak);

# Parse::YALALR::Build::new
#
# Reads the grammar file (Parse::YALALR::Read::read), collects all the
# interesting information (Parse::YALALR::Build::collect_grammar), and
# then builds the parser (Parse::YALALR::Build::build)
#
sub new {
    my ($class, $lang, $data, %opts) = @_;
    $data = Parse::YALALR::Read->read($lang, $data)
      unless UNIVERSAL::isa($data, 'Parse::YALALR::Read');
#    print "Done reading at ".time."= t0+".(time-$::t0)."\n";
    $class = ref $class if ref $class;
    no strict 'refs';
    my Parse::YALALR::Build $self = bless [\%{"$class\::FIELDS"}], $class;
    $self->{why} = $opts{why};
    $self->{parser} = Parse::YALALR::Parser->new(%opts);
    $self->collect_grammar($data); # Remember to add START -> S
    $self->build();
    return $self;
}

sub parser ($) { $_[0]->{parser} }

sub build {
    my ($self) = @_;
    $self->compute_NULLABLE();
    $self->compute_FIRST();
    $self->compute_chainFIRSTs();
    $self->compute_chains(); # Change this to demand-driven?
    $self->generate_parser();
    return $self;
}

sub decide_token {
    my Parse::YALALR::Build $self = shift;
    my ($str) = @_;
    return 0 if ref $str;
    return 1 if defined $self->{temp_tokmap}->{$str};
    return 1 if $str =~ /^'/;
#    return 1 if $str =~ /^[A-Z_]+$/;
    return 0;
}

# collect_grammar
#
# INPUT:
# $data->{rules} : [ [ lhs, [ rhssym ], prec ] ]
#  - rhssym is a SCALAR ref if it's an action. deref to get perl code.
#    Will be blessed into <lang>CODE if normal code;
#    <lang>CONDITION if a conditional (<lang> is C or perl)
#  - prec is a symbol to inherit precedence from, or '<default>'
#
# OUTPUT:
# $self->{grammar} : array of all symbols in all rules, each separated by $nil
# $self->{code} : [ code_index => code_subroutine ]
# $self->{rule_code} : [ rulepos => code_subroutine ]
# $self->{ruletable} : [ nonterminal => [ grammar_index of lhs for rule ] ]
# $self->{epsilonrules}
# $self->{chainrules} : { A => { B => [ chainrules for A=>B ] }
#  chainrule : [ grammar_index for rule => vec(FIRST??) ]
# $self->{nonterminals} : [ symbol ]
# $self->{tokens} : [ symbol ]
# $self->{ntflag} : [ symbol => boolean (is symmap[symbol] a nonterminal?) ]
# $self->{precedence} : [ token => <precedence, associativity> ]
# $self->{rule_precedence} : [ rule => <precedence, associativity> ]
#
# All symbols are converted to indexes in $self->{symmap}, which is built
# as a side effect.
#
sub collect_grammar {
    my Parse::YALALR::Build $self = shift;
    my ($data) = @_;
    my $parser = $self->parser;

    my $nil = $parser->{nil};
    my $end = $parser->{end};
    my $error = $parser->{error};
    $parser->register_token('error');
    # Add the START -> S rule

    my $something;
    if (exists $data->{start_symbol}) {
	$something = $data->{start_symbol};
    } else {
	$something = $data->{rules}->[0]->[0];
    }
    unshift(@{$data->{rules}}, [ '<START>', [ $something ] ]);
    $parser->{startsym} = $parser->{symmap}->add_value('<START>');
    $parser->{startrule} = 1; # HACK

    foreach my $token (@{$data->{tokens}}) {
	$parser->register_token($token);
    }

    foreach my $precset (@{$data->{precedence}}) {
	foreach my $token (@{$precset->[1]}) {
	    $parser->register_token($token);
	    $parser->{symmap}->add_value($token);
	}
    }

    my @rules;
    my %rules; # { nt => [ rule ] }
    my @epsilonrules;
    my %chainrules;

    my @grammar;

    my @code;
    my $code_ctr = 0;

    my $i = 0;
    my %ruleprecs; # For rules with hardcoded %prec things
    for my $rule (@{$data->{rules}}) {
	 my ($lhs, $rhs, $prec) = @$rule;
	 my $istok = $self->decide_token($lhs);
	 $lhs = $parser->{symmap}->get_index($lhs);

	 my $rulepos = $i;
	 push(@rules, $rulepos);
	 push(@{$rules{$lhs}}, $rulepos);
	 $ruleprecs{$rulepos} = $prec;
	 $grammar[$i++] = $lhs;

	 $parser->{ntflag}->[$lhs] = !$istok;

	 my $epsilonrule_flag = 1;
	 foreach my $j (0..$#$rhs) {
	     my $sym = $rhs->[$j];
	     my $isnonterminal = ! $self->decide_token($sym);

	     if (ref $sym) {
		 print "SYM=$sym\n";
		 print "ref=".(ref $sym)."\n";
		 print "yes\n" if (scalar(ref $sym) =~ /^perl/);
		 if (scalar(ref $sym) =~ /^perl/) {
		     $sym = eval "sub { my \@v = \@_; $$sym; }";
		 } else {
		     $sym = sub { print STDERR "Unrunnable ".(ref $sym)." called\n" };
		 }

		 # Code
		 my $codesym = '@'.(++$code_ctr);
		 $code[$code_ctr] = $sym;
		 $parser->{rule_code}->{$rulepos} = $sym;
		 $sym = $parser->{symmap}->get_index($codesym);
		 $parser->{codesyms}->{$sym} = $codesym; # Used as boolean map

		 $isnonterminal = '(code)';
		 if ($j != $#$rhs) {
		     push(@{$data->{rules}}, [ $codesym, [ ] ]);
                 } else {
		     $parser->{end_action_symbols}->{$sym} = 1;
		     $parser->{ntflag}->[$sym] = $isnonterminal;
		     next;
		 }

	     } else {
		 $sym = $parser->{symmap}->get_index($sym);
		 $epsilonrule_flag = 0;
	     }

	     $grammar[$i++] = $sym;
	     $parser->{ntflag}->[$sym] = $isnonterminal;
	 }

	 push(@epsilonrules, $rulepos) if $epsilonrule_flag;

	 $grammar[$i++] = $nil;
    }

    # Must do this while we can still muck with the symmap
    $parser->{grammar} = \@grammar;
    $self->compute_precedence($data->{precedence}, \%ruleprecs);

    $parser->{nilvec} = $parser->{symmap}->make_onevec($nil);
    my $endvec = $parser->{symmap}->make_onevec($end);

    my $bogus;
    ($parser->{init_state}) =
      $self->fetch_or_create_state([ [ $parser->new_item(1, $endvec), undef ] ], undef);

    # Compute chainrules
    foreach my $rule (@rules) {
	my $lhs = $grammar[$rule];
	my $rhs0 = $grammar[$rule + 1];
	if ($parser->is_nonterminal($rhs0)) {
	    push(@{$chainrules{$lhs}->{$rhs0}}, bless [ \%chain::FIELDS,
							$rule,
							undef ], 'chain');
	}
    }

    # For debugging: describe how to print out chainrules
    $parser->register_dump('chain' => sub {
        my ($self, $chain, $asXML) = @_;
	$self->dump_rule($chain->{RULEIDX}, undef, $asXML)." F=".
	  $self->dump_symvec($chain->{FIRSTLA}, $asXML);
    });

    $parser->{code} = \@code;
    $parser->{rules} = \@rules;
    $parser->{rulenum} = { map { $rules[$_] => $_ } 0 .. $#rules };
    $parser->{ruletable} = \%rules; # { A => [ rule A -> ... ] }
    $parser->{epsilonrules} = \@epsilonrules;
    $self->{chainrules} = \%chainrules;
    $parser->{nonterminals} =
      [ grep { $parser->{ntflag}->[$_] } 0 .. $#{$parser->{ntflag}} ];
    $parser->{tokens} =
      [ grep { !$parser->{ntflag}->[$_] } 0 .. $#{$parser->{ntflag}} ];
}

# compute_precedence
#
# INPUT:
# $precinfo : [ precedence layer ]
# $hardcoded : { rule => symbol to inherit precedence from or "<default>" }
# precedence layer : <associativity, [tokens]>
# $parser->{grammar} : see above
#
# OUTPUT:
# $parser->{precedence} : [ token => <precedence, associativity> ]
# $parser->{rule_precedence} : [ rule => <precedence, associativity> ]
#
sub compute_precedence {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my ($precinfo, $hardcoded) = @_;

    # Grab out the info from the precedence declarations
    my $prec = 0;
    foreach my $preclayer (@$precinfo) {
	my ($assoc, $tokens) = @$preclayer;
	$assoc = 'none' if $assoc eq 'token';
	foreach my $token (@$tokens) {
	    $token = $parser->{symmap}->get_index($token);
	    $parser->{precedence}->[$token] = [ $prec, $assoc ];
#	    print "Token precedence($token) := $prec ($assoc)\n";
	}
    } continue {
	$prec++;
    };

    # Compute the rule precedences.
    # It is the precedence of the %prec token, if given. Otherwise it
    # is the precedence of the last terminal, if any. Otherwise it is
    # undefined.
    my $nil = $parser->{nil};
    my $rule;
    my $lastterm;
    for (my $i = 0; $i < @{$parser->{grammar}}; $i++) {
	my $sym = $parser->{grammar}->[$i];
	if ($sym == $nil) {
	    my $hard = $hardcoded->{$rule};
	    if (defined $hard && $hard ne '<default>') {
                my $p = $parser->{rule_precedence}->[$rule] =
		  $parser->{precedence}->[$parser->{symmap}->get_index($hard)];
	    } elsif (defined $lastterm) {
	        my $p = $parser->{rule_precedence}->[$rule] =
	          $parser->{precedence}->[$lastterm];
	    }
	    undef $rule;
	    undef $lastterm;
	} elsif (!defined $rule) {
	    $rule = $i;
	} else {
	    $lastterm = $sym if $parser->is_token($sym);
	}
    }
}

sub isdef {
    my %x = @_;
    while (my ($name, $val) = each %x) {
	print "$name is ", (defined $val ? 'defined' : 'undefined'), "\n";
    }
}

# method FIRST(vec1 vec2 vec3...)
#
# Returns a vector of FIRST(vec1 vec2 vec3...)
# Will include nil if all vectors contain nil.
#
sub FIRST {
    my $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my $nil = $parser->{nil};
    my $first = shift;
    if (ref $first) {
	croak("FIRST(ref ".(ref $first).") called");
    }

    my $second;
    while (vec($first, $nil, 1) && defined($second = shift)) {
	vec($first, $nil, 1) = 0; # Clear out the epsilon
	$first |= $second; # first will only contain nil if second has it
    }

    return $first;
}

# method FIRST_nonvec(A B C...)
#
# Returns a vector of FIRST(A B C...)
# where the arguments are symbols. Will include nil if all symbols given
# are nullable.
#
sub FIRST_nonvec {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my $A = shift;
    my $nil = $parser->{nil};
    my $nilvec = $parser->{nilvec};
    my $symmap = $parser->{symmap};

    return $nilvec if !defined $A;

    my $first;
    if ($parser->is_nonterminal($A)) {
	$first = $self->{FIRST}->{$A};
    } else {
	$first = $symmap->make_onevec($A);
    }

    my $next;
    while (vec($first, $nil, 1) && defined($next = shift)) {
	vec($first, $nil, 1) = 0; # Clear out the epsilon
	if ($parser->is_nonterminal($next)) {
	    $next = $self->{FIRST}->{$next};
	} else {
	    $next = $symmap->make_onevec($next);
	}
	$first |= $next;
    }

    return $first;
}

# Could a (small) n^2 be removed by computing all of these at once?
# Or are few asked for? (Guess so; doesn't show up in profiling)
sub get_first_nextalpha {
    my ($self, $I) = @_;
    return $self->FIRST_nonvec($self->parser->get_dotalpha($I->{GRAMIDX} + 1));
}

sub hidden_shift {
    my ($self, $rule, $first) = @_;
    return [ $rule + 1, $first ];
}

# fetch_or_create_state
#
# Args:
#  items: [ <generated item, source item> ]
#   The source item is the Real item; the generated item is just a holder
#   for the necessary information (specifically, a GRAMIDX and a lookahead set)
#   and that reference will never be used inside any real state.
#  source_state: The state that caused this set of items to be generated.
#
# $self->{quickstate} : [ item_ofs => state ]
# state : { id => id, items => [ item ],
#                     la_effects => [ items index => [ item ] ] }
# where item_ofs is the first item state->{items}->[0]
#
# la_effects is the set of outward edges from a kernel item to the
# kernel items of other states that the lookaheads should propagate to.
#
# Returns:
#  state in scalar context, <state,changes> in list context
#   - state is the state generated
#   - changes is undefined if the state was created from scratch,
#     otherwise a reference to a (probably empty) list of items
#     whose lookaheads changed
#
sub fetch_or_create_state {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my ($edges, $source_state) = @_;
    croak("must have at least one item") if @$edges == 0;

#    $DB::single = 1 if defined $source_state && $source_state->{id} == 4;

    # Canonicalize $edges -> @canon_items by removing duplicates

    # { GRAMIDX of generated item => lookahead for item }
    my %canon_items;

    # { GRAMIDX of generated item => [ causing item, la, lawhy ] }
    # lawhy : <'generated'|'propagated'|'epsilon-generated', causeidx, la>
    my %causes;

    # { GRAMIDX of generating item that propagates its lookaheads => boolean }
    my %propagating_cause;

    for my $edge (@$edges) {
	my ($item, $cause) = @$edge;

	if (defined $cause) {
	    my $cause_restla = $self->get_first_nextalpha($cause);
	    $propagating_cause{$cause->{GRAMIDX}} = 1
	      if vec($cause_restla, $parser->{nil}, 1);
	}

	my $idx = $item->{GRAMIDX};
	if (exists $canon_items{$idx}) {
	    $canon_items{$idx} |= $item->{LA};
	} else {
	    $canon_items{$idx} = $item->{LA};
	}

	if ($self->{why}) {
	    while (my ($la, $lawhy) = each %{$item->{LA_WHY}}) {
		push(@{$causes{$idx}}, [ $cause, $la, $lawhy ]);
	    }
	} else {
	    push(@{$causes{$idx}}, [ $cause ] );
	}
    }

    # 96-bit hash value
    # TODO: Compute a hash of the set of items in a state.
    # It would be nice if the hash were insensitive to the order
    # of items in the set. We don't need 96 bits if we do a pairwise
    # comparison to check for sure, but we could get away with a
    # simple hash -> state table instead of hash -> [ state ] if
    # we use lots of bits. (96 bits means less than 1 chance in a million
    # of getting a collision with 256,000 states. Assuming a truly random
    # hash function, which this is nowhere close to.)
    my $h1 = 0;
    my $h2 = 0;
    my $h3 = 0;

    # Order-independent hash
    {
	use integer;
	foreach (keys %canon_items) {
	    $h1 ^= (($_ + 1) * 149706587);
	    $h2 ^= (($_ + 1) * 4243838327);
	    $h3 ^= (($_ + 1) * 1347946109);
	}
    }

    my $hash = pack("LLL", $h1, $h2, $h3);
    my $fetched = $self->{quickstate}->{$hash};

    # Found it!
    if (defined $fetched) {

	for my $fitem (@{$fetched->{items}}) {

	    # Merge lookaheads
	    my $merge = $canon_items{$fitem->{GRAMIDX}};
	    $fitem->{LA} |= $merge;

	    # Add in the new edges to the item lookahead dependency graph
	    for my $cause (@{$causes{$fitem->{GRAMIDX}}}) {
		my ($src_item, $la, $lawhy) = @$cause;

		if ($self->{why}) {
		    push(@{ $src_item->{DESTS} }, $fitem);
		    push(@{ $fitem->{SOURCES} }, $src_item);
		    $DB::single = 1 if $fitem->{GRAMIDX} == 35;
		    if ($fetched != $source_state) {
			$fitem->{LA_WHY}->{$la} = $lawhy;
		    }
		}

		next if ! $propagating_cause{$cause->[0]->{GRAMIDX}};
		$lawhy->[1] = $src_item;
		$self->add_item_edge($source_state, $src_item,
				     $fetched, $fitem,
				     $la => $lawhy);
	    }
	}
	return ($fetched);
    }

    # Didn't find it, create a new state.

    # Create the items in the new state. These will be the Real items if
    # the state is new, otherwise, they're just stores for the information
    # to be merged into the fetched state.
    my @canon_items;
    while (my ($idx, $la) = each %canon_items) {
	push(@canon_items, bless [ \%item::FIELDS, $idx, $la ], 'item');
    }
    @canon_items = sort { $a->{GRAMIDX} <=> $b->{GRAMIDX} } @canon_items;
    # FIXME

    # Create the new state itself
    my $state = Parse::YALALR::Kernel->new($parser, \@canon_items);

    # Register each item in the kernel with the causing kernel item
    # in the source state.
    if (defined $source_state) {
	foreach my $item (@canon_items) {
	    foreach my $cause (@{$causes{$item->{GRAMIDX}}}) {
		my ($src_item, $la, $lawhy) = @$cause;

		if ($self->{why}) {
		    push(@{ $src_item->{DESTS} }, $item);
		    push(@{ $item->{SOURCES} }, $src_item);
		    $DB::single = 1 if $item->{GRAMIDX} == 35;
		    die if $item == $lawhy->[1];
		    $item->{LA_WHY}->{$la} = $lawhy;
		}

		# Check whether the source_state is A -> \alpha . X \beta,
		# where \beta is nullable. If so, any change in the lookaheads
		# of the source_state should be propagated to the state
		# being created.
		next unless $propagating_cause{$src_item->{GRAMIDX}};

		$lawhy->[1] = $src_item;
#		print STDERR "$src_item->{GRAMIDX}   $lawhy->[2]\n";
		$self->add_item_edge($source_state, $src_item,
				     $state, $item,
				     $la => $lawhy);
	    }
	}
    }

    if ($self->{why}) {
	# Fill in the map from GRAMIDX -> [ kernel item ]
	for my $item (@canon_items) {
	    push(@{ $parser->{items}->{$item->{GRAMIDX}} }, $item);
	}
    }

    $self->{quickstate}->{$hash} = $state;
    $parser->{states}->[$state->{id}] = $state;
    return ($state, 1);
}

sub compute_NULLABLE {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my $grammar = $parser->{grammar};
    my $nil = $parser->{nil};

    # { B => [ A, rule A -> B..., item A -> . B... ] }
    my %might_cause_nullable;
    foreach my $nt (@{$parser->{nonterminals}}) {
	$might_cause_nullable{$nt} = []; # Avoid @{undef}
    }

    # Set up the might_cause_nullable cache
  RULE: foreach my $rule (@{$parser->{rules}}) {
	my $item = $rule;
	next if $grammar->[$item + 1] == $nil;

	my $rhssym;
	while (($rhssym = $grammar->[++$item]) != $nil) {
	    next RULE if $parser->is_token($rhssym);
	}

	push(@{$might_cause_nullable{$grammar->[$rule + 1]}},
	     [ $grammar->[$rule], $rule, $rule + 1 ]);
    }

    # Go through the epsilon rules and set the immediately nullable ones,
    # but also push stuff on the queue
    my @mightq;
    my %nullable;
    my %why_nullable;
    foreach my $rule (@{$parser->{epsilonrules}}) {
	my $lhs = $grammar->[$rule];
	next if $nullable{$lhs};
	$nullable{$lhs} = 1;
	$why_nullable{$lhs} = $rule;
	push(@mightq, @{$might_cause_nullable{$lhs}});
	$might_cause_nullable{$lhs} = [];
    }

    foreach my $nulsym (keys %{ $parser->{end_action_symbols} }) {
	$nullable{$nulsym} = 1;
	$why_nullable{$nulsym} = "is an action";
	push(@mightq, @{$might_cause_nullable{$nulsym}});
	$might_cause_nullable{$nulsym} = [];
    }

    while (my $might = pop(@mightq)) {
	my ($nullcand, $rule, $dot) = @$might;
	next if $nullable{$nullcand};

	# Skip other nullable symbols
	++$dot;
	++$dot while ($grammar->[$dot] != $nil && $nullable{$grammar->[$dot]});

	# If still some non-nullable symbols left, put it back on the
	# might_cause_nullable map.
	if ($grammar->[$dot] != $nil) {
	    push(@{$might_cause_nullable{$grammar->[$dot]}},
		 [ $nullcand, $rule, $dot ]);
	} else {
	    # Found new nullable symbol! Push its stuff onto the list
	    my $nulledsym = $grammar->[$rule];

	    # Now wait a minute! We might have already figured this out from
	    # something else on the list! (Stupid kids...)
	    if (!$nullable{$nulledsym}) {
		$nullable{$nulledsym} = 1;
		$why_nullable{$nulledsym} = $rule;
		push(@mightq, @{$might_cause_nullable{$nulledsym}});
		$might_cause_nullable{$nulledsym} = [];
	    }
	}
    }

    $self->{nullable} = \%nullable;
    $self->{why_nullable} = \%why_nullable if $self->{why};
}

sub nullable_vec {
    my ($self, $vec) = @_;
    return vec($vec, $self->{nullable}, 1);
}

# optimize by keeping only one A goesto B rule.
sub compute_FIRST {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my $grammar = $parser->{grammar};
    my $nullable = $self->{nullable};
    my $nil = $parser->{nil};

    # WHY_FIRST : { A => { t => <rule,reason,?parent> } } 
    # where reason : 'nullable'|'propagated'
    #
    # reason = 'nullable':
    #   t is in FIRST(A) because rule A : \a1 t \a2 and NULLABLE(\a1)
    # reason = 'propagated', parent = B
    #   t is in FIRST(A) because rule A : \a3 B \a4
    #     and NULLABLE(\a3) and t is in FIRST(B)
    #
    my %WHY_FIRST;
    my %FIRST;

    my $add_to_first = sub {
	my ($sym, $tok, $rule, $parent) = @_;
	$FIRST{$sym} = "" if !defined $FIRST{$sym};
	vec($FIRST{$sym}, $tok, 1) = 1;
	if ($self->{why}) {
	    if (defined $parent) {
		my $reason = ($tok == $parent) ? 'nullable' : 'propagated';
		$WHY_FIRST{$sym}->{$tok} = [ $rule, $reason, $parent ];
#		print "Set WHY_FIRST{".$parser->dump_sym($sym)."=>{".$parser->dump_sym($tok)."=> <".$parser->dump_rule($rule).",$reason,".$parser->dump_sym($parent).">}}\n";
	    } else {
		$WHY_FIRST{$sym}->{$tok} = [ $rule ];
	    }
	}
    };

    # Initialize FIRST of all nonterminals to the empty set. This
    # isn't used below, but will eliminate uses of undefined values
    # later.

    foreach my $sym (@{$parser->{nonterminals}}) {
	$FIRST{$sym} = '';
    }

    # Set up the goesto graph.
    # goesto{A} = [ B -> \alpha . A \beta ] means that
    # FIRST(B) \contains FIRST(A) because \alpha is nullable.

    my %goesto;
    foreach my $rule (@{$parser->{rules}}) {
	my $item = $rule + 1;
	while ($grammar->[$item] != $nil) {
	    my $sym = $grammar->[$item++];
	    push(@{$goesto{$sym}}, $rule);
	    last if $parser->is_token($sym) || !$nullable->{$sym};
	}
    }

    # Foreach token, do a BFS of the goesto graph, propagating the
    # token to the FIRST sets of everything reached.
    #
    # Default all WHY_FIRSTs to 'propagated'
    for my $tok (@{$parser->{tokens}}) {
	my %visited;
	my @queue;
	push(@queue, \$tok); # Push a marker on
	push(@queue, @{$goesto{$tok}}) if defined $goesto{$tok};
	my $parent;
	while (defined(my $x = shift(@queue))) {
	    if (ref $x) {
		$parent = $$x;
	    } else {
		my $rule = $x;
		my $sym = $grammar->[$rule];
		if (!$visited{$sym}) {
		    $visited{$sym} = 1;
		    $add_to_first->($sym, $tok, $rule, $parent);
		    if (defined $goesto{$sym}) {
			push(@queue, \$sym);
			push(@queue, @{$goesto{$sym}})
		    }
		}
	    }
	}
    }

    # epsilons need to be in FIRST sets also. But they're trivial
    # with NULLABLE.
    if ($self->{why}) {
	foreach (keys %$nullable) {
	    $add_to_first->($_, $nil, $self->{why_nullable}->{$_});
	}
    } else {
	foreach (keys %$nullable) {
	    $add_to_first->($_, $nil);
	}
    }

    $self->{FIRST} = \%FIRST;
    $self->{WHY_FIRST} = \%WHY_FIRST;
}

# Chain rules
#
# $self->{chainrules} = { A => { B => [ <A -> B \alpha,FIRST(\alpha)> ] } }
#
# INCORRECT:
# $self->{chainreachable} = { A => { B => [ <X -> B \beta2, FIRST(\beta1)> ] }}
#   where A ->* X \beta1
#         X -> B \beta2 (\beta1 is the accumulation of symbols required to
#                        reach X, which produces B)
#
# CORRECT: See the description later
#


# $self->{chainrules} = { nt_A => { nt_B => [ < rule, first > ] } }
# aka { A => { B => [ < A -> B \alpha, FIRST(\alpha) > ] } }

# Should really convert this to on-demand someday, too
sub compute_chainFIRSTs {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my $grammar = $parser->{grammar};
    my $chainrules = $self->{chainrules};
    my $nil = $parser->{nil};

    foreach my $X (values %$chainrules) {
	foreach my $cruleset (values %$X) {
	    foreach my $crule (@$cruleset) {

		# Point to B in A -> B x y z, will incr to x before using
		my $i = $crule->{RULEIDX} + 1;

		my @rhs;
		while ($grammar->[++$i] != $nil) {
		    push(@rhs, $grammar->[$i]);
		}
		$crule->{FIRSTLA} = $self->FIRST_nonvec(@rhs);
	    }
	}
    }
}

# chainreachable: {A => {B => rule} } means A ->* B \alpha, where
# no nonterminals died to get to B \alpha (== last rule in leftmost
# derivation was not epsilon rule, so no A -> C B x -> B x). The rule
# given is just some rule C -> B \beta, where C is reachable from A
# in zero or more steps. Mostly used as a boolean flag, but can be
# helpful for why.
#
# chainfirst: {A => {B => firstvec} } means firstvec is the union of the
# FIRST of all \alpha in A ->* B \alpha (no nonterminals die). It will
# be used for expanding X -> something1 . A something2, f1: this generates
# B -> ..., FIRST(\beta something2 f1) when A ->* B \beta (no dead nts).
#
sub compute_chain {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my ($A) = @_;
    my $chainrules = $self->{chainrules};

    my @todo;
    my %chainreachable;
    my %first;

    my $nullfs = $parser->{symmap}->make_nullvec;

    push(@todo, $A);
    while (my $X = pop(@todo)) {
	my $pushed = 0;
	foreach my $B (keys %{$chainrules->{$X}}) {
	    if (!exists $chainreachable{$B}) {
		$chainreachable{$B} = $chainrules->{$X}{$B}->[0]->{RULEIDX};
		push(@todo, $B);
		$pushed = 1;
	    }

	    my $oldfs = $first{$B} || $nullfs;
	    foreach my $crule (@{$chainrules->{$X}{$B}}) {
		my $propfs = $self->FIRST($crule->{FIRSTLA}, $first{$X});
		my $newfs = $propfs | $oldfs;
                if (($newfs & ~$oldfs) !~ /^\0*$/s) {
		    $first{$B} = $newfs;
		    push(@todo, $B) unless $pushed;
		    $pushed = 1;
		    # why_chain_la(A)(B)(propfs & ~oldfs) = crule->{RULEIDX}
		}
	    }
	}
    }

    $self->{chainreachable}->{$A} = \%chainreachable;
    $self->{chainfirst}->{$A} = \%first;
}

# This function should go away someday
sub compute_chains {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    foreach my $nt (@{$parser->{nonterminals}}) {
	$self->compute_chain($nt);
    }
}

# generate_parser
#
# Main entry point for creating a parser. Uses a bunch of precomputed data.
#
# Algorithm:
# Do a BFS creation of the state graph
# For each state (== kernel) during the BFS construction
#     Foreach item in the kernel
#         If it's a reduce, call add_reduce(kernel, lhs symbol, lookahead)
#         If it's A => \a1 . t \a2, push(shifto[t], new kernel)
#         If it's A => \a1 . B \a2, do the same as above,
#          but also handle everything reachable from B => . \a3 (see below)
#     Scan through the complete shifto sets and fetch or create the new
#      kernel resulting from the shift (I'm including both terminals
#      and nonterminals in shifto, as usual).
#     If the kernel is new, enqueue it.
#     The lookaheads for the reduces are tricky. SEE BELOW.
#
# The tricky part is handling the implicit kernel expansion. We have
# A => \a1 . B \a2, f1 (f1 is the lookahead)
#
# Let f2 = FIRST(\a2 with lookahead f1)
#
# Do a simple reduce|shift action, as above, for all rules
# B => \a3, f2
#
# Then, foreach X such that B =>+ X \a4 (use $self->{chainreachable} to find),
#  let f = FIRST(\a4 f2) (FIRST(\a4) is $self->{chainfirst})
#  Do the reduce|shift actions for each rule X -> \a5, using f as the lookahead
#
# To illustrate, we have something like:
# A => \a1 . B \a2, f1
# B => . X \a4, f2=FIRST(\a2 f1)
# X => \a5, FIRST(\a4 f2)
#
# (in general, B =>* . X \a4)
#
sub generate_parser {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my $grammar = $parser->{grammar};
    my $nil = $parser->{nil};
    my $nilvec = $parser->{nilvec};

    my %epsilon_items; # state id => [ generated item X -> . ]

    my @kq;
    push(@kq, $parser->{init_state}); # START -> . S, $;

    while (defined(my $K = pop(@kq))) {
	my @epsilon_items;

	my %shifto; # { symbol => [ item ] }
	my %shifto_why; # { symbol => <item,reason> }

      KERNEL_ITEM:
	foreach my $I (@{$K->{items}}) {
	    my $next = $parser->get_dot($I);
	    # If rule is A -> \a1 . then add a reduce and go to the next item
	    if ($next == $nil) {
		# Off end. Reduce.
                my $lhs = $I->{GRAMIDX};
		# Find symbol to reduce to
		while ($lhs > 0 && $grammar->[$lhs - 1] != $nil) { $lhs--; }
		# FIXME: Add assertion that kernel item is not A -> .
		$parser->add_reduce($K, $lhs, $I->{LA}, $I, 'kernel');
		next KERNEL_ITEM;
	    }

	    # Nope, so rule is A -> \a1 . X \a2
	    my $I2 = $parser->get_shift($I);
	    push(@{$shifto{$next}}, [ $I2, $I ]);
	    $DB::single = 1 if $I2->{GRAMIDX} == 35;
	    $I2->{LA_WHY}->{$I->{LA}} = [ 'propagated', $I ]
	      unless $I2->{GRAMIDX} == $I->{GRAMIDX};
	    $shifto_why{$next} = [ $I2, 'kernel' ];

	    # If X is a terminal, no need to expand
	    next KERNEL_ITEM if $parser->is_token($next);

	    # In fact, rule is A -> \a1 . B \a2, f1 (B is nonterminal)
	    # Oh boy. Chain rules.
	    my $B = $next; # Just renaming
	    my $f1 = $parser->get_la($I);
	    my $a2 = $self->get_first_nextalpha($I);
	    my $F_a2_f1 = $self->FIRST($a2, $f1);

	    # $item_prop is the item to blame for lookaheads in the
	    # reduces that will be added. It's just $I or undef. We'll
	    # undef it as soon as we hit something non-nullable.
	    my $item_prop = $I;
	    undef $item_prop if !$self->nullable_vec($a2);

	    # First, handle the rules for B (if B ->+ B..., then we'll
	    # visit B again in the following loop, but for now we
	    # just want B -> . \a3, FIRST(\a2 f1))
	    foreach my $rule ($parser->get_rules($B)) {
		my $x = $grammar->[$rule+1];

		if ($x == $nil) {
		    my $eI = $parser->make_item($rule, 0, $F_a2_f1);
	    $DB::single = 1 if $eI->{GRAMIDX} == 35;
		    $eI->{LA_WHY}->{$F_a2_f1} =
		      [ 'epsilon-generated', $I, $parser->{nilvec}, $a2 ]
		        unless $eI->{GRAMIDX} == $I->{GRAMIDX};
		    push(@epsilon_items, $eI);
		    $parser->add_reduce($K, $rule, $F_a2_f1, $I, 'chained');
		} else {
		    # I2 := B -> . \a3, FIRST(\a2 f1)
		    my $I2 = $parser->make_shift($rule + 1, $F_a2_f1);
		    push(@{$shifto{$x}}, [ $I2, $I ]);
	    $DB::single = 1 if $I2->{GRAMIDX} == 35;
		    $I2->{LA_WHY}->{$F_a2_f1} = [ 'generated', $I, $a2 ]
		      unless $I2 == $I;
		    # Don't use this explanation if there's a simpler
		    if ($self->{why} && !defined $shifto_why{$x}) {
			$shifto_why{$x} = [ $I2, 'chained', $rule + 1 ];
		    }
		}
	    }

	    foreach my $X (keys %{$self->{chainreachable}{$B}}) {
		# f3 = FIRST(everything up to just before \a2)
		my $f3 = $self->{chainfirst}->{$B}{$X} || $nilvec;
		my $f = $self->FIRST($f3, $F_a2_f1);
		# undefine $item_prop if FIRST(f3 a2) doesn't contain
		# epsilon. It'll already be undef if a2 is not
		# nullable, so just test f3
		undef $item_prop if !$self->nullable_vec($f3);
		foreach my $rule ($parser->get_rules($X)) {
		    my $x = $grammar->[$rule+1];

		    if ($x == $nil) {
			my $eI = $parser->make_item($rule, 0, $f);
	    $DB::single = 1 if $eI->{GRAMIDX} == 35;
			$eI->{LA_WHY}->{$f} =
			  [ 'epsilon-generated', $I, $f3, $a2 ]
			    unless $eI->{GRAMIDX} == $I->{GRAMIDX};

			push(@epsilon_items, $eI);
			$parser->add_reduce($K, $rule, $f, $I, 'chained');
		    } else {
			my $I2 = $parser->make_shift($rule + 1, $f);
			push(@{$shifto{$x}}, [ $I2, $I ]);
	    $DB::single = 1 if $I2->{GRAMIDX} == 35;
			$I2->{LA_WHY}->{$f} = [ 'chain-generated', $I, $f3, $a2 ]
			  unless $I2->{GRAMIDX} == $I->{GRAMIDX};

			# Don't use this explanation if there's a simpler
			if ($self->{why} && !defined $shifto_why{$x}) {
			    $shifto_why{$x} = [ $I2, 'chained', $self->{chainreachable}{$B}{$X} + 1 ];
			}
		    }
		}
	    }
	} # foreach item I in kernel K

	# Merge epsilon items with the same core
	my %canonical; # { GRAMIDX => item }
	for my $item (@epsilon_items) {
	    if (exists $canonical{$item->{GRAMIDX}}) {
	    } else {
	    }
	}

	$epsilon_items{$K->{id}} = \@epsilon_items;

	# Create all the new states and add shift actions
	while (my ($sym, $edges) = each %shifto) {
	    my ($K2, $new) = $self->fetch_or_create_state($edges, $K);
	    $parser->add_shift($K, $sym, $K2);
            $K->{SHIFT_WHY}->{$sym} = $shifto_why{$sym}
              if $self->{why};

	    # Stick new states in the queue
	    push(@kq, $K2) if $new;
	}
    }

    $self->create_item2state_map() if $self->{why};
    $self->effects_to_causes() if $self->{why};
    $self->propagate_lookaheads();
    $self->create_reduces();
}

sub add_item_edge {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my ($K0, $I0, $K1, $I1, $la, $reason) = @_;
    $I0->{EFFECTS}->{$I1} = $I1;
    $I1->{LA_WHY}->{$la} ||= $reason
      if $self->{why} && $I0 != $I1;
}

sub propagate_lookaheads {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};

    # Start out search with all kernel items
    my @Q = map { @{$_->{items}} } @{$parser->{states}};

    # Keep track of what's already in the queue to avoid adding duplicates
    my %Q = map { $_ => 1 } @Q;

    # Keep propagating changes until equilibrium is reached
    while (my $change = shift(@Q)) {
	delete $Q{$change};
#	print "Propagating $change->{GRAMIDX}...\n";
	foreach (values %{$change->{EFFECTS}}) {
	    (my $newla = $_->{LA}) |= $change->{LA};
	    if ($newla ne $_->{LA}) {
		if ($self->{why}) {
		    my $changela = $newla ^ $_->{LA};
		    $DB::single = 1 if (vec($changela, $parser->{end}, 1) && $_->{GRAMIDX} == 27);
		    if ($change->{GRAMIDX} + 1 == $_->{GRAMIDX}) {
			$_->{LA_WHY}{$changela} = [ 'propagated', $change ]
			  unless $_->{GRAMIDX} == $change->{GRAMIDX};
		    } else {
			$_->{LA_WHY}{$changela} = [ 'generated', $change ]
			  unless $_->{GRAMIDX} == $change->{GRAMIDX};
		    }
		}
		$_->{LA} = $newla;
		if (!exists $Q{$_}) {
		    push(@Q, $_);
		    $Q{$_} = 1;
		}
            }
	}
    }
}

# Update all reductions given the current lookaheads of the items they
# depend upon.
sub create_reduces {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    for my $K (@{$parser->{states}}) {
	for my $rinfo (@{$K->{reduces}}) {
            my ($la, $rule, $parent) = @$rinfo;
            if ($parent) {
                $rinfo->[0] |= $parent->{LA};
                if ($self->{why} && $rinfo->[0] ne $la) {
                    $K->{REDUCE_WHY}->{$la ^ $rinfo->[0]} =
                      [ $rule, $parent, 'propagated' ];
                }
            }
	}
    }
}

sub resolve_rr {
    my ($self, $state, $sym, $old, $new) = @_;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my $id = $state->{id};

    my $prec1 = $parser->{rule_precedence}->[$old->[0]];
    my $prec2 = $parser->{rule_precedence}->[$new];

    if (defined $prec1 && defined $prec2 && $prec1->[0] != $prec2->[0]) {
	print "Precedence resolved reduce/reduce conflict in state $id on token ", $parser->dump_sym($sym), ": ";
	if ($prec1->[0] < $prec2->[0]) {
	    print $parser->dump_rule($old->[0])."\n";
	    return $old;
	} else {
	    my $grammar = $parser->{grammar};
	    print $parser->dump_rule($new)."\n";
	    return bless [ $new, $grammar->[$new], $parser->rule_size($new) ],
	                 'reduce';
	}
    } else {
	print "Arbitrarily resolved reduce/reduce conflict in state $id on token ", $parser->dump_sym($sym), ": ",
	  $parser->dump_rule($old->[0]), "\n";
	return $old;
    }
}

sub resolve_sr {
    my ($self, $state, $sym, $old, $new) = @_;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my $id = $state->{id};

    my $prec1 = $parser->{precedence}->[$sym];
    my $prec2 = $parser->{rule_precedence}->[$new];

#    print "RESOLVING shift $sym vs rule $new\n";

    my $grammar = $parser->{grammar};
    my $reduce_rule = bless [ $new, $grammar->[$new], $parser->rule_size($new) ],
                            'reduce';

    if (defined $prec1 && defined $prec2) {
	if ($prec1->[0] != $prec2->[0]) {
	    print "Precedence resolved shift/reduce conflict in state $id on token ", $parser->dump_sym($sym), ": ";
	    if ($prec1->[0] < $prec2->[0]) {
		print $parser->dump_action($old)."\n";
		return $old;
	    } else {
		my $grammar = $parser->{grammar};
		print $parser->dump_rule($new)."\n";
		return $reduce_rule;
	    }
	}

	if ($prec1->[1] eq 'left') {
	    print "Left associativity resolved shift/reduce conflict in state $id on token ", $parser->dump_sym($sym), ": reduce\n";
	    return $reduce_rule;
	} elsif ($prec1->[1] eq 'right') {
	    print "Right associativity resolved shift/reduce conflict in state $id on token ", $parser->dump_sym($sym), ": shift\n";
	    return $old;
	} elsif ($prec1->[1] eq 'nonassoc') {
	    print "Nonassociative operator, resolved shift/reduce conflict in state $id on token ", $parser->dump_sym($sym), ": error\n";
	    return undef;
	} else {
	    die "What the hell is this?: $prec1->[1]";
	}
    }

    print "Arbitrarily resolved shift/reduce conflict in state $id on token ", $parser->dump_sym($sym), ": ",
      $parser->dump_action($old), "\n";
    print " (prec of ".$parser->dump_sym($sym)." is $prec1->[0] ($prec1->[1]))\n"
      if defined $prec1;
    print " (prec of rule is $prec2->[0] ($prec2->[1]))\n"
      if defined $prec2;
    return $old;
}

sub resolve {
    my ($self, $state, $sym, $old, $new) = @_;
    my Parse::YALALR::Parser $parser = $self->{parser};
    if ($old->[0] eq 'reduce' && $new->[0] eq 'reduce') {
	return $self->resolve_rr($state, $sym, $old->[1], $new->[1]);
    } elsif ($old->[0] eq 'shift' && $new->[0] eq 'reduce') {
	return $self->resolve_sr($state, $sym, $old->[1], $new->[1]);
    } else {
	return $self->resolve_sr($state, $sym, $new->[1], $old->[1]);
    }
}

# build_table
#
# INPUT:
# $self->{states} : [ state ]
# state : { 'id' => state number,
#           'shifts' => { symbol => to_state },
#           'reduces' => { lookahead => rule : grammar_index },
#         }
#
# OUTPUT:
# $self->{states}[i]{actions} : [ symbol => shiftact|reduceact ]
# (equiv, the above state += { 'actions' => [ symbol => shiftact|reduceact ] })
# shiftact : to_state
# reduceact : [ rule, lhs, number of elts in rhs ] : 'reduce'
#
sub build_table {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    foreach my $state (@{$parser->{states}}) {
	my @actions;
	my $id = $state->{id};
	while (my ($sym, $dest) = each %{$state->{shifts}}) {
	    $actions[$sym] = $dest;
	}

	foreach (@{$state->{reduces}}) {
	    my ($la, $rule, $item) = @$_;
	    foreach my $sym ($parser->{symmap}->get_indices($la)) {
		if (defined $actions[$sym]) {
		    if (ref $actions[$sym] eq 'reduce') {
			if ($actions[$sym]->[0] != $rule) {
			    $actions[$sym] =
			      $self->resolve($state, $sym,
					     [ 'reduce', $actions[$sym] ],
					     [ 'reduce', $rule ]);
			    next;
			} # else no conflict
		    } else {
			$actions[$sym] =
			  $self->resolve($state, $sym,
					 [ 'shift', $actions[$sym] ],
					 [ 'reduce', $rule ]);
			next;
		    }
		}

		my $sz_rhs = $parser->rule_size($rule);
		my $lhs = $parser->{grammar}->[$rule];
		$actions[$sym] = bless [ $rule, $lhs, $sz_rhs ], 'reduce';
	    }
	}

	$state->{actions} = \@actions;
    }
}

1;
