# This is really a -*- cperl -*- extension package to Parse::YALALR::Build,

package Parse::YALALR::Parser;
use strict;

sub register_dump {
    shift if (ref $_[0]); # Optional object
    my ($type, $sub) = @_;
    $Parse::YALALR::Parser::dumpsub{$type} = $sub;
}

sub dump_pseudo {
    my ($self, $ph) = @_;

    my %h;
    my $r = ref $ph;
    while (my ($field, $slot) = each %{ $ph->[0] }) {
	$h{$field} = $self->dump($ph->[$slot]);
    }
    return bless \%h, $r;
}

sub dump {
    my ($self, @v) = @_;
    return "<undef>" if @v == 0;

    my $asXML = $self->{dump_format};
    return map { $self->dump($_) } @v if @v > 1;
    my ($v) = @v;

    if (!ref $v) {
	return (undef) if !defined $v;
	return "<empty>" if $v eq "";
	if ($v =~ /^\d+$/) {
	    my $v2;
	    defined ($v2 = $self->dump_sym($v, $asXML)) && return $v2;
	    defined ($v2 = $self->dump_item($v, $asXML)) && return $v2;
	} elsif ($v =~ /[^-+.\/\w\s]/) {
	    return $self->dump_symvec($v, $asXML);
	}
	return $v;
    }

    if (defined $Parse::YALALR::Parser::dumpsub{ref $v}) {
	return $Parse::YALALR::Parser::dumpsub{ref $v}->($self, $v, $asXML);
    }

    if (UNIVERSAL::isa($v, 'ARRAY')) {
	if (ref $v ne 'ARRAY') {
	    my $r = ref $v;
	    no strict 'refs';
	    if (exists ${$r.'::'}{FIELDS}) {
	        return $self->dump_pseudo($r, $asXML);
	    } else {
		return bless [ map { $self->dump($_) } @$v ], $r;
	    }
	} else {
	    return [ map { $self->dump($_) } @$v ];
	}
    } elsif (UNIVERSAL::isa($v, 'HASH')) {
	my %h;
	while (my ($k, $val) = each %$v) {
	    $k = $self->dump($k) if ($k =~ /^\d+$/);
	    $k = $self->dump_symvec($k, $asXML) if ($k =~ /\0/);
	    $h{$k} = $self->dump($val);
	}
	if (ref $v ne 'HASH') {
	    return bless \%h, ref $v;
	} else {
	    my $ret = \%h;
#	    print "Returning $ret\n";
	    return $ret;
	}
    } else {
	return $v;
    }
}

sub dump_NULLABLE {
    my ($self) = @_;
    my $nullable = $self->{nullable};
    my $why_nullable = $self->{why_nullable};
    my $nil = $self->{nil};
    my $str = "";

    foreach my $null (keys %$nullable) {
	if ($null == $nil) {
	    $str .= $self->dump_sym($null).
	            " is nullable by definition\n";
	} elsif ($why_nullable->{$null} eq 'is an action') {
	    $str .= "is nullable because it is an action\n";
	} else {
	    $str .= $self->dump_sym($null).
	            " is nullable because of rule ".
		    $self->dump_rule($why_nullable->{$null})."\n";
	}
    }

    return $str;
}

sub dump_action {
    my ($self, $action, $asXML) = @_;
    my $str = "";

    if (ref $action eq 'reduce') {
	my ($rule, $lhs, $sz_rhs) = @$action;
	$str = "pop $sz_rhs syms, push ".$self->dump_sym($lhs, $asXML).", rule ";
	$str .= $self->dump_rule($rule, $asXML);
    } else {
	$str = "shift, goto state $action";
    }

    return $str;
}

sub dump_rule {
    my ($self, $rule, $arrow, $format) = @_;
    my $grammar = $self->{grammar};
    my $nil = $self->{nil};

    my $asXML = $format && $format =~ /xml/;
    my $brief = $format && $format =~ /brief/;

    $arrow ||= '->';
    $arrow = $E{$arrow} if $asXML;

    my $prec = $self->{rule_precedence}->[$rule];
    my $precstr = "";
    $precstr = "(prec $prec->[0])" if defined $prec;

    my $str = "";
    $str .= $self->dump_sym($grammar->[$rule], $asXML);
    $str .= " $arrow ";
    my $has_rhs = 0;
    while ($grammar->[++$rule] != $nil) {
	$str .= $self->dump_sym($grammar->[$rule], $asXML)." ";
        $has_rhs = 1;
    }
    $str .= "/*empty*/ " if !$has_rhs;
    $str .= $precstr unless $brief;
    $str =~ s/\s+$//;
    return $str;
}

