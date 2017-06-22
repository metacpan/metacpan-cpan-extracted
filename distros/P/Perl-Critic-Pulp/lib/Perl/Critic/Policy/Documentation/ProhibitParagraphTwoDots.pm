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


# perlcritic -s ProhibitParagraphTwoDots ProhibitParagraphTwoDots.pm
# perlcritic -s ProhibitParagraphTwoDots /usr/share/perl5/HTML/FormatText/WithLinks.pm

# Maybe foo.Z<>. to disguise two dots?


package Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 94;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitParagraphTwoDots on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitParagraphTwoDots->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitParagraphTwoDots;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  $self->SUPER::command(@_);  # maintain 'in_begin'
  return $self->command_as_textblock(@_);
}

sub textblock {
  my ($self, $text, $linenum, $pod_para) = @_;
  ### textblock: "linenum=$linenum"

  # "=begin :foo" is markup, check it.  Other =begin is not markup.
  unless ($self->{'in_begin'} eq '' || $self->{'in_begin'} =~ /^:/) {
    return '';
  }

  my $str = $self->interpolate($text, $linenum);
  ### $text
  ### $str

  if ($str =~ /(?<!\.)(\.\.\s*)$/sg) {
    $text =~ /(\s*)$/;
    my $pos = length($text) - length($1); # end of $text
    ### $pos
    $self->violation_at_linenum_and_textpos
      ("Paragraph ends with two dots (stray extra?)", $linenum, $text, $pos);
  }
  return '';
}
sub interior_sequence {
  my ($self, $cmd, $text, $pod_seq) = @_;
  if ($cmd eq 'X') {
    # index entry, no text output, but keep newlines for linenum
    $text =~ tr/\n//cd;

  } elsif ($cmd eq 'L') {
    my ($display, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($text);
    ### $display
    ### $inferred
    ### $name
    return $inferred;  # the display part, or the name part if no display
  }
  return $text;
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots - don't end a paragraph with two dots

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to end a POD paragraph with two dots,

    Some thing..                    # bad

This is a surprisingly easy typo, but of course is entirely cosmetic and on
that basis this policy is lowest severity and under the "cosmetic" theme
(see L<Perl::Critic/POLICY THEMES>).

Three or more dots as an ellipsis is fine,

    And some more of this ...       # ok

and anything within a paragraph is fine,

    Numbers 1 .. 10 are handled.    # ok

Only text paragraphs are checked.  Verbatim paragraphs can end with anything
at all

    This is an example,

        example_code (1 ..          # ok

There might be other dubious paragraph endings this policy could pick up,
but things like ";." or ":." can arise from code or smiley faces, so at the
moment only two dots are bad.

=head2 Disabling

If you don't care about this you can disable C<ProhibitParagraphTwoDots>
from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitParagraphTwoDots]

A C<## no critic> directive works in new enough C<Perl::Critic>, but if you
have an C<__END__> token then any C<no critic> generally must be before
that.

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<Perl::Critic::Policy::Documentation::ProhibitParagraphEndComma>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

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
