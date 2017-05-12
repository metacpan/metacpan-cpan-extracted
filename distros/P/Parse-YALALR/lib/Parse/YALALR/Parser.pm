# -*- cperl -*-
# FYI: -*-mode: Lisp; fill-column: 75; comment-column: 50; -*-
#

# Design of conditionals:
# Parser reads code as either {: ... :} or {? ... ?}. The latter case is a
# conditional. (future extension: {c: ... :} vs {perl: ... :})
# When a conditional is read, it is replaced with a dummy token. Any state
# containing a rule A -> \alpha . DUMMY \beta is flagged as special
# (action is multi? yes, that would correctly disambiguate based on lookahead
# before falling back to checking the conditional.) All conditionals valid
# for the observed lookahead are executed in an arbitrary order. One of the
# true ones (but do not short circuit! unless order becomes not arbitrary)
# gets its DUMMY token shifted. If multiple are true, issue a warning or
# maybe user-configurably abort or go to error recovery. If none are true,
# pretty much the same, though the default should probably then be error
# recovery.
#
# DUMMY tokens are considered nullable for the purposes of FIRST computation
# (??). They are allowed at the beginning of the RHS (?). Should code be
# allowed there too? I suppose. Run all of it, again in an arbitrary order.

#  BEGIN {
#      $SIG{__WARN__} = sub { print STDERR shift; $DB::single = 1; };
#  };

package item;
use fields qw(GRAMIDX LA EFFECTS LA_WHY CAUSES SOURCES DESTS);

package Parse::YALALR::Parser;

use Parse::YALALR::Common;
use Parse::YALALR::Vector;
use Parse::YALALR::Kernel;

# Load in the dumping extensions. The BEGIN {require} stuff is just
# to make it clear that this is not an independent module; it would
# work to say use instead.
BEGIN { require 'Parse/YALALR/Dump.pl'; };

use fields
# Major overarching things
  (grammar =>            # array of symbols in all rules, separated by nils
   symmap =>             # Parse::YALALR::Vector

# Fundamental data
   states =>             # [ state id => state ]
   nstates =>            # integer (number of states)
   rules =>              # [ rule number => grammar index of rule ]
   items =>              # { grammar index -> [ item w/ same gramidx ] }
   nonterminals =>       # [ symbol ]
   tokens =>             # [ symbol ]
   precedence =>         # [ token => <precedence, associativity> ]
   rule_code =>          # [ rulepos => code_subroutine ]

# Fundamental computed data
   ruletable =>          # [ nonterminal => [ grammar_index of lhs for rule ] ]
   rule_precedence =>    # [ rule => <precedence, associativity> ]

# Lookup tables
   rulenum =>            # { grammar index of rule => rule number }

# Attributes of data
   codesyms =>           # [ symbol ]
   code =>               # [ code_index => code_subroutine ]
   epsilonrules =>       # [ grammar index of rule X -> /*empty*/ ]
   end_action_symbols => # { symbol '@n' from converting A -> x {...} to
                         #   A -> x @n and @n -> /*empty*/ }

# Silly singletons
   nil =>                # symbol
   end =>                # symbol
   error =>              # symbol
   startsym =>           # symbol
   startrule =>          # rule START -> (start symbol)
   nilvec =>             # vec
   init_state =>         # state START -> . (start symbol), $

# misc & unclassified
   ntflag =>             # [ symbol => boolean ]

   dump_format =>        # default format (undef or 'xml') for dump()

   'temp_tokmap');       #

use strict;
use Carp qw(verbose croak);

sub new {
    my ($class, %opts) = @_;

    no strict 'refs';
    my Parse::YALALR::Parser $self = bless [\%{"$class\::FIELDS"}], $class;
    $self->{nstates} = 0;

    my $symmap = $self->{symmap} = Parse::YALALR::Vector->new;
    $self->{nil} = $symmap->add_value('<nil>');
    $self->{end} = $symmap->add_value('<end>');
    $self->{error} = $symmap->add_value('error');

    return $self;
}

sub register_token {
    my Parse::YALALR::Build $self = shift;
    my ($token) = @_;
    $self->{temp_tokmap}->{$token} = 1;
}

sub new_item {
    my ($self, $item, $la) = @_;
    return bless [ \%item::FIELDS, $item, $la ], 'item';
}

sub get_rule {
    my ($self, $item) = @_;
    $item = $item->{GRAMIDX} if (ref $item);
    my $grammar = $self->{grammar};
    my $nil = $self->{nil};
    --$item while ($item && ($grammar->[$item-1] != $nil));
    return $item;
}

sub get_rules {
    my ($self, $A) = @_;
    my $set = $self->{ruletable}->{$A};
    return defined $set ? @$set : ();
}

