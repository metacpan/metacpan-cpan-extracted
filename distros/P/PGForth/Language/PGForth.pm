#! /usr/bin/perl -w

require 5;
 
package Language::PGForth;

#######################################
# Forth in Perl5
# Copyright (c) by Peter Gallasch,
# municipality of Vienna, Austria
# Version 1.3
#
# the code may be used, copied and redistributed
# under the same terms as perl
# 
#######################################

#######################################
# 	Indirect threaded
#######################################

use strict 'subs';
use strict 'refs';

#######################################
# Stack
#
# Parameter Stack: @st
# Return Stack: @rst
# Control-Flow Stack: @cst
# Leave Stack: @lst
#######################################

#######################################
#	DICTIONARY
#
# Aufbau:
# %dic: 'name', [liste]
# @liste: \&code, [parameter]
#######################################

# definition of a primitiv word
sub prim ($&;$) {	# (name, sub, immediate?)
	my ($name, $subref, $is_immediate) = @_;
	$dic {$name} = [$subref];
	$immediate {$name} = 1 if $is_immediate;
}

# read input until pattern
sub parse ($) {
	my ($pattern) = @_;
	my $result = "";
	suche:   # loop with goto
		unless ($tib =~ s/^(.*?)$pattern//) {
			$result .= $tib;
			$tib = <>;
			goto suche;
		}
	$result .= $1;
}

# Execute word
sub do_execute ($) {
	my $entry = shift;
	&{$entry->[0]} ($entry->[1]);	# &$code ($parameter);
}

#######################################
# Stack words
#######################################
prim 'dup', sub {push (@st, $st[-1]) };
prim '?dup', sub {push (@st, $st[-1]) if $st[-1] };
prim 'drop', sub {pop @st};
prim 'swap', sub {splice (@st, -2, 2, @st[-2,-1]) };
prim 'over', sub {push (@st, $st[-2]) };
prim 'rot', sub {splice (@st, -3, 3, @st[-3,-1,-2]) };

#######################################
# Arithmetik
#######################################
prim '+', sub {splice (@st, -2, 2, $st[-2] + $st[-1]) };
prim '-', sub {splice (@st, -2, 2, $st[-2] - $st[-1]) };
prim '*', sub {splice (@st, -2, 2, $st[-2] * $st[-1]) };
prim '/', sub {splice (@st, -2, 2, $st[-2] / $st[-1]) };
prim 'mod', sub {splice (@st, -2, 2, $st[-2] % $st[-1]) };
prim '<', sub {splice (@st, -2, 2, $st[-2] < $st[-1] ? -1 : 0) };
prim '>', sub {splice (@st, -2, 2, $st[-2] > $st[-1] ? -1 : 0) };
prim '=', sub {splice (@st, -2, 2, $st[-2] == $st[-1] ? -1 : 0) };
prim 'and', sub {splice (@st, -2, 2, $st[-2] & $st[-1]) };
prim 'or', sub {splice (@st, -2, 2, $st[-2] | $st[-1]) };


#######################################
# Output
#######################################
prim '.', sub {print pop (@st)." " };
prim '.(', sub {print parse ('\)') };

prim '(.")', sub { print $words->[$wc++]; };

prim '."', sub {
	push @$adef, $dic{'(.")'}, parse ('"');
}, 1;

#######################################
# Misc
#######################################
prim 'bye', sub {print "Goodbye\n";  exit};
prim 'words', sub {
	foreach $word (sort keys(%dic)) {
		print "$word ";
	}
};
prim '.s', sub {
	if (@st) {
		foreach $i (reverse @st) { print "\t$i\n"; }
	} else {
		print "stack empty\n";
	}
};
prim '(', sub {parse ('\)') }, 1;
# parse ist not optimal, it saves text between ( and ) .

