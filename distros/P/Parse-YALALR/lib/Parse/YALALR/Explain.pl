# This is really a -*- cperl -*- extension package to Parse::YALALR::Build

package Parse::YALALR::Build;
use Parse::YALALR::Common;
use strict;

######################## EXPLANATIONS ###########################

sub effects_to_causes {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;

    for my $cause (map { @{$_->{items}} } @{$parser->{states}}) {
	for my $effect (values %{$cause->{EFFECTS}}) {
	    push(@{$effect->{CAUSES}}, $cause);
	}
    }
}

# Explain why $symbol ->* B, where $item is B -> \alpha (with a dot somewhere)
sub explain_sym_chain {
    my Parse::YALALR::Build $self = shift;
    my ($symbol, $item, $asXML) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;
    my $nil = $parser->{nil};

#    print "Called explain_sym_chain(".$parser->dump_sym($symbol).", ".$parser->dump_item($item)."\n";

    my @chain;

    return undef if ($parser->is_token($symbol));
    my $target;
    while (1) {
	--$item while ($parser->{grammar}[$item] != $nil);
	$item++;
	my $target = $parser->{grammar}[$item];
	push(@chain, $parser->dump_item($item+1, $asXML));
	last if ($symbol == $target);
	$item = $self->{chainreachable}{$symbol}{$target};
	return undef if !defined $item;
    }

    my $desc = '';
    foreach (reverse @chain) {
	$desc .= "generates $_\n";
    }
    chomp($desc);

    return $desc;
}

# Explain how STATE came to have an item X -> . SYMBOL \alpha
sub explain_chain {
    my Parse::YALALR::Build $self = shift;
    my ($state, $symbol, $asXML) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;
    my $desc;
    foreach my $kitem (@{$state->{items}}) {
	$desc = $self->explain_sym_chain($parser->{grammar}[$kitem->{GRAMIDX}],
					 $symbol, $asXML);
	return $desc if defined $desc;
    }
    return undef;
}

sub explain_FIRST {
    my Parse::YALALR::Build $self = shift;
    my ($token, $symbol, $asXML) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;

    # WHY_FIRST : { A => { t => <rule,reason,?parent> } } 
    my ($rule, $reason, $parent) = @{$self->{WHY_FIRST}->{$symbol}->{$token}};
    die unless defined $rule;
    
    my $str;
    $str .= "<rule id=$rule>" if $asXML;
    $str .= "rule ".$parser->dump_rule($rule, undef, $asXML);
    $str .= "</rule>" if $asXML;
    $str .= "\n";

    my $idx = $rule+1;
    while ((my $A = $parser->{grammar}->[$idx++]) != $parser->{nil}) {
	print "A=".$parser->dump_sym($A)." reason=$reason";
	if ($reason eq 'propagated') {
	    print " from ".$parser->dump_sym($parent);
	}
	print "\n";
	if ($A == $token) {
	    chomp($str);
	    return (undef, $str);
	} elsif ($reason eq 'propagated' && $A == $parent) {
	    $str .= "and ";
	    my (undef, $substr) =
	      $self->explain_FIRST($token, $parent, $asXML);
	    chomp($substr);
	    return (undef, $str.$substr);
	} else {
	    $str .= "and ";
	    $str .= "<nullable symbol=$A>" if $asXML;
	    $str .= $parser->dump_sym($A, $asXML)." is nullable";
	    $str .= "</nullable>" if $asXML;
	    $str .= "\n";
	}
    }

    die "Can't get here! tok=$ID{$parser->dump_sym($token)} symbol=$ID{$parser->dump_sym($symbol)} str=$str";
}

sub explain_nullable {
    my Parse::YALALR::Build $self = shift;
    my ($symbol, $asXML, $visited) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;
    my $grammar = $parser->{grammar};

    $visited ||= {};
    $visited->{$symbol} = 1;

    my $str;
    my $rule = $self->{why_nullable}->{$symbol};
    $str .= $parser->dump_rule($rule, undef, $asXML);

    my $idx = $rule;
    while ((my $A = $grammar->[++$idx]) != $parser->{nil}) {
	next if $visited->{$A};
	my (undef, $substr) = $self->explain_nullable($A, $asXML);
	$str .= "\n$substr";
    }

    return (undef, $str);
}