sub get_chains {
    my ($self, $A, $B) = @_;
    my $chains = $self->{chainrules}->{$A}->{$B};
    return defined $chains ? @$chains : ();
}

# integer var: 17usec/incr
# vector var: 24usec/incr
# array var: 18usec/incr
# hash var: 43usec/incr

# changing index
# array var: 71usec/incr
# vector var: 85usec/incr
# hash var: 91usec/incr

#sub epsilon_rule {
#    my ($self, $rule) = @_;
#    return vec($self->{grammar}, $rule+1, 32) == $self->{nil};
#}

# Returns
#   undef if a CODE symbol
#   0 if a nonterminal
#   1 if a terminal
sub is_token {
    my Parse::YALALR::Parser $self = shift;
    my ($sym) = @_;
    return ! $self->{ntflag}->[$sym];
}

sub is_nonterminal {
    my Parse::YALALR::Parser $self = shift;
    my ($sym) = @_;
    return $self->{ntflag}->[$sym];
}

sub is_codesym {
    my Parse::YALALR::Parser $self = shift;
    my ($sym) = @_;
    return exists $self->{codesyms}->{$sym};
}

sub get_dot {
    my Parse::YALALR::Parser $self = shift;
    my ($I) = @_;
    return $self->{grammar}->[$I->{GRAMIDX}];
}

sub get_shift {
    my Parse::YALALR::Parser $self = shift;
    my ($I) = @_;
    croak("shifted off end of item")
      if $self->{grammar}->[$I->{GRAMIDX}] == $self->{nil};
    return $self->make_shift($I->{GRAMIDX}, $I->{LA});
}

sub make_shift {
#    return bless [ \%item::FIELDS,
#		   $_[1] + 1, $_[2]
#		 ], 'item';

    my Parse::YALALR::Parser $self = shift;
    my ($item, $first) = @_;
    croak("bad thing")
      if $self->{grammar}->[$item] == $self->{nil};
    return bless [ \%item::FIELDS,
		   $item + 1, $first
		 ], 'item';
}

sub get_dotalpha {
    my ($self, $item) = @_;
    my $grammar = $self->{grammar};
    my $nil = $self->{nil};

    my @alpha;
    while ($grammar->[$item] != $nil) {
	push(@alpha, $grammar->[$item++]);
    }

    return @alpha;
}

sub get_la {
    my ($self, $I) = @_;
    return $I->{LA};
}

sub get_item_lhs {
    my ($self, $I) = @_;
    my $grammar = $self->{grammar};
    my $nil = $self->{nil};

    my $rule = $I->{GRAMIDX};
    while ($rule > 0 && $grammar->[$rule - 1] != $nil) { $rule--; }

    return $self->{grammar}->[$rule];
}

# make_item
#
# INPUT:
# $rule : grammar_index of rule
# $pos : position of . within rule
# $first : FIRST set
#
# OUTPUT:
# [ GRAMIDX, LA ] : item
# GRAMIDX : grammar_index of symbol just past $pos for $rule
# LA : Lookahead set of tokens
#
sub make_item {
    my Parse::YALALR::Parser $self = shift;
    my ($rule, $pos, $first) = @_;
    if ($pos < 0) {
	my $nil = $self->{nil};
	my $grammar = $self->{grammar};
	while ($grammar->[$rule] != $nil) { $rule++; }
    }
    return bless [ \%item::FIELDS, $rule + $pos + 1, $first ], 'item';
}

sub add_shift {
    my ($self, $K, $sym, $K2) = @_;
    $K->{shifts}->{$sym} = $K2->{id};
}

# $self->{reduces} : [ <lookahead, rule, parent item> ]
sub add_reduce {
    my ($self, $K, $rule, $la, $parent, $reason) = @_;
    # REASON is ignored
    push(@{$K->{reduces}}, [ $la, $rule, $parent ]);
    $K->{REDUCE_WHY}->{$la} = [ $rule, $parent, 'generated' ];
}

sub rule_size {
    my ($self, $rule) = @_;
    my $i = 0;
    while ($self->{grammar}->[$rule + $i + 1] != $self->{nil}) { $i++; };
    return $i;
}

sub stats {
    my Parse::YALALR::Parser $self = shift;
    my $str = '';
    $str .= "Number of states: $self->{nstates}\n";
    $str .= "Number of terminals: " . (0+@{$self->{tokens}}) . "\n";
    $str .= "Number of nonterminals: " . (0+@{$self->{nonterminals}}) . "\n";
    $str .= "Number of rules: " . (0+@{$self->{rules}}) . "\n";
    return $str;
}

1;