#######################################
# Compiler
#
# Word count: $wc
#
# list of parameters of actual definition: @$adef
# compiling adds to this list
#######################################
sub do_colon {
	local $words = shift;
	local $wc = 0;
	while ($wc <= $#$words) {
		do_execute ($words->[$wc++]);
	}
}

prim ':', sub {
	$tib =~ s/\s*(\S+)\s?//;
	$adef = [];
	@{$dic{$1}} = (\&do_colon, $adef);
	$state = 1;
};

prim ';', sub {
	$state = 0;
	undef ($adef);
}, 1;

prim 'literal', sub { push @st, $words->[$wc++]; };

#######################################
# control structures
#######################################

prim 'branch', sub {
	$wc += $words->[$wc];
};

prim '?branch', sub {
	$wc += pop (@st) ? 1 : $words->[$wc];
};

prim 'if', sub {
	push @$adef, $dic{'?branch'}, "unresolved forward reference";
	push @cst, $#$adef;   # index of reference orig
}, 1;

prim 'else', sub {
	push @$adef, $dic{'branch'}, "unresolved forward reference";

	# resolve old forward reference
	my $orig = pop(@cst);
	$adef->[$orig] = $#$adef + 1 - $orig;

	# leave index of new reference orig
	push @cst, $#$adef;
}, 1;

prim 'then', sub {
	# resolve forward reference
	my $orig = pop(@cst);
	$adef->[$orig] = $#$adef + 1 - $orig;
}, 1;

