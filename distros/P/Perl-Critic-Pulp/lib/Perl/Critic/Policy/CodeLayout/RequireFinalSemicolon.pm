# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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

package Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon;
use 5.006;
use strict;
use warnings;
use List::Util;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp;
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 96;

use constant supported_parameters =>
  ({ name           => 'except_same_line',
     description    => 'Whether to allow no semicolon at the end of blocks with the } closing brace on the same line as the last statement.',
     behavior       => 'boolean',
     default_string => '1',
   },
   { name           => 'except_expression_blocks',
     description    => 'Whether to allow no semicolon at the end of do{} expression blocks.',
     behavior       => 'boolean',
     default_string => '1',
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => qw(pulp cosmetic);
use constant applies_to       => 'PPI::Structure::Block';

sub violates {
  my ($self, $elem, $document) = @_;
  ### RequireFinalSemicolon elem: $elem->content

  if (_block_is_hash_constructor($elem) != 0) {
    ### hash constructor, or likely so, stop ...
    return;
  }

  my $block_last = $elem->schild(-1) || return;   # if empty
  ### block_last: ref($block_last),$block_last->content
  $block_last->isa('PPI::Statement') || do {
    ### last in block is not a PPI-Statement ...
    return;
  };
  if (_elem_statement_no_need_semicolon($block_last)) {
    return;
  }

  {
    my $bstat_last = $block_last->schild(-1)
      || return;   # statement shouldn't be empty, should it?
    ### bstat_last in statement: ref($bstat_last),$bstat_last->content

    if (_elem_is_semicolon($bstat_last)) {
      ### has final semicolon, ok
      return;
    }
  }

  if ($self->{'_except_expression_blocks'}) {
    if (_block_is_expression($elem)) {
      ### do expression, ok
      return;
    }
    ### not a do{} expression
  }

  # if don't have final brace then this option doesn't apply as there's no
  # final brace to be on the same line
  if ($self->{'_except_same_line'} && $elem->complete) {
    if (! _newline_in_following_sibling($block_last)) {
      ### no newline before close, ok
      return;
    }
  }

  my $report_at = $block_last->next_sibling || $block_last;
  return $self->violation
    ('Put semicolon ; on last statement in a block',
     '',
     $report_at);
}

# return true if $elem is a PPI::Statement subclass which doesn't require a
# terminating ";"
sub _elem_statement_no_need_semicolon {
  my ($elem) = @_;
  return ($elem->isa('PPI::Statement::Compound')  # for(){} etc
          || $elem->isa('PPI::Statement::Sub')    # nested named sub
          || $elem->isa('PPI::Statement::Given')
          || $elem->isa('PPI::Statement::When')
          || $elem->isa('PPI::Statement::End')    # __END__
          || $elem->isa('PPI::Statement::Null')   # ;
          || $elem->isa('PPI::Statement::UnmatchedBrace') # stray }
          || _elem_is_try_block($elem)
         );
}

my %postfix_loops = (while => 1, until => 1);

my %prefix_expressions = (do        => 1,
                          map       => 1,
                          grep      => 1,
                          sort      => 1,

                          map { $_ => 1, "List::Util::$_" => 1 }
                          qw(
                             reduce any all none notall first
                             pairfirst pairgrep pairmap
                            ),

                          map { $_ => 1, "List::Pairwise::$_" => 1 }
                          qw(
                             mapp map_pairwise grepp grep_pairwise
                             firstp first_pairwise lastp last_pairwise
                            ),
                         );

# $elem is a PPI::Structure::Block.
# return 1 definitely a hash
#        0 definitely a block
#       -1 not certain
#
# PPI 1.212 tends to be give PPI::Structure::Block for various things which
# are actually anon hash constructors and ought to be
# PPI::Structure::Constructor.  For example,
#
#     return bless { x => 123 };
#     return \ { x => 123 };
#
# _block_is_hash_constructor() tries to recognise some of those blocks which
# are actually hash constructors, so as not to apply the final semicolon
# rule to hash constructors.
#
my %word_is_block = (sub  => 1,
                     do   => 1,
                     map  => 1,
                     grep => 1,
                     sort => 1,

                     # from Try.pm, TryCatch.pm, Try::Tiny prototypes, etc
                     try     => 1,
                     catch   => 1,
                     finally => 1,

                     # List::Util first() etc are not of interest to
                     # RequireFinalSemicolon but ProhibitDuplicateHashKeys
                     # shares this code so recognise them for it.
                     %prefix_expressions,
                    );
sub _block_is_hash_constructor {
  my ($elem) = @_;
  ### _block_is_hash_constructor(): ref($elem), "$elem"

  # if (_block_starts_semi($elem)) {
  #   ### begins with ";", block is correct ...
  #   return 0;
  # }
  if (_block_has_multiple_statements($elem)) {
    ### contains one or more ";", block is correct ...
    return 0;
  }

  if (my $prev = $elem->sprevious_sibling) {
    ### prev: ref($prev), "$prev"
    if ($prev->isa('PPI::Structure::Condition')) {
      ### prev condition, block is correct ...
      return 0;
    }
    if ($prev->isa('PPI::Token::Cast')) {
      if ($prev eq '\\') {
        ### ref cast, is a hash ...
        return 1;
      } else {
        ### other cast, block is correct (or a variable name) ...
        return 0;
      }
    }
    if ($prev->isa('PPI::Token::Operator')) {
      ### prev operator, is a hash ...
      return 1;
    }
    if (! $prev->isa('PPI::Token::Word')) {
      ### prev not a word, not sure ...
      return -1;
    }

    if ($word_is_block{$prev}) {
      # "sub { ... }"
      # "do { ... }"
      ### do/sub/map/grep/sort, block is correct ...
      return 0;
    }

    if (! ($prev = $prev->sprevious_sibling)) {
      # "bless { ... }"
      # "return { ... }" etc
      # ENHANCE-ME: notice List::Util first{} and other prototyped things
      ### nothing else preceding, likely a hash ...
      return -1;
    }
    ### prev prev: "$prev"

    if ($prev eq 'sub') {
      # "sub foo {}"
        ### named sub, block is correct ...
        return 0;
    }
    # "word bless { ... }"
    # "word return { ... }" etc
    ### other word preceding, likely a hash ...
    return -1;
  }

  my $parent = $elem->parent || do {
    ### umm, toplevel, is a block
    return 0;
  };

  if ($parent->isa('PPI::Statement::Compound')
      && ($parent = $parent->parent)
      && $parent->isa('PPI::Structure::List')) {
    # "func({ %args })"
    ### in a list, is a hashref ...
    return 1;
  }

  return 0;
}

# $elem is a PPI::Structure::Block
# return true if it contains two or more PPI::Statement
#
sub _block_has_multiple_statements {
  my ($elem) = @_;
  my $count = 0;
  foreach my $child ($elem->schildren) {
    $count++;
    if ($count >= 2) { return 1; }
  }
  return 0;
}

# $elem is a PPI::Structure::Block
# return true if it starts with a ";"
#
sub _block_starts_semi {
  my ($elem) = @_;

  # note child() not schild() since an initial ";" is not "significant"
  $elem = $elem->child(0);
  ### first child: $elem && (ref $elem)."   $elem"

  $elem = _elem_skip_whitespace_and_comments($elem);
  return ($elem && $elem->isa('PPI::Statement::Null'));
}

# $elem is a PPI::Element or undef
# return the next non-whitespace and non-comment after it
sub _elem_skip_whitespace_and_comments {
  my ($elem) = @_;
  while ($elem
         && ($elem->isa('PPI::Token::Whitespace')
             || $elem->isa ('PPI::Token::Comment'))) {
    $elem = $elem->next_sibling;
    ### next elem: $elem && (ref $elem)."   $elem"
  }
  return $elem;
}

sub _elem_is_semicolon {
  my ($elem) = @_;
  return ($elem->isa('PPI::Token::Structure') && $elem eq ';');
}

# $elem is a PPI::Node
# return true if any following sibling (not $elem itself) contains a newline
sub _newline_in_following_sibling {
  my ($elem) = @_;
  while ($elem = $elem->next_sibling) {
    if ($elem =~ /\n/) {
      return 1;
    }
  }
  return 0;
}

# $block is a PPI::Structure::Block
# return true if it's "do{}" expression, and not a "do{}while" or "do{}until"
# loop
sub _block_is_expression {
  my ($elem) = @_;
  ### _block_is_expression(): "$elem"

  if (my $next = $elem->snext_sibling) {
    if ($next->isa('PPI::Token::Word')
        && $postfix_loops{$next}) {
      ### {}while or {}until, not an expression
      return 0;
    }
  }

  ### do, map, grep, sort, etc are expressions ..
  my $prev = $elem->sprevious_sibling;
  return ($prev
          && $prev->isa('PPI::Token::Word')
          && $prefix_expressions{$prev});
}

# Return true if $elem is a "try" block like
#     Try.pm                try { } catch {}
#     TryCatch.pm           try { } catch ($err) {} ... catch {}
#     Syntax::Feature::Try  try { } catch ($err) {} ... catch {} finally {}
# The return is true only for the block type "try"s of these three modules.
# "try" forms from Try::Tiny and its friends are plain subroutine calls
# rather than blocks.
#
sub _elem_is_try_block {
  my ($elem) = @_;
  return ($elem->isa('PPI::Statement')
          && ($elem = $elem->schild(0))
          && $elem->isa('PPI::Token::Word')
          && $elem->content eq 'try'
          && _elem_has_preceding_use_trycatch($elem));
}

# return true if $elem is preceded by any of
#     use Try
#     use TryCatch
#     use syntax 'try'
sub _elem_has_preceding_use_trycatch {
  my ($elem) = @_;
  my $ret = 0;
  my $document = $elem->top;  # PPI::Document, not Perl::Critic::Document
  $document->find_first (sub {
                           my ($doc, $e) = @_;
                           # ### comment: (ref $e)."  ".$e->content
                           if ($e == $elem) {
                             ### not found before target elem, stop ...
                             return undef;
                           }
                           if (_elem_is_use_try($e)) {
                             ### found "use Try" etc, stop ...
                             $ret = 1;
                             return undef;
                           }
                           return 0; # continue
                         });
  return $ret;
}

sub _elem_is_use_try {
  my ($elem) = @_;
  ($elem->isa('PPI::Statement::Include') && $elem->type eq 'use')
    or return 0;
  my $module = $elem->module;
  return ($module eq 'Try'
          || $module eq 'TryCatch'
          || ($module eq 'syntax'
             && _syntax_has_feature($elem,'try')));
}

# $elem is a PPI::Statement::Include of "use syntax".
# Return true if $feature (a string) is among the feature names it imports.
sub _syntax_has_feature {
  my ($elem, $feature) = @_;
  return ((grep {$_ eq $feature} _syntax_feature_list($elem)) > 0);
}

# $elem is a PPI::Statement::Include of "use syntax".
# Return a list of the feature names it imports.
sub _syntax_feature_list {
  my ($elem) = @_;
  ### _syntax_feature_list(): $elem && ref $elem
  my @ret;
  for ($elem = $elem->schild(2); $elem; $elem = $elem->snext_sibling) {
    if ($elem->isa('PPI::Token::Word')) {
      push @ret, $elem->content;
    } elsif ($elem->isa('PPI::Token::QuoteLike::Words')) {
      push @ret, $elem->literal;
    } elsif ($elem->isa('PPI::Token::Quote')) {
      push @ret, $elem->string;
    }
  }
  return @ret;
}

1;
__END__

=for stopwords boolean hashref eg Ryde

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon - require a semicolon at the end of code blocks

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to put a semicolon C<;> on the final statement of a
subroutine or block.

    sub foo {
      do_something();      # ok
    }

    sub bar {
      do_something()       # bad
    }

The idea is that if you add more code you don't have to notice the previous
line needs a terminator.  It's also more like the C language, if you
consider that a virtue.

This is only a matter of style since the code runs the same either way, and
on that basis this policy is low severity and under the "cosmetic" theme
(see L<Perl::Critic/POLICY THEMES>).

=head2 Same Line Closing Brace

By default (see L</CONFIGURATION> below) a semicolon is not required when
the closing brace is on the same line as the last statement.  This is good
for constants and one-liners.

    sub foo { 'my-constant-value' }     # ok

    sub square { return $_[0] ** 2 }    # ok

=head2 Final Value Expression

A semicolon is not required in places where the last statement is an
expression giving a value.

    map { some_thing();
          $_+123             # ok
        } @values;

    do {
      foo();
      1+2+3                  # ok
    }

This currently means

    do grep map sort                         # builtins

    reduce any all none notall first         # List::Util
    pairfirst pairgrep pairmap

    mapp map_pairwise grepp grep_pairwise    # List::Pairwise
    firstp first_pairwise lastp last_pairwise 

The module functions are always treated as expressions.  There's no check
for whether the respective module is actually in use.  Fully qualified names
like C<List::Util::first> are recognised too.

C<do {} while> or C<do {} until> loops are ordinary blocks, not expression
blocks, so still require a semicolon on the last statement inside.

    do {
      foo()                  # bad
    } until ($condition);

The last statement of a C<sub{}> is not considered an expression.  Perhaps
there could be an option to excuse all one-statement subs or even all subs
and have the policy just for nested code and control blocks.  For now the
suggestion is that if a sub is big enough to need a separate line for its
result expression then write an actual C<return> statement for maximum
clarity.

=head2 Try/Catch Blocks

The C<Try>, C<TryCatch> and C<Syntax::Feature::Try> modules all add C<try>
block forms.  These statements don't require a terminating semicolon (the
same as an C<if> doesn't).

    use TryCatch;
    sub foo {
      try {
          attempt_something();
      } catch {
          error_recovery();
      } # ok, no semi required here for TryCatch
    }

The insides of the C<try> and C<catch> are treated the same as other blocks.
But the C<try> statement itself doesn't require a semicolon.  (See policy
C<ValuesAndExpressions::ProhibitNullStatements> to notice one added
unnecessarily.)

For reference, C<PPI> doesn't know C<try>/C<catch> specifically, so when
they don't have a final semicolon the next statement runs together and the
nature of those parts might be lost.  This could upset things like
recognition of C<for> loops and could potentially make some perlcritic
reports go wrong.

The C<try>/C<catch> block exemption here is only for the modules with this
block syntax.  There are other try modules such as C<Try::Tiny> and friends
where a final semicolon is normal and necessary if more code follows
(because their C<try> and C<catch> are ordinary function calls prototyped to
take code blocks).

    use Try::Tiny;
    sub foo {
      try {
          attempt_something();
      } catch {
          error_recovery();
      } # bad, semi required here for Try::Tiny
    }

=head2 Disabling

If you don't care about this you can always disable from your
F<.perlcriticrc> file in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::RequireFinalSemicolon]

