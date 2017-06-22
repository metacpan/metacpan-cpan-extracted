# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


package Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

use Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon;
use Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;
use Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt;
use Perl::Critic::Pulp::Utils 'elem_is_comma_operator';

# uncomment this to run the ### lines
#use Smart::Comments;


our $VERSION = 94;

use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Structure::Constructor',
                                  'PPI::Structure::List',
                                  # this policy is not for blocks, but PPI
                                  # mis-reports some anonymous hashref
                                  # constructors as blocks, so look at them
                                  'PPI::Structure::Block');

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitDuplicateHashKeys violates() ...

  ### consider: (ref $elem)."  $elem"

  if ($elem->isa('PPI::Structure::Constructor')) {
    ### constructor ...
    unless ($elem->start eq '{') {
      ### constructor is not a hash ...
      return;
    }

  } elsif ($elem->isa('PPI::Structure::Block')) {
    ### block ...
    if (Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon::_block_is_hash_constructor($elem) == 1) {
      ### block is a hash, continue ...
    } else {
      ### block is a block, or not certain, stop ...
      return;
    }

  } else { # PPI::Structure::List
    _elem_is_assigned_to_hash($elem) || return;
  }

  $elem = $elem->schild(0) || return;
  if ($elem->isa('PPI::Statement')) {
    $elem = $elem->schild(0) || return;
  }
  ### first elem: (ref $elem)."   $elem"

  my @elems = Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt::_elem_and_ssiblings($elem);
  ### elems len: scalar(@elems)

  @elems = map {_expand_qw($_)} @elems;
  ### expanded len: scalar(@elems)

  my $state = 'key';
  my @violations;
  my %seen_key;

  while (@elems) {
    ### $state
    my ($comma, @arg) = _take_to_comma(\@elems);

    if (! @arg) {
      ### consecutive commas ...
      next;
    }

    $elem = $arg[0];
    ### first of arg: (ref $elem)."   $elem"
    ### arg elem count: scalar(@arg)

    if ($elem->isa('PPI::Token::Cast') && $elem eq '%') {
      ### skip cast % even num elements ...
      $state = 'key';
      next;
    }
    # %$foo is an even number of things
    if (@arg == 1
        && $elem->isa('PPI::Token::Symbol')
        && $elem->raw_type eq '%') {
      ### skip hash var even num elements ...
      $state = 'key';
      next;
    }

    if ($state eq 'unknown' && $comma eq '=>') {
      $state = 'key';
    }

    if ($state eq 'key') {
      my $str;
      my $any_vars;
      if ($elem->isa('Perl::Critic::Pulp::ProhibitDuplicateHashKeys::Qword')) {
        ### qword ...
        $str = $elem->{'word'};
        $any_vars = 0;
        $elem = $elem->{'elem'};
      } else {
        ($str, $any_vars) = Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::_arg_string(\@arg, $document);
      }

      ### $str
      if (defined $str
          && ! $any_vars
          && $seen_key{$str}++) {
        ### found duplicate ...
        push @violations, $self->violation ("Duplicate hash key \"$str\"",
                                            '',
                                            $elem);
      }

      if ($any_vars >= 2) {
        ### expression, go to unknown ...
        $state = 'unknown';
      } else {
        $state = 'value';
      }

    } elsif ($state eq 'value') {
      if ($comma eq '=>') {
        ### hmm, something like a=>b=>..., assume next is a value still ...
        $state = 'value';
      } else {
        $state = 'key';
      }
    }
  }

  ### done ...
  return @violations;
}

sub _expand_qw {
  my ($elem) = @_;
  if (! $elem->isa('PPI::Token::QuoteLike::Words')) {
    return $elem;
  }
  my @words = $elem->literal;
  ### @words

  return map {
    Perl::Critic::Pulp::ProhibitDuplicateHashKeys::Qword->new
      (word => $_,
       elem => $elem);
  } @words;
}

sub _take_to_comma {
  my ($aref) = @_;
  my @ret;
  while (@$aref) {
    my $elem = shift @$aref;
    if ($elem->isa('Perl::Critic::Pulp::ProhibitDuplicateHashKeys::Qword')) {
      push @ret, $elem;
      return ',', @ret;
    }
    if (elem_is_comma_operator($elem)) {
      return $elem, @ret; # found a comma
    }
    push @ret, $elem; # not a comma
  }
  return '', @ret; # no final comma
}

