package Switch::Plain;

use v5.14.0;
use warnings;

use Carp qw(croak);

use XSLoader;
BEGIN {
    our $VERSION = '0.0501';
    XSLoader::load;
}

my %export = (
    sswitch => FLAG_SSWITCH,
    nswitch => FLAG_NSWITCH,
);

sub _port {
    my $op = shift;

    my $class = shift;

    my @todo;
    for my $item (@_) {
        push @todo, $export{$item} || croak qq{"$item" is not exported by the $class module};
    }
    for my $item (@todo ? @todo : values %export) {
        $op->(\$^H{+HINTK_FLAGS}, $item);
    }
}

sub import {
    _port sub { ${$_[0]} |= $_[1]; }, @_;
}

sub unimport {
    _port sub { ${$_[0]} &= ~$_[1]; }, @_;
}

'ok'
__END__

=encoding UTF-8

=head1 NAME

Switch::Plain - a simple switch statement for Perl

=head1 SYNOPSIS

  use Switch::Plain;
  
  # string version
  sswitch (get_me_a_string()) {
    # return value of get_me_a_string() is bound to $_ in this block
  
    case 'foo': {
      # runs if $_ equals 'foo'
    }
  
    case 'bar': {
      # runs if $_ equals 'bar'
    }
  
    case 'melonlord' if $DEBUG: {
      # runs if $_ equals 'melonlord' and $DEBUG is true
    }
  
    default if $VERBOSE > 1: {
      # runs if nothing else matched so far and $VERBOSE is greater than 1
    }
  
    default: {
      # runs if nothing else matched so far
    }
  }
  
  # number version
  nswitch (get_me_a_number()) {
    # return value of get_me_a_number() is bound to $_ in this block
  
    case 1: {
      # runs if $_ equals 1
    }
  
    case 2: {
      # runs if $_ equals 2
    }
  
    case 99 if $DEBUG: {
      # runs if $_ equals 99 and $DEBUG is true
    }
  
    default if $VERBOSE > 1: {
      # runs if nothing else matched so far and $VERBOSE is greater than 1
    }
  
    default: {
      # runs if nothing else matched so far
    }
  }

=head1 DESCRIPTION

This module provides (yet another) switch statement for Perl. Differences
between this module and L<Switch> include:

=over

=item *

It's not a source filter. (It uses perl's
L<pluggable keywords|perlapi/PL_keyword_plugin> instead.)

=item *

It generates non-horrible code. If you want to see this for yourself, run some
sample code through C<perl L<-MO=Deparse|B::Deparse>>.

=item *

It doesn't try to be smart about matching fancy data structures; it only does
simple string or numeric equality tests. This also sets it apart from perl's
built in L<C<given> statement|perlsyn/Switch-Statements> and
L<smartmatch operator C<~~>|perlop/Smartmatch-Operator>.

=back

=head2 Syntax

This module understands the following grammar:

  switch_statement := switch_keyword switch_scrutinee switch_body

  switch_keyword := 'sswitch' | 'nswitch'

  switch_scrutinee := '(' EXPR ')'

  switch_body := '{' case_clause* '}'

  case_clause := case_pattern+ BLOCK

  case_pattern := case_keyword case_modifier? ':'

  case_keyword := 'default' | 'case' EXPR

  case_modifier := 'if' EXPR | 'unless' EXPR

C<*>, C<+>, and C<?> have their usual regex meaning; C<BLOCK> and C<EXPR>
represent standard Perl blocks and expressions, respectively.

=head2 Semantics

The meaning of a switch statement is given by the following translation rules:

=over

=item *

C<sswitch (FOO) { ... }> and C<nswitch (FOO) { ... }> turn into

  do {
    local *_ = \FOO;
    ...
  };

That is, they alias L<C<$_>|perlvar/"$ARG"> to C<FOO> within the body of the switch statement.

=item *

A series of case clauses in the switch body turns into a single
L<C<if>/C<elsif>|perlsyn/Compound-Statements> chain. That is, the first clause
becomes an C<if>; every subsequent clause becomes an C<elsif>.

=item *

C<case FOO:> becomes C<if ($_ eq FOO)> for C<sswitch> and C<if ($_ == FOO)> for
C<nswitch>.

C<default:> becomes C<if (1)>.

C<case FOO if BAR:> becomes C<if ($_ eq FOO && BAR)> for C<sswitch> and
C<if ($_ == FOO && BAR)> for C<nswitch>.

C<default if BAR:> becomes C<if (BAR)>.

C<... unless BAR> works similarly, but with the condition inverted (C<!BAR>).

If there are multiple C<case>/C<default>s before a single block, their
conditions are combined with L<C<||>|perlop/C-style-Logical-Or>.

=back

Here's an example demonstrating all combinations:

  sswitch (SCRUTINEE) {
    case FOO0: {
      BODY0
    }

    case FOO1:
    case FOO2 if BAR1:
    case FOO3 unless BAR2:
    default if BAR3:
    default unless BAR4: {
      BODY1
    }

    default: {
      BODY2
    }
  }

This is equivalent to:

  do {
    # temporarily alias $_ to SCRUTINEE within this block:
    local *_ = \SCRUTINEE;

    if ($_ eq FOO0) {
      BODY0
    }
    elsif (
        $_ eq FOO1 ||
        ($_ eq FOO2 && BAR1) ||
        ($_ eq FOO3 && !BAR2) ||
        BAR3 ||
        !BAR4
    ) {
      BODY1
    }
    elsif (1) {
      BODY2
    }
  };

=head2 Differences between C<Switch::Plain> and C's C<switch>

=over

=item *

C's C<switch> is limited to integer scrutinees. C<Switch::Plain> supports any
number or string.

=item *

C's C<case> labels must be compile-time constants. C<Switch::Plain> allows any
expression and even additional arbitrary conditions via the C<if>/C<unless>
case modifiers.

=item *

C's C<case> labels are actual labels in that they can appear anywhere within
the C<switch> statement's body (even nested). With C<Switch::Plain> all
C<case>s must be at the top level.

=item *

In C the order of the C<case>s does not matter since they're all known at
compile time and guaranteed to be distinct. C<Switch::Plain> evaluates them in
the order they're written: If you put C<default: { ... }> in the middle of a
C<switch>, it will intercept all values, and any following C<case>s will be
ignored (this is like writing C<... elsif (1) { ... } else { ... }>).

=item *

Since C's C<case> labels are actual labels and C's C<switch> is effectively a
dynamic C<goto>, C actually has no concept of a "case clause" or a "case
block". C<switch> simply transfers control to one of the C<case>s and that's
it. This has the side effect of "fallthrough" behavior if you want to use C's
C<switch> to check for multiple distinct cases; that is, you must insert an
explicit C<break;> to leave the C<switch> statement when you're done with your
case.

C<Switch::Plain> has nothing of the kind. Because it turns into a single
C<if>/C<elsif> chain and every case block is clearly delimited, execution of
C<sswitch>/C<nswitch> stops as soon one case pattern matches. However, it is
possible to attach multiple case patterns to a single block:

  case 2:
  case 3:
  case 5: {
    ...
  }

This trivial case works the same way as fallthrough would in C (any value of 2,
3, or 5 is accepted).

=item *

Since C's C<break> refers to the innermost enclosing C<switch> or loop, you
can't use it in C<switch> to leave a surrounding loop (you have to use C<goto>
instead). This particular problem would be avoidable in Perl thanks to
L<loop labels|perlsyn/Compound-Statements>; however, this isn't even necessary
because C<sswitch>/C<nswitch> work like C<if>: They don't count as loops and
L<C<last>|perlfunc/last>/L<C<next>|perlfunc/next>/L<C<redo>|perlfunc/redo>
ignore them.

=back

=head2 Scoping

This module is a lexical pragma, i.e. the effects of C<use Switch::Plain>
(turning C<sswitch> and C<nswitch> into keywords) are scoped to the innermost
enclosing block (or the whole file if there is no enclosing block).

If you are a module author who wants to wrap C<Switch::Plain> from another
module, simply call C<< Switch::Plain->import >> from your own C<import>
method. It will affect whatever scope is currently being compiled (i.e. your
caller).

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012-2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