sub dump_lr0item {
    my ($self, $item, $format) = @_;
    $format ||= 0;
    my $asXML = ($format =~ /xml/) && 'xml';

    my $grammar = $self->{grammar};
    my $nil = $self->{nil};

    my $rule = $item;
    --$rule while $rule && ($grammar->[$rule - 1] != $nil);

    my $str;
    $str .= "<item id=$item>" if ($asXML && $asXML !~ /untagged/);
    $str .= $self->dump_sym($grammar->[$rule], $asXML);
    $str .= $asXML ? " &arrow; " : " -> ";

    $rule++;
    while (1) {
	$str .= ". " if $rule == $item;
	last if $grammar->[$rule] == $nil;
	$str .= $self->dump_sym($grammar->[$rule], $asXML)." ";
	$rule++;
    }

    $str .= "</item>" if ($asXML && $asXML !~ /untagged/);

    return $str;
}

sub dump_lr1item {
    my ($self, $item, $format) = @_;
    $format ||= 0;
    my $asXML = ($format =~ /xml/) && 'xml';
    my $str;
    $str .= "<item id=$item->{GRAMIDX}>" if $asXML;
    $str .= $self->dump_lr0item($item->{GRAMIDX}, $asXML ? "untaggedxml" : 0);

    if ($format !~ /brief/) {
	$str .= ", ";
	$str .= "<lookahead>" if $asXML;
	$str .= $self->dump_symvec($item->{LA}, $asXML);
	$str .= "</lookahead>" if $asXML;
    }

    $str .= "</item>" if $asXML;

    return $str;
}

sub dump_item {
    if (ref $_[1] && ref $_[1] eq 'item') {
	&dump_lr1item;
    } else {
	&dump_lr0item;
    }
}

sub dump_xitem {
    my Parse::YALALR::Parser $self = shift;
    my ($xitem, $format) = @_;

    my $asXML = (defined $format && $format =~ /xml/);
    my $str =
      "XITEM($xitem->{item}) = ".$self->dump_item($xitem->{item}, $asXML);

    if ($format && ($format eq 'very' || $format eq 'brief')) {
	return $str if ($format eq 'very');
	return $str.", ".join(" ", map { $self->dump_sym($_, $asXML) }
			              grep { ! /^item|parent0$/ }
			                   (keys %$xitem));
    }

    # ARGH! Avoid colliding with the iterator for %$xitem (shared with
    # the enclosed dump_xitem with the brief flag set)
    my $brief_format = $asXML ? 'briefxml' : 'brief';
    foreach my $t (keys %$xitem) {
	next if $t eq 'item';
	next if $t eq 'parent0';
	my $cause = $xitem->{$t};
	$str .= "\n  ".$self->dump_sym($t, $asXML)." : ";
	if ($cause->[0] eq 'kernel') {
	    $str .= "(kernel item)";
	} else {
	    $str .= $cause->[0]." ";
	    $str .= ($cause->[0] eq 'generated') ? 'by ' : 'from ';
	    $str .= $self->dump_xitem($cause->[1], $brief_format);
	}
    }

    return $str;
}

sub dump_expansion {
    my Parse::YALALR::Parser $self = shift;
    my ($xitems, $format) = @_;

    my $str = '';
    foreach (values %$xitems) {
	$str .= $self->dump_xitem($_, $format)."\n";
    }
    chomp($str);
    return $str;
}