# $elem is any PPI::Element
# return true if it's assigned to a hash,
#     %foo = ELEM
#     %$foo = ELEM
#     %{expr()} = ELEM
#
sub _elem_is_assigned_to_hash {
  my ($elem) = @_;
  ### _elem_is_assigned_to_hash() ...

  $elem = $elem->sprevious_sibling || return 0;

  ($elem->isa('PPI::Token::Operator') && $elem eq '=')
    or return 0;

  $elem = $elem->sprevious_sibling || return 0;
  ### assign to: "$elem"

  # %{expr} = () deref
  if ($elem->isa('PPI::Structure::Block')) {
    $elem = $elem->sprevious_sibling || return 0;
    ### cast hash ...
    return ($elem->isa('PPI::Token::Cast') && $elem eq '%');
  }

  if ($elem->isa('PPI::Token::Symbol')) {
    if ($elem->symbol_type eq '%') {
      ### yes, %foo ...
      return 1;
    }
    if ($elem->symbol_type eq '$') {
      ### symbol scalar ...
      # %$x=() or %$$$x=() deref
      for (;;) {
        $elem = $elem->sprevious_sibling || return 0;
        ### prev: (ref $elem)."  $elem"
        if ($elem->isa('PPI::Token::Magic')) {
          # PPI 1.215 mistakes %$$$r as magic variable $$
        } elsif ($elem->isa('PPI::Token::Cast')) {
          if ($elem ne '$') {
            ### cast hash: ($elem eq '%')
            return ($elem eq '%');
          }
        } else {
          return 0;
        }
      }
    }
  }

  ### no ...
  return 0;
}

{
  package Perl::Critic::Pulp::ProhibitDuplicateHashKeys::Qword;
  sub new {
    my ($class, %self) = @_;
    return bless \%self, $class;
  }
}

1;
__END__

=for stopwords Ryde hashref runtime

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys - disallow duplicate literal hash keys

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It reports duplicate literal hash keys in a hash assignment or
anonymous hashref.

    my %hash = (red   => 1,
                green => 2,
                red   => 3,    # bad
               );

    my $hashref = { red   => 1,
                    red   => 3,   # bad
                  };

Writing duplicate literal keys is probably a mistake or too much cut and
paste, and if the values are different will make it unclear to human readers
what was meant.  On that basis this policy is under the "bugs" theme and
medium severity (see L<Perl::Critic/POLICY THEMES>).

Perl is happy to run code like the above.  The value of the last "red" is
stored.  Doing this at runtime is good since you can give defaults which
further values from a caller or similar can replace.  For example,

    sub new {
      my $class = shift;
      return bless { foo => 'default',
                     bar => 'default',
                     @_ }, $class;
    }

    MyClass->new (foo => 'caller value'); # overriding 'default'

=head2 Expressions

Expressions within a hash list cannot be checked in general.  Some
concatenations of literals are recognised though they're probably unusual.

    my %hash = (ab      => 1,
                'a'.'b' => 2);  # bad

    my %hash = (__PACKAGE__.'a' => 1,
                __PACKAGE__.'a' => 2);  # bad

Function calls etc within a list might return an odd or even number of
values.  Fat commas C<=E<gt>> are taken as indicating a key when in doubt.

    my %hash = (blah()    => 1,  # guided by =>
                a         => 2,
                a         => 3); # bad

    my %hash = (blah(),
                a         => 2,  # guided by =>
                a         => 3); # bad

A hash substitution is always an even number of arguments,

    my %hash = (a         => 1,
                %blah,           # even number
                a         => 5); # bad, duplicate

C<qw()> words are recognised too

    my %hash = (qw(foo value1
                   foo value2));  # bad

=head2 Disabling

If you don't care about this you can always disable
C<ProhibitDuplicateHashKeys> from your F<.perlcriticrc> file in the usual
way (see L<Perl::Critic/CONFIGURATION>),

    [-ValuesAndExpressions::ProhibitDuplicateHashKeys]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommas>,
L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
