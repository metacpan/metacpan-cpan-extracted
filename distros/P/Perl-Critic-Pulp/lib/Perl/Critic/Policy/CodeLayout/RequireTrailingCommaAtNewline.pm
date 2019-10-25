# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


package Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline;
use 5.006;
use strict;
use warnings;
use List::Util;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call is_method_call);
use Perl::Critic::Pulp::Utils 'elem_is_comma_operator';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 97;

use constant supported_parameters =>
  ({ name           => 'except_function_calls',
     description    => 'Don\'t demand a trailing comma in function call argument lists.',
     behavior       => 'boolean',
     default_string => '0',
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => qw(pulp cosmetic);
use constant applies_to       => qw(PPI::Structure::List
                                    PPI::Structure::Constructor);

sub violates {
  my ($self, $elem, $document) = @_;
  ### elem: ref($elem)
  ### content: "$elem"

  if ($self->{'_except_function_calls'}) {
    my $prev;
    if (($prev = $elem->sprevious_sibling)
        && $prev->isa('PPI::Token::Word')
        && (is_function_call($prev) || is_method_call($prev))) {
      ### is_function_call: !! is_function_call($prev)
      ### is_method_call: !! is_method_call($prev)
      return;
    }
  }

  my @children = $elem->children;
  @children = map {$_->isa('PPI::Statement') ? $_->children : $_} @children;
  ### children: "@children"

  if (_is_list_single_expression($elem)) {
    ### an expression not a list as such ...
    return;
  }

  my $newline = 0;
  my $after;
  foreach my $child (reverse @children) {
    if ($child->isa('PPI::Token::Whitespace')
        || $child->isa('PPI::Token::Comment')) {
      ### HWS ...
      $newline ||= ($child->content =~ /\n/);
      ### $newline
      $after = $child;
    } else {
      if ($newline && ! elem_is_comma_operator($child)) {
        return $self->violation
          ('Put a trailing comma at last of a list ending with a newline',
           '',
           $after);
      }
      last;
    }
  }

  return;
}

# $elem is any PPI::Element
# Return true if it's a PPI::Structure::List which contains just a single
# expression.  Any "," or "=>" in the list is multiple expressions, but also
# the various rules of the policy are applied as to what is list context
# (array assignments, function calls).
#
sub _is_list_single_expression {
  my ($elem) = @_;
  $elem->isa('PPI::Structure::List')
    or return 0;

  my @children = $elem->schildren;
  {
    # eg. PPI::Structure::List
    #       PPI::Statement::Expression
    #         PPI::Token::Number   '1'
    #         PPI::Token::Operator         ','
    # so descend through PPI::Statement::Expression
    #
    @children = map { $_->isa('PPI::Statement::Expression')
                        ? ($_->schildren) : ($_)}  @children;
    if (List::Util::first {elem_is_comma_operator($_)} @children) {
      ### contains comma operator, so not an expression ...
      return 0;
    }
  }

  if (my $prev = $elem->sprevious_sibling) {
    if ($prev->isa('PPI::Token::Word')) {
      if ($prev eq 'return') {
        ### return statement without commas, is reckoned a single expression ...
        return 1;
      }
      if (is_function_call($prev)
          || is_method_call($prev)) {
        ### function or method call ...
        if ($children[-1] && $children[-1]->isa('PPI::Token::HereDoc')) {
          return 1;
        }
        return 0;
      }

    } elsif ($prev->isa('PPI::Token::Operator')
             && $prev eq '='
             && _is_preceded_by_array($prev)) {
      ### array assignment, not a single expression ...
      if ($children[-1] && $children[-1]->isa('PPI::Token::HereDoc')) {
        return 1;
      }
      return 0;
    }
  }

  ### no commas, not a call, so is an expression
  return 1;
}

sub _is_preceded_by_array {
  my ($elem) = @_;
  ### _is_preceded_by_array: "$elem"

  my $prev = $elem->sprevious_sibling || return 0;
  while ($prev->isa('PPI::Structure::Subscript')
         || $prev->isa('PPI::Structure::Block')) {
    ### skip: ref $prev
    $prev = $prev->sprevious_sibling || return 0;
  }
  ### prev: ref $prev
  if ($prev->isa('PPI::Token::Symbol')) {
    my $cast;
    if (($cast = $prev->sprevious_sibling)
        && $cast->isa('PPI::Token::Cast')) {
      return ($cast->content eq '@');
    }
    ### raw_type: $prev->raw_type
    return ($prev->raw_type eq '@');
  }
  if ($prev->isa('PPI::Token::Cast')) {
    return ($prev->content eq '@');
  }
  return 0;
}

1;
__END__

=for stopwords paren parens Parens hashref boolean Ryde runtime subr

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline - comma at end of list at newline

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to put a comma at the end of a list etc when it ends
with a newline,

    @array = ($one,
              $two     # bad
             );

    @array = ($one,
              $two,    # ok
             );

This makes no difference to how the code runs, so the policy is low severity
and under the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

The idea is to make it easier when editing the code since you don't have to
remember to add a comma to a preceding item when extending or re-arranging
lines.

If the closing bracket is on the same line as the last element then no comma
is required.  It can be be present if desired, but is not required.

    $hashref = { abc => 123,
                 def => 456 };   # ok

Parens around an expression are not a list, so nothing is demanded in for
instance

    $foo = (
            1
            + 2        # ok, an expression not a list
           );

But a single element paren expression is a list when it's in an array
assignment or a function or method call.

    @foo = (
            1
            + 2        # bad, list of one value
           );
            

    @foo = (
            1
            + 2,       # ok
           );

=head2 Return Statement

A C<return> statement with a single value is considered an expression so a
trailing comma is not required.

    return ($x
            + $y    # ok
            );

Whether such code is a single-value expression or a list of only one value
depends on how the function is specified.  There's nothing in the text (nor
even at runtime) which would say for sure.

It's handy to included parens around a single-value expression to make it
clear some big arithmetic is all part of the return, especially if you can't
remember precedence levels.  In such an expression a newline before the
final ")" can help keep a comment together with a term for a cut and paste,
or not lose a paren if commenting the last line, etc.  So for now the policy
is lenient.  Would an option be good though?

=head2 Here Documents

An exception is made for a single expression ending with a here-document.
This is slightly experimental, and might become an option, but the idea is
that a newline is necessary for a here-document within parens and so
shouldn't demand a comma.

    foo(<<HERE      # ok
    some text
    HERE
       );

This style is a little unusual but some people like the whole here-document
at the place its string result will expand.  If the code is all on one line
(see L<perlop/E<lt>E<lt>EOF>) then trailing comma considerations don't
apply.  But both forms work and so are a matter of personal preference.

    foo(<<HERE);
    some text
    HERE

Multiple values still require a final comma.  Multiple values suggests a
list and full commas guards against forgetting to add a comma if extending
or rearranging.

    foo(<<HERE,
    one
    HERE
        <<HERE      # bad
    two
    HERE
       );

=head2 Disabling

If you don't care about trailing commas like this you can as always disable
from F<.perlcriticrc> in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::RequireTrailingCommaAtNewline]

=head1 CONFIGURATION

=over 4

=item C<except_function_calls> (boolean, default false)

If true then function calls and method calls are not checked, allowing for
instance

    foo (
      1,
      2     # ok under except_function_calls
    );

The idea is that if C<foo()> takes only two arguments then you don't want to
write a trailing comma as it might suggest something more could be added.

Whether you write calls spread out this way is a matter of personal
preference.  If you do then enable C<except_function_calls> with the
following in your F<.perlcriticrc> file,

    [CodeLayout::RequireTrailingCommaAtNewline]
    except_function_calls=1

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommas>

=head2 Other Ways to Do It

This policy is a variation of C<CodeLayout::RequireTrailingCommas>.  That
policy doesn't apply to function calls or hashref constructors, and you may
find its requirement for a trailing comma in even one-line lists like
C<@x=(1,2,)> too much.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