sub dump_xstate {
    my Parse::YALALR::Parser $self = shift;
    my ($kernel, $xstate, $format) = @_;
    my $asXML = ($format && $format =~ /xml/) ? 'xml' : undef;

    my $str;

    my @kernel;
    my @generated;
    
    foreach (values %$xstate) {
	(defined $_->{parent0}) ? push(@generated, $_) : push(@kernel, $_);
    }

    # Do something vaguely like a topological sort
    my %parental_intuition;
    foreach (@generated) {
	$parental_intuition{$_->{parent0}->{item}} +=
	    ($parental_intuition{$_->{item}} || 1);
    }
    foreach (@generated) {
	$parental_intuition{$_->{parent0}->{item}} +=
	    ($parental_intuition{$_->{item}} || 1);
    }
    @generated = sort { ($parental_intuition{$b->{item}} || 0) <=>
			($parental_intuition{$a->{item}} || 0) } @generated;

    my $grammar = $self->{grammar};
    my $nil = $self->{nil};

    $str .= "<state id=$kernel->{id}>" if $asXML;
    $str .= "State $kernel->{id}";
    $str .= "</state>" if $asXML;
    $str .= ": ".(0+@kernel)." kernel items, ";
    $str .= (@kernel + @generated)." total:\n";

    my $inkernel = 1;
    foreach my $xitem (@kernel, "---", @generated) {
	if (!ref $xitem) {
	    $str .= ("-" x 20);
	    $inkernel = 0;
	} else {
	    my $idx = $xitem->{item};
	    $str .= $self->dump_item($idx, $asXML);
	    $str .= ",";

	    foreach (keys %$xitem) {
		next if $_ eq 'item';
		next if $_ eq 'parent0';
		$str .= " ";

		$str .= "<lookahead token=$_ state=$kernel->{id} item=$idx>"
		    if $asXML && $inkernel;
		$str .= $self->dump_sym($_, $asXML);
		$str .= "</lookahead>" if $asXML && $inkernel;
	    }

	    my $rule = $idx;
	    $rule-- while ($rule && $grammar->[$rule] != $nil);
	    $rule++ if $rule;

	    if (defined (my $prec = $self->{rule_precedence}->[$rule])) {
		$str .= " ";
		$str .= "<prec rule=$rule level=$prec->[0] assoc=$prec->[1]>"
		    if $asXML;
		$str .= "\%$prec->[1] $prec->[0]";
		$str .= "</prec>" if $asXML;
	    }
	}

	$str .= "\n";
    }

    return $str;
}

# Weird calling convention
# In scalar context: args are self, symbol, asxml flag
# In list context: args are self, symbol list (no asxml flag available)
sub dump_sym {
    my Parse::YALALR::Parser $self = shift;
    if (wantarray) {
        my (@syms) = @_;
        return map { $self->{symmap}->get_value($_) } @syms;
    } else {
        my ($sym, $asXML) = @_;
        my $symname = $self->{symmap}->get_value($sym);
        return $asXML ? "<sym id=$sym>$E{$symname}</sym>" : $symname;
    }
}

sub dump_symvec {
    my ($self, $vec, $asXML) = @_;
    my @syms = $self->{symmap}->get_indices($vec);
    return "VEC(".join("|", map("".$self->dump_sym($_, $asXML), @syms)).")";
}

sub dump_FIRST {
    my ($self, $nt) = @_;
    return "FIRST(".$self->dump_sym($nt).") = ".
      join(" ", $self->{symmap}->get_values($self->{FIRST}->{$nt}));
}

sub dump_FIRSTs {
    my Parse::YALALR::Parser $self = shift;
    my $str = "";

    foreach my $nt (@{$self->{nonterminals}}) {
	$str .= $self->dump_FIRST($nt)."\n";
    }

    return $str;
}

sub dump_kernel {
    my Parse::YALALR::Parser $self = shift;
    my ($K, $asXML) = @_;
    my $n = @{$K->{items}};
    my $id = $K->{id};
    my $str;

    $str .= "<wholestate id=$id><state id=$id>" if $asXML;
    $str .= "State $id";
    $str .= "</state>" if $asXML;
    $str .= ": $n $P{'item', $n}\n";

    $str .= " ".$self->dump_item($_, $asXML)."\n"
      foreach @{$K->{items}};
    chomp($str);

    $str .= "</wholestate>" if $asXML;
    return $str;
}

sub dump_parser {
    my Parse::YALALR::Parser $self = shift;
    my $str = "";
    my $symmap = $self->{symmap};

    my $i;
    for my $i (0..$#{$self->{states}}) {
	my $state = $self->{states}->[$i];
	$str .= $self->dump_kernel($state)."\n";
	$str .= "Actions:\n";

        while (my ($sym, $kernel) = each %{$state->{shifts}}) {
	    $str .= "shift ".$self->dump_sym($sym).", go to state $kernel\n";
	}

	foreach (@{$state->{reduces}}) {
	    my ($la, $rule, $item) = @$_;
	    $str .= "reduce by ".$self->dump_rule($rule)." on la ".$self->dump_symvec($la)."\n";
	}

	$str .= "\n";
    }

    return $str;
}

BEGIN {
    register_dump('item', \&dump_lr1item);
    register_dump('Parse::YALALR::Kernel', \&dump_kernel);
    register_dump('shift', \&dump_action);
    register_dump('reduce', \&dump_action);
    register_dump('xitem', \&dump_xitem);
    register_dump('xreason', \&dump_xreason);
    *dump_state = \&dump_kernel;
}

1;
