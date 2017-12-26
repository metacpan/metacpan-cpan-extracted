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


# perlcritic -s ProhibitDuplicateSeeAlso ProhibitDuplicateSeeAlso.pm


package Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 96;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  # ### ProhibitDuplicateSeeAlso on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitDuplicateSeeAlso->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitDuplicateSeeAlso;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  $self->SUPER::command(@_);  # maintain 'in_begin'

  if ($command eq 'head1') {
    $self->{'in_see_also'} = ($text =~ /^\s*SEE\s+ALSO\b/);
    ### in_see_also: $self->{'in_see_also'}
  }
  return $self->command_as_textblock(@_);
}

sub textblock {
  my ($self, $text, $linenum, $pod_obj) = @_;
  ### textblock(): "linenum=$linenum"
  ### $text

  # Ignore all =begin blocks for now.
  #
  # Distinct "=begin :foo" and "=begin :bar" blocks would be mutually
  # exclusive and duplicates between don't matter.
  #
  # Multiple blocks "=begin :foo" or of an =begin and non-begin should not
  # duplicate, but expect such things to be rare.
  #
  unless ($self->{'in_begin'} eq '') {
    return '';
  }

  $self->interpolate($text, $linenum);
  return '';
}

sub interior_sequence {
  my ($self, $cmd, $text, $pod_obj) = @_;
  ### interior_sequence() ...

  if ($self->{'in_see_also'} && $cmd eq 'L') {
    my ($display, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($text);
    ### $name
    ### $section

    if (defined $name) {
      if (! defined $section) { $section = ''; }

      (undef, my $linenum) = $pod_obj->file_line;
      if (defined (my $prev_linenum = $self->{'seen'}->{$name,$section})) {

        $self->violation_at_linenum_and_textpos
          ("Duplicate SEE ALSO link L<$text> (already at line $prev_linenum)",
           $linenum, '', 0);
      } else {
        $self->{'seen'}->{$name,$section} = $linenum;
      }
    }
  }
  return '';
}

1;
__END__

=for stopwords Ryde clickable one's formatters filename

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso - don't duplicate LE<lt>E<gt> links in SEE ALSO

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to duplicate C<< LE<lt>FooE<gt> >> links in a SEE
ALSO section.

=for ProhibitVerbatimMarkup allow next 3

    =head1 SEE ALSO

    L<Foo::Bar>

    L<Foo::Bar>    # bad

The idea is that for readability a given cross-reference should be linked
just once and a duplicate is likely a leftover from too much cut-and-paste
etc.  This is minor matter so this policy is low severity and under the
C<cosmetic> theme (see L<Perl::Critic/POLICY THEMES>).

A module can appear more than once in a SEE ALSO, but only
C<< LE<lt>E<gt> >> linked once.  Anything else should be C<< CE<lt>E<gt> >>
markup or plain text.

=for ProhibitVerbatimMarkup allow next

    L<Foo::One>, L<Foo::Two>
    (C<Foo::Two> runs faster)     # ok

Links to different parts of a target POD are allowed,

=for ProhibitVerbatimMarkup allow next

    L<perlfunc/alarm>,
    L<perlfunc/kill>     # ok

=head2 Disabling

If you don't care about this then you can always disable
C<ProhibitDuplicateSeeAlso> from your F<.perlcriticrc> file in the usual way
(see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitDuplicateSeeAlso]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks>,
L<Perl::Critic::Policy::Documentation::ProhibitLinkToSelf>

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