prim 'begin',  sub {push @cst, $#$adef; }, 1;

prim 'until',  sub {
	push @$adef, $dic{'?branch'}, (pop @cst) - ($#$adef + 1);
}, 1;

prim 'while', sub {
	push @$adef, $dic{'?branch'}, "unresolved forward reference";
	my $dest = pop @cst;
	push @cst, $#$adef,   # index of reference orig
		   $dest;
}, 1;

prim 'repeat',  sub {
	push @$adef, $dic{'branch'}, (pop @cst) - ($#$adef + 1);
	my $orig = pop(@cst);
	$adef->[$orig] = $#$adef + 1 - $orig;
}, 1;

prim 'do', sub {
	push @$adef, $dic{'(do)'};

	# Place do-sys onto the control-flow stack
	push @cst, $#$adef;
}, 1;

sub resolve_leaves ($) {
	while (@lst and $lst[-1] > $_[0]) {
		# resolve forward reference
		my $orig = pop (@lst);
		$adef->[$orig] = $#$adef + 1 - $orig;
	}
}

prim 'loop', sub {
	my $do_sys = pop (@cst);
	push @$adef, $dic{'(loop)'}, $do_sys - ($#$adef + 1);
	resolve_leaves ($do_sys);
}, 1;

prim '+loop', sub {
	push @$adef, $dic{'(+loop)'}, (pop @cst) - ($#$adef + 1);
}, 1;

prim '(do)', sub {
	push @rst, splice (@st, -2);
};

prim '(loop)', sub {
	if (++$rst[-1] == $rst[-2]) {
		splice (@rst, -2);
		$wc++;
	} else {
		$wc += $words->[$wc];
	}
};

prim '(+loop)', sub {
	my $step = pop @st;
	if (($rst[-1] < $rst[-2]) xor ($rst[-1] + $step < $rst[-2])) {
		splice (@rst, -2);
		$wc++;
	} else {
		$rst[-1] += $step;
		$wc += $words->[$wc];
	}
};

prim 'i', sub { push @st, $rst[-1]; };

prim 'leave', sub {
	push @$adef, $dic{'(leave)'}, "unresolved forward reference";
	push @lst, $#$adef;
}, 1;

prim '(leave)', sub {
	splice (@rst, -2);
	$wc += $words->[$wc];
};

#######################################
# Variable, etc.
#######################################

sub do_const { push @st, $_[0]; }

prim 'variable', sub {
	$tib =~ s/\s*(\S+)\s?//;
	my $anonymous = "not defined";
	$dic{$1} = [\&do_const, \$anonymous];
};

prim '!', sub {
	($address, $value) = splice (@st, -2, 2);
	$$address = $value;
};

prim '+!', sub {
	($address, $value) = splice (@st, -2, 2);
	$$address += $value;
};

prim '@',  sub { $st[-1] = ${$st[-1]}; };

prim 'constant', sub {
	$tib =~ s/\s*(\S+)\s?//;
	$dic{$1} = [\&do_const, pop @st];
};

#######################################
# Dictionary
#######################################

prim "'", sub {
	$tib =~ s/\s*(\S+)\s?//;
	push (@st, $dic{$1});
};

prim 'execute', sub { do_execute (pop @st) };

#######################################
# connection to perl
#######################################
# interpret everything between perl( and )perl, leave returned values on @st
prim 'perl(', sub { push @st, eval parse ('\)perl'); };

# run-time portion of perl"
prim '(perl")', sub { &{$words->[$wc++]}; };

# compile everything between perl" and "perl
# as anonymous sub to the dictionary
# run-time: execute perl-code, leave returned values on @st
prim 'perl"', sub {
	push @$adef, $dic{'(perl")'},
		eval 'sub { push @st, ('. parse ('"perl'). ')}';
}, 1;

# pass following lines to the perl interpreter
# until /^forth$/
prim 'perl_', sub {
	while ($_ = <>, !m/^forth$/) { eval }
};

#######################################
#	Decompiler
#######################################

sub name_of ($) {
	foreach (keys %dic) { return $_ if $dic{$_} eq $_[0]; }
	return $_[0];
}

prim 'see', sub {
	$tib =~ s/\s*(\S+)\s?//;
	my ($code_field, $def) = @{$dic{$1}};
	if ($code_field eq \&do_colon) {
		print " : $1   ";
		foreach (@$def) {
			print +(ref ($_) and ref ($_) eq 'ARRAY') ?
					name_of ($_) :
					$_,
				" ";
		}
	} elsif ($code_field eq \&do_const) {
		print " value $1   $def ";
	} else {
		print " $1 is primitive ";
	}
};

#######################################
#	END DICTIONARY
#######################################

#######################################
# Interpreter
#
# $tib: terminal input buffer
#######################################
# execute a line written in Forth
sub line ($) {
	local ($tib) = @_;
	while ($tib =~ s/\s*(\S+)\s?//m) {
		if ($state == 0 || $immediate {$1}) {
			# interpret now
			if ($dic {$1}) {   # Execute
				do_execute ($dic {$1});
			} else {   # Number, eval expression
				push @st, eval $1;
			}
		} else {
			push @$adef,
				$dic{$1} ?
				$dic{$1} :
				($dic{'literal'}, eval $1);
		}
	}
}

# Forth Interpreter
sub interpret () {
	$state = 0;
	while (<>) {
		line ($_);
		print "ok\n" unless $state;
	}
}

# call Forth from Perl
# initialize @st with given values
# example: forth (4, 5, '- .')
# ist the same as: 4 5 - .
sub forth (@) {	# @stack (top of stack is right), "string to interpret"
	my $line = pop;
	local @st = @_;
	local $state = 0;
	line ($line);
	@st;
}

# some high level definitions
forth (<<'END');

	: cr   perl" print "\n" "perl drop ;

	: ls   perl" print `ls` "perl drop ;

END

1;

__END__

=head1 NAME

B<Language::PGForth> - Forth Interpreter in Perl

=head1 DESCRIPTION

PGForth is a Forth interpreter written in Perl.  It is very simple and tries
to minimize the effort of calling one language from another.

=head1 EXAMPLES

see file "run" in distribution

=head1 BUGS

No error handling at all.

=head1 AUTHOR

Peter Gallasch <gal@adv.magwien.gv.at>, Municipality of Vienna, Austria

=cut
