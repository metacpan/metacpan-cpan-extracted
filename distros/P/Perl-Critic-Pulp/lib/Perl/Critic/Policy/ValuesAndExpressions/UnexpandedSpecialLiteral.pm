# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# Change "12 Jul 2013 23:37:26 -0700" making __PACKAGE__ etc quoted by =>
# across newline.
#
# http://perl5.git.perl.org/perl.git/commit/21791330af556dc082f3ef837d772ba9a4d0b197
# http://perl5.git.perl.org/perl.git/patch/21791330af556dc082f3ef837d772ba9a4d0b197


package Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral;
use 5.006;
use strict;
use warnings;
use List::Util qw(min max);

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_perl_builtin
                           is_perl_builtin_with_no_arguments
                           precedence_of);

our $VERSION = 94;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => ('PPI::Token::Word');

my %specials = ('__FILE__'    => 1,
                '__LINE__'    => 1,
                '__PACKAGE__' => 1);

sub violates {
  my ($self, $elem, $document) = @_;
  $specials{$elem} or return;

  if (elem_is_quoted_by_big_comma ($elem)) {
    return $self->violation
      ("$elem is the literal string '$elem' on the left of a =>",
       '', $elem);
  }
  if (elem_is_solo_subscript ($elem)) {
    return $self->violation
      ("$elem is the literal string '$elem' in a hash subscript",
       '', $elem);
  }
  return;
}

# Perl::Critic::Utils::is_hash_key() does a similar thing to the following
# tests, identifying something on the left of "=>", or in a "{}" subscript.
# But here want those two cases separately since the subscript is only a
# violation if $elem also has no siblings.  (Separate cases allow a custom
# error message too.)
#
# { __FILE__ => 123 }
# ( __FILE__ => 123 )
#
sub elem_is_quoted_by_big_comma {
  my ($elem) = @_;

  my $next = $elem;
  for (;;) {
    $next = $next->next_sibling
      || return 0;  # nothing following
    if ($next->isa('PPI::Token::Whitespace')
        && $next->content !~ /\n/) {
      next;
    }
    return ($next->isa('PPI::Token::Operator') && $next->content eq '=>');
  }
}

# $hash{__FILE__}
#
#   PPI::Structure::Subscript   { ... }
#       PPI::Statement::Expression
#           PPI::Token::Word        '__PACKAGE__'
#
# and not multi subscript like $hash{__FILE__,123}
#
#   PPI::Structure::Subscript   { ... }
#     PPI::Statement::Expression
#       PPI::Token::Word        '__PACKAGE__'
#       PPI::Token::Operator    ','
#       PPI::Token::Number      '123'
#
sub elem_is_solo_subscript {
  my ($elem) = @_;

  # must be sole elem
  if ($elem->snext_sibling) { return 0; }
  if ($elem->sprevious_sibling) { return 0; }

  my $parent = $elem->parent || return 0;
  $parent->isa('PPI::Statement::Expression') || return 0;

  my $grandparent = $parent->parent || return 0;
  return $grandparent->isa('PPI::Structure::Subscript');
}

1;
__END__

=for stopwords filename parens Subhash Concated HashRef OOP Ryde bareword Unexpanded

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral - specials like __PACKAGE__ used literally

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It picks up some cases where the special literals C<__FILE__>,
C<__LINE__> and C<__PACKAGE__> (see L<perldata/Special Literals>) are used
with C<< => >> or as a hash subscript and so don't expand to the respective
filename, line number or package name.

    my $seen = { __FILE__ => 1 };          # bad
    return ('At:'.__LINE__ => 123);        # bad
    $obj->{__PACKAGE__}->{myextra} = 123;  # bad

In each case you get a string C<"__FILE__">, C<"__LINE__"> or
C<"__PACKAGE__">, as if

    my $seen = { '__FILE__' => 1 };
    return ('At:__LINE__' => 123);
    $obj->{'__PACKAGE__'}->{'myextra'} = 123;

where almost certainly it was meant to expand to the filename etc.  On that
basis this policy is under the "bugs" theme (see L<Perl::Critic/POLICY
THEMES>).

Expression forms like

    'MyExtra::'.__PACKAGE__ => 123    # bad

are still bad because the word immediately to the left of a C<< => >> is
quoted even when that word is part of an expression.

If you really do want a string C<"__FILE__"> etc then the suggestion is to
write the quotes, even if you're not in the habit of using quotes in hash
constructors etc.  It'll pass this policy and make it clear to everyone that
you really did want the literal string.

The C<__PACKAGE__> literal is new in Perl 5.004 but this policy is applied
to all code.  Even if you're targeting an earlier Perl extra quotes will
make it clear to users of later Perl that a literal string C<"__PACKAGE__">
is indeed intended.

=head2 Fat Comma After Newline

A C<< => >> fat comma only quotes when it's on the same line as the
preceding bareword, so in the following C<__PACKAGE__> is not quoted and is
therefore not reported by this policy,

    my %hash = (__PACKAGE__   # ok, expands
                =>
                'blah');

Of course whether or not writing this is a good idea is another matter.  It
might be a bit subtle to depend on the newline.  Probably a plain C<,> comma
would make the intention clearer than C<< => >>.

=head2 Class Data

A bad C<< $obj->{__PACKAGE__} >> can arise when you're trying to hang extra
data on an object using your package name to hopefully not clash with the
object's native fields.  Unexpanded C<__PACKAGE__> like that is a mistake
you'll probably only make once; after that the irritation of writing extra
parens or similar will keep it fresh in your mind!

As usual there's more than one way to do it when associating extra data to
an object.  As a crib here are some ways,

=over 4

=item Subhash C<< $obj->{(__PACKAGE__)}->{myfield} >>

The extra parens ensure expansion, and you get a sub-hash (or sub-array or
whatever) to yourself.  It's easy to delete the single entry from C<$obj>
if/when you later want to cleanup.

=item Subscript C<< $obj->{__PACKAGE__,'myfield'} >>

This makes entries in C<$obj>, with the C<$;> separator emulating
multidimensional arrays/hashes (see L<perlvar/$;>).

=item Concated key C<< $obj->{__PACKAGE__.'--myfield'} >>

Again entries in C<$obj>, but key formed by concatenation and an explicit
unlikely separator.  The advantage over C<,> is that the key is a constant
(after constant folding), instead of a C<join> on every access because C<$;>
could change.

=item Separate C<Tie::HashRef::Weak>

Use the object as a hash key and the value whatever data you want to
associate.  Keeps completely out of the object's hair and also works with
objects which use a "restricted hash" (see L<Hash::Util>) to prevent extra
keys.

=item Inside-Out C<Hash::Util::FieldHash>

Similar to HashRef with object as key and any value you want as the data
outside the object, hence the jargon "inside out".  The docs are very hard
to follow (as of its version 1.04), especially if you're not into OOP, but
it's actually fairly simple.

=item C<Scalar::Footnote>

Key/value pairs attached to an object using its "magic" list.  Doesn't touch
the object's contents but separate footnote users must be careful not to let
their keys clash.

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<perldata/"Special Literals">

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
