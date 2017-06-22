# Copyright 2009, 2010, 2011, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# use strict;
# $, = "\n";
# sub foo {
#   return 123;
# }
# sub x {
#     my %h = (-foo
#              => 'abc');
# print %h
#   }
# x();


package Perl::Critic::Policy::CodeLayout::ProhibitFatCommaNewline;
use 5.006;
use strict;
use warnings;
use version (); # but don't import qv()
use Perl::Critic::Utils;

# 1.084 for Perl::Critic::Document highest_explicit_perl_version()
use Perl::Critic::Policy 1.084;
use base 'Perl::Critic::Policy';

our $VERSION = 94;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Token::Operator');

my $v5008 = version->new('5.008');

sub violates {
  my ($self, $elem, $document) = @_;

  $elem->content eq '=>'
    or return; # some other operator

  my $prev = $elem->sprevious_sibling || return;
  if (! $prev->isa('PPI::Token::Word')) {
    ### previous not a word, so => acts as a plain comma, ok ...
    return;
  }
  if (! _elems_any_newline_between ($prev, $elem)) {
    ### no newline before =>, ok ...
    return;
  }

  my $word = $prev->content;

  # A builtin is never quoted by newline fat comma.
  # PPI 1.213 gives a word "-print" where it should be a negate of a
  # print(), so check the word "sans dash".
  if (Perl::Critic::Utils::is_perl_builtin(_sans_dash($word))) {
    return $self->violation
      ("Fat comma after newline doesn't quote Perl builtin \"$word\"",
       '',
       $elem);
  }

  # In 5.8 up words are quoted by newline fat comma, so ok.
  if (defined (my $doc_version = $document->highest_explicit_perl_version)) {
    if ($doc_version >= $v5008) {
      return;
    }
  }

  # In 5.6 and earlier newline fat comma doesn't quote.
  return $self->violation
    ("Fat comma after newline doesn't quote preceding bareword \"$word\"",
     '',
     $elem);
}

# return $str stripped of a leading "-", if it has one
sub _sans_dash {
  my ($str) = @_;
  $str =~ s/^-//;
  return $str;
}

# $from and $to are PPI::Element
# Return true if there's a "\n" newline anywhere in between those elements,
# not including either $from or $to themselves.
sub _elems_any_newline_between {
  my ($from, $to) = @_;
  if ($from == $to) { return 0; }
  for (;;) {
    $from = $from->next_sibling || return 0;
    if ($from == $to) { return 0; }
    if ($from =~ /\n/) { return 1; }
  }
}

1;
__END__

=for stopwords Ryde bareword builtin Builtin builtins Builtins eg parens

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitFatCommaNewline - keep a fat comma on the same line as its quoted word

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It reports a newline between a fat comma and preceding bareword for
Perl builtins,

    my %h = (caller         # bad, builtin called as a function
             => 'abc');

And for all words when targeting Perl 5.6 and earlier,

    use 5.006;
    my %h = (foo            # bad, all words in perl 5.6 and earlier
             => 'def');

When there's a newline between the word and the fat comma like this the word
executes as a function call (builtins always, and also user defined in Perl
5.6 and earlier), giving its return value rather than a word string.

Such a return value is probably not what was intended and on that basis this
policy is under the "bugs" theme and medium severity (see
L<Perl::Critic/POLICY THEMES>).

=head2 Builtins

Perl builtin functions with a newline always execute and give their return
value rather than a the quoted word.

    my %h = (print          # bad, builtin print() executes
             => "abc");
    # %h is key "1" value "abc"

The builtin is called with no arguments and that might provoke a warning
from some, but others like C<print> will quietly run.

Dashed builtin names such as C<-print> are also function calls, with a
negate operator.

    my %h = (-print       # bad, print() call and negate
             => "123");
    # h is key "-1" value "123"

For the purposes of this policy the builtins are C<is_perl_builtin()> from
L<Perl::Critic::Utils>.  It's possible this is more builtins than the
particular Perl in use, but guarding against all will help if going to a
newer Perl in the future.

=head2 Non-Builtins

In Perl 5.6 and earlier all words C<foo> execute as a function call when
there's a newline before the fat comma.

    sub foo {
      return 123
    }
    my %h = (foo
             => "def");
    # in Perl 5.6 and earlier %h is key "123" value "def"

Under C<use strict> an error is thrown if no such function, in the usual
way.  A word builtin is a function call if it exists (with a warning about
being interpreted that way), or a bareword if not.

This policy prohibits all words with newline before fat comma when targeting
Perl 5.6 or earlier.  This means either an explicit C<use 5.006> or smaller,
or no such minimum C<use> at all.

One subtle way an executing word with newline before fat comma can go
undetected (in 5.6 and earlier still) is an accidental redefinition of a
constant,

    use constant FOO => "blah";
    use constant FOO
      => "some value";
    # makes a constant subr called blah (in Perl 5.6)

C<constant.pm> might reject some return values from C<FOO()>, eg. a number,
but a string like "blah" here quietly expands and creates a constant
C<blah()>.

The difference between Perl 5.6 and later Perl is that in 5.6 the parser
only looked as far as a newline for a possible quoting C<=E<gt>> fat comma.
In Perl 5.8 and later for non-builtins the lookahead continues beyond any
newlines and comments.  For Perl builtins the behaviour is the same, in all
versions the lookahead stops at the newline.

=head2 Avoiding Problems

Putting the fat comma on the same line as the word ensures it quotes in all
cases.

    my %h = (-print =>    # ok, fat comma on same line quotes
             "123");

If for layout purposes you do want a newline then the suggestion is to give
a string or perhaps a parenthesized expression since that doesn't rely on
the C<=E<gt>> fat comma quoting.  A fat comma can still emphasize a
key/value pair.

    my %h = ('print'      # ok, string
             =>
             123);

Alternately if instead a function call is really what's intended (builtin or
otherwise) then parens can be used in the normal way to ensure it's a call
(as per L<perltrap> the rule being "if it looks like a function, it is a
function").

    my %h = (foo()        # ok, function call
             =>
             123);

=head2 Disabling

As always if you don't care about this then you can disable
C<ProhibitFatCommaNewline> from your F<.perlcriticrc> in the usual
way (see L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::ProhibitFatCommaNewline]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<perlop>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2011, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
