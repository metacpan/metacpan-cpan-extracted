# Copyright 2013, 2014, 2015, 2016 Kevin Ryde

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


# perlcritic -s ProhibitMarkupExtraClose ProhibitMarkupExtraClose.pm

# bad B<>
# perlcritic -s ProhibitMarkupExtraClose /usr/share/perl5/Curses/UI/Widget.pm

# email addr
# perlcritic -s ProhibitMarkupExtraClose /usr/share/perl5/Email/Address.pm


package Perl::Critic::Policy::Documentation::ProhibitMarkupExtraClose;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 93;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitMarkupExtraClose on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitMarkupExtraClose->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitMarkupExtraClose;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  $self->command_as_textblock(@_);
  return $self->SUPER::command(@_);  # for $self->{'in_begin'}
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock(): "in_begin=$self->{'in_begin'}"
  ### $text

  if ($self->{'in_begin'}) {
    return '';
  }

  my @pending = ($self->parse_text ($text, $linenum));
  ### @pending
  while (@pending) {
    my $obj = pop @pending;
    if (ref $obj && $obj->isa('Pod::ParseTree')) {
      ### $obj

      my @objs = $obj->children;
      push @pending, reverse @objs;

      foreach my $i (0 .. $#objs-1) {
        my $markup = $objs[$i];
        my $after  = $objs[$i+1];
        if (ref $markup && $markup->isa('Pod::InteriorSequence') # markup "C<>"
            && ! ref $after && $after =~ /^(>+)/) {  # followed by text ">"
          my $extra_angles = $1;

          # exception for <<F<blah>>> balanced angles before
          if ($i >= 1) {
            my $before = $objs[$i-1];
            my $before_angles = '<' x length($extra_angles); # "<"
            if (! ref $before && $before =~ m{\Q$before_angles\E$}) {
              next;
            }
          }

          my $cmd = $markup->cmd_name;
          my $left = $markup->left_delimiter;
          my $right = $markup->right_delimiter;
          $right =~ s/^ //;
          (undef, $linenum) = $markup->file_line;
          $self->violation_at_linenum
            ("Extra \"$extra_angles\" after $cmd$left$right markup",
             $linenum);
        }
      }
    }
  }
  return '';
}

1;
__END__

=for stopwords Ryde paren parens ie deref there'd backslashing Parens

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitMarkupExtraClose - extra closing ">" after markup

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It reports POD markup which has an extra closing ">" after a
markup.

=for ProhibitVerbatimMarkup allow next

    C<foo>>       # bad

The formatters are perfectly happy with this.  They take it as a ">" after
some markup.  But the idea of this policy is that it's likely to be a stray
extra closing ">", or at least will make a human reader wonder.  On that
basis this policy is under the "bugs" theme (see L<Perl::Critic/POLICY
THEMES>) but low severity.

An attempt to markup a readline like "E<lt>FHE<gt>" or similar will trigger
the policy because the first ">" closes the markup.

    C<<FH>>       # bad, markup is "<FH" and plain ">" follows

It's also possible this is meant to be some double-angle markup but is
missing the spaces required at the start and end.

    C<<bad double angles >>      # bad
    C<< good double angles >>    # ok

=head2 Surrounding Angles

Balanced surrounding angle brackets are allowed, such as for an email
address marked up like

=for ProhibitVerbatimMarkup allow next

    Some One <F<someone@foo.org>>

Whether this looks good from the formatters is another matter, but it's not
an erroneous extra close to the C<FE<lt>E<gt>> markup.

=head2 Disabling

If you don't care about this you can disable C<ProhibitMarkupExtraClose>
from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitMarkupExtraClose]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2013, 2014, 2015, 2016 Kevin Ryde

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
