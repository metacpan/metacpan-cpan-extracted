# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


package Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare;
use 5.006;
use strict;
use warnings;
use List::Util qw(min max);
use base 'Perl::Critic::Policy';
# 1.100 for precedence_of() supporting -f etc filetests
use Perl::Critic::Utils 1.100 qw(is_perl_builtin
                                 is_perl_builtin_with_no_arguments
                                 precedence_of);

our $VERSION = 99;


use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => 'PPI::Token::Operator';

my %op_postfix = ('++'  => 1,
                  '--'  => 1);

my %op_andor = ('&&'  => 1,
                '||'  => 1,
                '//'  => 1,
                'and' => 1,
                'or'  => 1,
                'xor' => 1);

my %post_control = (if      => 1,
                    unless  => 1,
                    until   => 1,
                    for     => 1,
                    foreach => 1,
                    while   => 1);

my %is_bad_precedence = (precedence_of('=~') => 1,
                         precedence_of('>')  => 1,
                         precedence_of('==') => 1);
my $stop_precedence = max (keys %is_bad_precedence);


sub violates {
  my ($self, $bang_elem, $document) = @_;
  if ($bang_elem->content ne '!') { return; }
  my $constants;

  # only report when "!" is at the start of an expression, so "-f ! $x" is
  # not applicable (though bizarre), or with "! ! $x" look only from the
  # first "!"
  if (my $prev = $bang_elem->sprevious_sibling) {
    if ($prev->isa('PPI::Token::Operator')) {
      my $op = $prev->content;
      if (! $op_andor{$op}) { # but do look following "&&" etc
        return;
      }
    }
  }

  my $state = 'prefix';
  my $seen_precedence = 1;

  my $elem = $bang_elem;
  for (;;) {
    $elem or return;  # nothing evil up to end of expression
    $elem = $elem->snext_sibling
      or return;      # nothing evil up to end of expression

    if ($elem->isa('PPI::Token::Cast')) {
      # "\ &foo" is a single form, not a function call
      $elem = _next_cast_operand ($elem);
      $state = 'postfix';
      next;
    }

    if ($elem->isa('PPI::Token::Symbol')) {
      $state = 'postfix';
      if ($elem->content =~ /^&/) {
        if (my $after = $elem->snext_sibling) {
          if ($after->isa('PPI::Structure::List')) {
            $elem = $after; # "! &foo() == 1"
            next;
          }
        }
        # "! &foo ..." varargs function call, eats to "," or ";"
        return;
      }
      next; # "! $x" etc
    }

    if ($elem->isa('PPI::Token::Operator')) {
      my $op = $elem->content;

      if ($state eq 'postfix' && $op_postfix{$op}) {
        next;  # stay in postfix state after '++' or '--'
      }
      if ($state eq 'prefix' && $op eq '<') {
        # in prefix position assume "<" is "<STDIN>" glob or readline
        $elem = _next_gt ($elem);
        $state = 'postfix';
        next;  # can leave $elem undef for something dodgy like "! < 123"
      }
      my $precedence = precedence_of($op) || return;

      if ($precedence > $stop_precedence) {
        return;  # something below "==" etc, expression to ! is ok
      }
      if (($op eq '==' || $op eq '!=') && _snext_is_bang($elem)) {
        return;  # special case "! $x == ! $y" is ok
      }
      if ($op eq '->') {
        if (my $method = $elem->snext_sibling) {
          $elem = $method;
          $state = 'postfix';
          if (my $after = $method->snext_sibling) {
            if ($after->isa('PPI::Token::Operator')) {
              next;  # "! $foo->bar == 1"
            }
            if ($after->isa('PPI::Structure::List')) {
              $elem = $after; # "! $foo->bar() == 1"
              next;
            }
            # bogosity "$foo->bar 123, 456" or the like
            return;
          }
        }
      }

      if ($seen_precedence <= $precedence && $is_bad_precedence{$precedence}) {
        # $op is a compare, so bad
        return $self->violation
          ("Logical \"!\" attempted with a compare \"$op\"",
           '', $bang_elem);
      }
      $seen_precedence = max ($precedence, $seen_precedence);
      $state = 'prefix';
      next;
    }

    if ($elem->isa('PPI::Token::Word')) {
      my $word = $elem->content;

      if ($post_control{$word}) {
        return;  # postfix control like "$foo = ! $foo if ..." ends expression
      }
      if (is_perl_builtin_with_no_arguments ($word)) {
        # eg "! time ..."
        # "time" is a single token, look at operators past it
        $state = 'postfix';
        next;
      }

      $constants ||= _constants ($document);
      if (exists $constants->{$word}) {
        # eg. use constant FOO => 456;
        #     ! FOO ...
        # the FOO is a single token, look at operators past it
        $state = 'postfix';
        next;
      }

      my $next = $elem->snext_sibling
        or return;  # "! FOO" expression ending at a bareword

      if ($next->isa('PPI::Structure::List')) {
        # "! FOO(...)" function call
        $elem = next;
        $state = 'postfix';
        next;
      }

      if (is_perl_builtin ($word)) {
        return; # builtins all taking args, eating "," or ";"
      }

      if ($next->isa('PPI::Token::Operator')) {
        my $op = $next->content;
        if ($op eq '<') {
          if (_next_gt ($next)) {
            # "! FOO <*.c>" assumed to be glob passed to varargs func, it
            # ends at "," or ";" so nothing bad for "!"
            return;
          }
        }
        # other "! FOO > 123" assumed to be a constant
        $state = 'postfix';
        next;
      }

      # otherwise word is a no parens call, like "foo 123, 456"
      # exactly how this parses depends on the prototype, but there's
      # going to be a "," or ";" terminating, so our "!" is ok
      return;
    }
  }

  return;
}

