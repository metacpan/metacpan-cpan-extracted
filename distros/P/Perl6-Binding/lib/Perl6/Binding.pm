##==============================================================================
## Perl6::Binding - implement Perl6 aliasing features
##==============================================================================
## $Id: Binding.pm,v 1.1 2004/05/23 01:54:13 kevin Exp $
##==============================================================================
require 5.006;

package Perl6::Binding;
use strict;
use warnings;
our $VERSION = '0.601';
require XSLoader;
XSLoader::load('Perl6::Binding', $VERSION);

use Filter::Util::Call;
use Text::Balanced qw(extract_bracketed);
use PadWalker;
use Carp;

our %INSTALLED;

=head1 NAME

Perl6::Binding - implement Perl6 aliasing features

=head1 SYNOPSIS

	use Perl6::Binding;

	my ($foo, @bar, %baz) := @hash{qw/foo bar baz/};
	my ($foo, @bar, %baz) := *%hash;
	my ($foo, @bar, %baz) := *@array;
	my @array1 := @array2;

=head1 DESCRIPTION

This module creates lexical aliases to items that can be either lexical or
dynamic using the C<:=> operator. The left side of C<:=> is a variable or a list
of variable names in parentheses. The right side is a list of items to which the
items on the left should should refer. Each item on the left side is made an
alias to the corresponding item on the right.

=head2 What's an Alias?

An I<alias> is a way of making the same value have more than one way to get at
it.  For example, after the statement:

	my $foo := $array[2];

anyplace you refer to C<$foo>, you are actually referring to C<$array[2]>.
Changing either one is the same as changing the other. If you take a reference
to each of them, you'll discover that the references are identical.

The example above may not look that useful, but something like this could be:

	my %hash := %{$parameter->{index}->{option}};

Now you can type C<$hash{foo}> instead of C<<
$parameter->{index}->{option}->{foo} >>. Not only does this save typing, but it
should execute slighly faster as well.

Perl automatically creates aliases to the items in the C<@_> array when a
function is called, and to the variable in a B<foreach> statement. So, after a
statement like

	my ($foo, @bar, %baz) := *@_;

the items are aliases to the actual parameters passed to the function. Changing
the value of C<$foo> changes the value of the item that was passed as the first
parameter.

The C<*> on the right side of C<:=> indicates that the item it prefixes is to be
I<flattened>. That is, the contents are considered as if they had been added to
the list explicitly. The following two lines are equivalent, except that the
second one requires less typing:

	my ($foo, @bar, %baz) := ($array[0], @{$array[1]}, %{$array[2]});
	my ($foo, @bar, %bax) := *@array;

The C<*> can appear before any number of items on the right side, and before
either arrays or hashes. However, using it on a hash causes everything after it
on the right side to be ignored, and selects the items from the hash that are to
be aliased from the names of the variables on the left side. The following two
statements have identical effects:

	my ($foo, @bar, %baz) := @hash{qw/foo bar baz/};
	my ($foo, @bar, %baz) := *%hash;

You can also do something like this:

	my ($name, *@parameters) := *@_;

This says that C<$name> is to be an alias to C<$_[0]>, while the rest of the
contents of C<@_> are copied to C<@parameters>, which becomes a "real" array
rather than an alias. Changing the items in C<@parameters> does I<not> affect
the values passed to the function. The C<*> on the left side says "throw
everything else into this variable." It may only be used on the last item (or
rather, anything after it in the list will neither become an alias to anything
nor have a value assigned to it).

If the variable prefixed by C<*> is a scalar, it receives the count of the
remaining items rather than any of the items themselves.

The type of the left item and the type of the right item must match. The
following statements are invalid:

	my @foo := %bar;
	my $baz := @foobar;

This module works both at compile time (via a source filter) and at runtime.

=head1 NOTES

=over 4

=item *

It's possible that the source filter might find something that looks like the
statements it handles in odd locations, such as within a string. If this
happens, use C<no Perl6::Binding> to turn off the filter where necessary. Don't
forget to turn it back on afterwards!

=item *

This is currently alpha software. It seems to work, but I am sure there are odd
bugs lurking in the woodwork. Please let me know if you find them.

=item *

Version 0.6 fixes a long-standing problem in that bindings in recursive
subroutines did not work.  Now they do.

=item *

Version 0.601 is an update to 0.6 that puts the dependencies back into the Makefile.PL.

=back

=head1 REQUIRED MODULES

L<Filter::Util::Call|Filter::Util::Call>

L<Text::Balanced|Text::Balanced>

L<PadWalker|PadWalker>

=head1 BUGS

Under Perl 5.8.x, it is not possible to create aliases at the root level
of the program due to a problem in PadWalker 0.09 and 0.10 (see the README
for PadWalker).  Aliases created in subroutines continue to work, however.

=head1 ACKNOWLEDGEMENTS

Some code was taken from Devel::LexAlias and Devel::Caller, both by Richard
Clamp.

The name Perl6::Binding was suggested by Benjamin Goldberg.

=head1 AUTHOR

Kevin Michael Vail <F<kevin>@F<vaildc>.F<net>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Kevin Michael Vail

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

##==============================================================================
## import - install the filter
##==============================================================================
sub import {
	my $caller = (caller)[1];
	unless ($INSTALLED{$caller}) {
		shift;
		filter_add({ @_ });
		$INSTALLED{$caller} = 1;
	}
}

##==============================================================================
## unimport - uninstall the filter
##==============================================================================
sub unimport {
	my $caller = (caller)[1];
	if ($INSTALLED{$caller}) {
		filter_del();
		delete $INSTALLED{$caller};
	}
}