=head1 CONFIGURATION

=over 4

=item C<except_same_line> (boolean, default true)

If true (the default) then don't demand a semicolon if the closing brace is
on the same line as the final statement.

    sub foo { return 123 }     # ok  if "except_same_line=yes"
                               # bad if "except_same_line=no"

=item C<except_expression_blocks> (boolean, default true)

If true (the default) then don't demand a semicolon at the end of an
expression block, as described under L</Final Value Expression> above.

    # ok under "except_expression_blocks=yes"
    # bad under "except_expression_blocks=no"
    do { 1+2+3 }               
    map { $_+1 } @array
    grep {defined} @x

The statements and functions for this exception are currently hard coded.
Maybe in the future they could be configurable, though multi-line
expressions in this sort of thing tends to be unusual anyway.  (See policy
C<BuiltinFunctions::RequireSimpleSortBlock> to demand C<sort> is only one
line.)

=back

=head1 BUGS

It's very difficult to distinguish a code block from an anonymous hashref
constructor if there might be a function prototype in force, eg.

    foo { abc => 123 };   # hash ref normally
                          # code block if foo() has prototype

C<PPI> tends to assume code.  C<RequireFinalSemicolon> currently assumes
hashref so as to avoid false violations.  Any C<try>, C<catch> or C<finally>
are presumed to be code blocks (the various Try modules).  Perhaps other
common or particular functions or syntax with code blocks could be
recognised.  In general this sort of ambiguity is another good reason to
avoid function prototypes.

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommas>,
L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline>,
L<Perl::Critic::Policy::Subroutines::RequireFinalReturn>,
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements>,
L<Perl::Critic::Policy::BuiltinFunctions::RequireSimpleSortBlock>

L<List::Util>, L<List::Pairwise>,
L<Try>, L<TryCatch>, L<Syntax::Feature::Try>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses>.

=cut