# When in state $state, why shift on token/nonterminal $symbol?
sub explain_shift {
    my Parse::YALALR::Build $self = shift;
    my ($state, $symbol, $action, $actions, $asXML) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;

    if (!ref $actions->[$symbol]) {
	# Usual explanation of a shift: state n has A -> \a1 . t \a2
	# in it. This might actually be because the kernel has
	# X -> \a3 . A \a4, though.

        my ($item, $reason, $chainfrom) = @{$state->{SHIFT_WHY}->{$symbol}};
        my $where = ($reason eq 'kernel' ? 'kernel ' : 'chained ');
        my $desc;
        if ($reason eq 'chained') {
	    # No need to dump out the generation list if ...?
	    if ($item->{GRAMIDX} != $chainfrom + 1) {
		$desc .= "\n".$self->explain_chain($state, $chainfrom, $asXML);
	    }
	    $desc .= "\ngenerates ";
	    $desc .= $parser->dump_item($item->{GRAMIDX}-1, $asXML);
        } else {
	    if (@{ $parser->{states}->[$state] } > 1) {
		$desc .= "in particular, item ";
		$desc .= $parser->dump_item($item->{GRAMIDX}-1, $asXML);
	    }
	}
        return ($state->{SHIFT_WHY}->{$symbol}, $desc);
    } else {
	# Hm. Some strange reason.
	return (undef, 'dunno(shift)(internal error)');
    }
}

sub create_item2state_map {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    for my $state (@{$parser->{states}}) {
	for my $item (@{$state->{items}}) {
	    $self->{item2state}->{$item} = $state;
	    $self->{itemmap}->{"$state->{id}_$item->{GRAMIDX}"} = $item;
	}
    }
}

sub lookup_lookahead_why ($$) {
    my ($why, $token) = @_;
    while (my ($vec, $reason) = each %$why) {
	return $reason if vec($vec, $token, 1);
    }
    warn("Failed to figure out why token is in lookahead of item");
    return undef;
}

# Figure out which (possibly generated) item propagated lookahead TOKEN
# to the item EFFECT. Favor items which were themselves generated rather
# than propagated (to avoid propagation cycles).
#
# <effect item, token> -> <causing state, causing item idx>
#
sub search_for_cause {
    my Parse::YALALR::Build $self = shift;
    my ($effect, $token) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;
    my $effect_idx = $effect->{GRAMIDX};

    my $cand_state;
    my $cand_item;
    for my $cause (@{ $effect->{SOURCES} }) {
#	$DB::single = 1 if $effect->{GRAMIDX} == 245;
	my $state = $self->{item2state}->{$cause};
	my $xstate = $self->expand_state($state);
	my $cause_xitem = $xstate->{$effect_idx - 1};
	next if !exists $cause_xitem->{$token};
	$cand_item = $cause_xitem->{item};
	return ($state, $cand_item)
	  if $cause_xitem->{$token}->[0] eq 'generated';
	return ($state, $cand_item)
	  if $cause_xitem->{$token}->[0] eq 'kernel';
	$cand_state = $state;
    }

    $DB::single = 1 if !defined $cand_state;
    die "No cause found!" if !defined $cand_state;
    return ($cand_state, $cand_item);
}

sub find_ultimate {
    my Parse::YALALR::Build $self = shift;
    my ($state, $symbol) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;
    my $reasons;
    while (my ($la, $r) = each %{$state->{REDUCE_WHY}}) {
        $reasons = $r, last if vec($la, $symbol, 1);
    }
    return $reasons->[1];
}

sub explain_reduce {
    my Parse::YALALR::Build $self = shift;
    my ($state, $symbol, $action, $actions, $asXML) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;
    my $str = '';

    my $reasons;
    while (my ($la, $r) = each %{$state->{REDUCE_WHY}}) {
        $reasons = $r, last if vec($la, $symbol, 1);
    }

    my $index = $reasons->[0];
    ++$index while $parser->{grammar}->[$index] != $parser->{nil};

    my ($xml, $reason);
    $xml .= "has item ".$parser->dump_item($index, $asXML);
    $xml .= "\nwith lookahead "
         ."<lookahead state=$state->{id} item=$index token=$symbol ultimate=$reasons->[1]->{GRAMIDX}>"
         .$parser->dump_sym($symbol, $asXML)
         ."</lookahead>";
    $reason = bless [ $state, $index, $symbol, $reasons->[1] ], 'reduce_reason';
    print "WOULD HAVE CALLED exp_la($state=$state->{id}, $index, ".$parser->dump_sym($symbol).", $reasons->[1]=$reasons->[1]->{GRAMIDX}, $asXML\n";
    return ($reason, $xml);
}

# Why was conflict resolved to $action?
sub explain_conflict {
}

sub explain {
    my Parse::YALALR::Build $self = shift;
    my ($state0, $cause, $action) = @_;
    my Parse::YALALR::Parser $parser = $self->parser;
    $state0 = $parser->{states}->[$state0];
    my $actions = $state0->{actions};
    my $desc = "state $state0->{id} is ".$parser->dump_kernel($state0)."\nand in particular ";
    my ($exp, $reason);
    if ($action eq 'shift') {
	($exp, $reason) = $self->explain_shift($state0, $cause, $action, $actions);
    } elsif ($action eq 'reduce') {
	($exp, $reason) = $self->explain_reduce($state0, $cause, $action, $actions);
    }

    return ($exp, $desc.$reason);
}

# DESTRUCTION TRACKING (no practical purpose yet)
#  sub xitem::DESTROY { print "xitem::DESTROY\n"; }
#  sub item::DESTROY { print "item::DESTROY\n"; }
#  sub kernel::DESTROY { print "kernel::DESTROY\n"; }

# Create a graph of xitem : { 'item' => grammar index of item B -> . \beta,
#                             token => <whylookahead, xitem ref> }
#   where whylookahead is 'generated' | 'propagated' | 'kernel'
#   and the xitem ref is the xitem containing item A -> \a1 . B \a2, f1
#     if 'generated', then token is in FIRST(\a2)
#     if 'propagated', then token is in f1
#     if 'kernel', then item is a kernel item and token is in the lookahead
#
# Note that this routine is very slow and produces a huge amount of data.
# Should probably destroy the whole thing afterwards. (This routine is NOT
# used to build a parser, only to explain why a lookahead is in an item if
# the user asks.)
#
sub expand_state {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($state) = @_;
    return $self->expand_items(@{ $state->{items} });
}

sub expand_items {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my (@kitems) = @_;

    my @xitems;
    my %visited; # { grammar index => xitem }
    my @Q;

    for my $kitem (@kitems) {
	my $xitem = bless { item => $kitem->{GRAMIDX},
			    map { ($_ => [ 'kernel' ]) }
			        ($parser->{symmap}->get_indices($kitem->{LA})) },
		          'xitem';
	push @xitems, $xitem;
	$visited{$kitem->{GRAMIDX}} = $xitem;
	push(@Q, $xitem);
    }

    while (@Q) {
	my $node = shift(@Q);
	# $node : { 'item' => B -> \gamma . \beta1, t1=>..., t2=>... }
	# (t1,t2 are the lookahead)
	# (\gamma is empty unless it's a kernel item)
	#
	# If we make it past the upcoming 'next's, we'll know that
	# the item is actually -> \gamma . C \beta2
	# (i.e., \beta1 = C \beta2)

	my $C = $parser->{grammar}->[$node->{item}];
	next if $C == $parser->{nil};
	next if $parser->is_token($C);

	# $F_beta2 := FIRST(\beta2)
	my @beta2 = $parser->get_dotalpha($node->{item} + 1);
	my $F_beta2 = $self->FIRST_nonvec(@beta2);
	# Gather up everything that will be passed to the children, either
	# by being generated by FIRST(\beta2) or propagated from the lookahead
	# of $node.
	my %generations;
	my %propagations;
	for my $t ($parser->{symmap}->get_indices($F_beta2)) {
	    if ($t == $parser->{nil}) {
		foreach (keys %$node) {
		    next if $_ eq 'item';
		    next if $_ eq 'parent0';
		    next if $_ == $parser->{nil};
		    $propagations{$_} = [ 'propagated', $node ];
		}
	    } else {
		$generations{$t} = [ 'generated', $node ];
	    }
	}

	for my $rule ($parser->get_rules($C)) {
	    # $rule : grammar index of . C -> \alpha
	    my $child = $rule + 1; # C -> . \alpha

	    my $newXitem;
	    if ($visited{$child}) {
		$newXitem = $visited{$child};
		my $old_number_of_lookaheads = keys %$newXitem;
		%$newXitem = (%propagations,
			      %generations,
			      %{$visited{$child}});
		next if keys %$newXitem == $old_number_of_lookaheads;
	    } else {
		$newXitem = bless { item => $child,
				    parent0 => $node,
				    %generations,
				    %propagations }, 'xitem';
	    }

	    $visited{$child} = $newXitem;
	    push(@Q, $newXitem);
	}
    }

    return \%visited;
}

sub dump_xreason {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my $reason = shift;
    my $str = $parser->dump_item($reason->[0]);
    if ($reason->[1] eq 'kernel') {
	return $str." (kernel item)";
    } else {
	return $str." <-$reason->[1]-- ".$parser->dump_item($reason->[2]->{item});
    }
}

# 1. LA_WHY trace to an item in the correct state
sub LA_WHY_chain_explstr {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;

    my $asXML;
    if (!ref $_[-1]) {
        $asXML = pop(@_);
    }

    my $str = '';
    foreach (reverse @_) {
	my ($reason, $cause_item, $f1, $f2) = @$_;
        my $itemdesc = $parser->dump_item($cause_item, $asXML);
#  	if ($reason eq 'generated') {
#  	    $str .= "generated by $itemdesc\n";
#  	} elsif ($reason eq 'propagated') {
#  	    $str .= "propagated from $itemdesc\n";
#  	} elsif ($reason eq 'chain-generated') {
#  	    $str .= "chain-generated from $itemdesc\n";
#  	} elsif ($reason eq 'epsilon-generated') {
#  	    $str .= "epsilon-generated from $itemdesc\n";
#  	}
	$str .= "propagates the lookahead to $itemdesc\n";
    }

    chomp($str);
    return $str;
}

sub xreason_chain_explstr {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($token, $chain, $ultimate_state, $asXML) = @_;
    return '' if @$chain == 0;

    my $str;

    print "asXML: ".((defined $asXML) ? $asXML : "(undef)")."\n";
    print "ITEMS: ", join(";; ", map { $parser->dump_item($_->[0]) } @$chain), "\n";
    print "REASONS: ", join(" , ", map { $_->[1] } @$chain), "\n";
    print "CAUSES: ", join(" , ", map { (defined $_->[2]) ? $parser->dump_item($_->[2]{item}) : "(undef)" } @$chain), "\n";

    @$chain = reverse @$chain;

    my $lastitem;

    if ($chain->[0]->[1] eq 'kernel') {
	$lastitem = $chain->[0]->[0];
	if ($lastitem == 1) {
	    $str .= ":automatically generated item ";
#	    $str .= $parser->dump_item($lastitem, $asXML)."\n";
	} else {
	    my (undef, $tmp) =
	      $self->lookahead_inherit_explanation($ultimate_state, $lastitem,
						   $token, $asXML);
	    $tmp =~ s/\n/\n:/g;
	    $str .= ":$tmp\n";
	}
    } else {
	$lastitem = $chain->[0]->[2]->{item};
	$str .= "generates ".$parser->dump_item($lastitem, $asXML)."\n";
    }

    foreach (@$chain) {
	my ($item, $reason, $cause) = @$_;

#	if ($reason eq 'generated') {
#	    $str .= "with la ".$parser->dump_sym($token, $asXML);
#	    $str .= "generates ".$parser->dump_item($cause->{item}, $asXML)."\n";
#	} elsif ($reason eq 'propagated') {
#	    $str .= "with la ".$parser->dump_sym($token, $asXML);
#	    $str .= "generates ".$parser->dump_item($cause->{item}, $asXML)."\n";
#	} else {
#	    $str .= "which is a kernel item\n";
#	}

	if ($reason eq 'generated') {
	    # That means $lastitem generated the lookahead. Examine why.
	    $str .= $self->lookahead_generation_explanation($lastitem, $token, $asXML, "    ")."\n";
	} elsif ($reason eq 'kernel') {
	    $str .= $self->lookahead_generation_explanation($item, $token, $asXML, "")."\n";
	}

	$str .= "generates ".$parser->dump_item($item, $asXML)."\n";

	print "LASTITEM turning over from ".$parser->dump_item($lastitem)." TO ".$parser->dump_item($item)."\n";

	$lastitem = $item;
    }

    $str =~ s/\n+$//;
    return $str;
}

sub lookahead_generation_explanation {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($item, $lookahead, $asXML, $tab) = @_;
    my @alpha = $parser->get_dotalpha($item+1);
    print "ALPHA=".join(" ", $parser->dump_sym(@alpha))."\n";
    my $firstalpha = $self->FIRST_nonvec(@alpha);
    my $str = '';
    if (vec($firstalpha, $lookahead, 1)) {
	my $expl = $self->explain_first_alpha($lookahead, \@alpha, $asXML);
	$str .= "generates the lookahead ";
	$str .= $parser->dump_sym($lookahead, $asXML)."\n";
	$str .= "because $expl";
    } else {
#	$str = "inherits the lookahead ".$parser->dump_sym($lookahead, $asXML);
    }

    chomp($str);
    $str =~ s/\n/\n$tab/g;
    return $tab.$str;
}

sub lookahead_inherit_explanation {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($ultimate_state, $lastitem, $token, $asXML) = @_;
    return $self->explain_lookahead($ultimate_state, $lastitem, $token,
				    undef, $asXML);
}

sub explain_first_alpha {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($la, $alpha, $asXML) = @_;

    my $str;
    foreach (@$alpha) {
	if ($self->FIRST_nonvec($_)) {
	    if ($parser->is_nonterminal($_)) {
		$str .= $parser->dump_sym($la, $asXML)." is in ";
		$str .= "<FIRST symbol=$_ token=$la>" if $asXML;
		$str .= "FIRST(".$parser->dump_sym($_).")";
		$str .= "</FIRST>" if $asXML;
	    } else {
		$str .= $parser->dump_sym($la, $asXML)." immediately follows the expanded nonterminal";
	    }
	    return $str;
	} elsif ($parser->is_nonterminal($_)) {
	    $str .= "<nullable symbol=$_>" if $asXML;
	    $str .= $parser->dump_sym($_, $asXML)." derives the empty string";
	    $str .= "</nullable>" if $asXML;
	    $str .= ", and\n";
	}
    }

    die "Hey! Never found lookahead in alpha!";
}

sub xitem_chain_explstr {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;

    my $asXML;
    if (!ref $_[-1]) {
        $asXML = pop(@_);
    }

    return '' if @_ == 0;

    my $xformat = ($asXML ? "briefxml" : "brief");
    my $str = '';
    my @xitems = reverse @_;
    my $kernel = shift(@xitems);
    $str .= "kernel item ".$parser->dump_item($kernel->{item}, $xformat)."\n";

    for my $xitem (@xitems) {
	$str .= "generates ".$parser->dump_item($xitem->{item}, $xformat)."\n";
    }

    chomp($str);
    return $str;
}

# Tie the chains together
# $ultimate_chain
# $xreason_chain
# $lawhy_chain
# 
# $lawhy_chain is in reverse order
# $xreason_chain is in reverse order
# $ultimate_chain is in reverse order
#
sub explain_lookahead {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($state, $idx, $token, $ultimate_kitem, $asXML) = @_;

    $DB::single = 1;

    my ($lawhy_chain, $xreason_chain, $ultimate_chain, $ultimate_state) =
      $self->lookahead_explanation($state, $idx, $token, $ultimate_kitem);

    my $str;

#    $str .= "--Kernel to just before cause--\n";
    $str .= $self->xitem_chain_explstr(@$ultimate_chain, $asXML);
    $str =~ s/^\n//;
#    $str .= "\n--Cause to A : . b x y--";
    $str .= "\n".$self->xreason_chain_explstr($token, $xreason_chain, $ultimate_state, $asXML);
    $str =~ s/^\n//;
#    $str .= "\n--Propagation chain--";
    pop(@$lawhy_chain); # Get rid of kernel item (printed above)
    $str .= "\n".$self->LA_WHY_chain_explstr(@$lawhy_chain, $asXML);
#    $str .= "\n--done--";

    return [ $lawhy_chain, $xreason_chain, $ultimate_chain ], $str;
}

# lookahead_explanation
#
# Explaining lookaheads is a 3-step process:
#
# 1. Use item->{LA_WHY} to trace to the ultimately generating state
# and kernel item.
#
# 2. Look back at the path found in #1 and find the second-to-last
# item (it will be the one the was propagated from an item generated
# by the ultimate kernel item.) Expand the ultimate state and use the
# xitem lookahead links to get to the generating xitem for that 2nd to
# last item respecting that particular lookahead.
#
# 3. To get to the kernel, expand just the ultimately generating
# kernel item to find the chain of GRAMIDXes that lead from the xitem
# found in the previous step to the kernel item.
#
# Example:
# A -> X D C y
# D -> B d
# B -> a b
# C ->
# X ->
#
# Consider X -> a b ., d
#
# Step 1 finds
#   D -> X . D C y      (kernel)
#   B -> a . b, d       (propagated)
#   B -> a b ., d       (propagated)
# Step 2 finds the generating xitem
#   D -> . B d, ...
#   B -> . a b, d       (generated)
# Step 3 finds the path from the kernel
#   A -> X . D C y      (kernel)
#   D -> . B d, ...     (generated)
#
# Sewing those together in the correct order results in:
#   A -> X . D C y      (kernel)
#   D -> . B d, ...     (generated) *** source of the lookahead
#   B -> . a b, d       (generated)
#   B -> a . b, d       (propagated)
#   B -> a b ., d       (propagated)
#
sub lookahead_explanation {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->{parser};
    my ($state, $idx, $token, $ultimate_kitem) = @_;

    # Output
    my (@lawhy_chain, @xreason_chain, @ultimate_chain);

    # First, find the item we're talking about
    my ($item) = grep { $_->{GRAMIDX} == $idx } @{ $state->{items} };
    undef $ultimate_kitem if defined $item;

    # Step 1 is unnecessary if the caller gave us the ultimate kernel item
    my $lastidx;
    if (!defined $ultimate_kitem) {
	use Carp;
	confess "No ultimate kernel item given and item not found"
	  if !defined $item;

	# Step 1: item->{LA_WHY} chain
	@lawhy_chain = $self->get_LA_WHY_chain($token, $item);
	$ultimate_kitem = $lawhy_chain[-1]->[1];
	if ($lawhy_chain[-1]->[0] eq 'init') {
	    print "Ran afoul of autogenerated item\n";
	    $DB::single = 1;
	    $ultimate_kitem = $parser->{states}->[0]->{items}->[0];
	    $lastidx = 1;
	} else {
	    $state = $self->{item2state}->{$ultimate_kitem};
	    $lastidx = $lawhy_chain[-2]->[1]->{GRAMIDX}-1;
	}
    } else {
	$lastidx = $idx;
    }

    # Step 2: expand the state and find the generating xitem
    my $xstate = $self->expand_state($state);
    { local $^W = 0; print $parser->dump_xstate($xstate); }
    my $xitem = $xstate->{$lastidx};
    $DB::single = 1;
    @xreason_chain = $self->get_xreason_chain($xitem, $token);
    my $generating_reason = $xreason_chain[-1];

    # Check whether step 3 makes sense
    if ($generating_reason->[1] ne 'kernel') {
	@ultimate_chain =
	  $self->get_any_chain($generating_reason->[2]->{item},
			       $ultimate_kitem);
    } else {
	warn "Hm. Found an alternate reason?"
	  if $generating_reason->[0] != $ultimate_kitem->{GRAMIDX};
    }

    return \@lawhy_chain, \@xreason_chain, \@ultimate_chain, $state;
}

# Given an item A -> x y z . \alpha, t|other0 and a token t
# return the sequence
#   <'myself', A -> x y z . \alpha, t|other0>
#   <'propagated', A -> x y . z \alpha, t|other1>
#   <'propagated', A -> x . y z \alpha, t|other2>
#   <'generated', Q -> Z t P . A t>
#
# Could this be changed to produce shorter chains by favoring generated
# links? (I don't think this is necessary to avoid cycles)
sub get_LA_WHY_chain {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($token, $item) = @_;

    my @chain = ([ 'myself', $item ]);
    
    if ($item->{GRAMIDX} == 1) {
	return ([ 'init', $item ]);
    }

    my $lawhy;
    do {
	my @la = grep { vec($_, $token, 1) } (keys %{ $item->{LA_WHY} });
	die "Unable to find LA_WHY for ".$parser->dump_sym($token)
	  if @la == 0;
	$lawhy = $item->{LA_WHY}->{$la[0]};
	push(@chain, $lawhy);
	$item = $lawhy->[1];
    } while ($lawhy->[0] !~ /generated/);

    return @chain;
}

# Given an xitem C -> . \alpha and token a token d, produce a chain
#   C -> . \alpha, d
#   B -> . C D
#   A -> X . B d
#
# saying that d is generated by A -> . B d (because D is nullable)
#
sub get_xreason_chain {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($xitem, $token) = @_;

    my %visited; # { grammar index }

    use Carp;
    confess ($token || "false") if !defined $xitem->{$token};
    my @chain = (bless [ $xitem->{item}, @{$xitem->{$token}} ], 'xreason');

    # Traverse upwards from the given item until either a kernel item
    # is reached or the requested token is generated.
    while (1) {
	my ($last_item, $last_reason, $last_cause) = @{$chain[-1]};
	return @chain if $last_reason ne 'propagated';
	die "Infinite loop!" if $visited{$last_cause->{item}}; # DBG
	$visited{$last_cause->{item}} = 1;
	push(@chain,
	     bless [ $last_cause->{item}, @{$last_cause->{$token}} ],
	           'xreason');
	return @chain if $chain[-1]->[1] eq 'kernel';
    }
}

# from_xitem
# .
# .
# .
# to_xitem
sub get_any_chain {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($from_idx, $to_kitem) = @_;

    my $xwad = $self->expand_items($to_kitem);
    my @chain;
    my $xitem = $xwad->{$from_idx};
    while (1) {
	push(@chain, $xitem);
	last if $xitem->{item} == $to_kitem->{GRAMIDX};
	$xitem = $xitem->{parent0};
    }

    shift(@chain); # Really just want the explanation starting after from_idx
    return @chain;
}

sub get_lookahead_chain {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($state, $token, $item) = @_;

    my $lawhy;
    # Foreach lavec in LA_WHY = { la => lawhy } that contains TOKEN
    for my $lavec (grep { vec($_, $token, 1) } (keys %{$item->{LA_WHY}})) {
	$lawhy = $item->{LA_WHY}->{$lavec};
	last if $lawhy->[0] eq 'generated';
    }

    $DB::single = 1 if !defined $lawhy;
    die "Unable to find lookahead chain for token ".$parser->dump_sym($token)." in item ".$parser->dump_item($item) if !defined $lawhy;

    return ($lawhy) if $lawhy->[0] eq 'generated';
    my $K0 = $self->{item2state}->{$lawhy->[1]};
    my @chain = $self->get_lookahead_chain($K0, $token, $lawhy->[1]->{GRAMIDX});
    return ($lawhy, @chain);
}

sub get_lookahead_chain3 {
    my Parse::YALALR::Build $self = shift;
    my Parse::YALALR::Parser $parser = $self->parser;
    my ($state, $token, $item) = @_;

    my $expansion = $self->expand_state($state);
    my $xitem = $expansion->{$item};

    # @chain : ( <itemidx, reason, cause> )
    # item ITEMIDX was created because REASON by xitem CAUSE
    my @chain = (bless [ $item, @{$xitem->{$token}} ], 'xreason');
    my %visited;
    $visited{$item} = 1;

    # Traverse upwards from the given item until either a kernel item
    # is reached or the requested token is generated.
    while (1) {
	my ($last_item, $last_reason, $last_cause) = @{$chain[-1]};
	$visited{$last_cause->{item}} = 1;
	last if $last_reason ne 'propagated';
	push(@chain,
	     bless [ $last_cause->{item}, @{$last_cause->{$token}} ], 'xreason');
	return \@chain if $chain[-1]->[1] eq 'kernel';
    }

    # Then keep traversing upward along randomly chosen unvisited
    # links until a kernel item is reached.
  LINK: while (1) {
	my ($last_item, $last_reason, $last_cause) = @{$chain[-1]};
	$visited{$last_cause->{item}} = 1;

	# Pick randomly (grab the first one reached)
	while (my ($t, $r) = each %$last_cause) {
	    next if $t eq 'item';
	    next if $t eq 'parent0';
	    last LINK if $r->[0] eq 'kernel';
	    next if $visited{$r->[1]->{item}};
	    push(@chain, bless [ $last_cause->{item}, @$r ], 'xreason');
	    next LINK;
	}

	print STDERR "Failed to find path to kernel item\n";
	print STDERR "Visited items:\n";
	foreach (keys %visited) {
	    print STDERR $parser->dump_item($_)."\n";
	}
	die "Bye bye\n";
    }

    return \@chain;
}

1; # I am not a module!