##==============================================================================
## filter - do the actual work
##==============================================================================
sub filter {
	my ($f) = @_;
	my $status = filter_read();

	return $status if $status <= 0 || /^\s*#/;
	if (/^(.*)\b(my\b.*)$/s) {
		my $prior = $1;
		$_ = $2;
		my $recovery = '';
		my $parser = $f->_parser;
		my $newline_count = 0;
		my $need_line = 0;
		my ($token, $value);
		OUTER: while (1) {
			do {
				if ($need_line) {
					$status = filter_read();
					$need_line = 0;
					croak "unexpected EOF or error" if $status <= 0;
				}
				s/^(\s*)//;
				$recovery .= $1;
				if (/^(my|undef)\b(.*)$/s
				 || /^(\(|\)|\*|\@|\$|%|:=|,|;)(.*)$/s) {
					$token = $1;
					$value = undef;
					$_ = $2;
					$recovery .= $1;
				} elsif (/^(\w+)(.*)$/s) {
					$token = 'identifier';
					$value = $1;
					$_ = $2;
					$recovery .= $1;
				} elsif (/^[{\[]/) {
					my $text;
					do {
						$text = extract_bracketed($_, '[{"\'q}]');
					} while (!$text && ($status = filter_read()) > 0);
					if ($text ne '') {
						$token = substr($text, 0, 1) eq '{'
							? 'bracexpr' : 'brackexpr';
						$value = $text;
						$recovery .= $text;
					} else {
						$_ = $prior. $recovery . $_;
						return $status;
					}
				} elsif (/^#/) {
					$recovery .= $_;
					$need_line = 1;
				} elsif (!/^$/) {
					$_ = $prior . $recovery . $_;
					return $status;
				} else {
					$need_line = 1;
				}
			} while $need_line;
			eval { $parser->parse($token, $value) };
			if ($@) {
				$_ = $prior. $recovery. $_;
				return $status;
			}
			last if $token eq ';';
		}
		my $result = $parser->finish;
		$_ = ("\n" x $newline_count) . $_;
		$_ = $prior . $f->_process($result) . $_;
	}
	return $status;
}

##==============================================================================
## _process - take the result from the parser and build appropriate statements.
##==============================================================================
sub _process {
	my ($f, $result) = @_;
	my ($left, $right) = @$result;
	$result  = 'my ('
			 . join(
				', ',
				map { $_->[1] } grep { $_->[0] ne 'undef' } @$left
			 )
			 . '); ';
	$result .= 'Perl6::Binding::alias(['
			 . join(
			 	', ',
			 	map {
			 		$_->[0] eq 'var'
			 			? qq{[ 0, '@{[$_->[1]]}', \\@{[$_->[1]]} ]}
			 		: $_->[0] eq 'flatten'
			 			? qq{[ 1, '@{[$_->[1]]}', \\@{[$_->[1]]} ]}
			 			: 'undef';
			 	} @$left
			 )
			 . '], '
			 . join(
			 	', ',
			 	map {
			 		$_->[0] eq 'var'
			 			? qq{[ 0, @{[$_->[1]]} ]}
			 		: $_->[0] eq 'flatten'
			 			? qq{[ 1, @{[$_->[1]]} ]}
			 			: qq{[ 2, @{[$_->[1]]} ]};
			 	} @$right
			 )
			 . ');';
	return $result;
}

##==============================================================================
## _parser - return parser object, creating if necessary
##==============================================================================
sub _parser {
	my ($f) = @_;

	unless (exists $f->{parser}) {
		$f->{parser} = new Perl6::Binding::Grammar;
	}
	$f->{parser}->reset;
	return $f->{parser};
}

##==============================================================================
## alias(\@left, @right);
## Create the actual aliases. The left side is a reference to an array of
## array references or undef values. The array reference has three elements.
## The first is either 0 for the normal case or 1 for the "flattened" case.
## The second is a string containing the name of the variable.
## The third is a reference to the variable.
## The right side is an actual array (not a reference) containing array
## references.  Each of these contains two or more elements. The first is 0
## for the normal case or 1 for a flattened case, or 2 if the original item
## is a hash or array slice. If the first element is 0 or 1, the second element
## is a single reference to the target item. If the first element is 2, there
## will be one or more references to scalars (or references to references if
## the element in the slice is itself a hash or array reference).
## This routine is called at runtime.
##==============================================================================
sub alias {
	my $left = shift;
	my $cx = PadWalker::_upcontext(1);
	my $cv = $cx ? _context_cv($cx) : 0;
	my ($rtype, $rpos, @rrefs);

	foreach (@$left) {
		##----------------------------------------------------------------------
		## Create an alias to the next element on the right side if this item
		## is defined.
		##----------------------------------------------------------------------
		if (defined $_) {
			my ($flattened, $varname, $varref) = @$_;
			my ($vartype, $varid) = unpack('a1a*', $varname);
			##------------------------------------------------------------------
			## If flattened, just assign what's left in @_ to the variable in
			## question. A scalar gets the count of the items left.
			##------------------------------------------------------------------
			if ($flattened) {
				if ($vartype eq '$') {
					$$varref = @_;
				} elsif ($vartype eq '@') {
					@$varref = @_;
				} elsif ($vartype eq '%') {
					%$varref = @_;
				} else {
					die "internal error: invalid vartype '$vartype'";
				}
				last;	## no sense in continuing!
			}
			##------------------------------------------------------------------
			## Not flattened.  Actually get the next element from the right
			## side and create an alias to it in the element on the left side.
			##------------------------------------------------------------------
			elsif (@_) {
				unless (defined $rtype) {
					($rtype, @rrefs) = @{$_[0]};
					$rpos = 0;
				}
				##--------------------------------------------------------------
				## If this is a normal alias (type 0), the item in $varref
				## simply becomes an alias to the item in $rcurrent.
				##--------------------------------------------------------------
				if ($rtype == 0) {
					my $value = $rrefs[0];
					_lexalias($cv, $varname, $value);
					undef $rtype;
					shift;
				}
				##--------------------------------------------------------------
				## If this is a flattened alias (type 1), decode the item in
				## $rcurrent so that it becomes a list of items.  For a hash,
				## we can't actually do this since the aliased items depend on
				## the names of the variables on the left side.
				##--------------------------------------------------------------
				elsif ($rtype == 1) {
					my $rref = $rrefs[0];
					if (UNIVERSAL::isa($rref, 'HASH')) {
						croak "key '$varid' doesn't exist"
							unless exists $rref->{$varid};
						if ((ref $rref->{$varid}) =~ /^ARRAY|HASH$/
						  && $vartype ne '$') {
						  	my $value = $rref->{$varid};
							_lexalias($cv, $varname, $value);
						} else {
							_lexalias($cv, $varname, \$rref->{$varid});
						}
					} elsif (UNIVERSAL::isa($rref, 'ARRAY')) {
						if ($rpos >= @$rref) {
							undef $rtype;
							shift;
							redo;
						} elsif ((ref $rref->[$rpos]) =~ /^ARRAY|HASH$/
						  && $vartype ne '$') {
						  	my $value = $rref->[$rpos++];
							_lexalias($cv, $varname, $value);
						} else {
							_lexalias($cv, $varname, \$rref->[$rpos++]);
						}
					} else {
						croak "invalid type after *: must be % or @";
					}
				}
				##--------------------------------------------------------------
				## If this is an array or a hash slice (type 2), the rest of
				## the items in $rcurrent are references to scalars or other
				## references. Assign these one at a time to the items on the
				## left.
				##--------------------------------------------------------------
				elsif ($rtype == 2) {
					if ($rpos >= @rrefs) {
						undef $rtype;
						shift;
						redo;
					} else {
						my $rref = $rrefs[$rpos++];
						if (UNIVERSAL::isa($rref, 'SCALAR') && !ref $$rref) {
							_lexalias($cv, $varname, $rref);
						} else {
							_lexalias($cv, $varname, $$rref);
						}
					}
				} else {
					die "internal error: invalid reference type";
				}
			}
			##------------------------------------------------------------------
			## If there aren't any more arguments on the right, might as well
			## exit the loop.
			##------------------------------------------------------------------
			else {
				last;
			}
		}
		##----------------------------------------------------------------------
		## Otherwise, skip the next item on the right side.
		##----------------------------------------------------------------------
		else {
			unless (defined $rtype) {
				($rtype, @rrefs) = @{$_[0]};
				$rpos = 0;
			}
			if ($rtype == 0) {
				undef $rtype;
				shift;
			} elsif ($rtype == 1) {
				my $rref = $rrefs[0];
				if (UNIVERSAL::isa($rref, 'ARRAY')) {
					if ($rpos++ >= @$rref) {
						undef $rtype;
						shift;
						redo;
					}
				}
			}
		}
	}
}

BEGIN {
##%BEGIN GRAMMAR

package Perl6::Binding::Grammar;
use strict;
use vars qw(@RuleTexts @StateDefaults @RuleTokenCounts @RuleTokens
			@Reductions %TransitionTable %GotoTable %Attributes);



@RuleTexts = (
	"\$accept : statement \$end",
	"statement : my left-side := right-side ;",
	"left-side : left-side-item",
	"left-side : ( left-side-item-list )",
	"left-side-item-list : left-side-item",
	"left-side-item-list : left-side-item-list , left-side-item",
	"left-side-item : variable-type var_identifier",
	"left-side-item : * variable-type var_identifier",
	"left-side-item : undef",
	"right-side : right-side-item",
	"right-side : ( right-side-item-list )",
	"right-side-item-list : right-side-item",
	"right-side-item-list : right-side-item-list , right-side-item",
	"right-side-item : variable-type opt-deref var_identifier",
	"right-side-item : * variable-type opt-deref var_identifier",
	"right-side-item : variable-type opt-deref var_identifier bracexpr",
	"right-side-item : variable-type opt-deref var_identifier brackexpr",
	"right-side-item : variable-type bracexpr",
	"right-side-item : * variable-type bracexpr",
	"right-side-item : variable-type bracexpr bracexpr",
	"right-side-item : variable-type bracexpr brackexpr",
	"variable-type : \$",
	"variable-type : @",
	"variable-type : %",
	"opt-deref :",
	"opt-deref : deref-list",
	"deref-list : \$",
	"deref-list : deref-list \$",
	"var_identifier : identifier",
	"var_identifier : my",
	"var_identifier : undef",
);

@StateDefaults = (
	"Expected my",
	"Expected @, \$, %, (, *, or undef",
	"Expected \$end",
	-22,
	-21,
	-23,
	"Expected :=",
	"Expected @, \$, %, *, or undef",
	"Expected @, \$, or %",
	-8,
	-2,
	"Expected my, undef, or identifier",
	0,
	"Expected @, \$, %, (, or *",
	"Expected ) or ,",
	-4,
	"Expected my, undef, or identifier",
	-6,
	-29,
	-30,
	-28,
	"Expected ;",
	-9,
	"Expected @, \$, %, or *",
	"Expected @, \$, or %",
	24,
	-3,
	"Expected @, \$, %, *, or undef",
	-7,
	-1,
	-11,
	"Expected ) or ,",
	24,
	25,
	-26,
	17,
	"Expected my, undef, or identifier",
	-5,
	-10,
	"Expected @, \$, %, or *",
	-18,
	"Expected my, undef, or identifier",
	-27,
	-19,
	-20,
	13,
	-12,
	-14,
	-15,
	-16,
);

@RuleTokenCounts = (
	2,
	5,
	1,
	3,
	1,
	3,
	2,
	3,
	1,
	1,
	3,
	1,
	3,
	3,
	4,
	4,
	4,
	2,
	3,
	3,
	3,
	1,
	1,
	1,
	0,
	1,
	1,
	2,
	1,
	1,
	1,
);

@RuleTokens = (
	"\$accept",
	"statement",
	"left-side",
	"left-side",
	"left-side-item-list",
	"left-side-item-list",
	"left-side-item",
	"left-side-item",
	"left-side-item",
	"right-side",
	"right-side",
	"right-side-item-list",
	"right-side-item-list",
	"right-side-item",
	"right-side-item",
	"right-side-item",
	"right-side-item",
	"right-side-item",
	"right-side-item",
	"right-side-item",
	"right-side-item",
	"variable-type",
	"variable-type",
	"variable-type",
	"opt-deref",
	"opt-deref",
	"deref-list",
	"deref-list",
	"var_identifier",
	"var_identifier",
	"var_identifier",
);

@Reductions = (
	\&PASS,
	sub {
			[ $_[2], $_[4] ];
	},
	\&MAKELIST,
	sub {
			$_[2];
	},
	\&MAKELIST,
	\&DLIST,
	sub {
			[ 'var', "$_[1]$_[2]" ];
	},
	sub {
			[ 'flatten', "$_[2]$_[3]" ];
	},
	sub {
			[ 'undef' ];
	},
	\&MAKELIST,
	sub {
			$_[2];
	},
	\&MAKELIST,
	\&DLIST,
	sub {
			[ 'var', "\\$_[1]$_[2]$_[3]" ];
	},
	sub {
			[ 'flatten', "\\$_[2]$_[3]$_[4]" ];
	},
	sub {
			[ 'slice', "\\$_[1]$_[2]$_[3]$_[4]" ];
	},
	sub {
			[ 'slice', "\\$_[1]$_[2]$_[3]$_[4]" ];
	},
	sub {
			[ 'var', "\\$_[1]$_[2]" ];
	},
	sub {
			[ 'flatten', "\\$_[2]$_[3]" ];
	},
	sub {
			[ 'slice', "\\$_[1]$_[2]$_[3]" ];
	},
	sub {
			[ 'slice', "\\$_[1]$_[2]$_[3]" ];
	},
	sub {
			'$';
	},
	sub {
			'@';
	},
	sub {
			'%';
	},
	sub {
			'';
	},
	sub {
			$_[1];
	},
	sub {
			'$';
	},
	sub {
			$_[1] . '$';
	},
	sub {
			$_[1];
	},
	sub {
			'my';
	},
	sub {
			'undef';
	},
);

%TransitionTable = (
	"@" => sub {
		(grep { $_ == $_[1] } (1, 7, 8, 13, 23, 24, 27, 39)) && $_[0]->shift(3,
$_[2])
	},
	":=" => sub {
		$_[1] == 6 && $_[0]->shift(13, $_[2])
	},
	"\$" => sub {
		$_[1] == 33 && $_[0]->shift(42, $_[2])
		or (grep { $_ == $_[1] } (25, 32)) && $_[0]->shift(34, $_[2])
		or (grep { $_ == $_[1] } (1, 7, 8, 13, 23, 24, 27, 39)) &&
$_[0]->shift(4, $_[2])
	},
	"%" => sub {
		(grep { $_ == $_[1] } (1, 7, 8, 13, 23, 24, 27, 39)) && $_[0]->shift(5,
$_[2])
	},
	"(" => sub {
		$_[1] == 1 && $_[0]->shift(7, $_[2])
		or $_[1] == 13 && $_[0]->shift(23, $_[2])
	},
	"\$end" => sub {
		$_[1] == 2 && $_[0]->shift(12, $_[2])
	},
	")" => sub {
		$_[1] == 31 && $_[0]->shift(38, $_[2])
		or $_[1] == 14 && $_[0]->shift(26, $_[2])
	},
	"my" => sub {
		$_[1] == 0 && $_[0]->shift(1, $_[2])
		or (grep { $_ == $_[1] } (11, 16, 36, 41)) && $_[0]->shift(18, $_[2])
	},
	"bracexpr" => sub {
		$_[1] == 45 && $_[0]->shift(48, $_[2])
		or $_[1] == 32 && $_[0]->shift(40, $_[2])
		or $_[1] == 35 && $_[0]->shift(43, $_[2])
		or $_[1] == 25 && $_[0]->shift(35, $_[2])
	},
	"*" => sub {
		(grep { $_ == $_[1] } (1, 7, 27)) && $_[0]->shift(8, $_[2])
		or (grep { $_ == $_[1] } (13, 23, 39)) && $_[0]->shift(24, $_[2])
	},
	";" => sub {
		$_[1] == 21 && $_[0]->shift(29, $_[2])
	},
	"," => sub {
		$_[1] == 31 && $_[0]->shift(39, $_[2])
		or $_[1] == 14 && $_[0]->shift(27, $_[2])
	},
	"identifier" => sub {
		(grep { $_ == $_[1] } (11, 16, 36, 41)) && $_[0]->shift(20, $_[2])
	},
	"undef" => sub {
		(grep { $_ == $_[1] } (1, 7, 27)) && $_[0]->shift(9, $_[2])
		or (grep { $_ == $_[1] } (11, 16, 36, 41)) && $_[0]->shift(19, $_[2])
	},
	"brackexpr" => sub {
		$_[1] == 45 && $_[0]->shift(49, $_[2])
		or $_[1] == 35 && $_[0]->shift(44, $_[2])
	},
);

%GotoTable = (
	0 => {
		'statement' => 2,
	},
	39 => {
		'right-side-item' => 46,
		'variable-type' => 25,
	},
	1 => {
		'left-side-item' => 10,
		'left-side' => 6,
		'variable-type' => 11,
	},
	11 => {
		'var_identifier' => 17,
	},
	7 => {
		'left-side-item-list' => 14,
		'left-side-item' => 15,
		'variable-type' => 11,
	},
	13 => {
		'right-side-item' => 22,
		'right-side' => 21,
		'variable-type' => 25,
	},
	8 => {
		'variable-type' => 16,
	},
	23 => {
		'right-side-item' => 30,
		'right-side-item-list' => 31,
		'variable-type' => 25,
	},
	32 => {
		'deref-list' => 33,
		'opt-deref' => 41,
	},
	16 => {
		'var_identifier' => 28,
	},
	24 => {
		'variable-type' => 32,
	},
	41 => {
		'var_identifier' => 47,
	},
	25 => {
		'deref-list' => 33,
		'opt-deref' => 36,
	},
	27 => {
		'left-side-item' => 37,
		'variable-type' => 11,
	},
	36 => {
		'var_identifier' => 45,
	},
);

%Attributes = (
);

sub PASS {
	$_[1];
}

sub MAKELIST {
	[ $_[1] ];
}

sub CLIST {
	push @{$_[1]}, $_[2];
	$_[1];
}

sub DLIST {
	push @{$_[1]}, $_[3];
	$_[1];
}

sub new {
	my ($class, %options) = @_;
	my $parser = bless {}, $class;
	$parser->initialize(\%options);
	return $parser;
}

sub initialize {
	my ($parser, $options) = @_;
	my $class = ref $parser;

	$parser->{lrDebug} = delete $options->{-debug};
	$parser->reset;

	if ($^W) {
		warn "invalid option '$_' passed to $class\::initialize\n"
			foreach (keys %$options);
	}
}

sub reset {
	my ($parser) = @_;

	$parser->{lrStates} = [ 0 ];
	$parser->{lrTokens} = [ undef ];
	$parser->{lrValues} = [ undef ];
	$parser->{lrTokLoc} = [ [ undef, undef, undef, undef ] ];
	$parser->{lrCurTok} = undef;
	$parser->{lrCurVal} = undef;
	$parser->{lrCurLoc} = undef;
	$parser->{lrRedLoc} = undef;
	$parser->{lrLocStk} = undef;
	$parser->{lrErrTok} = 'lrCurLoc';
	$parser->{lrParseResult} = undef;
}

sub parse {
	my $parser = shift;
	my $accepted;

	OUTER: while (@_) {
		@{$parser}{qw/lrCurTok lrCurVal lrCurLoc/} = splice @_, 0, 3;
		while (defined $parser->{lrCurTok}) {
			my $state = $parser->{lrStates}->[-1];
			my $default = $StateDefaults[$state];
			if ($default =~ /^-(\d+)$/) {
				$parser->reduce($1);
			} elsif ($default eq "0") {
				$parser->reduce(0);
				print "accept\n" if $parser->{lrDebug};
				$parser->{lrParseResult} = $parser->accept;
				$accepted = 1;
				last OUTER;
			} else {
				my $action = $TransitionTable{$parser->{lrCurTok}};
				unless (defined $action) {
					$parser->error("invalid token: @{[$parser->{lrCurTok}]}");
				}
				unless ($action->($parser, $state, $parser->{lrCurVal})) {
					if ($default =~ /^\d+$/) {
						$parser->reduce($default);
					} else {
						$parser->error($default);
					}
				}
			}
		}
	}

	return $accepted;
}

sub finish {
	my ($parser) = @_;

	1 until $parser->parse('$end', undef);
	my $result = $parser->{lrParseResult};
	return $result;
}

sub shift {
	my ($parser, $state) = @_;

	if ($parser->{lrDebug}) {
		my ($curtok, $curval) = @{$parser}{qw/lrCurTok lrCurVal/};
		if (defined $curval && $curtok ne $curval) {
			$curtok .= "<$curval>";
		}
		print "token = $curtok, ",
			  "state = @{[$parser->{lrStates}->[-1]]} : shift $state\n";
	}
	push @{$parser->{lrStates}}, $state;
	push @{$parser->{lrValues}}, $parser->{lrCurVal};
	push @{$parser->{lrTokens}}, $parser->{lrCurTok};
	push @{$parser->{lrTokLoc}}, $parser->{lrCurLoc};
	undef $parser->{lrCurTok};

	1;
}

sub reduce {
	my ($parser, $rule) = @_;

	local $parser->{lrErrTok} = 'lrRedLoc';
	$parser->{lrLocStk} = [];
	my (@args, $value);
	my $count = $RuleTokenCounts[$rule];
	$parser->error("invalid rule in reduce: $rule") unless defined $count;
	if ($parser->{lrDebug}) {
		print "reduce $rule : $RuleTexts[$rule]\n";
	}
	if ($count > 0) {
		@args = splice @{$parser->{lrValues}}, -$count, $count;
		splice @{$parser->{lrTokens}}, -$count, $count;
		splice @{$parser->{lrStates}}, -$count, $count;
		@{$parser->{lrLocStk}} = splice @{$parser->{lrTokLoc}}, -$count, $count;
		$parser->{lrRedLoc} = $parser->{lrLocStk}->[0];
	}
	$value = $Reductions[$rule]->($parser, @args);
	push @{$parser->{lrTokens}}, $RuleTokens[$rule];
	push @{$parser->{lrValues}}, $value;
	push @{$parser->{lrTokLoc}}, $parser->{lrRedLoc};
	my $state = $parser->{lrStates}->[-1];
	push @{$parser->{lrStates}},
		$GotoTable{$state}->{$RuleTokens[$rule]};

	1;
}

sub accept {
	return $_[0]->{lrValues}->[-1];
}

sub error {
	my ($parser, @msg) = @_;

	die join('', @msg);
}

1;
##%END GRAMMAR
}

1;

##==============================================================================
## $Log: Binding.pm,v $
## Revision 1.1  2004/05/23 01:54:13  kevin
## Fix Makefile.PL.
##
## Revision 1.0  2004/05/23 01:12:28  kevin
## Initial revision
##
## Revision 0.5  2003/12/17 03:58:31  kevin
## Complain if a hash element being aliased doesn't exist,
## rather than silently creating a new hash element.
##
## Revision 0.4  2003/06/19 02:20:47  kevin
## Some bug fixes, some major, some minor.
##
## Revision 0.3  2003/04/30 01:03:56  kevin
## Change to Makefile.PL to add proper prerequisites.
##
## Revision 0.2  2003/04/29 00:52:46  kevin
## Fix INSTALL functionality and s///.
##
## Revision 0.1  2003/04/27 06:26:41  kevin
## Initial Revision
##==============================================================================
