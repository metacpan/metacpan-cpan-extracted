# Copyright 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# perlcritic -s ProhibitIfIfSameLine /usr/share/perl5/Pod/Simple.pm
#    preceded by "return" so actually ok
# perlcritic -s ProhibitIfIfSameLine /usr/share/perl5/Tk/AbstractCanvas.pm
#    two ifs one line


package Perl::Critic::Policy::CodeLayout::ProhibitIfIfSameLine;
use 5.006;
use strict;
use warnings;
use Perl::Critic::Utils;

use base 'Perl::Critic::Policy';

our $VERSION = 94;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Statement::Compound');

my %compound_type_is_if = (if     => 1,
                           unless => 1);

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitIfIfSameLine elem: "$elem"
  ### type: $elem->type

  unless (_compound_statement_is_if($elem)) {
    ### not an "if" ...
    return;
  }

  if (_elems_any_separator ($elem->child(0), $elem->schild(0))) {
    ### leading whitespace in elem itself, so ok ...
    return;
  }

  my $prev = $elem->sprevious_sibling || return;
  unless ($prev->isa('PPI::Statement::Compound')
          && $compound_type_is_if{$prev->type}) {
    ### not preceded by an "if", so ok ...
    return;
  }

  if (_elems_any_separator ($prev->next_sibling, $elem)) {
    ### newlines after previous statement, so ok ...
    return;
  }

  return $self->violation
    ('Put a newline in "} if (x)" so it doesn\'t look like possible \"elsif\"',
     '',
     $elem);
}

# $elem is a PPI::Statement::Compound
# Return true if it's an "if" statement.
# Note this is not simply $elem->type eq "if", since type "if" includes
# "unless" statements, but _compound_statement_is_if() is true only on "if"
# statements.
#
sub _compound_statement_is_if {
  my ($elem) = @_;
  return (($elem->schild(0)||'') eq 'if');
}

# Return true if there is a suitable separator in $from or its following
# elements up to $to, but not including $to.
#
sub _elems_any_separator {
  my ($from, $to) = @_;
  for (;;) {
    if ($from == $to) {
      return 0;
    }
    if ($from =~ /\n/
        || $from->isa('PPI::Statement::Null')) {
      return 1;
    }
    $from = $from->next_sibling || return 0;
  }
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitIfIfSameLine - don't put if after if on same line

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to not to write an C<if> statement on the same line as
a preceding C<if>.

    if ($x) {
      ...
    } if ($y) {       # bad
      ...
    }

    if ($x) {
      ...
    } elsif ($y) {    # was "elsif" intended ?
      ...
    }

The idea is that an C<if> in the layout of an C<elsif> may be either a
mistake or will be confusing to a human reader.  On that basis this policy
is under the "bugs" theme and medium severity (see L<Perl::Critic/POLICY
THEMES>).

=head2 Unless

An C<unless...if> is treated the same.  Perl allows C<unless ... elsif> and
so the same potential confusion with an C<elsif> layout arises.

    unless ($x) {
      ...
    } if ($y) {       # bad
      ...
    }

    unless ($x) {
      ...
    } elsif ($y) {    # maybe meant to be "elsif" like this ?
      ...
    }

Whether C<unless ... elsif> is a good idea at all is another matter.
Sometimes it suits a combination of conditions.

=head2 Statement Modifiers

This policy only applies to a statement followed by a statement.  An C<if>
as a statement modifier is not affected.  It's usual to put that on the same
line as the statement it modifies.

    do {
      ...
    } if ($x);        # ok, statement modifier

=head2 All One Line

Two C<if> statements written on the same line will trigger the policy.

    if(1){one;}   if(2){two;}      # bad

Perhaps there could be an exception or option when both statements are
entirely on the one line, or some such, for code which is trying to be
compact.

=head2 Disabling

As always if you don't care about this then you can disable
C<ProhibitIfIfSameLine> from your F<.perlcriticrc> (see
L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::ProhibitIfIfSameLine]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

L<Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse>,
L<Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