sub _snext_is_bang {
  my ($elem) = @_;
  my $next = $elem->snext_sibling;
  return ($next
          && $next->isa('PPI::Token::Operator')
          && $next eq '!');
}

# return the next ">" operator following $elem, or undef if no such
sub _next_gt {
  my ($elem) = @_;
  while ($elem = $elem->snext_sibling) {
    if ($elem->isa('PPI::Token::Operator') && $elem eq '>') {
      last;
    }
  }
  return $elem;
}

# $elem is a PPI::Token::Cast, return its operand elem, meaning the next
# non-Cast (usually a Symbol).  Return undef if no non-cast, for something
# dodgy like "\" with nothing following.
sub _next_cast_operand {
  my ($elem) = @_;
  while ($elem = $elem->snext_sibling) {
    if (! $elem->isa('PPI::Token::Cast')) {
      last;
    }
  }
  return $elem;
}

# return a hashref which has keys for all the "use constant"s defined in
# $document
sub _constants {
  my ($document) = @_;
  return ($document->{__PACKAGE__.'.NotWithCompareConstants'} ||= do {
    require Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt;
    my %constants;
    $document->find
      (sub {
         my ($document, $elem) = @_;
         @constants{ Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt::_use_constants($elem) }
           = ();  # hash slice
         return 0;  # no-match, and continue
       });
    \%constants;
  });
}

1;
__END__

=for stopwords booleans varargs builtins args Ryde

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare - logical not used with compare

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It picks up some cases of logical not C<!> used with a comparison,
like

    ! $x =~ /^[123]/  # bad
    ! $x + $y >= $z   # bad

In each case precedence means Perl parses this as C<< (!$x) >>, like

    (! $x) =~ /^[123]/
    (! $x) + $y >= $z

rather than a negated comparison.  Usually this is a mistake, so this policy
is under the "bugs" theme (see L<Perl::Critic/POLICY THEMES>).

As a special case, C<!> on both sides of C<< == >> or C<< != >> is allowed,
since it's quite a good way to compare booleans.

    !$x == !$y   # ok
    !$x != !$y   # ok

=head1 LIMITATIONS

User functions called without parentheses are assumed to be usual varargs
style.  But a prototype may mean that's not the case, letting a bad
C<!>-with-compare expression to go undetected.

    ! userfunc $x == 123   # indeterminate
    # without prototype would be ok:   ! (userfunc ($x==123))
    # with ($) prototype would be bad: (! userfunc($x)) == 123

Perl builtins with no args, and constant subs created with C<use constant>
or C<sub FOO () {...}> in the file under test are recognised.  Hopefully
anything else too weird is rare.

    ! time == 1   # bad

    use constant FIVE => 5;
    ! FIVE < 1    # bad

    sub name () { "foo" }
    ! name =~ /bar/    # bad

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut
